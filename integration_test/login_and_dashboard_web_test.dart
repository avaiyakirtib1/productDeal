import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:productdeal/main.dart' as app;

/// Web E2E: Login page and dashboard flow (including API when credentials set).
/// Run: flutter test integration_test/login_and_dashboard_web_test.dart --platform chrome
/// Optional env for real API: TEST_LOGIN_EMAIL, TEST_LOGIN_PASSWORD
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Login and Dashboard (Web)', () {
    testWidgets('app starts and shows login or splash then login',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 15));

      await expectLater(
        find.text('Welcome back'),
        findsOneWidget,
      );
    });

    testWidgets('login form has email, password and sign in button',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 15));

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
      expect(find.byType(TextField), findsAtLeastNWidgets(1));
    });

    testWidgets('after valid login (if credentials set), dashboard appears',
        (WidgetTester tester) async {
      final email = const String.fromEnvironment(
        'TEST_LOGIN_EMAIL',
        defaultValue: '',
      );
      final password = const String.fromEnvironment(
        'TEST_LOGIN_PASSWORD',
        defaultValue: '',
      );

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 15));

      if (email.isEmpty || password.isEmpty) {
        expect(find.text('Welcome back'), findsOneWidget);
        return;
      }

      await tester.enterText(find.byType(TextField).first, email);
      await tester.enterText(find.byType(TextField).last, password);
      await tester.tap(find.text('Sign in'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle(const Duration(seconds: 10));

      expect(find.text('Hello'), findsOneWidget);
    });
  });
}
