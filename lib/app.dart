import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import 'app_router.dart';
import 'core/constants/app_languages.dart';
import 'core/widgets/app_lifecycle_handler.dart';
import 'core/localization/app_localizations.dart';
import 'core/localization/language_controller.dart';
import 'core/services/fcm_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/deals/data/deal_live_data_service.dart';

class ProductDealApp extends ConsumerWidget {
  const ProductDealApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final authState = ref.watch(authControllerProvider);
    final locale = ref.watch(languageControllerProvider);

    // Initialize FCM and set deal_closed handler when user is logged in
    if (authState.valueOrNull != null) {
      ref.read(fcmInitializedProvider.future).catchError((e) {
        debugPrint('FCM initialization error: $e');
      });
      ref.watch(fcmDealClosedHandlerProvider);
    }

    // Global auth listener to react to automatic logouts (e.g. token expiry)
    ref.listen<AuthState>(authControllerProvider, (previous, next) async {
      final prevUser = previous?.valueOrNull?.user;
      final nextUser = next.valueOrNull?.user;
      final controller = ref.read(authControllerProvider.notifier);
      final reason = controller.lastLogoutReason;

      // Only handle automatic session expiry transitions
      if (prevUser != null &&
          nextUser == null &&
          reason == AuthLogoutReason.sessionExpired) {
        controller.clearLogoutReason();

        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            final l10n = AppLocalizations.of(dialogContext);
            return AlertDialog(
              title: Text(l10n?.sessionExpired ?? 'Session expired'),
              content: Text(
                l10n?.sessionExpiredMessage ??
                    'Your session has expired. Please log in again to continue using the app.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    GoRouter.of(dialogContext).go(LoginScreen.routePath);
                  },
                  child: Text(l10n?.loginAgain ?? 'Login again'),
                ),
              ],
            );
          },
        );
      }
    });

    return AppLifecycleHandler(
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'Product Deal',
        theme: AppTheme.lightTheme(GoogleFonts.interTextTheme()),
        routerConfig: router,
        locale: locale,
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLanguages.supportedLocales,
      ),
    );
  }
}
