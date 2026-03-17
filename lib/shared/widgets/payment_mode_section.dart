import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import 'payment_mode_selector.dart';

/// Reusable Payment Mode section: selector + conditional payment fields.
/// Use in: registration, profile, create deal, create product.
///
/// - [value]: current payment mode (cash_on_delivery, bank_transfer, invoice)
/// - [onChanged]: callback when mode changes
/// - [paymentFieldsBuilder]: when mode is invoice or bank_transfer, build this widget
/// - [title]: optional custom title (default: Payment Mode)
/// - [subtitle]: optional custom subtitle
/// - [enabled]: whether the selector is enabled (e.g. during save)
class PaymentModeSection extends StatelessWidget {
  const PaymentModeSection({
    super.key,
    required this.value,
    required this.onChanged,
    this.paymentFieldsBuilder,
    this.title,
    this.subtitle,
    this.enabled = true,
    this.l10n,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final Widget Function(BuildContext context)? paymentFieldsBuilder;
  final String? title;
  final String? subtitle;
  final bool enabled;
  final AppLocalizations? l10n;

  static const _bankTransfer = 'bank_transfer';
  static const _invoice = 'invoice';

  static bool needsPaymentFields(String mode) =>
      mode == _bankTransfer || mode == _invoice;

  @override
  Widget build(BuildContext context) {
    final l10n = this.l10n ?? AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title ?? (l10n?.paymentMode ?? 'Payment Mode'),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
        const SizedBox(height: 12),
        PaymentModeSelector(
          value: value,
          onChanged: enabled ? onChanged : null,
          l10n: l10n,
        ),
        if (needsPaymentFields(value) && paymentFieldsBuilder != null) ...[
          const SizedBox(height: 24),
          paymentFieldsBuilder!(context),
        ],
      ],
    );
  }
}
