import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/challenge.dart';
import '../services/challenge_service.dart';

class ChallengeVotingScreen extends StatefulWidget {
  final Challenge challenge;
  final String participantId;
  
  const ChallengeVotingScreen({
    Key? key, 
    required this.challenge,
    required this.participantId,
  }) : super(key: key);

  @override
  _ChallengeVotingScreenState createState() => _ChallengeVotingScreenState();
}

class _ChallengeVotingScreenState extends State<ChallengeVotingScreen> {
  final ChallengeService _challengeService = ChallengeService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  final Map<String, double> _criteria = {
    'technical': 0.0,
    'creativity': 0.0,
    'difficulty': 0.0,
    'quality': 0.0,
  };
  
  bool _isVoting = false;
  String? _comment;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1e7d32),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '🗳️ Голосування',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок
              _buildHeader(),
              const SizedBox(height: 20),
              
              // Критерії оцінювання
              _buildCriteriaSection(),
              const SizedBox(height: 20),
              
              // Коментар (опціонально)
              _buildCommentSection(),
              const SizedBox(height: 20),
              
              // Загальна оцінка
              _buildTotalScoreSection(),
              const SizedBox(height: 30),
              
              // Кнопка голосування
              _buildVoteButton(),
              const SizedBox(height: 20),
              
              // Пояснення критеріїв
              _buildCriteriaExplanation(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                widget.challenge.typeIcon,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.challenge.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Учасник: ${widget.participantId}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: const Text(
              'Голосування відкрите',
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriteriaSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 Критерії оцінювання',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          _buildCriteriaItem(
            '⚽ Технічне виконання',
            'Якість виконання технічних елементів',
            'technical',
            0.4,
            Colors.green,
          ),
          
          _buildCriteriaItem(
            '🎨 Креативність',
            'Оригінальність та творчий підхід',
            'creativity',
            0.3,
            Colors.purple,
          ),
          
          _buildCriteriaItem(
            '🔥 Складність',
            'Рівень складності виконаного',
            'difficulty',
            0.2,
            Colors.orange,
          ),
          
          _buildCriteriaItem(
            '📹 Якість відео',
            'Технічна якість запису',
            'quality',
            0.1,
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildCriteriaItem(String title, String description, String key, 
      double weight, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(weight * 100).toInt()}%',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Слайдер оцінки
          Row(
            children: [
              Text(
                '0',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: color,
                    inactiveTrackColor: color.withOpacity(0.3),
                    thumbColor: color,
                    overlayColor: color.withOpacity(0.2),
                    valueIndicatorColor: color,
                    valueIndicatorTextStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: Slider(
                    value: _criteria[key]!,
                    min: 0.0,
                    max: 10.0,
                    divisions: 10,
                    label: _criteria[key]!.toStringAsFixed(1),
                    onChanged: (value) {
                      setState(() {
                        _criteria[key] = value;
                      });
                    },
                  ),
                ),
              ),
              Text(
                '10',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          
          // Поточна оцінка
          Center(
            child: Text(
              'Оцінка: ${_criteria[key]!.toStringAsFixed(1)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '💬 Коментар (опціонально)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: (value) {
              _comment = value;
            },
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Додайте коментар до вашої оцінки...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF1e7d32)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalScoreSection() {
    final totalScore = _calculateTotalScore();
    final scoreColor = _getScoreColor(totalScore);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🏆 Загальна оцінка',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: scoreColor.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: scoreColor, width: 3),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      totalScore.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: scoreColor,
                      ),
                    ),
                    Text(
                      'з 10',
                      style: TextStyle(
                        fontSize: 14,
                        color: scoreColor.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Розбивка по критеріях
          _buildScoreBreakdown(),
        ],
      ),
    );
  }

  Widget _buildScoreBreakdown() {
    return Column(
      children: [
        _buildScoreRow('⚽ Техніка', _criteria['technical']!, 0.4, Colors.green),
        _buildScoreRow('🎨 Креативність', _criteria['creativity']!, 0.3, Colors.purple),
        _buildScoreRow('🔥 Складність', _criteria['difficulty']!, 0.2, Colors.orange),
        _buildScoreRow('📹 Якість', _criteria['quality']!, 0.1, Colors.blue),
      ],
    );
  }

  Widget _buildScoreRow(String label, double score, double weight, Color color) {
    final weightedScore = score * weight;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: score / 10,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 60,
            child: Text(
              '${weightedScore.toStringAsFixed(1)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoteButton() {
    final totalScore = _calculateTotalScore();
    final canVote = totalScore > 0;
    
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: canVote && !_isVoting ? _submitVote : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canVote ? const Color(0xFFFF9800) : Colors.grey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 8,
        ),
        child: _isVoting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                canVote ? '🗳️ Проголосувати (+1 монета)' : 'Встановіть оцінки',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildCriteriaExplanation() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Text(
                'Як оцінювати:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• 0-3: Погано\n'
            '• 4-5: Задовільно\n'
            '• 6-7: Добре\n'
            '• 8-9: Відмінно\n'
            '• 10: Ідеально',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Ваша оцінка впливає на фінальний результат учасника!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateTotalScore() {
    return _criteria['technical']! * 0.4 +
           _criteria['creativity']! * 0.3 +
           _criteria['difficulty']! * 0.2 +
           _criteria['quality']! * 0.1;
  }

  Color _getScoreColor(double score) {
    if (score >= 8.0) return Colors.green;
    if (score >= 6.0) return Colors.blue;
    if (score >= 4.0) return Colors.orange;
    return Colors.red;
  }

  Future<void> _submitVote() async {
    setState(() {
      _isVoting = true;
    });

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Користувач не авторизований');
      }

      // Перевірка чи користувач не голосує за себе
      if (currentUser.uid == widget.participantId) {
        throw Exception('Не можна голосувати за себе');
      }

      // Перевірка чи користувач вже голосував
      if (widget.challenge.votes.containsKey(currentUser.uid)) {
        throw Exception('Ви вже голосували за це відео');
      }

      // Підтвердження голосу
      final confirmed = await _showVoteConfirmation();
      if (!confirmed) {
        return;
      }

      // Відправка голосу
      await _challengeService.voteForVideo(
        widget.challenge.id,
        widget.participantId,
        _criteria,
      );

      // Показати повідомлення про успіх
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Ваш голос зараховано! +1 монета',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      // Повернутися назад
      Navigator.pop(context);
    } catch (e) {
      // Показати помилку
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Помилка: ${e.toString()}',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      setState(() {
        _isVoting = false;
      });
    }
  }

  Future<bool> _showVoteConfirmation() async {
    final totalScore = _calculateTotalScore();
    
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Підтвердження голосу'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ви впевнені, що хочете поставити оцінку ${totalScore.toStringAsFixed(1)}/10?'),
            const SizedBox(height: 16),
            const Text(
              'Після підтвердження змінити голос буде неможливо.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Скасувати'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF9800),
            ),
            child: const Text(
              'Підтвердити',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    ) ?? false;
  }
}


