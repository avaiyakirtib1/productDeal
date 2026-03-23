import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/localization/app_localizations.dart';
import 'core/localization/language_onboarding_provider.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';
import 'features/auth/presentation/screens/terms_consent_screen.dart';
import 'features/dashboard/presentation/screens/categories_list_screen.dart';
import 'features/dashboard/presentation/screens/category_detail_screen.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';
import 'features/dashboard/presentation/screens/product_detail_screen.dart';
import 'features/dashboard/presentation/screens/product_search_screen.dart';
import 'features/dashboard/presentation/screens/products_list_screen.dart';
import 'features/dashboard/presentation/screens/story_viewer_screen.dart';
import 'features/dashboard/presentation/screens/kiosk_statistics_screen.dart';
import 'features/dashboard/presentation/screens/wholesaler_profile_screen.dart';
import 'features/dashboard/presentation/screens/wholesalers_list_screen.dart';
import 'features/deals/presentation/screens/deal_detail_screen.dart';
import 'features/deals/presentation/screens/deal_list_screen.dart';
import 'features/info/presentation/screens/about_us_screen.dart';
import 'features/info/presentation/screens/faq_screen.dart';
import 'features/info/presentation/screens/help_support_screen.dart';
import 'features/profile/presentation/profile_screen.dart';
import 'features/splash/presentation/splash_screen.dart';
import 'features/orders/presentation/screens/my_orders_screen.dart';
import 'features/orders/presentation/screens/my_order_detail_screen.dart';
import 'features/orders/presentation/screens/quantity_change_result_screen.dart';
import 'features/deals/presentation/screens/my_deal_orders_screen.dart';
import 'features/orders/presentation/screens/cart_screen.dart';
import 'features/stories/presentation/screens/create_story_screen.dart';
import 'features/options/presentation/screens/options_screen.dart';
import 'features/onboarding/presentation/screens/initial_language_selection_screen.dart';
import 'features/options/presentation/screens/language_selection_screen.dart';
import 'features/options/presentation/screens/notification_settings_screen.dart';
import 'features/options/presentation/screens/currency_selection_screen.dart';
import 'features/manager/presentation/screens/manager_dashboard_screen.dart';
import 'features/manager/presentation/screens/manager_products_screen.dart';
import 'features/manager/presentation/screens/manager_categories_screen.dart';
import 'features/manager/presentation/screens/manager_deals_screen.dart';
import 'features/manager/presentation/screens/manager_orders_screen.dart';
import 'features/manager/presentation/screens/manager_revenue_detail_screen.dart';
import 'features/manager/presentation/screens/inactive_members_screen.dart';
import 'features/account/presentation/screens/waiting_approval_screen.dart';
import 'features/account/presentation/screens/delete_account_screen.dart';
import 'features/admin/presentation/screens/manage_users_screen.dart';
import 'features/manager/presentation/screens/manager_banners_screen.dart';
import 'features/manager/presentation/screens/banner_detail_screen.dart';
import 'features/admin/presentation/screens/admin_banner_manage_screen.dart';
import 'features/auth/data/models/auth_models.dart';
import 'features/notifications/presentation/screens/notification_history_screen.dart';
import 'features/manager/presentation/screens/select_wholesaler_screen.dart';
import 'features/manager/presentation/screens/select_product_screen.dart';
import 'features/manager/presentation/screens/select_deal_screen.dart';
import 'features/manager/presentation/screens/select_category_screen.dart';
import 'shared/widgets/main_scaffold.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);
  final hasSelectedLanguage = ref.watch(hasSelectedLanguageProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: SplashScreen.routePath,
    routes: [
      GoRoute(
        path: SplashScreen.routePath,
        name: SplashScreen.routeName,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: InitialLanguageSelectionScreen.routePath,
        name: InitialLanguageSelectionScreen.routeName,
        builder: (context, state) =>
            const InitialLanguageSelectionScreen(),
      ),
      GoRoute(
        path: LoginScreen.routePath,
        name: LoginScreen.routeName,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RegisterScreen.routePath,
        name: RegisterScreen.routeName,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: TermsConsentScreen.routePath,
        name: TermsConsentScreen.routeName,
        builder: (context, state) => const TermsConsentScreen(),
      ),
      GoRoute(
        path: DashboardScreen.routePath,
        name: DashboardScreen.routeName,
        builder: (context, state) => const MainScaffold(
          initialIndex: 0,
        ),
      ),
      GoRoute(
        path: OptionsScreen.routePath,
        name: OptionsScreen.routeName,
        builder: (context, state) => const MainScaffold(
          initialIndex: 4, // Options tab
        ),
      ),
      GoRoute(
        path: ProfileScreen.routePath,
        name: ProfileScreen.routeName,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: DeleteAccountScreen.routePath,
        name: DeleteAccountScreen.routeName,
        builder: (context, state) => const DeleteAccountScreen(),
      ),
      GoRoute(
        path: CartScreen.routePath,
        name: CartScreen.routeName,
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: StoryViewerScreen.routePath,
        name: StoryViewerScreen.routeName,
        builder: (context, state) {
          final args = state.extra as StoryViewerArgs?;
          if (args == null) {
            return _RouteErrorScreen(
              message: AppLocalizations.of(context)?.noStoryDataProvided ??
                  'No story data provided.',
            );
          }
          return StoryViewerScreen(args: args);
        },
      ),
      // IMPORTANT: Specific routes must come before parameterized routes
      GoRoute(
        path: WholesalersListScreen.routePath,
        name: WholesalersListScreen.routeName,
        builder: (context, state) => const WholesalersListScreen(),
      ),
      GoRoute(
        path: WholesalerProfileScreen.routePath,
        name: WholesalerProfileScreen.routeName,
        builder: (context, state) {
          final id = state.pathParameters['id'];
          if (id == null) {
            return _RouteErrorScreen(
              message: AppLocalizations.of(context)?.missingWholesalerId ??
                  'Missing wholesaler id.',
            );
          }
          return WholesalerProfileScreen(wholesalerId: id);
        },
      ),
      // IMPORTANT: Specific routes must come before parameterized routes
      GoRoute(
        path: ProductSearchScreen.routePath,
        name: ProductSearchScreen.routeName,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ProductSearchScreen(
            initialQuery: extra?['query'] as String?,
          );
        },
      ),
      GoRoute(
        path: ProductsListScreen.routePath,
        name: ProductsListScreen.routeName,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ProductsListScreen(
            initialQuery: extra?['query'] as String?,
            featuredOnly: extra?['featuredOnly'] as bool? ?? false,
            showSearch: extra?['featuredOnly'] == true ? false : true,
            showCartAction: extra?['featuredOnly'] == true ? false : true,
            title: extra?['featuredOnly'] == true
                ? (AppLocalizations.of(context)?.featuredProducts ??
                    'Featured Products')
                : null,
          );
        },
      ),
      GoRoute(
        path: ProductDetailScreen.routePath,
        name: ProductDetailScreen.routeName,
        builder: (context, state) {
          final id = state.pathParameters['id'];
          if (id == null) {
            return _RouteErrorScreen(
              message: AppLocalizations.of(context)?.missingProductId ??
                  'Missing product id.',
            );
          }
          return ProductDetailScreen(productId: id);
        },
      ),
      GoRoute(
        path: CategoriesListScreen.routePath,
        name: CategoriesListScreen.routeName,
        builder: (context, state) => const CategoriesListScreen(),
      ),
      GoRoute(
        path: CategoryDetailScreen.routePath,
        name: CategoryDetailScreen.routeName,
        builder: (context, state) {
          final slug = state.pathParameters['slug'];
          if (slug == null) {
            return _RouteErrorScreen(
              message: AppLocalizations.of(context)?.missingCategorySlug ??
                  'Missing category slug.',
            );
          }
          final extra = state.extra as Map<String, dynamic>?;
          return CategoryDetailScreen(
            slug: slug,
            wholesalerId: extra?['wholesalerId'] as String?,
          );
        },
      ),
      GoRoute(
        path: DealListScreen.routePath,
        name: DealListScreen.routeName,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return DealListScreen(
            storyId: extra?['storyId'] as String?,
            wholesalerId: extra?['wholesalerId'] as String?,
            productId: extra?['productId'] as String?,
            title: extra?['title'] as String?,
          );
        },
      ),
      GoRoute(
        path: DealDetailScreen.routePath,
        name: DealDetailScreen.routeName,
        builder: (context, state) {
          final id = state.pathParameters['id'];
          if (id == null) {
            return _RouteErrorScreen(
              message: AppLocalizations.of(context)?.missingDealId ??
                  'Missing deal id.',
            );
          }
          return DealDetailScreen(dealId: id);
        },
      ),
      GoRoute(
        path: QuantityChangeResultScreen.routePath,
        name: QuantityChangeResultScreen.routeName,
        builder: (context, state) {
          final q = state.uri.queryParameters;
          return QuantityChangeResultScreen(
            quantityChange: q['quantity_change'] ?? 'error',
            type: q['type'],
            message: q['message'],
          );
        },
      ),
      GoRoute(
        path: MyOrdersScreen.routePath,
        name: MyOrdersScreen.routeName,
        builder: (context, state) => const MyOrdersScreen(),
      ),
      GoRoute(
        path: MyOrderDetailScreen.routePath,
        name: MyOrderDetailScreen.routeName,
        builder: (context, state) {
          final id = state.pathParameters['id'];
          if (id == null) {
            return _RouteErrorScreen(
              message: AppLocalizations.of(context)?.missingOrderId ??
                  'Missing order id.',
            );
          }
          return MyOrderDetailScreen(orderId: id);
        },
      ),
      GoRoute(
        path: MyDealOrdersScreen.routePath,
        name: MyDealOrdersScreen.routeName,
        builder: (context, state) => const MyDealOrdersScreen(),
      ),
      GoRoute(
        path: AboutUsScreen.routePath,
        name: AboutUsScreen.routeName,
        builder: (context, state) => const AboutUsScreen(),
      ),
      GoRoute(
        path: FAQScreen.routePath,
        name: FAQScreen.routeName,
        builder: (context, state) => const FAQScreen(),
      ),
      GoRoute(
        path: HelpSupportScreen.routePath,
        name: HelpSupportScreen.routeName,
        builder: (context, state) => const HelpSupportScreen(),
      ),
      GoRoute(
        path: LanguageSelectionScreen.routePath,
        name: LanguageSelectionScreen.routeName,
        builder: (context, state) => const LanguageSelectionScreen(),
      ),
      GoRoute(
        path: NotificationSettingsScreen.routePath,
        name: NotificationSettingsScreen.routeName,
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: CurrencySelectionScreen.routePath,
        name: CurrencySelectionScreen.routeName,
        builder: (context, state) => const CurrencySelectionScreen(),
      ),
      GoRoute(
        path: KioskStatisticsScreen.routePath,
        name: KioskStatisticsScreen.routeName,
        builder: (context, state) => const KioskStatisticsScreen(),
      ),
      GoRoute(
        path: CreateStoryScreen.routePath,
        name: CreateStoryScreen.routeName,
        builder: (context, state) => const CreateStoryScreen(),
      ),
      // Manager routes (role-aware: works for admin, sub-admin, and wholesaler)
      GoRoute(
        path: ManagerDashboardScreen.routePath,
        name: ManagerDashboardScreen.routeName,
        builder: (context, state) => const ManagerDashboardScreen(),
      ),
      GoRoute(
        path: ManagerProductsScreen.routePath,
        name: ManagerProductsScreen.routeName,
        builder: (context, state) => const ManagerProductsScreen(),
      ),
      GoRoute(
        path: ManagerDealsScreen.routePath,
        name: ManagerDealsScreen.routeName,
        builder: (context, state) => const ManagerDealsScreen(),
      ),
      GoRoute(
        path: ManagerOrdersScreen.routePath,
        name: ManagerOrdersScreen.routeName,
        builder: (context, state) => const ManagerOrdersScreen(),
      ),
      GoRoute(
        path: ManagerRevenueDetailScreen.routePath,
        name: ManagerRevenueDetailScreen.routeName,
        builder: (context, state) => const ManagerRevenueDetailScreen(),
      ),
      GoRoute(
        path: InactiveMembersScreen.routePath,
        name: InactiveMembersScreen.routeName,
        builder: (context, state) => const InactiveMembersScreen(),
      ),
      GoRoute(
        path: ManagerCategoriesScreen.routePath,
        name: ManagerCategoriesScreen.routeName,
        builder: (context, state) => const ManagerCategoriesScreen(),
      ),
      GoRoute(
        path: ManageUsersScreen.routePath,
        name: ManageUsersScreen.routeName,
        builder: (context, state) => const ManageUsersScreen(),
      ),
      GoRoute(
        path: WaitingApprovalScreen.routePath,
        name: WaitingApprovalScreen.routeName,
        builder: (context, state) => const WaitingApprovalScreen(),
      ),
      GoRoute(
        path: ManagerBannersScreen.routePath,
        name: ManagerBannersScreen.routeName,
        builder: (context, state) => const ManagerBannersScreen(),
      ),
      GoRoute(
        path: BannerDetailScreen.routePath,
        name: BannerDetailScreen.routeName,
        builder: (context, state) {
          final id = state.pathParameters['id'];
          if (id == null) {
            return _RouteErrorScreen(
              message: AppLocalizations.of(context)?.bannerNotFound ??
                  'Banner not found',
            );
          }
          return BannerDetailScreen(bannerId: id);
        },
      ),
      GoRoute(
        path: AdminBannerManageScreen.routePath,
        name: AdminBannerManageScreen.routeName,
        builder: (context, state) => const AdminBannerManageScreen(),
      ),
      GoRoute(
        path: NotificationHistoryScreen.routePath,
        name: NotificationHistoryScreen.routeName,
        builder: (context, state) => const NotificationHistoryScreen(),
      ),
      // Selection screens
      GoRoute(
        path: SelectWholesalerScreen.routePath,
        name: SelectWholesalerScreen.routeName,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return SelectWholesalerScreen(
            selectedWholesalerId: extra?['selectedWholesalerId'] as String?,
          );
        },
      ),
      GoRoute(
        path: SelectProductScreen.routePath,
        name: SelectProductScreen.routeName,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return SelectProductScreen(
            selectedProductId: extra?['selectedProductId'] as String?,
            wholesalerId: extra?['wholesalerId'] as String?,
          );
        },
      ),
      GoRoute(
        path: SelectDealScreen.routePath,
        name: SelectDealScreen.routeName,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return SelectDealScreen(
            selectedDealId: extra?['selectedDealId'] as String?,
          );
        },
      ),
      GoRoute(
        path: SelectCategoryScreen.routePath,
        name: SelectCategoryScreen.routeName,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final ids = extra?['selectedCategoryIds'];
          return SelectCategoryScreen(
            selectedCategoryId: extra?['selectedCategoryId'] as String?,
            selectedCategoryIds: ids is List
                ? List<String>.from(ids.map((e) => e.toString()))
                : const [],
            multiSelect: extra?['multiSelect'] == true,
          );
        },
      ),
    ],
    redirect: (context, state) {
      final session = authState.valueOrNull;
      final isInitializing = authState.isLoading;
      final loggingIn = state.matchedLocation == LoginScreen.routePath;
      final registering = state.matchedLocation == RegisterScreen.routePath;
      final onSplash = state.matchedLocation == SplashScreen.routePath;
      final onOnboardingLanguage =
          state.matchedLocation ==
              InitialLanguageSelectionScreen.routePath;
      final onTermsConsent =
          state.matchedLocation == TermsConsentScreen.routePath;
      final onQuantityChangeResult =
          state.matchedLocation == QuantityChangeResultScreen.routePath;

      // Allow quantity-change-result without auth (user lands from email link)
      if (onQuantityChangeResult) return null;

      // Only redirect to splash if truly initializing (checking stored session)
      // Don't redirect if user is actively logging in/registering
      if (isInitializing && !loggingIn && !registering && !onSplash) {
        return SplashScreen.routePath;
      }

      if (session == null) {
        if (onOnboardingLanguage) return null;
        if (!hasSelectedLanguage) {
          return InitialLanguageSelectionScreen.routePath;
        }
        if (loggingIn || registering) return null;
        return LoginScreen.routePath;
      }

      // Check if user needs approval
      final userStatus = session.user.status;
      final needsApproval = userStatus != UserStatus.approved &&
          userStatus != UserStatus.suspended; // Suspended users can't access

      // Require T&C + GDPR acceptance for all logged-in users
      final hasAcceptedLegal =
          session.user.termsAccepted && session.user.privacyAccepted;

      if (!hasAcceptedLegal && !onTermsConsent) {
        // Force user to TermsConsentScreen until they accept
        return TermsConsentScreen.routePath;
      }

      if (needsApproval &&
          state.matchedLocation != WaitingApprovalScreen.routePath) {
        return WaitingApprovalScreen.routePath;
      }

      if (loggingIn ||
          registering ||
          state.matchedLocation == SplashScreen.routePath) {
        // Only go to dashboard if approved
        if (!needsApproval) {
          return DashboardScreen.routePath;
        } else {
          return WaitingApprovalScreen.routePath;
        }
      }

      return null;
    },
  );
}, name: 'AppRouter');

class _RouteErrorScreen extends StatelessWidget {
  const _RouteErrorScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            return Text(l10n?.navigationError ?? 'Navigation error');
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
