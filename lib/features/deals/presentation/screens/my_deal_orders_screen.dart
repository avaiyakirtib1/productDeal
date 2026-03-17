import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/currency_controller.dart';
import '../../../../core/services/currency_service.dart';
import '../../data/models/deal_models.dart';
import '../../data/repositories/deal_repository.dart';

final myDealOrdersProvider =
    FutureProvider.autoDispose<List<DealOrder>>((ref) async {
  final repo = ref.watch(dealRepositoryProvider);
  return repo.fetchMyOrders();
});

class MyDealOrdersScreen extends ConsumerWidget {
  const MyDealOrdersScreen({super.key});

  static const routePath = '/deals/orders/my';
  static const routeName = 'myDealOrders';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(
        currencyControllerProvider); // Rebuild when display currency changes
    final ordersAsync = ref.watch(myDealOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)?.myDealOrders ?? 'My deal orders',
        ),
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
                '${AppLocalizations.of(context)?.unableToLoadOrders ?? 'Unable to load your orders'}: $error',
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(myDealOrdersProvider),
                child: Text(
                  AppLocalizations.of(context)?.retry ?? 'Retry',
                ),
              ),
            ],
          ),
        ),
        data: (orders) {
          if (orders.isEmpty) {
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
                    AppLocalizations.of(context)?.noDealOrdersYet ??
                        'No deal orders yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)?.browseDealsPlaceFirstOrder ??
                        'Browse active deals and place your first order.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final order = orders[index];
              final deal = order.deal;
              final created =
                  DateFormat('d MMM, HH:mm').format(order.createdAt.toLocal());

              return Card(
                child: ListTile(
                  onTap: deal != null
                      ? () => context.push('/deals/${deal.id}')
                      : null,
                  title: Text(
                    '${order.quantity} units · '
                    '${context.formatPriceEurOnly(order.totalAmount)} '
                    '(${context.formatPriceUsdFromEur(order.totalAmount)})',
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (deal != null)
                        Text(
                          deal.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      Text(
                        '${AppLocalizations.of(context)?.statusLabel ?? 'Status'}: ${order.status.name.toUpperCase()}',
                      ),
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
