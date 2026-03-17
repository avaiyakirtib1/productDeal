import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/snackbar.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/primary_text_field.dart';
import '../../data/models/auth_models.dart';
import '../controllers/auth_controller.dart';
import '../controllers/login_form_controller.dart';
import '../widgets/auth_header.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  static const routePath = '/login';
  static const routeName = 'login';

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  late final ProviderSubscription<AsyncValue<void>> _loginListener;

  @override
  void initState() {
    super.initState();
    _loginListener = ref.listenManual<AsyncValue<void>>(
        loginFormControllerProvider, (previous, next) {
      next.whenOrNull(
        data: (_) {
          // Don't manually redirect - let router handle it based on auth state
          // Router will automatically redirect based on user status (approved -> dashboard, pending -> waiting)
          final session = ref.read(authControllerProvider).valueOrNull;
          final l10n = AppLocalizations.of(context);
          if (session?.user.status == UserStatus.pending) {
            showSnackBar(
                context,
                l10n?.accountSubmittedForApproval ??
                    'Account submitted for approval. Dashboard will unlock once approved.');
          } else {
            final firstName = session?.user.fullName.split(' ').first ?? '';
            showSnackBar(
                context, '${l10n?.welcomeBack ?? 'Welcome back'}, $firstName!');
          }
          // Router will automatically redirect based on auth state
        },
        // Error handling moved to UI (shown in build method)
        // Keep snackbar as backup notification
        error: (error, stackTrace) {
          final message = ref
              .read(authControllerProvider.notifier)
              .resolveError(error)
              .message;
          // Error is now shown on the page itself, but keep snackbar for accessibility
          showSnackBar(context, message, isError: true);
        },
      );
    });
  }

  @override
  void dispose() {
    _loginListener.close();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(loginFormControllerProvider.notifier).submit(
          LoginPayload(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginFormControllerProvider);
    // Only show loading in button, not full screen
    final isLoading = loginState.isLoading;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            children: [
              Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return AuthHeader(
                    title: l10n?.welcomeBack ?? 'Welcome back',
                    subtitle: l10n?.signInToReach ??
                        'Sign in to reach approved wholesalers near you.',
                  );
                },
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Show error message on page if login failed
                      Builder(
                        builder: (context) {
                          final loginState =
                              ref.watch(loginFormControllerProvider);
                          final error = loginState.error;
                          if (error != null) {
                            final message = ref
                                .read(authControllerProvider.notifier)
                                .resolveError(error)
                                .message;
                            return Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .errorContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Theme.of(context).colorScheme.error,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      message,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .error,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      Builder(
                        builder: (context) {
                          final l10n = AppLocalizations.of(context);
                          return PrimaryTextField(
                            controller: _emailController,
                            label: l10n?.businessEmail ?? 'Business email',
                            keyboardType: TextInputType.emailAddress,
                            enabled: !isLoading, // Disable during login
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return l10n?.emailRequired ??
                                    'Email is required';
                              }
                              if (!value.contains('@')) {
                                return l10n?.provideValidEmail ??
                                    'Enter a valid email';
                              }
                              return null;
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Builder(
                        builder: (context) {
                          final l10n = AppLocalizations.of(context);
                          return PrimaryTextField(
                            controller: _passwordController,
                            label: l10n?.password ?? 'Password',
                            obscureText: _obscure,
                            enabled: !isLoading, // Disable during login
                            validator: (value) {
                              if (value == null || value.length < 8) {
                                return l10n?.minimum8CharactersRequired ??
                                    'Minimum 8 characters required';
                              }
                              return null;
                            },
                            suffix: IconButton(
                              icon: Icon(_obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined),
                              onPressed: isLoading
                                  ? null
                                  : () => setState(() => _obscure = !_obscure),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Builder(
                        builder: (context) {
                          final l10n = AppLocalizations.of(context);
                          return IgnorePointer(
                            ignoring:
                                isLoading, // Disable interaction during login
                            child: Opacity(
                              opacity: isLoading ? 0.5 : 1.0,
                              child: Text(
                                l10n?.forgotPassword ?? 'Forgot password?',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 36),
                      Builder(
                        builder: (context) {
                          final l10n = AppLocalizations.of(context);
                          return PrimaryButton(
                            label: l10n?.signIn ?? 'Sign in',
                            prefixIcon: Icons.lock_open_rounded,
                            onPressed: isLoading ? null : _submit,
                            isLoading: isLoading,
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      Builder(
                        builder: (context) {
                          final l10n = AppLocalizations.of(context);
                          return IgnorePointer(
                            ignoring:
                                isLoading, // Disable navigation during login
                            child: Opacity(
                              opacity: isLoading ? 0.5 : 1.0,
                              child: OutlinedButton(
                                onPressed: () =>
                                    context.push(RegisterScreen.routePath),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                      color: AppColors.primary, width: 1.5),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16), // button padding
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 2),
                                  child: Text(
                                    l10n?.createKioskOrWholesalerAccount ??
                                        'Create a kiosk or wholesaler account',
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
