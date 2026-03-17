import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class EmailSection extends ConsumerStatefulWidget {
  const EmailSection({super.key});

  @override
  ConsumerState<EmailSection> createState() => _EmailSectionState();
}

class _EmailSectionState extends ConsumerState<EmailSection> {
  bool _emailOpened = false;

  Future<void> _openEmailApp() async {
    final user = ref.read(authControllerProvider).valueOrNull?.user;
    if (user == null) return;

    final email = 'x@gmail.com'; // Replace with actual admin email
    final subject =
        'Account Verification - Product Deal - ${user.fullName} - ${user.id}';
    final body = '''Hello Admin,
I'm requesting account approval.

**User details**

* Full name: ${user.fullName}
* Email: ${user.email}
* Phone: ${user.phone ?? 'Not provided'}
* User ID: ${user.id}
* Company/Business name: ${user.businessName ?? 'Not provided'}

I have attached my verification document(s): [Business license / Driver's license / ID card].

Thanks.''';

    final uri = Uri(
      scheme: 'mailto',
      path: email,
      query:
          'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        setState(() => _emailOpened = true);
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n?.emailDraftOpened ??
                  'Email draft opened. Please send it to complete submission. Our admin will verify your documents and update your account status.'),
              backgroundColor: Colors.blue,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '${l10n?.couldNotOpenEmailApp ?? 'Could not open email app. Please send an email to'} $email ${l10n?.manually ?? 'manually'}.'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${l10n?.failedToOpenEmail ?? 'Failed to open email'}: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.email_outlined,
                  color: Colors.orange.shade700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n?.sendByEmail ?? 'Send by Email',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.blue.shade200,
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue.shade700,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n?.emailOptionDescription ??
                        'Alternatively, you can send your verification documents directly via email. Our admin will verify the documents and update your account status accordingly.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.blue.shade900,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openEmailApp,
              icon: const Icon(Icons.email),
              label: Text(l10n?.openEmailToAdmin ?? 'Open Email to Admin'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(
                  color: Colors.blue.shade300,
                  width: 1.5,
                ),
              ),
            ),
          ),
          if (_emailOpened) ...[
            const SizedBox(height: 12),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.9 + (value * 0.1),
                  child: Opacity(
                    opacity: value,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.shade200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: Colors.blue.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              l10n?.emailDraftOpened ??
                                  'Email draft opened. Please send it to complete submission. Our admin will verify your documents and update your account status.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.blue.shade900,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
