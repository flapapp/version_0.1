import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/challenge.dart';

class ChallengeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Колекція челенджів
  CollectionReference get _challengesCollection => 
      _firestore.collection('challenges');

  // Отримати всі активні челенджі
  Stream<List<Challenge>> getActiveChallenges() {
    return _challengesCollection
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Challenge.fromFirestore(doc))
            .toList());
  }

  // Отримати челенджі за статусом
  Stream<List<Challenge>> getChallengesByStatus(ChallengeStatus status) {
    return _challengesCollection
        .where('isActive', isEqualTo: true)
        .where('status', isEqualTo: status.toString().split('.').last)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Challenge.fromFirestore(doc))
            .toList());
  }

  // Отримати челенджі за містом
  Stream<List<Challenge>> getChallengesByCity(String city) {
    return _challengesCollection
        .where('isActive', isEqualTo: true)
        .where('city', isEqualTo: city)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Challenge.fromFirestore(doc))
            .toList());
  }

  // Отримати челенджі за типом
  Stream<List<Challenge>> getChallengesByType(ChallengeType type) {
    return _challengesCollection
        .where('isActive', isEqualTo: true)
        .where('type', isEqualTo: type.toString().split('.').last)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Challenge.fromFirestore(doc))
            .toList());
  }

  // Отримати конкретний челендж
  Future<Challenge?> getChallenge(String challengeId) async {
    try {
      final doc = await _challengesCollection.doc(challengeId).get();
      if (doc.exists) {
        return Challenge.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting challenge: $e');
      return null;
    }
  }

  // Створити новий челендж
  Future<String?> createChallenge(Challenge challenge) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Користувач не авторизований');
      }

      // Перевірка ліміту челенджів для користувача
      final userChallenges = await _challengesCollection
          .where('creatorId', isEqualTo: currentUser.uid)
          .get();
      
      // Фільтруємо на клієнті
      final recentChallenges = userChallenges.docs.where((doc) {
        final challenge = Challenge.fromFirestore(doc);
        return challenge.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 30)));
      }).toList();

      if (recentChallenges.length >= 1) {
        throw Exception('Ліміт: 1 челендж на місяць');
      }

      final docRef = await _challengesCollection.add(challenge.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Error creating challenge: $e');
      rethrow;
    }
  }

  // Приєднатися до челенджу
  Future<bool> joinChallenge(String challengeId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Користувач не авторизований');
      }

      final challengeRef = _challengesCollection.doc(challengeId);
      
      // Перевірка чи можна приєднатися
      final challengeDoc = await challengeRef.get();
      if (!challengeDoc.exists) {
        throw Exception('Челендж не знайдено');
      }

      final challenge = Challenge.fromFirestore(challengeDoc);
      if (!challenge.canJoin) {
        throw Exception('Не можна приєднатися до цього челенджу');
      }

      // Перевірка чи користувач вже учасник
      if (challenge.participants.contains(currentUser.uid)) {
        throw Exception('Ви вже учасник цього челенджу');
      }

      // Додати учасника
      await challengeRef.update({
        'participants': FieldValue.arrayUnion([currentUser.uid]),
        'currentParticipants': FieldValue.increment(1),
      });

      // Нарахувати монети за участь (ставка входу)
      await _addCoinsToUser(currentUser.uid, challenge.entryFee);

      return true;
    } catch (e) {
      print('Error joining challenge: $e');
      rethrow;
    }
  }

  // Подати відео на челендж
  Future<bool> submitVideo(String challengeId, String videoUrl) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Користувач не авторизований');
      }

      final challengeRef = _challengesCollection.doc(challengeId);
      
      // Перевірка чи можна подати відео
      final challengeDoc = await challengeRef.get();
      if (!challengeDoc.exists) {
        throw Exception('Челендж не знайдено');
      }

      final challenge = Challenge.fromFirestore(challengeDoc);
      if (!challenge.canSubmit) {
        throw Exception('Не можна подати відео на цей челендж');
      }

      // Перевірка чи користувач учасник
      if (!challenge.participants.contains(currentUser.uid)) {
        throw Exception('Ви не учасник цього челенджу');
      }

      // Перевірка чи вже подано відео
      if (challenge.submissions.contains(currentUser.uid)) {
        throw Exception('Ви вже подали відео на цей челендж');
      }

      // Додати відео
      await challengeRef.update({
        'submissions': FieldValue.arrayUnion([currentUser.uid]),
      });

      return true;
    } catch (e) {
      print('Error submitting video: $e');
      rethrow;
    }
  }

  // Проголосувати за відео
  Future<bool> voteForVideo(String challengeId, String userId, Map<String, double> criteria) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Користувач не авторизований');
      }

      // Перевірка чи користувач не голосує за себе
      if (currentUser.uid == userId) {
        throw Exception('Не можна голосувати за себе');
      }

      final challengeRef = _challengesCollection.doc(challengeId);
      
      // Перевірка чи можна голосувати
      final challengeDoc = await challengeRef.get();
      if (!challengeDoc.exists) {
        throw Exception('Челендж не знайдено');
      }

      final challenge = Challenge.fromFirestore(challengeDoc);
      if (!challenge.canVote) {
        throw Exception('Голосування не відкрите');
      }

      // Перевірка чи користувач вже голосував
      if (challenge.votes.containsKey(currentUser.uid)) {
        throw Exception('Ви вже голосували за це відео');
      }

      // Розрахунок загальної оцінки за критеріями
      final totalRating = (criteria['technical'] ?? 0) * 0.4 +
                          (criteria['creativity'] ?? 0) * 0.3 +
                          (criteria['difficulty'] ?? 0) * 0.2 +
                          (criteria['quality'] ?? 0) * 0.1;

      // Зберегти голос
      await challengeRef.update({
        'votes.$currentUser.uid': totalRating,
        'detailedVotes.$currentUser.uid': criteria,
      });

      // Нарахувати монети за голос (+1 монета)
      await _addCoinsToUser(currentUser.uid, 1);

      return true;
    } catch (e) {
      print('Error voting for video: $e');
      rethrow;
    }
  }

  // Завершити челендж та визначити переможців
  Future<bool> completeChallenge(String challengeId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Користувач не авторизований');
      }

      final challengeRef = _challengesCollection.doc(challengeId);
      
      // Перевірка чи користувач створювач челенджу
      final challengeDoc = await challengeRef.get();
      if (!challengeDoc.exists) {
        throw Exception('Челендж не знайдено');
      }

      final challenge = Challenge.fromFirestore(challengeDoc);
      if (challenge.creatorId != currentUser.uid) {
        throw Exception('Тільки створювач може завершити челендж');
      }

      if (challenge.status != ChallengeStatus.voting) {
        throw Exception('Челендж не в стадії голосування');
      }

      // Розрахунок фінальних оцінок
      final finalScores = <String, double>{};
      for (final submission in challenge.submissions) {
        double totalScore = 0;
        int voteCount = 0;
        
        for (final vote in challenge.votes.values) {
          totalScore += vote;
          voteCount++;
        }
        
        if (voteCount > 0) {
          finalScores[submission] = totalScore / voteCount;
        }
      }

      // Визначення переможців
      final sortedParticipants = finalScores.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final winners = <String>[];
      if (sortedParticipants.isNotEmpty) {
        winners.add(sortedParticipants[0].key); // 1-е місце
      }
      if (sortedParticipants.length > 1) {
        winners.add(sortedParticipants[1].key); // 2-е місце
      }
      if (sortedParticipants.length > 2) {
        winners.add(sortedParticipants[2].key); // 3-є місце
      }

      // Нарахування призів
      if (winners.isNotEmpty) {
        await _addCoinsToUser(winners[0], challenge.firstPlacePrize.toInt()); // 1-е місце
      }
      if (winners.length > 1) {
        await _addCoinsToUser(winners[1], challenge.secondPlacePrize.toInt()); // 2-е місце
      }
      if (winners.length > 2) {
        await _addCoinsToUser(winners[2], challenge.thirdPlacePrize.toInt()); // 3-є місце
      }

      // Оновлення статусу челенджу
      await challengeRef.update({
        'status': ChallengeStatus.completed.toString().split('.').last,
        'finalScores': finalScores,
        'winners': winners,
        'endDate': Timestamp.fromDate(DateTime.now()),
      });

      return true;
    } catch (e) {
      print('Error completing challenge: $e');
      rethrow;
    }
  }

  // Отримати челенджі користувача
  Stream<List<Challenge>> getUserChallenges(String userId) {
    return _challengesCollection
        .where('participants', arrayContains: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Challenge.fromFirestore(doc))
            .toList());
  }

  // Отримати створені користувачем челенджі
  Stream<List<Challenge>> getCreatedChallenges(String userId) {
    return _challengesCollection
        .where('creatorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Challenge.fromFirestore(doc))
            .toList());
  }

  // Видалити челендж (тільки створювач)
  Future<bool> deleteChallenge(String challengeId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Користувач не авторизований');
      }

      final challengeDoc = await _challengesCollection.doc(challengeId).get();
      if (!challengeDoc.exists) {
        throw Exception('Челендж не знайдено');
      }

      final challenge = Challenge.fromFirestore(challengeDoc);
      if (challenge.creatorId != currentUser.uid) {
        throw Exception('Тільки створювач може видалити челендж');
      }

      await _challengesCollection.doc(challengeId).delete();
      return true;
    } catch (e) {
      print('Error deleting challenge: $e');
      rethrow;
    }
  }

  // Приватний метод для додавання монет користувачу
  Future<void> _addCoinsToUser(String userId, int coins) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      await userRef.update({
        'coins': FieldValue.increment(coins),
      });
    } catch (e) {
      print('Error adding coins to user: $e');
    }
  }

  // Отримати статистику челенджів
  Future<Map<String, dynamic>> getChallengeStats() async {
    try {
      final totalChallenges = await _challengesCollection.count().get();
      final activeChallenges = await _challengesCollection
          .where('isActive', isEqualTo: true)
          .count()
          .get();
      final completedChallenges = await _challengesCollection
          .where('status', isEqualTo: ChallengeStatus.completed.toString().split('.').last)
          .count()
          .get();

      return {
        'total': totalChallenges.count,
        'active': activeChallenges.count,
        'completed': completedChallenges.count,
      };
    } catch (e) {
      print('Error getting challenge stats: $e');
      return {'total': 0, 'active': 0, 'completed': 0};
    }
  }

  // Додати відео до челенджу
  Future<bool> addVideoToChallenge(String challengeId, String videoId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Користувач не авторизований');
      }

      final challengeRef = _challengesCollection.doc(challengeId);
      final challengeDoc = await challengeRef.get();
      
      if (!challengeDoc.exists) {
        throw Exception('Челендж не знайдено');
      }

      final challenge = Challenge.fromFirestore(challengeDoc);
      
      // Перевірка, чи користувач є учасником
      if (!challenge.participants.contains(currentUser.uid)) {
        throw Exception('Ви не є учасником цього челенджу');
      }

      // Перевірка, чи відкрито подання відео
      if (!challenge.isSubmissionOpen) {
        throw Exception('Подання відео закрито');
      }

      // Додаємо відео до челенджу
      await challengeRef.update({
        'submissions': FieldValue.arrayUnion([currentUser.uid]),
      });

      return true;
    } catch (e) {
      print('Error adding video to challenge: $e');
      rethrow;
    }
  }
}
