import '../../features/auth/data/models/auth_models.dart';

/// Permission utilities for role-based access control
class Permissions {
  /// Check if user can manage other users (create, edit, delete)
  static bool canManageUsers(UserRole role) {
    return role == UserRole.admin || role == UserRole.subAdmin;
  }

  /// Check if user can manage categories (create, edit, delete)
  static bool canManageCategories(UserRole role) {
    return role == UserRole.admin || role == UserRole.subAdmin;
  }

  /// Check if user can add products
  /// Admin/SubAdmin cannot add products, only edit
  static bool canAddProducts(UserRole role) {
    return role == UserRole.wholesaler ||
        role == UserRole.admin ||
        role == UserRole.subAdmin;
  }

  /// Check if user can add deals
  /// Only Admin/SubAdmin can create deals (wholesalers cannot create deals for now)
  static bool canAddDeals(UserRole role) {
    return role == UserRole.admin || role == UserRole.subAdmin;
  }

  /// Check if user can edit products
  static bool canEditProducts(UserRole role) {
    return role == UserRole.admin ||
        role == UserRole.subAdmin ||
        role == UserRole.wholesaler;
  }

  /// Check if user can edit deals
  static bool canEditDeals(UserRole role) {
    return role == UserRole.admin ||
        role == UserRole.subAdmin ||
        role == UserRole.wholesaler;
  }

  /// Check if user can delete any product (not just own)
  static bool canDeleteAnyProduct(UserRole role) {
    return role == UserRole.admin || role == UserRole.subAdmin;
  }

  /// Check if user can delete any deal (not just own)
  static bool canDeleteAnyDeal(UserRole role) {
    return role == UserRole.admin || role == UserRole.subAdmin;
  }

  /// Check if user can view all data (or just own data)
  static bool canViewAllData(UserRole role) {
    return role == UserRole.admin || role == UserRole.subAdmin;
  }

  /// Check if user is admin or sub-admin
  static bool isAdminOrSubAdmin(UserRole role) {
    return role == UserRole.admin || role == UserRole.subAdmin;
  }

  /// Check if user is wholesaler
  static bool isWholesaler(UserRole role) {
    return role == UserRole.wholesaler;
  }

  /// Check if user is admin
  static bool isAdmin(UserRole role) {
    return role == UserRole.admin;
  }

  /// Check if user is sub-admin
  static bool isSubAdmin(UserRole role) {
    return role == UserRole.subAdmin;
  }

  /// Deal order placement RBAC. Modify allowed roles as needed:
  /// - ADMIN_ONLY: [admin, subAdmin]
  /// - WHOLESALER_ONLY: [wholesaler]
  /// - KIOSK_SHOP_ONLY: [kiosk]
  /// - ALL: [admin, subAdmin, wholesaler, kiosk]
  static const _dealOrderAllowedRoles = [
    UserRole.admin,
    UserRole.subAdmin,
    UserRole.wholesaler,
    UserRole.kiosk,
  ];

  /// Check if user can place orders (add bids) on deals.
  static bool canPlaceOrderOnDeal(UserRole role) {
    return _dealOrderAllowedRoles.contains(role);
  }
}
