import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/storage/session_storage.dart';
import '../../auth/presentation/controllers/auth_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  static const routePath = '/splash';
  static const routeName = 'splash';

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    debugPrint('🚀 Splash: Initializing app...');

    // Small delay for splash screen visibility
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      // Check if user has a saved session
      final storage = ref.read(sessionStorageProvider);
      final savedSession = await storage.readSession();

      if (savedSession != null) {
        debugPrint('🔑 Splash: Found saved session, refreshing token...');

        // Refresh token to ensure it's valid and not expired
        final authController = ref.read(authControllerProvider.notifier);
        final refreshed = await authController.refreshTokens();

        if (refreshed) {
          debugPrint('✅ Splash: Token refreshed successfully');
        } else {
          debugPrint('⚠️ Splash: Token refresh failed (expired or invalid)');
          // Auth controller will handle logout automatically
        }
      } else {
        debugPrint('ℹ️ Splash: No saved session found');
      }
    } catch (e) {
      debugPrint('❌ Splash: Error during initialization: $e');
      // Continue anyway, router will redirect to login
    }

    debugPrint('✅ Splash: Initialization complete');
    // Router will handle navigation based on auth state
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.primary, Color(0xFF5F6BF1)],
                ),
              ),
              child:
                  const Icon(Icons.storefront, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 24),
            Text(
              'Product Deal',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (authState.isLoading)
              const CircularProgressIndicator()
            else
              Text(
                'Preparing your experience...',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textMuted),
              ),
          ],
        ),
      ),
    );
  }
}
