import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/currency_service.dart';
import '../../data/models/dashboard_models.dart';

class VariantSelector extends StatelessWidget {
  const VariantSelector({
    super.key,
    required this.variants,
    required this.selectedVariantId,
    required this.onVariantSelected,
  });

  final List<ProductVariant> variants;
  final String? selectedVariantId;
  final ValueChanged<String> onVariantSelected;

  @override
  Widget build(BuildContext context) {
    if (variants.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final selectedVariant = variants.firstWhere(
      (v) => v.id == selectedVariantId,
      orElse: () => variants.firstWhere(
        (v) => v.isDefault,
        orElse: () => variants.first,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              AppLocalizations.of(context)?.selectVariant ?? 'Select Variant',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            _StockBadge(
              context: context,
              stock: selectedVariant.availableStock,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: variants.map((variant) {
            final isSelected = variant.id == selectedVariant.id;
            final isAvailable = variant.availableStock > 0;

            return GestureDetector(
              onTap: isAvailable ? () => onVariantSelected(variant.id) : null,
              child: Opacity(
                opacity: isAvailable ? 1.0 : 0.5,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surface,
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Attributes
                      if (variant.attributes != null &&
                          variant.attributes!.isNotEmpty)
                        ...variant.attributes!.entries.map(
                          (entry) => Text(
                            '${entry.key}: ${entry.value}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),

                      // SKU
                      Text(
                        variant.sku,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isSelected
                              ? theme.colorScheme.onPrimaryContainer
                              : theme.colorScheme.onSurfaceVariant,
                          fontFamily: 'monospace',
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Price (EUR primary + USD indicator)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.formatPriceEurOnly(variant.price),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '(${context.formatPriceUsdFromEur(variant.price)})',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isSelected
                                  ? theme.colorScheme.onPrimaryContainer
                                      .withValues(alpha: 0.9)
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _StockBadge extends StatelessWidget {
  const _StockBadge({
    required this.context,
    required this.stock,
  });

  final BuildContext context;
  final int stock;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (stock <= 0) {
      return Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          return _badge(
            theme,
            label: l10n?.outOfStock ?? 'OUT OF STOCK',
            bg: theme.colorScheme.errorContainer,
            fg: theme.colorScheme.onErrorContainer,
          );
        },
      );
    }

    if (stock < 10) {
      return Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          return _badge(
            theme,
            label: '${l10n?.onlyLeft ?? 'ONLY'} $stock ${l10n?.left ?? 'LEFT'}',
            bg: theme.colorScheme.tertiaryContainer,
            fg: theme.colorScheme.onTertiaryContainer,
          );
        },
      );
    }

    return const SizedBox.shrink();
  }

  Widget _badge(
    ThemeData theme, {
    required String label,
    required Color bg,
    required Color fg,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
