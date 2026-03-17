import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/permissions/permissions.dart';
import '../../../auth/data/models/auth_models.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../orders/presentation/screens/my_orders_screen.dart';
import '../../../info/presentation/screens/about_us_screen.dart';
import '../../../info/presentation/screens/faq_screen.dart';
import '../../../info/presentation/screens/help_support_screen.dart';
import '../../../profile/presentation/profile_screen.dart';
import '../../../manager/presentation/screens/manager_categories_screen.dart';
import '../../../manager/presentation/screens/manager_products_screen.dart';
import '../../../manager/presentation/screens/manager_deals_screen.dart';
import '../../../manager/presentation/screens/manager_orders_screen.dart';
import '../../../manager/presentation/screens/manager_banners_screen.dart';
import '../../../manager/presentation/screens/inactive_members_screen.dart';
import '../../../admin/presentation/screens/admin_banner_manage_screen.dart';
import '../../../account/presentation/screens/delete_account_screen.dart';
import 'language_selection_screen.dart';
import 'notification_settings_screen.dart';
import '../../../dashboard/presentation/screens/kiosk_statistics_screen.dart';

class OptionsScreen extends ConsumerWidget {
  const OptionsScreen({super.key});

  static const routePath = '/options';
  static const routeName = 'options';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final l10n = AppLocalizations.of(context);

