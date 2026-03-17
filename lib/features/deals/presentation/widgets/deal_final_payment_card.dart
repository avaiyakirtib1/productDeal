import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/currency_controller.dart';
import '../../../../core/services/currency_service.dart';
import '../../../../shared/utils/snackbar_utils.dart';
import '../../data/repositories/deal_repository.dart';

/// Shows payment instructions when deal has succeeded and user has unpaid orders.
/// Payment is via invoice/bank transfer; instructions are sent by email.
class DealFinalPaymentCard extends ConsumerWidget {
  const DealFinalPaymentCard({
    super.key,
    required this.dealId,
    required this.orderIds,
    required this.totalAmountEur,
    this.onPaymentComplete,
  });

  final String dealId;
  final List<String> orderIds;
  final double totalAmountEur;
  final VoidCallback? onPaymentComplete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(currencyControllerProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final displayAmount =
        '${context.formatPriceEurOnly(totalAmountEur)} (${context.formatPriceUsdFromEur(totalAmountEur)})';

    return Card(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.payment,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n?.dealSucceededPayNow ?? 'Deal succeeded – pay now',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${l10n?.totalToPay ?? 'Total to pay'}: $displayAmount',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              l10n?.paymentInstructionsBankOnly ??
                  'Payment instructions were sent by email. Pay by bank transfer. If you\'ve already paid, the deal owner will confirm receipt.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (orderIds.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showReportPaymentDialog(
                    context,
                    ref,
                    orderIds.first,
                    l10n,
                    onPaymentComplete,
                  ),
                  icon: const Icon(Icons.payment, size: 20),
                  label: Text(
                    l10n?.reportPayment ?? "I've made the payment",
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static void _showReportPaymentDialog(
    BuildContext context,
    WidgetRef ref,
    String orderId,
    AppLocalizations? l10n,
    VoidCallback? onPaymentComplete,
  ) {
    final refController = TextEditingController();
    final txController = TextEditingController();
    final bankController = TextEditingController();
    final notesController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n?.reportPayment ?? "I've made the payment"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n?.reportPaymentSubtitle ??
                      'Share your payment details so we can verify',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: refController,
                  decoration: InputDecoration(
                    labelText: l10n?.referenceNumber ?? 'Reference number',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: txController,
                  decoration: InputDecoration(
                    labelText: l10n?.transactionId ?? 'Transaction ID',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bankController,
                  decoration: InputDecoration(
                    labelText: l10n?.bankName ?? 'Bank name',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  decoration: InputDecoration(
                    labelText: l10n?.paymentDetailsNotes ?? 'Additional notes (optional)',
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              child: Text(l10n?.cancel ?? 'Cancel'),
            ),
            FilledButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      setState(() => isSubmitting = true);
                      try {
                        await ref
                            .read(dealRepositoryProvider)
                            .reportDealOrderPayment(
                              orderId,
                              referenceNumber: refController.text.trim().isEmpty
                                  ? null
                                  : refController.text.trim(),
                              transactionId: txController.text.trim().isEmpty
                                  ? null
                                  : txController.text.trim(),
                              bankName: bankController.text.trim().isEmpty
                                  ? null
                                  : bankController.text.trim(),
                              notes: notesController.text.trim().isEmpty
                                  ? null
                                  : notesController.text.trim(),
                            );
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          onPaymentComplete?.call();
                          SnackbarUtils.showSuccess(
                            ctx,
                            l10n?.reportPaymentSuccess ??
                                'Payment details submitted. The deal owner will verify and update the order.',
                          );
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          setState(() => isSubmitting = false);
                          SnackbarUtils.showError(
                            ctx,
                            '${l10n?.failedToPlaceOrder ?? 'Failed'}: $e',
                          );
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n?.reportPayment ?? "I've made the payment"),
            ),
          ],
        ),
      ),
    );
  }
}
