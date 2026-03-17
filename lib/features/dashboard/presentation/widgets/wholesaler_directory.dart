import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../data/models/dashboard_models.dart';
import '../controllers/wholesaler_directory_controller.dart';
import '../controllers/story_view_state.dart';

class WholesalerDirectory extends ConsumerStatefulWidget {
  const WholesalerDirectory({
    super.key,
    required this.onWholesalerTap,
    required this.onStoryTap,
    this.onViewAll,
    this.activeShopsCount,
  });

  final ValueChanged<SpotlightWholesaler> onWholesalerTap;
  final ValueChanged<StoryGroup> onStoryTap;
  final VoidCallback? onViewAll;

  /// When set, shown beside "View All" (e.g. "X active shops · View All")
  final int? activeShopsCount;

  @override
  ConsumerState<WholesalerDirectory> createState() =>
      _WholesalerDirectoryState();
}

class _WholesalerDirectoryState extends ConsumerState<WholesalerDirectory> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 120) {
      ref.read(wholesalerDirectoryControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wholesalerDirectoryControllerProvider);
    final controller = ref.read(wholesalerDirectoryControllerProvider.notifier);
    final snapshot = state.valueOrNull;
    final viewedIds = ref.watch(storyViewStateProvider);
    final storyViewNotifier = ref.read(storyViewStateProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)?.nearbyWholesalers ?? '',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (snapshot != null)
                    Text(
                      '${snapshot.totalRows} ${AppLocalizations.of(context)?.verifiedPartners ?? ''}',
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(color: Colors.grey[600]),
                    ),
                ],
              ),
              const Spacer(),
              if (widget.onViewAll != null)
                TextButton(
                  onPressed: widget.onViewAll,
                  child: Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context);
                      return Text(l10n?.viewAll ?? 'View All');
                    },
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        state.when(
          data: (data) {
            if (data.items.isEmpty) {
              return const _EmptyDirectoryMessage();
            }
            return SizedBox(
              height: 152,
              child: ListView.separated(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: data.items.length + (data.isLoadingMore ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  if (index >= data.items.length) {
                    return const SizedBox(
                      width: 64,
                      child: Center(
                          child: SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2))),
                    );
                  }
                  final wholesaler = data.items[index];
                  final hasStory = wholesaler.hasActiveStory &&
                      wholesaler.stories.isNotEmpty;
                  final isViewed = viewedIds.contains(wholesaler.id);
                  // Debug: Log ID matching
                  if (hasStory && kDebugMode) {
                    debugPrint(
                        'Wholesaler ${wholesaler.businessName} (ID: ${wholesaler.id}) - Viewed: $isViewed');
                  }
                  return _DirectoryAvatar(
                    wholesaler: wholesaler,
                    isViewed: isViewed,
                    onStoryTap: hasStory
                        ? () {
                            storyViewNotifier.markViewed(wholesaler.id);
                            widget.onStoryTap(
                              StoryGroup(
                                wholesalerId: wholesaler.id,
                                wholesalerName: wholesaler.businessName,
                                avatarUrl: wholesaler.avatarUrl,
                                stories: wholesaler.stories,
                                distanceKm: wholesaler.distanceKm,
                                locations: wholesaler.locations,
                              ),
                            );
                          }
                        : null,
                    onTap: () => widget.onWholesalerTap(wholesaler),
                  );
                },
              ),
            );
          },
          loading: () => const SizedBox(
            height: 140,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => _DirectoryError(
            message: error.toString(),
            onRetry: controller.refresh,
          ),
        ),
      ],
    );
  }
}

class _DirectoryAvatar extends StatelessWidget {
  const _DirectoryAvatar({
    required this.wholesaler,
    required this.isViewed,
    required this.onStoryTap,
    required this.onTap,
  });

  final SpotlightWholesaler wholesaler;
  final VoidCallback onTap;
  final bool isViewed;
  final VoidCallback? onStoryTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final distance =
        wholesaler.distanceKm != null && wholesaler.distanceKm!.isFinite
            ? '${wholesaler.distanceKm!.toStringAsFixed(1)} km'
            : null;

    final hasStory = wholesaler.hasActiveStory && wholesaler.stories.isNotEmpty;

    final storyColor = hasStory
        ? (isViewed
            ? theme.colorScheme.outlineVariant
            : theme.colorScheme.primary)
        : theme.colorScheme.outlineVariant;

    return Container(
      width: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.primaryContainer,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar + story ring
              InkWell(
                onTap: hasStory ? onStoryTap : null,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: storyColor,
                      width: hasStory ? 3 : 1.5,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white,
                    backgroundImage: CachedNetworkImageProvider(
                      wholesaler.avatarUrl.replaceAll("/svg", "/png"),
                    ),
                    onBackgroundImageError: (_, __) {},
                    child: wholesaler.avatarUrl.isEmpty
                        ? const Icon(Icons.person, size: 28)
                        : null,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Name
              Text(
                wholesaler.businessName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.blueGrey.shade900,
                ),
              ),

              // Distance
              if (distance != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    distance,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.blueGrey.shade700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DirectoryError extends StatelessWidget {
  const _DirectoryError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)?.couldNotLoadWholesalers ??
                'We couldn’t load wholesalers right now.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: Colors.redAccent),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context);
                return Text(l10n?.retry ?? 'Retry');
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDirectoryMessage extends StatelessWidget {
  const _EmptyDirectoryMessage();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        AppLocalizations.of(context)?.noWholesalersNearYou ??
            'No wholesalers near you yet. Update your location to unlock nearby inventory.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
