import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/currency_controller.dart';
import '../../../../core/services/currency_service.dart';
import '../../data/models/dashboard_models.dart';
import '../../../orders/presentation/controllers/cart_controller.dart';
import '../../../reviews/presentation/widgets/rating_widget.dart';

class ProductListItem extends ConsumerWidget {
  const ProductListItem({
    super.key,
    required this.product,
    required this.onTap,
    this.margin = const EdgeInsets.only(bottom: 5), // Amazon uses thin dividers
    this.padding = const EdgeInsets.all(5),
  });

  final DashboardProduct product;
  final VoidCallback onTap;
  final EdgeInsets margin;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(
        currencyControllerProvider); // Rebuild when display currency changes
    final theme = Theme.of(context);

    return Container(
      // Replaced fixed height with dynamic constraint
      margin: margin,
      // height: 160, // REMOVED to prevent overflow
      constraints: const BoxConstraints(minHeight: 160),
      color: Colors.white, // Amazon/Flipkart usually use flat white backgrounds
      padding: padding,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // --- LEFT: IMAGE SECTION ---
              _buildImageSection(theme),

              const SizedBox(width: 12),

              // --- RIGHT: PRODUCT INFO ---
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.black87,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Wholesaler name
                    if (product.wholesalerName != null &&
                        product.wholesalerName!.isNotEmpty) ...[
                      Text(
                        product.wholesalerName!,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4), // Fixed width->height
                    ],
                    // Rating Row (Amazon Style)
                    if (product.averageRating != null)
                      Row(
                        children: [
                          RatingWidget(
                            rating: product.averageRating!,
                            size: 14,
                            showNumber: false,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${product.reviewCount ?? 0}',
                            style: TextStyle(
                                color: Colors.blue.shade700, fontSize: 12),
                          ),
                        ],
                      ),

                    const SizedBox(height: 8),

                    // Price Section (Flipkart Style)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              context.formatPriceEurOnly(product.displayPrice,
                                  decimalDigits: 0),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Mocking a "Discount" UI (EUR only)
                            Text(
                              context.formatPriceEurOnly(
                                  product.displayPrice * 1.2,
                                  decimalDigits: 0),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '(${context.formatPriceUsdFromEur(product.displayPrice)})',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Add to Cart / Variants Button (Bottom Action)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildTag(
                            product.distanceKm != null
                                ? '${product.distanceKm!.toStringAsFixed(1)} km'
                                : product.unit,
                            theme),
                        if (!product.isOutOfStock)
                          _buildAddToCartButton(theme, ref, context),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(ThemeData theme) {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: CachedNetworkImage(
              imageUrl: product.imageUrl,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover, // Android centerCrop
            ),
          ),
          if ((product.reviewCount ?? 0) >= 1)
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                color: Colors.orange,
                child: const Text(
                  'Best Seller',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(text,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
    );
  }

  Widget _buildAddToCartButton(
      ThemeData theme, WidgetRef ref, BuildContext context) {
    //onPressed: () {
    //   String? variantId;
    //   if (product.variants?.isNotEmpty ?? false) {
    //     variantId = product.defaultVariant?.id ?? product.variants!.first.id;
    //   }
    //   ref.read(cartControllerProvider.notifier).addDashboardProduct(
    //         product,
    //         quantity: 1,
    //         variantId: variantId,
    //       );
    // }
    return InkWell(
      onTap: () {
        String? variantId;
        if (product.variants?.isNotEmpty ?? false) {
          variantId = product.defaultVariant?.id ?? product.variants!.first.id;
        }
        ref.read(cartControllerProvider.notifier).addDashboardProduct(
              product,
              quantity: 1,
              variantId: variantId,
            );
      },
      child: Icon(
        Icons.add_shopping_cart,
        size: 20,
        color: theme.colorScheme.primary,
      ),
    );
  }
}
