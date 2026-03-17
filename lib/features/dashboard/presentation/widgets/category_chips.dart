import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../data/models/dashboard_models.dart';

class CategoryChips extends StatelessWidget {
  const CategoryChips({
    super.key,
    required this.categories,
    required this.onCategoryTap,
    this.onViewAll,
  });

  final List<DashboardCategory> categories;
  final ValueChanged<DashboardCategory> onCategoryTap;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                l10n.categories,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              if (onViewAll != null)
                TextButton(
                  onPressed: onViewAll,
                  child: Text(l10n.viewAll),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 70, // Increased height for the card
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final category = categories[index];
              final cs = Theme.of(context).colorScheme;

              return GestureDetector(
                onTap: () => onCategoryTap(category),
                child: Container(
                  width: 150, // Fixed width for consistency
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.4),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: cs.shadow.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: category.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Center(
                              child: Icon(
                                Icons.image_outlined,
                                size: 16,
                                color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                              ),
                            ),
                            errorWidget: (context, url, error) => Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                size: 16,
                                color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    height: 1.1,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.itemsCount.replaceAll('{n}', '${category.productCount}'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: cs.onSurfaceVariant,
                                    fontSize: 10,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemCount: categories.length,
          ),
        ),
      ],
    );
  }
}