    return authState.when(
      data: (session) {
        final user = session?.user;
        return Scaffold(
          extendBody: true,
          appBar: AppBar(
            title: Text(l10n?.options ?? 'Options'),
            actions: [
              if (user != null)
                IconButton(
                  icon: const Icon(Icons.person_outline),
                  onPressed: () => context.push(ProfileScreen.routePath),
                  tooltip: l10n?.profile ?? 'Profile',
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
                0, 8, 0, 90), // Extra padding for curved nav bar
            children: [
              if (user != null) ...[
                _SectionHeader(title: l10n?.account ?? 'Account'),
                // Show "My Orders" for buyers and kiosks only
                if (!Permissions.isAdminOrSubAdmin(user.role) &&
                    user.role != UserRole.wholesaler)
                  _OptionTile(
                    icon: Icons.receipt_long_outlined,
                    title: l10n?.myOrders ?? 'My Orders',
                    subtitle:
                        l10n?.myOrdersSubtitle ?? 'View and track your orders',
                    onTap: () => context.push(MyOrdersScreen.routePath),
                  ),
                // Statistics for kiosk users – deal participation stats
                if (user.role == UserRole.kiosk)
                  _OptionTile(
                    icon: Icons.bar_chart_outlined,
                    title: l10n?.statistics ?? 'Statistics',
                    subtitle: l10n?.statisticsSubtitle ??
                        'View your deal participation stats',
                    onTap: () =>
                        context.push(KioskStatisticsScreen.routePath),
                  ),
                _OptionTile(
                  icon: Icons.person_outline,
                  title: l10n?.profile ?? 'Profile',
                  subtitle: l10n?.profileSubtitle ?? 'Manage your account',
                  onTap: () => context.push(ProfileScreen.routePath),
                ),
                _OptionTile(
                  icon: Icons.notifications_outlined,
                  title: l10n?.notificationSettings ?? 'Notification Settings',
                  subtitle: l10n?.notificationSettingsSubtitle ??
                      'Choose which notifications to receive',
                  onTap: () => context.push(NotificationSettingsScreen.routePath),
                ),
                const Divider(height: 1),
              ],
              // Admin/Wholesaler: all quick actions from manager dashboard (so users can find management here)
              if (user != null &&
                  (Permissions.isAdminOrSubAdmin(user.role) ||
                      user.role == UserRole.wholesaler)) ...[
                _SectionHeader(title: l10n?.management ?? 'Management'),
                if (Permissions.canAddProducts(user.role))
                  _OptionTile(
                    icon: Icons.add_circle_outline,
                    title: l10n?.addProduct ?? 'Add Product',
                    subtitle: l10n?.createNewProductSubtitle ?? 'Create a new product',
                    onTap: () => context.push(ManagerProductsScreen.routePath),
                  ),
                if (Permissions.canAddDeals(user.role))
                  _OptionTile(
                    icon: Icons.local_offer_outlined,
                    title: l10n?.createDeal ?? 'Create Deal',
                    subtitle: l10n?.createNewDealSubtitle ?? 'Create a new deal',
                    onTap: () => context.push(ManagerDealsScreen.routePath),
                  ),
                _OptionTile(
                  icon: Icons.receipt_long_outlined,
                  title: l10n?.viewOrders ?? 'View Orders',
                  subtitle: l10n?.viewOrdersSubtitle ?? 'View and manage orders',
                  onTap: () => context.push(ManagerOrdersScreen.routePath),
                ),
                if (Permissions.isAdminOrSubAdmin(user.role)) ...[
                  _OptionTile(
                    icon: Icons.category_outlined,
                    title: l10n?.manageCategories ?? 'Manage Categories',
                    subtitle: l10n?.manageCategoriesSubtitle ??
                        'Create and manage product categories',
                    onTap: () =>
                        context.push(ManagerCategoriesScreen.routePath),
                  ),
                  _OptionTile(
                    icon: Icons.people_outlined,
                    title: l10n?.manageUsers ?? 'Manage Users',
                    subtitle: l10n?.manageUsersSubtitle ??
                        'View and manage user accounts',
                    onTap: () => context.push('/admin/users'),
                  ),
                  _OptionTile(
                    icon: Icons.warning_amber_rounded,
                    title: l10n?.inactiveMembers ?? 'Inactive Members',
                    subtitle: l10n?.inactiveMembersViewSubtitle ??
                        'View shops with no recent orders',
                    onTap: () => context.push(InactiveMembersScreen.routePath),
                  ),
                  _OptionTile(
                    icon: Icons.view_carousel_outlined,
                    title: l10n?.manageBanners ?? 'Manage Banners',
                    subtitle: l10n?.manageBannersSubtitle ?? 'Manage app banners (admin)',
                    onTap: () =>
                        context.push(AdminBannerManageScreen.routePath),
                  ),
                ] else ...[
                  _OptionTile(
                    icon: Icons.analytics_outlined,
                    title: l10n?.analytics ?? 'Analytics',
                    subtitle: l10n?.analyticsSubtitle ??
                        'View your business analytics',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(l10n?.analyticsComingSoon ??
                                'Analytics coming soon')),
                      );
                    },
                  ),
                  _OptionTile(
                    icon: Icons.view_carousel_outlined,
                    title: l10n?.myBanners ?? 'My Banners',
                    subtitle: l10n?.myBannersSubtitle ?? 'Manage your banners',
                    onTap: () => context.push(ManagerBannersScreen.routePath),
                  ),
                ],
                const Divider(height: 1),
              ],
              _SectionHeader(title: l10n?.information ?? 'Information'),
              _OptionTile(
                icon: Icons.help_outline,
                title: l10n?.faq ?? 'FAQ',
                subtitle: l10n?.faqSubtitle ?? 'Frequently asked questions',
                onTap: () => context.push(FAQScreen.routePath),
              ),
              _OptionTile(
                icon: Icons.info_outline,
                title: l10n?.aboutUs ?? 'About Us',
                subtitle:
                    l10n?.aboutUsSubtitle ?? 'Learn more about our platform',
                onTap: () => context.push(AboutUsScreen.routePath),
              ),
              _OptionTile(
                icon: Icons.support_agent_outlined,
                title: l10n?.helpSupport ?? 'Help & Support',
                subtitle:
                    l10n?.helpSupportSubtitle ?? 'Get help and contact support',
                onTap: () => context.push(HelpSupportScreen.routePath),
              ),
              // Language option - available to all users
              _OptionTile(
                icon: Icons.language,
                title: l10n?.language ?? 'Language',
                subtitle: l10n?.languageSubtitle ?? 'Change app language',
                onTap: () => context.push(LanguageSelectionScreen.routePath),
              ),
              if (user != null) ...[
                const Divider(height: 1),
                _SectionHeader(
                    title: l10n?.accountActions ?? 'Account Actions'),
                _OptionTile(
                  icon: Icons.delete_outline,
                  title: l10n?.deleteAccount ?? 'Delete Account',
                  subtitle: l10n?.deleteAccountSubtitle ??
                      'Request to permanently delete your account',
                  iconColor: AppColors.error,
                  textColor: AppColors.error,
                  onTap: () => context.push(DeleteAccountScreen.routePath),
                ),
                _OptionTile(
                  icon: Icons.logout,
                  title: l10n?.logout ?? 'Logout',
                  subtitle: l10n?.logoutSubtitle ?? 'Sign out of your account',
                  iconColor: AppColors.error,
                  textColor: AppColors.error,
                  onTap: () => _showLogoutConfirmation(context, ref),
                ),
              ],
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) {
        final l10n = AppLocalizations.of(context);
        return Scaffold(
          appBar: AppBar(title: Text(l10n?.options ?? 'Options')),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                  l10n?.unableToLoadOptions ?? 'Unable to load options',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    bool isLoggingOut = false;

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing during logout
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n?.confirmLogout ?? 'Confirm Logout'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoggingOut) ...[
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n?.loggingOut ?? 'Logging out...',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ] else
                Text(l10n?.confirmLogoutMessage ??
                    'Are you sure you want to logout?'),
            ],
          ),
          actions: isLoggingOut
              ? [] // Hide the buttons while logging out
              : [
                  TextButton(
                    onPressed: isLoggingOut
                        ? null
                        : () => Navigator.of(dialogContext).pop(),
                    child: Text(l10n?.cancel ?? 'Cancel'),
                  ),
                  FilledButton(
                    onPressed: isLoggingOut
                        ? null
                        : () async {
                            setState(() {
                              isLoggingOut = true;
                            });

                            try {
                              await ref
                                  .read(authControllerProvider.notifier)
                                  .logout();
                            } catch (e) {
                              debugPrint('Logout error: $e');
                            }
                            // Always pop dialog (use dialogContext so we close even after auth state clears / iOS)
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.error,
                    ),
                    child: isLoggingOut
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(l10n?.logout ?? 'Logout'),
                  ),
                ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
    this.textColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor = iconColor ?? theme.colorScheme.onSurface;
    final effectiveTextColor = textColor ?? theme.colorScheme.onSurface;

    return ListTile(
      leading: Icon(icon, color: effectiveIconColor),
      title: Text(
        title,
        style: TextStyle(color: effectiveTextColor),
      ),
      subtitle: Text(subtitle),
      trailing: Icon(
        Icons.chevron_right,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }
}
