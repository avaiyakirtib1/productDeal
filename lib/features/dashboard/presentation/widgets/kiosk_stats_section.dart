import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../deals/presentation/screens/my_deal_orders_screen.dart';
import '../../../manager/data/repositories/manager_repository.dart';
import '../../../wholesaler/presentation/widgets/stats_card.dart';

/// Provider for kiosk statistics (deals joined, total ordered quantity, total orders)
final kioskStatsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(managerRepositoryProvider);
  return repo.fetchKioskStats();
});

/// Kiosk statistics section – shown only for kiosk users on the dashboard
class KioskStatsSection extends ConsumerWidget {
  const KioskStatsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(kioskStatsProvider);
    final l10n = AppLocalizations.of(context);

    return statsAsync.when(
      data: (data) {
        final dealsJoined =
            (data['dealsJoined'] as num?)?.toInt() ?? 0;
        final totalOrderedQuantity =
            (data['totalOrderedQuantity'] as num?)?.toInt() ?? 0;
        final totalOrders = (data['totalOrders'] as num?)?.toInt() ?? 0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n?.myDealStats ?? 'My deal stats',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: StatsCard(
                      title: l10n?.dealsJoined ?? 'Deals joined',
                      value: '$dealsJoined',
                      icon: Icons.local_offer_outlined,
                      color: Colors.orange,
                      onTap: () => _navigateToMyDealOrders(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatsCard(
                      title: l10n?.totalOrders ?? 'Total orders',
                      value: '$totalOrders',
                      icon: Icons.receipt_long_outlined,
                      color: Colors.blue,
                      onTap: () => _navigateToMyDealOrders(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              StatsCard(
                title: l10n?.totalOrderedQuantity ?? 'Total quantity ordered',
                value: '$totalOrderedQuantity',
                icon: Icons.inventory_outlined,
                color: Colors.green,
                onTap: () => _navigateToMyDealOrders(context),
              ),
            ],
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          height: 80,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _navigateToMyDealOrders(BuildContext context) {
    context.push(MyDealOrdersScreen.routePath);
  }
}
