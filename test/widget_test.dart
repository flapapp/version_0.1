import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flap_app/main.dart';

void main() {
  testWidgets('Welcome screen renders and navigates to Login', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Бачимо бренд
    expect(find.text('FLAP'), findsOneWidget);
    // Кнопки
    expect(find.text('УВІЙТИ'), findsOneWidget);
    expect(find.text('РЕЄСТРАЦІЯ'), findsOneWidget);

    // Переходимо на логін
    await tester.tap(find.text('УВІЙТИ'));
    await tester.pumpAndSettle();

    // Очікуємо елементи логіну
    expect(find.text('Увійти'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });
}