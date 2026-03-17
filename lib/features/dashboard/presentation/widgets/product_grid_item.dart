import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/currency_controller.dart';
import '../../../../core/services/currency_service.dart';
import '../../data/models/dashboard_models.dart';
import '../../../orders/presentation/controllers/cart_controller.dart';
import '../../../reviews/presentation/widgets/rating_widget.dart';

class ProductGridItem extends ConsumerWidget {
  const ProductGridItem({
    super.key,
    required this.product,
    required this.onTap,
  });

  final DashboardProduct product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(
        currencyControllerProvider); // Rebuild when display currency changes
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            AspectRatio(
              aspectRatio: 1,
              child: CachedNetworkImage(
                imageUrl: product.imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (_, __, ___) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.primaryContainer,
                        theme.colorScheme.secondaryContainer,
                      ],
                    ),
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
            // Product Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    product.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Wholesaler & Unit
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${product.wholesalerName ?? ''} · ${product.unit}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Variant indicator
                      if (product.variants != null &&
                          product.variants!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.style,
                                size: 10,
                                color: theme.colorScheme.onSecondaryContainer,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${product.variants!.length}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSecondaryContainer,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Rating (if available)
                  if (product.averageRating != null &&
                      product.averageRating! > 0 &&
                      product.reviewCount != null &&
                      product.reviewCount! > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          RatingWidget(
                            rating: product.averageRating!,
                            size: 14,
                            showNumber: true,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${product.reviewCount})',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Price, Distance & Add-to-cart Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Price (EUR primary + USD indicator)
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.formatPriceEurOnly(
                                        product.displayPrice),
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '(${context.formatPriceUsdFromEur(product.displayPrice)})',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Distance Badge
                            if (product.distanceKm != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      size: 12,
                                      color: theme
                                          .colorScheme.onSecondaryContainer,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${product.distanceKm!.toStringAsFixed(1)} km',
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
                                        color: theme
                                            .colorScheme.onSecondaryContainer,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (!product.isOutOfStock)
                        IconButton(
                          icon: const Icon(Icons.add_shopping_cart),
                          color: theme.colorScheme.primary,
                          tooltip: AppLocalizations.of(context)?.addToCart ??
                              'Add to cart',
                          onPressed: () {
                          // If product has variants, use first variant ID
                          String? variantId;
                          if (product.variants != null &&
                              product.variants!.isNotEmpty) {
                            variantId = product.defaultVariant?.id ??
                                product.variants!.first.id;
                          }

                          ref
                              .read(cartControllerProvider.notifier)
                              .addDashboardProduct(product,
                                  quantity: 1, variantId: variantId);

                          // Clear any existing snackbar before showing new one
                          ScaffoldMessenger.of(context).clearSnackBars();
                          final l10n = AppLocalizations.of(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text(l10n?.addedToCart ?? '✅ Added to cart'),
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
