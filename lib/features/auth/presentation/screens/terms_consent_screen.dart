import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
import '../../data/models/auth_models.dart';
import '../controllers/auth_controller.dart';

class TermsConsentScreen extends ConsumerStatefulWidget {
  const TermsConsentScreen({super.key});

  static const routePath = '/auth/terms-consent';
  static const routeName = 'termsConsent';

  @override
  ConsumerState<TermsConsentScreen> createState() => _TermsConsentScreenState();
}

class _TermsConsentScreenState extends ConsumerState<TermsConsentScreen> {
  final ScrollController _termsScrollController = ScrollController();
  bool _hasScrolledTerms = false;
  bool _termsAccepted = false;
  bool _privacyAccepted = false;
  bool _isSubmitting = false;
  bool _isTermsScrollable = false;

  @override
  void initState() {
    super.initState();
    _termsScrollController.addListener(_onTermsScroll);
    final user = ref.read(authControllerProvider).valueOrNull?.user;
    if (user != null) {
      _termsAccepted = user.termsAccepted;
      _privacyAccepted = user.privacyAccepted;
    }
    // If content is not scrollable, consider it already "scrolled"
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_termsScrollController.hasClients) return;
      final max = _termsScrollController.position.maxScrollExtent;
      setState(() {
        _isTermsScrollable = max > 0;
        if (max <= 0) {
          _hasScrolledTerms = true;
        }
      });
    });
  }

  @override
  void dispose() {
    _termsScrollController
      ..removeListener(_onTermsScroll)
      ..dispose();
    super.dispose();
  }

  void _onTermsScroll() {
    if (_hasScrolledTerms) return;
    if (!_termsScrollController.hasClients) return;
    final max = _termsScrollController.position.maxScrollExtent;
    final offset = _termsScrollController.offset;
    if (max <= 0) return;
    if (offset >= max - 16) {
      setState(() {
        _hasScrolledTerms = true;
      });
    }
  }

  Future<void> _submit() async {
    if (!_termsAccepted || !_privacyAccepted) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.mustAcceptTermsAndPrivacy ??
                'Please accept the Terms & Conditions and Data Privacy / GDPR to continue.',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref
          .read(authControllerProvider.notifier)
          .updateProfile(
        UpdateProfilePayload(
          termsAccepted: true,
          privacyAccepted: true,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      final l10n = AppLocalizations.of(context); // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar( // ignore: use_build_context_synchronously
        SnackBar(
          content: Text(
            l10n?.failedToUpdateStatus ??
                'Failed to update legal settings. Please try again.',
          ),
          backgroundColor: Theme.of(context).colorScheme.error, // ignore: use_build_context_synchronously
        ),
      );
      setState(() {
        _isSubmitting = false;
      });
      return;
    }

    if (!context.mounted) return;
    setState(() {
      _isSubmitting = false;
    });
    // After confirming terms, always go to dashboard
    context.go(DashboardScreen.routePath); // ignore: use_build_context_synchronously
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.legalComplianceTitle ?? 'Legal & Compliance'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n?.legalComplianceTitle ?? 'Legal & Compliance',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                l10n?.scrollToAcceptTerms ??
                    'Scroll to the end of the Terms & Conditions to unlock the acceptance checkbox.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.7),
                    ),
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                  ),
                  child: Scrollbar(
                    controller: _termsScrollController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _termsScrollController,
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        l10n?.termsAndConditionsFullText ??
                            'By continuing you confirm that you have read and accept the platform\'s Terms & Conditions (AGB) and Data Privacy / GDPR policy.',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: cs.onSurface),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (_isTermsScrollable)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      _termsScrollController.animateTo(
                        _termsScrollController.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOut,
                      );
                    },
                    icon: const Icon(Icons.arrow_downward_rounded, size: 18),
                    label: Text(
                      l10n?.scrollToBottom ?? 'Scroll to bottom',
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _termsAccepted,
                onChanged: (!_hasScrolledTerms || _isSubmitting)
                    ? null
                    : (value) {
                        setState(() {
                          _termsAccepted = value ?? false;
                        });
                      },
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  l10n?.acceptTermsLabel ??
                      'I have read and accept the Terms & Conditions (AGB).',
                ),
                subtitle: !_hasScrolledTerms
                    ? Text(
                        l10n?.termsScrollHint ??
                            'Please scroll through the Terms & Conditions before accepting.',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.textMuted),
                      )
                    : null,
              ),
              CheckboxListTile(
                value: _privacyAccepted,
                onChanged: _isSubmitting
                    ? null
                    : (value) {
                        setState(() {
                          _privacyAccepted = value ?? false;
                        });
                      },
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  l10n?.acceptPrivacyLabel ??
                      'I have read and accept the Data Privacy / GDPR policy.',
                ),
                subtitle: Text(
                  l10n?.privacySummaryText ??
                      'Your data will be processed for account management, orders and security in line with our privacy policy.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: l10n?.save ?? 'Save',
                isLoading: _isSubmitting,
                onPressed: _isSubmitting ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

