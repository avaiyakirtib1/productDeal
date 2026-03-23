import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_languages.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/language_controller.dart';
import '../../../../core/localization/language_onboarding_provider.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../auth/presentation/screens/login_screen.dart';

/// Onboarding language selection shown once when the user is not logged in
/// and has not yet completed this step. Current system/default locale is
/// pre-selected; tapping a language updates the app locale in real time.
class InitialLanguageSelectionScreen extends ConsumerWidget {
  const InitialLanguageSelectionScreen({super.key});

  static const routePath = '/onboarding/language';
  static const routeName = 'initialLanguageSelection';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final currentLocale = ref.watch(languageControllerProvider);
    final languageController = ref.read(languageControllerProvider.notifier);
    final hasSelectedNotifier = ref.read(hasSelectedLanguageProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Icon(
                    Icons.language_rounded,
                    size: 56,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n?.selectYourLanguage ?? 'Select your language',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n?.selectYourLanguageSubtitle ??
                        'Choose the language for the app. You can change it later in settings.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: AppLanguages.supportedCodes.length,
                itemBuilder: (context, index) {
                  final code = AppLanguages.supportedCodes[index];
                  final name = AppLanguages.contentLanguageNames[code] ?? code;
                  final isSelected = currentLocale.languageCode == code;
                  final language = AppLanguage.fromCode(code);
                  return _OnboardingLanguageTile(
                    displayName: name,
                    flag: language.flag,
                    isSelected: isSelected,
                    onTap: () => languageController.setLanguage(language),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: PrimaryButton(
                onPressed: () async {
                  await hasSelectedNotifier.setHasSelectedLanguage(true);
                  if (context.mounted) {
                    context.go(LoginScreen.routePath);
                  }
                },
                label: l10n?.continueButton ?? 'Continue',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingLanguageTile extends StatelessWidget {
  const _OnboardingLanguageTile({
    required this.displayName,
    required this.flag,
    required this.isSelected,
    required this.onTap,
  });

  final String displayName;
  final String flag;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.12)
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Text(
                  flag,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    displayName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? AppColors.primary
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: AppColors.primary,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
