import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/currency_controller.dart';
import '../../../../core/services/currency_service.dart';
import '../../../../core/localization/language_controller.dart';
import '../../../deals/data/models/deal_models.dart';
import '../../../deals/data/repositories/deal_repository.dart';
import '../../data/models/order_models.dart';
import '../../data/repositories/order_repository.dart';

final _myOrdersProvider = FutureProvider.autoDispose<
    ({List<DealOrder> dealOrders, List<OrderSummary> productOrders})>(
  (ref) async {
    // Watch language to refresh when language changes
    ref.watch(languageControllerProvider);

    final dealRepo = ref.watch(dealRepositoryProvider);
    final orderRepo = ref.watch(orderRepositoryProvider);

    final results = await Future.wait([
      dealRepo.fetchMyOrders(),
      orderRepo.fetchMyOrders(),
    ]);

    return (
      dealOrders: results[0] as List<DealOrder>,
      productOrders: results[1] as List<OrderSummary>,
    );
  },
  name: 'MyOrdersProvider',
);

class MyOrdersScreen extends ConsumerWidget {
  const MyOrdersScreen({super.key});

  static const routePath = '/orders/my';
  static const routeName = 'myOrders';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(
        currencyControllerProvider); // Rebuild when display currency changes
    final ordersAsync = ref.watch(_myOrdersProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.myOrders ?? 'My Orders'),
      ),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                  '${l10n?.unableToLoadOrders ?? 'Unable to load your orders'}: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(_myOrdersProvider),
                child: Text(l10n?.retry ?? 'Retry'),
              ),
            ],
          ),
        ),
        data: (data) {
          final dealOrders = data.dealOrders;
          final productOrders = data.productOrders;

          if (dealOrders.isEmpty && productOrders.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n?.noOrdersYet ?? 'No orders yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n?.noOrdersYetMessage ??
                        'Browse products and deals to place your first order.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final entries = <_OrderEntry>[];

          for (final order in dealOrders) {
            entries.add(
              _OrderEntry.deal(
                // For deal orders, navigate to the deal detail page, so use dealId
                id: order.deal?.id ?? order.id,
                totalAmount: order.totalAmount,
                status: order.status.name.toUpperCase(),
                createdAt: order.createdAt,
                title: order.deal?.title ?? (l10n?.dealOrder ?? 'Deal order'),
              ),
            );
          }

          for (final order in productOrders) {
            final firstItemTitle = order.items.isNotEmpty
                ? order.items.first.title
                : (l10n?.productOrder ?? 'Product order');
            final itemCount =
                order.items.fold<int>(0, (sum, item) => sum + item.quantity);
            final title = itemCount > 1
                ? (l10n != null
                        ? l10n.itemPlusMore
                            .replaceAll('{item}', firstItemTitle)
                            .replaceAll('{n}', (itemCount - 1).toString())
                        : '$firstItemTitle + ${itemCount - 1} more')
                : firstItemTitle;

            entries.add(
              _OrderEntry.product(
                id: order.id,
                totalAmount: order.totalAmount,
                status: order.status.localizedLabel(l10n!),
                createdAt: order.createdAt,
                title: title,
              ),
            );
          }

          // Sort combined list by createdAt desc
          entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final entry = entries[index];
              final created =
                  DateFormat('d MMM, HH:mm').format(entry.createdAt.toLocal());

              return Card(
                child: ListTile(
                  onTap: () {
                    if (entry.type == _OrderType.deal) {
                      // Navigate to deal detail
                      context.push('/deals/${entry.id}');
                    } else {
                      // Navigate to product order detail
                      context.push('/orders/my/${entry.id}');
                    }
                  },
                  leading: Chip(
                    label: Text(
                      entry.type == _OrderType.deal
                          ? (l10n?.bid ?? 'Bid')
                          : (l10n?.orderLabel ?? 'Order'),
                    ),
                  ),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.formatPriceEurOnly(entry.totalAmount),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '(${context.formatPriceUsdFromEur(entry.totalAmount)})',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text('${l10n?.status ?? 'Status'}: ${entry.status}'),
                      Text(
                        created,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

enum _OrderType { deal, product }

class _OrderEntry {
  const _OrderEntry._({
    required this.type,
    required this.id,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    required this.title,
  });

  factory _OrderEntry.deal({
    required String id,
    required double totalAmount,
    required String status,
    required DateTime createdAt,
    required String title,
  }) {
    return _OrderEntry._(
      type: _OrderType.deal,
      id: id,
      totalAmount: totalAmount,
      status: status,
      createdAt: createdAt,
      title: title,
    );
  }

  factory _OrderEntry.product({
    required String id,
    required double totalAmount,
    required String status,
    required DateTime createdAt,
    required String title,
  }) {
    return _OrderEntry._(
      type: _OrderType.product,
      id: id,
      totalAmount: totalAmount,
      status: status,
      createdAt: createdAt,
      title: title,
    );
  }

  final _OrderType type;
  final String id;
  final double totalAmount;
  final String status;
  final DateTime createdAt;
  final String title;
}
