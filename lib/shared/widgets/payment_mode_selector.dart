import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';

/// Payment mode selector: Cash (default), Bank Transfer, Invoice.
/// Used in registration and profile screens.
class PaymentModeSelector extends StatelessWidget {
  const PaymentModeSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.l10n,
  });

  final String value;
  final ValueChanged<String>? onChanged;
  final AppLocalizations? l10n;

  static const options = [
    ('cash_on_delivery', 'paymentMethodCash', 'paymentMethodCashDesc', Icons.money),
    ('bank_transfer', 'paymentMethodBankTransfer', 'paymentMethodBankTransferDesc', Icons.account_balance),
    ('invoice', 'paymentMethodInvoice', 'paymentMethodInvoiceDesc', Icons.receipt_long),
  ];

  String _tr(AppLocalizations? l10n, String key) {
    if (l10n == null) return key;
    switch (key) {
      case 'paymentMethodCash':
        return l10n.paymentMethodCash;
      case 'paymentMethodCashDesc':
        return l10n.paymentMethodCashDesc;
      case 'paymentMethodInvoice':
        return l10n.paymentMethodInvoice;
      case 'paymentMethodInvoiceDesc':
        return l10n.paymentMethodInvoiceDesc;
      case 'paymentMethodBankTransfer':
        return l10n.paymentMethodBankTransfer;
      case 'paymentMethodBankTransferDesc':
        return l10n.paymentMethodBankTransferDesc;
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: options.map((m) {
        final isSelected = value == m.$1;
        final title = _tr(l10n, m.$2);
        final desc = _tr(l10n, m.$3);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: onChanged != null ? () => onChanged!(m.$1) : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? cs.primaryContainer.withValues(alpha: 0.5)
                    : cs.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? cs.primary
                      : cs.outlineVariant.withValues(alpha: 0.5),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(m.$4,
                      size: 22,
                      color: isSelected ? cs.primary : cs.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          desc,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (isSelected) Icon(Icons.check_circle, color: cs.primary, size: 22),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Multi-select payment mode selector with checkboxes.
/// Used in registration (and profile) so users can accept multiple payment methods.
class PaymentModeSelectorMulti extends StatelessWidget {
  const PaymentModeSelectorMulti({
    super.key,
    required this.value,
    required this.onChanged,
    this.l10n,
  });

  final List<String> value;
  final ValueChanged<List<String>>? onChanged;
  final AppLocalizations? l10n;

  static const options = [
    ('cash_on_delivery', 'paymentMethodCash', 'paymentMethodCashDesc', Icons.money),
    ('bank_transfer', 'paymentMethodBankTransfer', 'paymentMethodBankTransferDesc', Icons.account_balance),
    ('invoice', 'paymentMethodInvoice', 'paymentMethodInvoiceDesc', Icons.receipt_long),
  ];

  String _tr(AppLocalizations? l10n, String key) {
    if (l10n == null) return key;
    switch (key) {
      case 'paymentMethodCash':
        return l10n.paymentMethodCash;
      case 'paymentMethodCashDesc':
        return l10n.paymentMethodCashDesc;
      case 'paymentMethodInvoice':
        return l10n.paymentMethodInvoice;
      case 'paymentMethodInvoiceDesc':
        return l10n.paymentMethodInvoiceDesc;
      case 'paymentMethodBankTransfer':
        return l10n.paymentMethodBankTransfer;
      case 'paymentMethodBankTransferDesc':
        return l10n.paymentMethodBankTransferDesc;
      default:
        return key;
    }
  }

  void _toggle(String mode) {
    if (onChanged == null) return;
    final selected = value.contains(mode);
    if (selected && value.length <= 1) return; // keep at least one
    final next = selected
        ? value.where((m) => m != mode).toList()
        : [...value, mode];
    onChanged!(next);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: options.map((m) {
        final isSelected = value.contains(m.$1);
        final title = _tr(l10n, m.$2);
        final desc = _tr(l10n, m.$3);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: onChanged != null ? () => _toggle(m.$1) : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? cs.primaryContainer.withValues(alpha: 0.5)
                    : cs.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? cs.primary
                      : cs.outlineVariant.withValues(alpha: 0.5),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: isSelected,
                    onChanged: onChanged != null
                        ? (_) => _toggle(m.$1)
                        : null,
                    fillColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) return cs.primary;
                      return null;
                    }),
                  ),
                  Icon(m.$4,
                      size: 22,
                      color: isSelected ? cs.primary : cs.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          desc,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
