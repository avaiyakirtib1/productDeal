import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../shared/widgets/network_avatar.dart';
import '../../data/models/dashboard_models.dart';

class WholesalerStrip extends StatelessWidget {
  const WholesalerStrip({
    super.key,
    required this.spotlight,
    required this.onWholesalerTap,
  });

  final List<SpotlightWholesaler> spotlight;
  final ValueChanged<SpotlightWholesaler> onWholesalerTap;

  @override
  Widget build(BuildContext context) {
    if (spotlight.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          AppLocalizations.of(context)?.spotlightWholesalersEmpty ??
              'Spotlight wholesalers will appear here once the marketplace is buzzing.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            AppLocalizations.of(context)?.spotlight ?? 'Spotlight',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final item = spotlight[index];
              final distance =
                  item.distanceKm != null && item.distanceKm! < double.infinity
                      ? '${item.distanceKm!.toStringAsFixed(1)} km'
                      : null;

              final borderColor = item.hasActiveStory
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).dividerColor;
              final borderWidth = item.hasActiveStory ? 3.0 : 1.5;

              return GestureDetector(
                onTap: () => onWholesalerTap(item),
                child: Column(
                  children: [
                    NetworkAvatar(
                      imageUrl: item.avatarUrl,
                      size: 68,
                      borderColor: borderColor,
                      borderWidth: borderWidth,
                      overlayIcon: item.hasActiveStory
                          ? Icons.play_circle_fill_outlined
                          : null,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 90,
                      child: Column(
                        children: [
                          Text(
                            item.businessName,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          if (distance != null)
                            Text(
                              distance,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: AppColors.textMuted),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemCount: spotlight.length,
          ),
        ),
      ],
    );
  }
}
