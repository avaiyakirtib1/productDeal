import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/data/models/auth_models.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/models/account_models.dart';
import '../utils/status_helpers.dart';

void _showSignOutConfirmation(
  BuildContext context,
  WidgetRef ref,
  AppLocalizations? l10n,
) {
  showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n?.useDifferentAccount ?? 'Use different account'),
      content: Text(
        l10n?.useDifferentAccountConfirm ??
            'Sign out to log in or register with a different account?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n?.cancel ?? 'Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l10n?.logout ?? 'Logout'),
        ),
      ],
    ),
  ).then((confirmed) {
    if (confirmed == true) {
      ref.read(authControllerProvider.notifier).logout();
    }
  });
}

class StatusSection extends ConsumerWidget {
  final AccountStatus status;
  final int countdownSeconds;

  const StatusSection({
    super.key,
    required this.status,
    required this.countdownSeconds,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final user = ref.read(authControllerProvider).valueOrNull?.user;
    final isWholesaler = user?.role == UserRole.wholesaler;
    final isBuyer = user?.role == UserRole.kiosk;

    String message;
    if (status.status == UserStatus.rejected ||
        status.status == UserStatus.needMoreInfo) {
      message = status.reason ??
          (l10n?.pleaseReviewAndResubmit ??
              'Please review and resubmit your documents.');
    } else if (isWholesaler) {
      message = l10n?.wholesalerVerificationMessage ??
          'Thanks! To activate your wholesaler account, please submit your business verification documents. Our admin will review and approve your account.';
    } else if (isBuyer) {
      message = l10n?.buyerVerificationMessage ??
          'Thanks! To activate your buyer account, please submit your identity verification documents. Our admin will review and approve your account.';
    } else {
      message = l10n?.generalVerificationMessage ??
          'Thanks! To activate your account, please submit verification documents. Our admin will review and approve your account.';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            getStatusColor(status.status).withValues(alpha: 0.1),
            getStatusColor(status.status).withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: getStatusColor(status.status).withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: getStatusColor(status.status),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  getStatusText(status.status, l10n),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Refreshing status in $countdownSeconds seconds...',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.5,
            ),
          ),
          if (status.reason != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange.shade200,
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${l10n?.adminNote ?? 'Admin note'}: ${status.reason}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.orange.shade900,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => _showSignOutConfirmation(context, ref, l10n),
            icon: const Icon(Icons.logout, size: 18),
            label: Text(
              l10n?.useDifferentAccount ?? 'Use different account',
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              foregroundColor: theme.colorScheme.primary,
              side: BorderSide(color: theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}
