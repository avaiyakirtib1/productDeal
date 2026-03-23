import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_languages.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/language_controller.dart';

class LanguageSelectionScreen extends ConsumerStatefulWidget {
  const LanguageSelectionScreen({super.key});

  static const routePath = '/options/language';
  static const routeName = 'languageSelection';

  @override
  ConsumerState<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState
    extends ConsumerState<LanguageSelectionScreen> {
  bool _isChangingLanguage = false;
  AppLanguage? _changingLanguage;

  Future<void> _handleLanguageChange(AppLanguage language) async {
    final currentLocale = ref.read(languageControllerProvider);
    final languageController = ref.read(languageControllerProvider.notifier);

    // If already selected, just close
    if (currentLocale.languageCode == language.code) {
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      return;
    }

    // Set loading state
    setState(() {
      _isChangingLanguage = true;
      _changingLanguage = language;
    });

    try {
      // Wait for language sync to complete before restarting
      final success = await languageController.setLanguage(language);

      final ctx = context;
      if (ctx.mounted) {
        Navigator.of(ctx).pop();
        // Only restart app if server sync succeeded
        if (success) {
          Phoenix.rebirth(ctx);
        } else {
          // Show error message if sync failed
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text(
                  AppLocalizations.of(ctx)?.languageChangeFailed ??
                      'Failed to sync language preference. Please try again.'),
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      // Handle any errors
      final ctx = context;
      if (ctx.mounted) {
        setState(() {
          _isChangingLanguage = false;
          _changingLanguage = null;
        });
        ScaffoldMessenger.of(ctx).showSnackBar( // ignore: use_build_context_synchronously
          SnackBar(
            content: Text(AppLocalizations.of(ctx)?.failedToChangeLanguage ?? // ignore: use_build_context_synchronously
                'Failed to change language. Please try again.'),
            backgroundColor: Theme.of(ctx).colorScheme.error, // ignore: use_build_context_synchronously
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentLocale = ref.watch(languageControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.language ?? 'Language'),
      ),
      body: Stack(
        children: [
          ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  l10n?.languageSubtitle ?? 'Change app language',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
              _LanguageTile(
                language: AppLanguage.english,
                isSelected: currentLocale.languageCode == 'en',
                isLoading: _isChangingLanguage &&
                    _changingLanguage == AppLanguage.english,
                onTap: _isChangingLanguage
                    ? null
                    : () => _handleLanguageChange(AppLanguage.english),
              ),
              _LanguageTile(
                language: AppLanguage.german,
                isSelected: currentLocale.languageCode == 'de',
                isLoading: _isChangingLanguage &&
                    _changingLanguage == AppLanguage.german,
                onTap: _isChangingLanguage
                    ? null
                    : () => _handleLanguageChange(AppLanguage.german),
              ),
              _LanguageTile(
                language: AppLanguage.turkish,
                isSelected: currentLocale.languageCode == 'tr',
                isLoading: _isChangingLanguage &&
                    _changingLanguage == AppLanguage.turkish,
                onTap: _isChangingLanguage
                    ? null
                    : () => _handleLanguageChange(AppLanguage.turkish),
              ),
              _LanguageTile(
                language: AppLanguage.arabic,
                isSelected: currentLocale.languageCode == 'ar',
                isLoading: _isChangingLanguage &&
                    _changingLanguage == AppLanguage.arabic,
                onTap: _isChangingLanguage
                    ? null
                    : () => _handleLanguageChange(AppLanguage.arabic),
              ),
              _LanguageTile(
                language: AppLanguage.urdu,
                isSelected: currentLocale.languageCode == 'ur',
                isLoading: _isChangingLanguage &&
                    _changingLanguage == AppLanguage.urdu,
                onTap: _isChangingLanguage
                    ? null
                    : () => _handleLanguageChange(AppLanguage.urdu),
              ),
              _LanguageTile(
                language: AppLanguage.hindi,
                isSelected: currentLocale.languageCode == 'hi',
                isLoading: _isChangingLanguage &&
                    _changingLanguage == AppLanguage.hindi,
                onTap: _isChangingLanguage
                    ? null
                    : () => _handleLanguageChange(AppLanguage.hindi),
              ),
              _LanguageTile(
                language: AppLanguage.russian,
                isSelected: currentLocale.languageCode == 'ru',
                isLoading: _isChangingLanguage &&
                    _changingLanguage == AppLanguage.russian,
                onTap: _isChangingLanguage
                    ? null
                    : () => _handleLanguageChange(AppLanguage.russian),
              ),
              _LanguageTile(
                language: AppLanguage.ukrainian,
                isSelected: currentLocale.languageCode == 'uk',
                isLoading: _isChangingLanguage &&
                    _changingLanguage == AppLanguage.ukrainian,
                onTap: _isChangingLanguage
                    ? null
                    : () => _handleLanguageChange(AppLanguage.ukrainian),
              ),
            ],
          ),
          if (_isChangingLanguage)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          l10n?.changingLanguage ?? 'Changing language...',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.language,
    required this.isSelected,
    required this.onTap,
    this.isLoading = false,
  });

  final AppLanguage language;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Text(
        language.flag,
        style: const TextStyle(fontSize: 24),
      ),
      title: Text(language.displayName),
      subtitle: Text(_getLanguageNativeName(language)),
      trailing: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : isSelected
              ? Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                )
              : null,
      onTap: onTap,
      enabled: onTap != null && !isLoading,
    );
  }

  String _getLanguageNativeName(AppLanguage language) {
    switch (language) {
      case AppLanguage.english:
        return 'English';
      case AppLanguage.german:
        return 'Deutsch';
      case AppLanguage.turkish:
        return 'Türkçe';
      case AppLanguage.arabic:
        return 'العربية';
      case AppLanguage.urdu:
        return 'اردو';
      case AppLanguage.hindi:
        return 'हिन्दी';
      case AppLanguage.russian:
        return 'Русский';
      case AppLanguage.ukrainian:
        return 'Українська';
    }
  }
}
