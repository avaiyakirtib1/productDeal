import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:productdeal/main.dart' as app;
import 'package:productdeal/core/networking/api_timing.dart';

/// Credentials for API timing analysis (local/test accounts).
const String _adminEmail = 'admin@productdeal.local';
const String _aliEmail = 'ali@productdeal.local';
const String _password = 'ChangeMe123!';

/// Runs app, logs in with given credentials, waits for dashboard, prints API
/// timing report. Returns recorded API timings for assertions.
Future<List<ApiTimingRecord>> runLoginAndPrintTiming(
  WidgetTester tester, {
  required String email,
  required String label,
}) async {
  ApiTimingCollector.enable();
  app.main();
  await tester.pumpAndSettle(const Duration(seconds: 15));

  if (find.text('Welcome back').evaluate().isNotEmpty) {
    await tester.enterText(find.byType(TextField).first, email);
    await tester.enterText(find.byType(TextField).last, _password);
    await tester.tap(find.text('Sign in'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle(const Duration(seconds: 15));
  }

  final records = ApiTimingCollector.getRecords();
  ApiTimingCollector.printReport(
    title: 'API TIMING ANALYSIS — Login: $label ($email)',
  );
  ApiTimingCollector.disable();
  ApiTimingCollector.clear();
  return records;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('API timing analysis (with correct credentials)', () {
    testWidgets('login as admin@productdeal.local and report API timings',
        (WidgetTester tester) async {
      final records = await runLoginAndPrintTiming(
        tester,
        email: _adminEmail,
        label: 'admin',
      );
      expect(
        records.any((r) => r.path.contains('auth') && r.path.contains('login')),
        true,
        reason: 'Login API should appear in timing report',
      );
    });

    testWidgets('login as ali@productdeal.local and report API timings',
        (WidgetTester tester) async {
      final records = await runLoginAndPrintTiming(
        tester,
        email: _aliEmail,
        label: 'ali',
      );
      expect(
        records.any((r) => r.path.contains('auth') && r.path.contains('login')),
        true,
        reason: 'Login API should appear in timing report',
      );
    });
  });
}
