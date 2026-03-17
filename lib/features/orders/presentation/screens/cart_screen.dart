import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/networking/api_client.dart';
import '../../../../core/localization/currency_controller.dart';
import '../../../../core/services/currency_service.dart';
import '../../../../shared/utils/snackbar_utils.dart';
import '../../../auth/data/models/auth_models.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/repositories/order_repository.dart';
import '../controllers/cart_controller.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  static const routePath = '/cart';
  static const routeName = 'cart';

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  bool _isPlacingOrder = false;

  @override
  Widget build(BuildContext context) {
    ref.watch(
        currencyControllerProvider); // Rebuild when display currency changes
    final cart = ref.watch(cartControllerProvider);
    final orderRepo = ref.watch(orderRepositoryProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.yourCart ?? 'Your Cart'),
      ),
      body: cart.items.isEmpty
          ? _EmptyCartView(l10n: l10n)
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              itemCount: cart.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = cart.items.values.elementAt(index);
                return _CartItemCard(
                  item: item,
                  onDecrease: () {
                    ref
                        .read(cartControllerProvider.notifier)
                        .updateQuantity(item.cartKey, item.quantity - 1);
                  },
                  onIncrease: () {
                    ref
                        .read(cartControllerProvider.notifier)
                        .updateQuantity(item.cartKey, item.quantity + 1);
                  },
                );
              },
            ),
      bottomNavigationBar: cart.items.isEmpty
          ? null
          : _CartSummaryBar(
              total: cart.totalAmount,
              isLoading: _isPlacingOrder,
              l10n: l10n,
              onPlaceOrder: _isPlacingOrder
                  ? null
                  : () async {
                      if (cart.items.isEmpty) return;

                      // RBAC: Only Kiosk/Shop owners can place orders
                      final authState = ref.read(authControllerProvider);
                      final session = authState.valueOrNull;
                      final userRole = session?.user.role;

                      if (userRole != UserRole.kiosk) {
                        if (mounted) {
                          final roleName = userRole == UserRole.admin
                              ? (l10n?.admins ?? 'Admins')
                              : userRole == UserRole.subAdmin
                                  ? (l10n?.subAdmins ?? 'Sub-Admins')
                                  : (l10n?.wholesalers ?? 'Wholesalers');
                          SnackbarUtils.showError(
                            context,
                            '$roleName ${l10n?.canOnlyViewProducts ?? 'can only view products. Only Kiosk/Shop accounts can place orders.'}',
                          );
                        }
                        return;
                      }

                      setState(() => _isPlacingOrder = true);

                      try {
                        final itemsPayload = cart.items.values
                            .map((item) => {
                                  'productId': item.productId,
                                  'quantity': item.quantity,
                                  if (item.variantId != null)
                                    'variantId': item.variantId,
                                })
                            .toList();

                        await orderRepo.createOrder(
                          items: itemsPayload,
                          paymentMethod: 'cash_on_delivery',
                        );
                        ref.read(cartControllerProvider.notifier).clear();

                        if (context.mounted) {
                          SnackbarUtils.showSuccess(
                            context,
                            '${l10n?.orderPlacedSuccessfully ?? 'Order placed successfully!'} ✅',
                          );
                        }
                      } catch (error) {
                        debugPrint('Order Placing Error: $error');
                        if (context.mounted) {
                          final message = error is DioException
                              ? mapDioException(error).message
                              : (l10n?.failedToPlaceOrder ?? 'Failed to place order');
                          SnackbarUtils.showError(context, message);
                        }
                      } finally {
                        if (mounted) setState(() => _isPlacingOrder = false);
                      }
                    },
            ),
    );
  }
}

class _EmptyCartView extends StatelessWidget {
  const _EmptyCartView({this.l10n});

  final AppLocalizations? l10n;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 64, color: cs.primary),
            const SizedBox(height: 12),
            Text(
              l10n?.emptyCart ?? 'Your cart is empty',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n?.addProductsToSeeThemHere ??
                  'Add products to see them here.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.item,
    required this.onDecrease,
    required this.onIncrease,
  });

  final dynamic item; // your cart item model type
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 360;

        Widget totalBlock() => Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  context.formatPriceEurOnly(item.lineTotal),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  '(${context.formatPriceUsdFromEur(item.lineTotal)})',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${context.formatPriceEurOnly(item.price)} ${AppLocalizations.of(context)?.each ?? 'each'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  '(${context.formatPriceUsdFromEur(item.price)}) ${AppLocalizations.of(context)?.each ?? 'each'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
              ],
            );

        return Card(
          elevation: 0,
          color: cs.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProductThumb(
                      imageUrl: (item.imageUrl as String?) ?? '',
                      title: (item.title as String?) ?? '',
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title row: give it space (fixes long names)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  maxLines: isCompact ? 3 : 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ),
                              if (!isCompact) ...[
                                const SizedBox(width: 10),
                                totalBlock(),
                              ],
                            ],
                          ),

                          const SizedBox(height: 6),

                          // Variant details
                          if (item.variantAttributes != null &&
                              (item.variantAttributes as Map).isNotEmpty) ...[
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: (item.variantAttributes as Map)
                                  .entries
                                  .map<Widget>((e) => Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: cs.surfaceContainerHighest
                                              .withValues(alpha: 0.6),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          '${e.key}: ${e.value}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                  color: cs.onSurfaceVariant),
                                        ),
                                      ))
                                  .toList(),
                            ),
                            const SizedBox(height: 6),
                          ],
                          if (item.variantSku != null) ...[
                            Text(
                              '${AppLocalizations.of(context)?.sku ?? 'SKU'}: ${item.variantSku}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: cs.onSurfaceVariant,
                                    fontFamily: 'monospace',
                                  ),
                            ),
                            const SizedBox(height: 6),
                          ],

                          // Qty + controls
                          Row(
                            children: [
                              _QtyButton(
                                icon: Icons.remove,
                                onPressed: onDecrease,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '${item.quantity}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(width: 10),
                              _QtyButton(
                                icon: Icons.add,
                                onPressed: onIncrease,
                              ),
                              const Spacer(),
                              if (isCompact) totalBlock(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
        ),
        child: Icon(icon, size: 18, color: cs.onSurfaceVariant),
      ),
    );
  }
}

class _ProductThumb extends StatelessWidget {
  const _ProductThumb({required this.imageUrl, required this.title});

  final String imageUrl;
  final String title;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: imageUrl.isEmpty
          ? null
          : () {
              showDialog(
                context: context,
                builder: (_) => Dialog(
                  insetPadding: const EdgeInsets.all(16),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: InteractiveViewer(
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        errorWidget: (context, url, error) => const Center(
                          child: Icon(Icons.error),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 72,
          height: 72,
          color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
          child: imageUrl.isEmpty
              ? Center(
                  child: Text(
                    title.isNotEmpty ? title[0].toUpperCase() : '?',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                )
              : CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => const Center(
                    child: Icon(Icons.error),
                  ),
                ),
        ),
      ),
    );
  }
}

class _CartSummaryBar extends StatelessWidget {
  const _CartSummaryBar({
    required this.total,
    required this.isLoading,
    required this.onPlaceOrder,
    this.l10n,
  });

  final double total;
  final bool isLoading;
  final VoidCallback? onPlaceOrder;
  final AppLocalizations? l10n;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(
              top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  l10n?.total ?? 'Total',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      context.formatPriceEurOnly(total),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '(${context.formatPriceUsdFromEur(total)})',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n?.fxDisclaimer ??
                  'FX rate is subject to change. Displayed amount is indicative.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onPlaceOrder,
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(l10n?.placeOrder ?? 'Place Order'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
