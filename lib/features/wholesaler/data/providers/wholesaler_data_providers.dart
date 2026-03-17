import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dashboard/data/repositories/dashboard_repository.dart';
import '../../../manager/data/repositories/manager_repository.dart';
import '../../../../core/networking/api_client.dart';

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
/// Note: This provider is deprecated - use manager_data_providers.productsForDealProvider instead
/// which supports dynamic fetching based on wholesalerId
final productsForDealProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  try {
    final repo = ref.watch(managerRepositoryProvider);
    // Use reasonable limit for dropdown (500 products should be enough)
    final page = await repo.fetchProducts(page: 1, limit: 500);
    return page.items
        .map((product) => {
              'id': product.id,
              'title': product.title,
              'name': product.title,
              'variants': <Map<String,
                  dynamic>>[], // Will be loaded separately if needed
            })
        .toList();
  } catch (e) {
    return [];
  }
});

/// Provider for loading wholesalers (for admin when creating products)
/// Uses admin API endpoint directly
/// Note: This provider is deprecated - use manager_data_providers.wholesalersForProductProvider instead
final wholesalersForProductProvider =
    FutureProvider.autoDispose<List<Map<String, String>>>((ref) async {
  try {
    final dio = ref.watch(dioProvider);
    // Use reasonable limit for dropdown (500 wholesalers should be enough)
    final response =
        await dio.get<Map<String, dynamic>>('/admin/users', queryParameters: {
      'limit': 500,
      'role': 'wholesaler',
      'status': 'approved', // Only show approved wholesalers
    });
    final users = (response.data?['data'] as List<dynamic>?) ?? [];
    return users
        .where((user) => (user as Map<String, dynamic>)['role'] == 'wholesaler')
        .map((user) {
      final u = user as Map<String, dynamic>;
      return <String, String>{
        'id': (u['_id'] ?? u['id']).toString(),
        'name': (u['businessName'] ?? u['fullName'] ?? 'Unknown').toString(),
      };
    }).toList();
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
/// This is important for wholesalers creating deals on their own products
final productVariantsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, productId) async {
  try {
    // Use wholesaler repository which calls admin endpoint
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
