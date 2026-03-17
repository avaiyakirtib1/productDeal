import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/permissions/permissions.dart';
import '../../features/auth/data/models/auth_models.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/products_list_screen.dart';
import '../../features/dashboard/presentation/screens/wholesalers_list_screen.dart';
import '../../features/options/presentation/screens/options_screen.dart';
import '../../features/orders/presentation/screens/cart_screen.dart';
import '../../features/manager/presentation/screens/manager_dashboard_screen.dart';
import '../../features/manager/presentation/screens/manager_deals_screen.dart';
import '../../features/manager/presentation/screens/manager_orders_screen.dart';
import '../../features/manager/presentation/screens/manager_products_screen.dart';

/// Shared provider to control the active bottom navigation tab.
final mainTabIndexProvider = StateProvider<int>((ref) => 0);

enum MainTab {
  // Buyer tabs
  home('Home', Icons.home_outlined, Icons.home),
  wholesalers('Wholesalers', Icons.store_mall_directory_outlined, Icons.store),
  products('Products', Icons.grid_view_outlined, Icons.grid_on),
  cart('Cart', Icons.shopping_cart_outlined, Icons.shopping_cart),
  options('Options', Icons.settings_outlined, Icons.settings),
  // Wholesaler tabs
  wholesalerDashboard('Dashboard', Icons.dashboard_outlined, Icons.dashboard),
  wholesalerProducts('Products', Icons.inventory_2_outlined, Icons.inventory_2),
  wholesalerDeals('Deals', Icons.local_offer_outlined, Icons.local_offer),
  wholesalerOrders('Orders', Icons.receipt_long_outlined, Icons.receipt_long),
  wholesalerProfile('Profile', Icons.person_outline, Icons.person),
  wholesalerOptions('Options', Icons.settings_outlined, Icons.settings),
  // Admin tabs
  adminDashboard('Dashboard', Icons.dashboard_outlined, Icons.dashboard),
  adminUsers('Users', Icons.people_outlined, Icons.people),
  adminProducts('Products', Icons.inventory_2_outlined, Icons.inventory_2),
  adminDeals('Deals', Icons.local_offer_outlined, Icons.local_offer),
  adminOrders('Orders', Icons.receipt_long_outlined, Icons.receipt_long),
  adminCategories('Categories', Icons.category_outlined, Icons.category),
  adminProfile('Profile', Icons.person_outline, Icons.person);

  const MainTab(this.label, this.icon, this.activeIcon);

  final String label;
  final IconData icon;
  final IconData activeIcon;

  int get tabIndex {
    switch (this) {
      case MainTab.home:
        return 0;
      case MainTab.wholesalers:
        return 1;
      case MainTab.products:
        return 2;
      case MainTab.cart:
        return 3;
      case MainTab.options:
        return 4;
      case MainTab.wholesalerDashboard:
        return 0;
      case MainTab.wholesalerProducts:
        return 1;
      case MainTab.wholesalerDeals:
        return 2;
      case MainTab.wholesalerOrders:
        return 3;
      case MainTab.wholesalerProfile:
        return 4; // Keep for backward compatibility, but not used
      case MainTab.wholesalerOptions:
        return 4; // Options is now at index 4 (replacing Profile)
      case MainTab.adminDashboard:
        return 0;
      case MainTab.adminUsers:
        return 1;
      case MainTab.adminProducts:
        return 2;
      case MainTab.adminDeals:
        return 3;
      case MainTab.adminOrders:
        return 4;
      case MainTab.adminCategories:
        return 5;
      case MainTab.adminProfile:
        return 6;
    }
  }

  /// Get buyer navigation tabs
  static List<MainTab> get buyerTabs => [
        MainTab.home,
        MainTab.wholesalers,
        MainTab.products,
        MainTab.cart,
        MainTab.options,
      ];

  /// Get wholesaler navigation tabs (Deals hidden for now, will add in future)
  static List<MainTab> get wholesalerTabs => [
        MainTab.wholesalerDashboard,
        MainTab.wholesalerProducts,
        // MainTab.wholesalerDeals, // Hidden for wholesaler - will add in future
        MainTab.wholesalerOrders,
        MainTab.wholesalerOptions,
      ];

  /// Manager tabs with Deals (used for admin - same layout as wholesaler but with Deals)
  static List<MainTab> get managerTabsWithDeals => [
        MainTab.wholesalerDashboard,
        MainTab.wholesalerProducts,
        MainTab.wholesalerDeals,
        MainTab.wholesalerOrders,
        MainTab.wholesalerOptions,
      ];

