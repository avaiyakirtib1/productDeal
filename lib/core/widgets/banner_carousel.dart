import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

import '../localization/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../permissions/permissions.dart';
import '../../features/dashboard/data/repositories/banner_repository.dart';
import '../../features/dashboard/domain/models/banner_model.dart';
import '../../features/dashboard/presentation/controllers/banner_controller.dart';

const double bannerHeight = 260.0;

class BannerCarousel extends ConsumerWidget {
  const BannerCarousel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bannersAsync = ref.watch(publicBannersProvider);
    final authState = ref.watch(authControllerProvider);
    final userRole = authState.maybeWhen(
      data: (session) => session?.user.role,
      orElse: () => null,
    );
    final isSeller = userRole != null &&
        (Permissions.isAdminOrSubAdmin(userRole) ||
            Permissions.isWholesaler(userRole));

    return bannersAsync.when(
      data: (banners) {
        if (banners.isEmpty) {
          return isSeller ? _SellerEmptyBanner() : const _CustomerEmptyBanner();
        }

        return Column(
          children: [
            CarouselSlider(
              options: CarouselOptions(
                height: bannerHeight,
                autoPlay: true,
                enlargeCenterPage: true,
                aspectRatio: 16 / 9,
                autoPlayCurve: Curves.fastEaseInToSlowEaseOut,
                enableInfiniteScroll: banners.length > 1,
                autoPlayAnimationDuration: const Duration(milliseconds: 2000),
                viewportFraction: 0.92,
              ),
              items: banners.map((banner) {
                return Builder(
                  builder: (BuildContext context) {
                    final hasTarget = _hasTarget(banner);
                    return GestureDetector(
                      onTap: hasTarget
                          ? () => _handleBannerTap(context, banner)
                          : null,
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        margin: const EdgeInsets.all(5.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.0),
                          image: DecorationImage(
                            image: CachedNetworkImageProvider(
                                banner.displayImageUrl),
                            fit: BoxFit.cover,
                          ),
                          boxShadow: hasTarget
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12.0),
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.7),
                                    Colors.black.withValues(alpha: 0.4),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                              padding: const EdgeInsets.all(16.0),
                              alignment: Alignment.bottomLeft,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    banner.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (banner.description != null &&
                                      banner.description!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      banner.description!,
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.9),
                                        fontSize: 13.0,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  if (hasTarget) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withValues(alpha: 0.2),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color:
                                                  Colors.white.withValues(alpha: 0.3),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                _getTargetIcon(banner.type),
                                                size: 14,
                                                color: Colors.white,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                _getTargetText(context, banner.type),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Icon(
                                          Icons.arrow_forward_ios,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            // Click indicator in top-right corner
                            if (hasTarget)
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.touch_app,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
      loading: () => const SizedBox(
        height: bannerHeight,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  void _handleBannerTap(BuildContext context, BannerModel banner) async {
    // Track click (fire and forget)
    _trackBannerClick(context, banner.id);

    switch (banner.type) {
      case BannerType.product:
        if (banner.targetId != null) {
          // Navigate to product detail - fixed route to use plural
          context.push('/products/${banner.targetId}');
        }
        break;
      case BannerType.deal:
        // Navigate to deal detail
        if (banner.targetId != null) {
          context.push('/deals/${banner.targetId}');
        }
        break;
      case BannerType.external:
        if (banner.targetUrl != null) {
          final uri = Uri.parse(banner.targetUrl!);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
        break;
      case BannerType.promotion:
        if (banner.description != null && banner.description!.isNotEmpty) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(banner.description!),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
        break;
    }
  }

  void _trackBannerClick(BuildContext context, String bannerId) {
    // Fire and forget - track click asynchronously
    final container = ProviderScope.containerOf(context);
    final repository = container.read(bannerRepositoryProvider);
    repository.trackBannerClick(bannerId).catchError((error) {
      // Silently fail - click tracking shouldn't block user experience
      debugPrint('Failed to track banner click: $error');
    });
  }

  bool _hasTarget(BannerModel banner) {
    switch (banner.type) {
      case BannerType.product:
      case BannerType.deal:
        return banner.targetId != null && banner.targetId!.isNotEmpty;
      case BannerType.external:
        return banner.targetUrl != null && banner.targetUrl!.isNotEmpty;
      case BannerType.promotion:
        return banner.description != null && banner.description!.isNotEmpty;
    }
  }

  IconData _getTargetIcon(BannerType type) {
    switch (type) {
      case BannerType.product:
        return Icons.shopping_bag;
      case BannerType.deal:
        return Icons.local_offer;
      case BannerType.external:
        return Icons.open_in_new;
      case BannerType.promotion:
        return Icons.info_outline;
    }
  }

  String _getTargetText(BuildContext context, BannerType type) {
    final l10n = AppLocalizations.of(context);
    switch (type) {
      case BannerType.product:
        return l10n?.viewProduct ?? 'View Product';
      case BannerType.deal:
        return l10n?.viewDeal ?? 'View Deal';
      case BannerType.external:
        return l10n?.openLink ?? 'Open Link';
      case BannerType.promotion:
        return l10n?.viewDetails ?? 'View Details';
    }
  }
}

class _SellerEmptyBanner extends StatelessWidget {
  const _SellerEmptyBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: bannerHeight,
      width: double.infinity,
      margin: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        gradient: LinearGradient(
          colors: [Colors.blue.shade800, Colors.blue.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context);
                    return Text(l10n?.bannerRequestComingSoon ??
                        'Banner request feature coming soon!');
                  },
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12.0),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context);
                      return Text(
                        l10n?.advertiseWithUs ?? 'Advertise with us',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                const Spacer(),
                Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n?.boostYourSales ?? 'Boost your sales!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n?.promoteYourProducts ??
                              'Promote your products here and reach more customers.',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14.0,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomerEmptyBanner extends StatelessWidget {
  const _CustomerEmptyBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: bannerHeight,
      width: double.infinity,
      margin: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/kf_app_icon.jpg',
              width: 64,
              height: 64,
            ),
            const SizedBox(height: 12),
            Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context);
                return Text(
                  l10n?.discoverGreatDealsNearby ?? 'Discover great deals nearby',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                );
              },
            ),
            const SizedBox(height: 6),
            Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context);
                return Text(
                  l10n?.stayTunedForOffers ??
                      'Stay tuned for new offers and stories from verified wholesalers.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
