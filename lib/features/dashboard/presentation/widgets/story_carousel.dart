import 'package:flutter/material.dart';

import '../../../../core/widgets/smart_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localizations.dart';

import '../../../auth/data/models/auth_models.dart';
import '../../data/models/dashboard_models.dart';
import '../controllers/story_view_state.dart';

class StoryCarousel extends ConsumerWidget {
  const StoryCarousel({
    super.key,
    required this.title,
    required this.storyGroups,
    required this.onStoryTap,
    this.onViewAll,
    this.onCreateStory,
    this.userRole,
    this.allGroups,
  });

  final String title;
  final List<StoryGroup> storyGroups;
  final ValueChanged<StoryGroup> onStoryTap;
  final VoidCallback? onViewAll;
  final VoidCallback? onCreateStory;
  final UserRole? userRole;
  final List<StoryGroup>? allGroups; // Optional: all groups for navigation

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWholesaler = userRole == UserRole.wholesaler;
    final showCreateButton = isWholesaler && onCreateStory != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Title takes only leftover space and can shrink to zero
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              if (storyGroups.isNotEmpty) ...[
                Text(
                  '(${storyGroups.fold<int>(0, (total, group) => total + group.stories.length)} ${AppLocalizations.of(context)?.storiesCountSuffix ?? 'stories'})',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: Colors.white70),
                ),
              ],
              const SizedBox(width: 12),
              // Show "Create" button for wholesalers, hide for others
              if (showCreateButton)
                FilledButton.icon(
                  onPressed: onCreateStory,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(AppLocalizations.of(context)?.create ?? 'Create'),
                  style: FilledButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (storyGroups.isNotEmpty || showCreateButton)
          SizedBox(
            height: 190,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                // Show "Create Story" card first for wholesalers
                if (showCreateButton && index == 0) {
                  return _CreateStoryCard(
                    onTap: onCreateStory!,
                  );
                }

                // Adjust index for story groups if create card is shown
                final groupIndex = showCreateButton ? index - 1 : index;
                final group = storyGroups[groupIndex];

                if (group.stories.isEmpty) {
                  return const SizedBox.shrink();
                }

                final viewedIds = ref.watch(storyViewStateProvider);
                final isViewed = viewedIds.contains(group.wholesalerId);
                return _StoryItem(
                  group: group,
                  isViewed: isViewed,
                  onTap: () {
                    ref
                        .read(storyViewStateProvider.notifier)
                        .markViewed(group.wholesalerId);
                    onStoryTap(group);
                  },
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemCount: storyGroups.length + (showCreateButton ? 1 : 0),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome_outlined,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      showCreateButton
                          ? (AppLocalizations.of(context)?.beTheFirstStory ??
                              'Be the first! Share your story with customers')
                          : (AppLocalizations.of(context)
                                  ?.storiesWillAppearHere ??
                              'Stories will appear here once wholesalers start posting.'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                  if (showCreateButton) ...[
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: onCreateStory,
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(
                          AppLocalizations.of(context)?.create ?? 'Create'),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _StoryItem extends StatelessWidget {
  const _StoryItem({
    required this.group,
    required this.isViewed,
    required this.onTap,
  });

  final StoryGroup group;
  final bool isViewed;
  final VoidCallback onTap;

  String _timeUntil(DateTime date) {
    final diff = date.difference(DateTime.now());
    if (diff.inHours >= 1) {
      return '${diff.inHours}h';
    }
    return '${diff.inMinutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final story = group.stories.first;
    debugPrint(
        'User : ${group.wholesalerName}\nStory URL : ${story.mediaUrl}\nUser Avtar URL : ${group.avatarUrl}',
      );
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 150,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              Positioned.fill(
                child: SmartNetworkImage(
                  imageUrl: story.thumbnailUrl.isNotEmpty
                      ? story.thumbnailUrl
                      : story.mediaUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image_outlined,
                        size: 64, color: Colors.white70),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: .75),
                      Colors.transparent,
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isViewed
                                  ? Colors.white38
                                  : Theme.of(context).colorScheme.primary,
                              width: isViewed ? 2 : 3,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 16,
                            backgroundImage: smartImageProvider(
                              group.avatarUrl.replaceAll("/svg", "/png"),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            group.wholesalerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      '${group.stories.length} ${group.stories.length > 1 ? (AppLocalizations.of(context)?.updates ?? 'updates') : (AppLocalizations.of(context)?.updates ?? 'update')}',
                      style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(color: Colors.white70) ??
                          const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${AppLocalizations.of(context)?.expires ?? 'Expires'} ${_timeUntil(story.expiresAt)}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
              if (story.isVideo)
                const Positioned(
                  top: 12,
                  right: 12,
                  child: Icon(
                    Icons.play_circle_fill,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateStoryCard extends StatelessWidget {
  const _CreateStoryCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: theme.colorScheme.primary,
            width: 1.6,
          ),
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.05),
              theme.colorScheme.secondary.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary,
              ),
              child: const Icon(
                Icons.add,
                size: 22,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)?.create ?? 'Create',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              AppLocalizations.of(context)?.story ?? 'Story',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              AppLocalizations.of(context)?.shareWithCustomers ??
                  'Share with customers',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