  /// Get admin navigation tabs
  static List<MainTab> get adminTabs => [
        MainTab.adminDashboard,
        MainTab.adminUsers,
        MainTab.adminProducts,
        MainTab.adminDeals,
        MainTab.adminOrders,
        MainTab.adminCategories,
        MainTab.adminProfile,
      ];
}

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({
    super.key,
    this.initialIndex = 0,
  });

  final int initialIndex;

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  late int _currentIndex;
  List<Widget Function()>? _pageFactories;
  List<MainTab>? _tabs;
  final Map<int, Widget> _cachedPages = {}; // Cache pages once created

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mainTabIndexProvider.notifier).state = widget.initialIndex;
    });
  }

  void _initializePages(UserRole? userRole) {
    final isAdmin = Permissions.isAdminOrSubAdmin(userRole ?? UserRole.kiosk);
    final isWholesaler = userRole == UserRole.wholesaler;

    if (isAdmin || isWholesaler) {
      if (isAdmin) {
        _tabs = MainTab.managerTabsWithDeals;
        // Admin: full tabs including Deals
        _pageFactories = [
          () => const ManagerDashboardScreen(), // Index 0 - Dashboard
          () => const ManagerProductsScreen(), // Index 1 - Products
          () => const ManagerDealsScreen(), // Index 2 - Deals
          () => const ManagerOrdersScreen(), // Index 3 - Orders
          () => const OptionsScreen(), // Index 4 - Options
        ];
      } else {
        // Wholesaler: Deals hidden for now (will add in future)
        _tabs = MainTab.wholesalerTabs;
        _pageFactories = [
          () => const ManagerDashboardScreen(), // Index 0 - Dashboard
          () => const ManagerProductsScreen(), // Index 1 - Products
          // () => const ManagerDealsScreen(), // Index 2 - Deals (hidden)
          () => const ManagerOrdersScreen(), // Index 2 - Orders
          () => const OptionsScreen(), // Index 3 - Options
        ];
      }
    } else {
      _tabs = MainTab.buyerTabs;
      _pageFactories = [
        () => const DashboardScreen(), // Index 0 - Dashboard
        () => const WholesalersListScreen(), // Index 1 - Wholesalers (lazy)
        () => const ProductsListScreen(), // Index 2 - Products (lazy)
        () => const CartScreen(), // Index 3 - Cart (lazy)
        () => const OptionsScreen(), // Index 4 - Options
      ];
    }
  }

  Widget _getPage(int index, int currentIndex) {
    // Only create page if it's the current page, dashboard (index 0), or already cached
    // This prevents unnecessary API calls for hidden tabs
    if (index == 0 ||
        index == currentIndex ||
        _cachedPages.containsKey(index)) {
      if (!_cachedPages.containsKey(index) &&
          _pageFactories != null &&
          index < _pageFactories!.length) {
        _cachedPages[index] = _pageFactories![index]();
      }
      return _cachedPages[index] ?? const SizedBox.shrink();
    }
    // Return placeholder for unaccessed pages
    return const SizedBox.shrink();
  }

  @override
  void didUpdateWidget(MainScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      _currentIndex = widget.initialIndex;
    }
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;

    ref.read(mainTabIndexProvider.notifier).state = index;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final watchedIndex = ref.watch(mainTabIndexProvider);

    if (watchedIndex != _currentIndex) {
      _currentIndex = watchedIndex;
    }

    return authState.when(
      data: (session) {
        final userRole = session?.user.role;

        // Initialize pages based on role
        if (_pageFactories == null || _tabs == null) {
          _initializePages(userRole);
        } else {
          // Re-initialize if role changed
          final currentRole = userRole;
          List<MainTab> expectedTabs;
          if (Permissions.isAdminOrSubAdmin(currentRole ?? UserRole.kiosk)) {
            expectedTabs = MainTab.managerTabsWithDeals;
          } else if (currentRole == UserRole.wholesaler) {
            expectedTabs = MainTab.wholesalerTabs;
          } else {
            expectedTabs = MainTab.buyerTabs;
          }

          if (_tabs != expectedTabs) {
            _cachedPages.clear(); // Clear cache when role changes
            _initializePages(userRole);
            // Reset to first tab if role changed
            if (_currentIndex >= (_pageFactories?.length ?? 5)) {
              _currentIndex = 0;
              ref.read(mainTabIndexProvider.notifier).state = 0;
            }
          }
        }

        if (_pageFactories == null || _tabs == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final colorScheme = Theme.of(context).colorScheme;

        return PopScope(
          canPop:
              _currentIndex == 0, // Only allow pop if on dashboard (index 0)
          onPopInvokedWithResult: (didPop, result) async {
            if (!didPop && _currentIndex != 0) {
              // If not on dashboard, navigate to dashboard first
              _onTabTapped(0);
            }
          },
          child: Scaffold(
            extendBody: true,
            body: IndexedStack(
              index: _currentIndex,
              // Performance: Only create pages when accessed (lazy loading)
              // Always create dashboard (index 0), others only when accessed
              // This prevents unnecessary API calls for hidden tabs
              children: List.generate(
                _pageFactories!.length,
                (index) => _getPage(index, _currentIndex),
              ),
            ),
            bottomNavigationBar: CurvedNavigationBar(
              index: _currentIndex,
              onTap: _onTabTapped,
              height: 65,
              backgroundColor: Colors.transparent,
              color: colorScheme.surface,
              buttonBackgroundColor: colorScheme.primaryContainer,
              animationCurve: Curves.easeInOut,
              animationDuration: const Duration(milliseconds: 280),
              items: _tabs!.map((tab) {
                final isActive = _currentIndex == tab.tabIndex;
                return Icon(
                  isActive ? tab.activeIcon : tab.icon,
                  color: isActive
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                );
              }).toList(),
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          final msg = l10n != null
              ? l10n.errorWithDetail.replaceAll('{detail}', error.toString())
              : 'Error: $error';
          return Scaffold(
            body: Center(child: Text(msg)),
          );
        },
      ),
    );
  }
}
