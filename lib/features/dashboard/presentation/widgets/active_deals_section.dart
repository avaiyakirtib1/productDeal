import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/currency_controller.dart';
import '../../../../core/services/currency_service.dart';
import '../../../deals/data/models/deal_models.dart';
import '../../../deals/data/repositories/deal_repository.dart';

/// Shared provider for active deals, optionally filtered by wholesaler.
final activeDealsProvider = FutureProvider.autoDispose
    .family<List<Deal>, String?>((ref, wholesalerId) async {
  final repo = ref.watch(dealRepositoryProvider);
  final page = await repo.fetchDeals(
    page: 1,
    limit: 10,
    status: DealStatus.live,
    wholesalerId: wholesalerId,
  );
  return page.items;
});

class ActiveDealsSection extends ConsumerWidget {
  const ActiveDealsSection({
    super.key,
    this.deals,
    this.wholesalerId,
    this.onViewAll,
  });

  /// If provided, render these deals directly (no extra API call).
  final List<Deal>? deals;

  /// Optional wholesaler to scope deals to a single seller.
  final String? wholesalerId;

  /// Optional view-all handler.
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(
        currencyControllerProvider); // Rebuild when display currency changes
    final providedDeals = deals;
    if (providedDeals != null) {
      return _buildContent(
        context,
        providedDeals,
        showEmptyState: false,
      );
    }

    final dealsAsync = ref.watch(activeDealsProvider(wholesalerId));
    return dealsAsync.when(
      data: (items) => _buildContent(
        context,
        items,
        showEmptyState: wholesalerId != null,
      ),
      loading: () => const SizedBox(
        height: 250,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<Deal> items, {
    required bool showEmptyState,
  }) {
    if (items.isEmpty) {
      if (!showEmptyState) {
        return const SizedBox.shrink();
      }

      final theme = Theme.of(context);
      return SizedBox(
        width: double.infinity,
        child: Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.local_offer_outlined,
                  size: 56,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)?.noActiveDeals ??
                      'No active deals',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)?.checkBackLaterForNewDeals ??
                      'Check back later for new deals',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n?.activeDeals ?? 'Active Deals',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (onViewAll != null)
                TextButton(
                  onPressed: onViewAll,
                  child: Text(l10n?.viewAll ?? 'View all'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 270,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final deal = items[index];
              return _DealCard(deal: deal);
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _DealCard extends StatelessWidget {
  const _DealCard({required this.deal});

  final Deal deal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final imageUrl = _resolveImageUrl(deal);

    return SizedBox(
      width: 220,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/deals/${deal.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 120,
                width: double.infinity,
                child: imageUrl == null
                    ? Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.local_offer_outlined, size: 32),
                      )
                    : Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${deal.title}\n',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              context.formatPriceEurOnly(deal.dealPrice,
                                  decimalDigits: 0),
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_hasDiscount(deal)) ...[
                              const SizedBox(width: 6),
                              Text(
                                context.formatPriceEurOnly(deal.product!.price,
                                    decimalDigits: 0),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  decoration: TextDecoration.lineThrough,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '(${context.formatPriceUsdFromEur(deal.dealPrice)})',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatTimeRemaining(deal.timeRemaining, l10n),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _hasDiscount(Deal deal) {
    return deal.product != null && deal.product!.price > deal.dealPrice;
  }

  String? _resolveImageUrl(Deal deal) {
    final dealImages = deal.images;
    if (dealImages != null && dealImages.isNotEmpty) {
      return dealImages.first;
    }
    final productImages = deal.product?.displayImages;
    if (productImages != null && productImages.isNotEmpty) {
      return productImages.first;
    }
    return deal.imageUrl;
  }

  String _formatTimeRemaining(Duration duration, AppLocalizations? l10n) {
    if (duration.isNegative) {
      return l10n?.ended ?? 'Ended';
    }
    if (duration.inDays > 0) {
      final count = duration.inDays;
      final template = count == 1
          ? (l10n?.timeRemainingDay ?? '{count} day left')
          : (l10n?.timeRemainingDays ?? '{count} days left');
      return template.replaceAll('{count}', count.toString());
    }
    if (duration.inHours > 0) {
      final count = duration.inHours;
      final template = count == 1
          ? (l10n?.timeRemainingHour ?? '{count}h left')
          : (l10n?.timeRemainingHours ?? '{count}h left');
      return template.replaceAll('{count}', count.toString());
    }
    final minutes = duration.inMinutes.clamp(0, 59);
    final count = minutes;
    final template = count == 1
        ? (l10n?.timeRemainingMinute ?? '{count}m left')
        : (l10n?.timeRemainingMinutes ?? '{count}m left');
    return template.replaceAll('{count}', count.toString());
  }
}
