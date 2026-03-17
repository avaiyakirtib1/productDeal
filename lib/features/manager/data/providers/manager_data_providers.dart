import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dashboard/data/repositories/dashboard_repository.dart';
import '../../data/repositories/manager_repository.dart';
import '../../../../core/networking/api_client.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/data/models/auth_models.dart';

/// Provider for loading categories for product creation (uses catalog endpoint)
final categoriesForProductProvider =
    FutureProvider.autoDispose<List<Map<String, String>>>((ref) async {
  try {
    final repo = ref.watch(dashboardRepositoryProvider);
    final categories = await repo.fetchCategories();
    return categories
        .map((cat) => {
              'id': cat.id,
              'name': cat.name,
            })
        .toList();
  } catch (e) {
    debugPrint('categoriesForProductProvider error: $e');
    return [];
  }
});

/// Provider for loading products for deal creation
/// Fetches products dynamically based on selected wholesalerId
/// If wholesalerId is null, returns empty list (admin must select a wholesaler first)
/// If wholesalerId is provided, fetches all products for that wholesaler
final productsForDealProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String?>((ref, wholesalerId) async {
  try {
    // If no wholesaler selected, return empty list
    if (wholesalerId == null || wholesalerId.isEmpty) {
      return [];
    }

    final repo = ref.watch(managerRepositoryProvider);
    // Use reasonable limit for dropdown (500 products should be enough for most wholesalers)
    // For very large wholesalers, consider adding search functionality in the future
    final page = await repo.fetchProducts(
      page: 1,
      limit: 500,
      wholesalerId: wholesalerId,
    );
    return page.items.map((product) {
      return {
        'id': product.id,
        'title': product.title,
        'name': product.title,
        'variants':
            <Map<String, dynamic>>[], // Will be loaded separately if needed
      };
    }).toList();
  } catch (e) {
    debugPrint('productsForDealProvider error: $e');
    return [];
  }
});

/// Provider for loading wholesalers (for admin when creating products)
/// Uses admin API endpoint directly
/// Fetches approved wholesalers with reasonable limit (500) and ensures current user is included if they're a wholesaler
final wholesalersForProductProvider =
    FutureProvider.autoDispose<List<Map<String, String>>>((ref) async {
  try {
    final dio = ref.watch(dioProvider);

    // Fetch approved wholesalers with reasonable limit (500 should be enough for most cases)
    // For very large deployments, consider adding search functionality in the future
    final response =
        await dio.get<Map<String, dynamic>>('/admin/users', queryParameters: {
      'limit': 500, // Reasonable limit for dropdown selection
      'role': 'wholesaler',
      'status': 'approved', // Only show approved wholesalers
    });

    final users = (response.data?['data'] as List<dynamic>?) ?? [];
    final wholesalerMap = <String, Map<String, String>>{};

    // Process all wholesalers from API
    for (final user in users) {
      final u = user as Map<String, dynamic>;
      if (u['role'] == 'wholesaler') {
        final id = (u['_id'] ?? u['id']).toString();
        // Format: "Full Name (Business Name)"
        final name =
            '${u['fullName'] ?? 'Unknown'} (${u['businessName'] ?? 'Unknown'})';
        wholesalerMap[id] = {
          'id': id,
          'name': name,
        };
      }
    }

    // Get current user to ensure they're included if they're a wholesaler
    try {
      final authState = ref.read(authControllerProvider);
      final session = authState.valueOrNull;
      if (session != null) {
        final currentUser = session.user;
        // If current user is a wholesaler and not in the list, add them
        if (currentUser.role == UserRole.wholesaler &&
            !wholesalerMap.containsKey(currentUser.id)) {
          final name =
              '${currentUser.fullName} (${currentUser.businessName ?? 'Unknown'})';
          wholesalerMap[currentUser.id] = {
            'id': currentUser.id,
            'name': name,
          };
        }
      }
    } catch (e) {
      debugPrint('Error getting current user for wholesaler list: $e');
      // Continue without current user if there's an error
    }

    // Convert map to list and sort by name for better UX
    final wholesalerList = wholesalerMap.values.toList();
    wholesalerList.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));

    return wholesalerList;
  } catch (e) {
    debugPrint('wholesalersForProductProvider error: $e');
    return [];
  }
});

/// Provider for loading parent categories (for category creation)
/// Uses admin API endpoint directly
final parentCategoriesProvider =
    FutureProvider.autoDispose<List<Map<String, String>>>((ref) async {
  try {
    final dio = ref.watch(dioProvider);
    final response = await dio.get<Map<String, dynamic>>('/admin/categories');
    final categories = (response.data?['data'] as List<dynamic>?) ?? [];
    return categories.map((cat) {
      final c = cat as Map<String, dynamic>;
      return <String, String>{
        'id': (c['_id'] ?? c['id']).toString(),
        'name': (c['name'] ?? 'Unknown').toString(),
      };
    }).toList();
  } catch (e) {
    debugPrint('parentCategoriesProvider error: $e');
    return [];
  }
});

/// Provider for loading product variants
/// Uses admin endpoint to get variants for all product statuses (not just APPROVED)
/// This is important for managers creating deals on their own products
final productVariantsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, productId) async {
  try {
    // Use manager repository which calls admin endpoint
    // This works for all product statuses (DRAFT, PENDING, APPROVED, etc.)
    final repo = ref.watch(managerRepositoryProvider);
    return await repo.fetchProductVariants(productId);
  } catch (e) {
    debugPrint('productVariantsProvider error: $e');
    // Fallback to catalog endpoint if admin endpoint fails (for public products)
    try {
      final dashboardRepo = ref.watch(dashboardRepositoryProvider);
      final product = await dashboardRepo.fetchProductDetail(productId);
      return (product.variants ?? [])
          .map((variant) => {
                'id': variant.id,
                'sku': variant.sku,
                'attributes': variant.attributes,
                'price': variant.price,
                'costPrice': variant.costPrice,
                'stock': variant.stock,
                'reservedStock':
                    0, // Catalog endpoint doesn't return reservedStock
                'availableStock': variant.availableStock,
                'images': variant.images ?? [],
                'isDefault': variant.isDefault,
                'isActive': true,
              })
          .toList();
    } catch (fallbackError) {
      debugPrint('productVariantsProvider fallback error: $fallbackError');
      return [];
    }
  }
});

/// Provider for manager product detail
final managerProductDetailProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, productId) async {
  try {
    final repo = ref.watch(managerRepositoryProvider);
    return await repo.fetchProductDetail(productId);
  } catch (e) {
    debugPrint('managerProductDetailProvider error: $e');
    rethrow;
  }
});
