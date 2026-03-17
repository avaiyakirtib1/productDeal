import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../auth/data/models/auth_models.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/models/dashboard_models.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/banner_controller.dart';
import '../../../../core/widgets/banner_carousel.dart';
import '../widgets/active_deals_section.dart';
import '../widgets/category_chips.dart';
import '../widgets/story_carousel.dart';
import '../widgets/wholesaler_directory.dart';
import '../../../notifications/presentation/controllers/notification_controller.dart';
import '../../../orders/presentation/widgets/cart_icon_button.dart';
import 'categories_list_screen.dart';
import 'story_viewer_screen.dart';
import '../../../../shared/widgets/main_scaffold.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static const routePath = '/dashboard';
  static const routeName = 'dashboard';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final dashboardState = ref.watch(dashboardControllerProvider);

    return authState.when(
      data: (session) {
        final user = session?.user;
        if (user == null) {
          return const _EmptyDashboard();
        }

        return dashboardState.when(
          data: (snapshot) => _DashboardContent(
            user: user,
            snapshot: snapshot,
            onRefresh: () async {
              await Future.wait([
                ref.read(authControllerProvider.notifier).hydrate(),
                ref.read(dashboardControllerProvider.notifier).refresh(),
                ref.read(publicBannersProvider.notifier).refresh(),
              ]);
            },
            onCategoryTap: (category) =>
                context.push('/categories/${category.slug}'),
            onStoryTap: (group) {
              final allGroups = ref.read(dashboardControllerProvider).maybeWhen(
                    data: (snapshot) => snapshot.storyGroups,
                    orElse: () => <StoryGroup>[],
                  );
              final groupIndex = allGroups.indexWhere(
                (g) => g.wholesalerId == group.wholesalerId,
              );
              context.push(
                StoryViewerScreen.routePath,
                extra: StoryViewerArgs(
                  group: group,
                  allGroups: allGroups,
                  groupIndex: groupIndex >= 0 ? groupIndex : 0,
                ),
              );
            },
            onWholesalerTap: (wholesaler) =>
                context.push('/wholesalers/${wholesaler.id}'),
            onShowWholesalersTab: () => ref
                .read(mainTabIndexProvider.notifier)
                .state = MainTab.wholesalers.tabIndex,
          ),
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (error, stackTrace) => _DashboardError(
            message: error.toString(),
            onRetry: () =>
                ref.read(dashboardControllerProvider.notifier).refresh(),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => _DashboardError(
        message: error.toString(),
        onRetry: () => ref.read(authControllerProvider.notifier).hydrate(),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.user,
    required this.snapshot,
    required this.onRefresh,
    required this.onCategoryTap,
    required this.onStoryTap,
    required this.onWholesalerTap,
    required this.onShowWholesalersTab,
  });

  final UserModel user;
  final DashboardSnapshot snapshot;
  final Future<void> Function() onRefresh;
  final ValueChanged<DashboardCategory> onCategoryTap;
  final ValueChanged<StoryGroup> onStoryTap;
  final ValueChanged<SpotlightWholesaler> onWholesalerTap;
  final VoidCallback onShowWholesalersTab;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            return Text(
                '${l10n?.hello ?? 'Hello'}, ${user.fullName.split(' ').first}');
          },
        ),
        actions: [
          const CartIconButton(),
          Consumer(
            builder: (context, ref, _) {
              final unreadCount = ref.watch(
                unreadCountProvider.select((value) => value.valueOrNull ?? 0),
              );

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      context.push('/notifications');
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: onRefresh,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  const BannerCarousel(),
                  const SizedBox(height: 16),
                  if (snapshot.activeShopsCount > 0 ||
                      snapshot.activeMembersCount > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _ActiveUsersSummary(
                        activeShops: snapshot.activeShopsCount,
                        activeMembers: snapshot.activeMembersCount,
                      ),
                    ),
                  const SizedBox(height: 16),
                  Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context);
                      return StoryCarousel(
                        title: l10n?.storiesFromVerifiedWholesalers ??
                            'Stories from verified wholesalers',
                        storyGroups: snapshot.storyGroups,
                        onStoryTap: onStoryTap,
                        userRole: user.role,
                        onCreateStory: user.role == UserRole.wholesaler
                            ? () => context.push('/stories/create')
                            : null,
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  ActiveDealsSection(deals: snapshot.activeDeals),
                  const SizedBox(height: 24),
                  WholesalerDirectory(
                    onWholesalerTap: onWholesalerTap,
                    onStoryTap: onStoryTap,
                    onViewAll: onShowWholesalersTab,
                    activeShopsCount: snapshot.activeShopsCount,
                  ),
                  const SizedBox(height: 24),
                  CategoryChips(
                    categories: snapshot.categories,
                    onCategoryTap: onCategoryTap,
                    onViewAll: () =>
                        context.push(CategoriesListScreen.routePath),
                  ),
                  const SizedBox(height: 24),
                  const SizedBox(height: 32),
                  // Contact Information Section
                  ContactInformationSection(user: user),
                  const SizedBox(
                      height: 100), // Extra space for floating button
                ],
              ),
            ),
            const SliverPadding(
              padding: EdgeInsets.only(
                  bottom: 90), // Extra padding for curved nav bar
            ),
          ],
        ),
      ),
      // Floating WhatsApp Button
      floatingActionButton: FloatingWhatsAppButton(user: user),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class _ActiveUsersSummary extends StatelessWidget {
  const _ActiveUsersSummary({
    required this.activeShops,
    required this.activeMembers,
  });

  final int activeShops;
  final int activeMembers;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.insights_outlined, color: cs.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (activeShops > 0)
                  Text(
                    '$activeShops ${l10n?.activeShops ?? 'active shops'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (activeShops > 0 && activeMembers > 0) const SizedBox(height: 4),
                if (activeMembers > 0)
                  Text(
                    '$activeMembers ${l10n?.activeMembers ?? 'active members'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurfaceVariant,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Contact Information Section Widget
class ContactInformationSection extends StatelessWidget {
  const ContactInformationSection({super.key, required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.contact_support,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.getInTouch ?? 'Get in Touch',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n?.wereHereToHelp ?? 'We\'re here to help you',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return _ContactInfoItem(
                icon: Icons.phone,
                title: l10n?.phone ?? 'Phone',
                value: '+971585065913', // Dummy number
                color: Colors.green,
              );
            },
          ),
          const SizedBox(height: 16),
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return _ContactInfoItem(
                icon: Icons.email,
                title: l10n?.email ?? 'Email',
                value: 'support@productdeal.com', // Dummy email
                color: Colors.blue,
              );
            },
          ),
          const SizedBox(height: 16),
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return _ContactInfoItem(
                icon: Icons.location_on,
                title: l10n?.address ?? 'Address',
                value: '123 Business Street, City, Country',
                color: Colors.red,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ContactInfoItem extends StatelessWidget {
  const _ContactInfoItem({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Floating WhatsApp Button Widget
class FloatingWhatsAppButton extends StatelessWidget {
  const FloatingWhatsAppButton({super.key, required this.user});

  final UserModel user;

  Future<void> _openWhatsApp(BuildContext context) async {
    // Dummy WhatsApp number (replace with actual number)
    // Format: country code + number (no + or spaces)
    // Example: 1234567890 for +1 234 567 8900
    const whatsappNumber = '+971585065913';

    // Pre-fill message with user information
    final message = _buildWhatsAppMessage(context);
    final encodedMessage = Uri.encodeComponent(message);

    // WhatsApp URL scheme - wa.me redirects to WhatsApp app or web
    final whatsappUrl = 'https://wa.me/$whatsappNumber?text=$encodedMessage';

    try {
      // Directly try to launch - canLaunchUrl is unreliable for web URLs
      // wa.me will redirect to WhatsApp app if installed, or open web version
      final uri = Uri.parse(whatsappUrl);
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      // If launch fails, show error message
      if (context.mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.unableToOpenWhatsApp ??
                'Unable to open WhatsApp. Please try again.'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: l10n?.retry ?? 'Retry',
              textColor: Colors.white,
              onPressed: () => _openWhatsApp(context),
            ),
          ),
        );
      }
    }
  }

  String _buildWhatsAppMessage(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final buffer = StringBuffer();
    buffer.writeln(l10n.helloNeedAssistance);
    buffer.writeln('');
    buffer.writeln(l10n.myDetails);
    buffer.writeln('${l10n.nameLabel} ${user.fullName}');
    if (user.phone != null && user.phone!.isNotEmpty) {
      buffer.writeln('${l10n.phoneLabel} ${user.phone}');
    }
    buffer.writeln('${l10n.emailLabel} ${user.email}');
    if (user.businessName != null && user.businessName!.isNotEmpty) {
      buffer.writeln('${l10n.businessLabel} ${user.businessName}');
    }
    buffer.writeln('');
    buffer.writeln(l10n.howCanYouHelpMe);

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 80), // Above bottom navigation
      child: FloatingActionButton.extended(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
        onPressed: () => _openWhatsApp(context),
        backgroundColor: const Color(0xFF25D366), // WhatsApp green
        icon: Image.asset('assets/icons/whatsapp48.png', width: 24, height: 24),
        label: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            return Text(
              l10n?.chatWithUs ?? 'Chat with us',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
        elevation: 4,
        tooltip: AppLocalizations.of(context)?.contactUsOnWhatsApp ??
            'Contact us on WhatsApp',
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context);
                return Text(
                  l10n?.unableToLoadDashboard ?? 'Unable to load dashboard',
                  style: Theme.of(context).textTheme.titleMedium,
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context);
                return FilledButton(
                  onPressed: onRetry,
                  child: Text(l10n?.retry ?? 'Retry'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyDashboard extends StatelessWidget {
  const _EmptyDashboard();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
