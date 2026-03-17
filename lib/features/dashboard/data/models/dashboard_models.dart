import '../../../deals/data/models/deal_models.dart';

class DashboardCategory {
  const DashboardCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.imageUrl,
    this.description,
    this.productCount = 0,
  });

  final String id;
  final String name;
  final String slug;
  final String imageUrl;
  final String? description;
  final int productCount;

  factory DashboardCategory.fromJson(Map<String, dynamic> json) =>
      DashboardCategory(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        slug: json['slug'] as String? ?? '',
        imageUrl: json['imageUrl'] as String? ?? '',
        description: json['description'] as String?,
        productCount: json['productCount'] as int? ?? 0,
      );
}

/// Category Tree Node (hierarchical structure)
class CategoryTreeNode {
  const CategoryTreeNode({
    required this.id,
    required this.name,
    required this.slug,
    required this.imageUrl,
    this.description,
    this.parentId,
    required this.hierarchyLevel,
    required this.path,
    required this.isActive,
    required this.displayOrder,
    this.children = const [],
  });

  final String id;
  final String name;
  final String slug;
  final String imageUrl;
  final String? description;
  final String? parentId;
  final int hierarchyLevel;
  final String path;
  final bool isActive;
  final int displayOrder;
  final List<CategoryTreeNode> children;

  factory CategoryTreeNode.fromJson(Map<String, dynamic> json) {
    final childrenJson = json['children'] as List<dynamic>? ?? [];
    return CategoryTreeNode(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      description: json['description'] as String?,
      parentId: json['parentId']?.toString(),
      hierarchyLevel: (json['hierarchyLevel'] as num?)?.toInt() ?? 0,
      path: json['path'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
      children: childrenJson
          .map((child) =>
              CategoryTreeNode.fromJson(child as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Category Children Response
class CategoryChildrenResponse {
  const CategoryChildrenResponse({
    required this.category,
    required this.children,
  });

  final DashboardCategory category;
  final List<DashboardCategory> children;

  factory CategoryChildrenResponse.fromJson(Map<String, dynamic> json) {
    final categoryJson = json['category'] as Map<String, dynamic>? ?? {};
    final childrenJson = json['children'] as List<dynamic>? ?? [];
    return CategoryChildrenResponse(
      category: DashboardCategory.fromJson(categoryJson),
      children: childrenJson
          .map((child) =>
              DashboardCategory.fromJson(child as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ProductVariant {
  const ProductVariant({
    required this.id,
    required this.sku,
    required this.price,
    required this.stock,
    required this.availableStock,
    this.attributes,
    this.costPrice,
    this.images,
    this.isActive = true,
    this.isDefault = false,
  });

  final String id;
  final String sku;
  final double price;
  final int stock;
  final int availableStock;
  final Map<String, dynamic>? attributes;
  final double? costPrice;
  final List<String>? images;
  final bool isActive;
  final bool isDefault;

  factory ProductVariant.fromJson(Map<String, dynamic> json) => ProductVariant(
        id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
        sku: json['sku'] as String? ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0,
        stock: (json['stock'] as num?)?.toInt() ?? 0,
        availableStock: (json['availableStock'] as num?)?.toInt() ??
            (json['stock'] as num?)?.toInt() ??
            0,
        attributes: json['attributes'] as Map<String, dynamic>?,
        costPrice: (json['costPrice'] as num?)?.toDouble(),
        images: (json['images'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList(),
        isActive: json['isActive'] as bool? ?? true,
        isDefault: json['isDefault'] as bool? ?? false,
      );
}

/// Parse product image URL - same logic for list and detail.
String _parseProductImageUrl(Map<String, dynamic> json) {
  final imageUrl = (json['imageUrl'] as String?)?.trim();
  if (imageUrl != null && imageUrl.isNotEmpty) return imageUrl;
  final images = json['images'] as List<dynamic>?;
  if (images != null && images.isNotEmpty) {
    final first = images.first;
    if (first is String) return first;
    if (first is Map && first['url'] != null) return first['url'].toString();
  }
  return '';
}

class DashboardProduct {
  const DashboardProduct({
    required this.id,
    required this.title,
    required this.unit,
    required this.price,
    required this.imageUrl,
    this.categoryName,
    this.wholesalerName,
    this.distanceKm,
    this.variants,
    this.basePrice,
    this.averageRating,
    this.reviewCount,
  });

  final String id;
  final String title;
  final String unit;
  final double price; // Current/default variant price or base price
  final String imageUrl;
  final String? categoryName;
  final String? wholesalerName;
  final double? distanceKm;
  final List<ProductVariant>? variants;
  final double? basePrice; // Base price if variants exist
  final double? averageRating; // Average rating (0-5)
  final int? reviewCount; // Number of reviews

  // Get the default or first variant
  ProductVariant? get defaultVariant {
    if (variants == null || variants!.isEmpty) return null;
    return variants!.firstWhere(
      (v) => v.isDefault,
      orElse: () => variants!.first,
    );
  }

  // Get price from default variant or use base price
  double get displayPrice {
    final variant = defaultVariant;
    if (variant != null && variant.price > 0) return variant.price;
    return (basePrice != null && basePrice! > 0) ? basePrice! : price;
  }

  /// Available stock from default variant, or null if unknown (no variants).
  int? get availableStock {
    final variant = defaultVariant;
    if (variant != null) return variant.availableStock;
    return null;
  }

  /// True if product is out of stock (known stock and <= 0).
  bool get isOutOfStock {
    final s = availableStock;
    return s != null && s <= 0;
  }

  factory DashboardProduct.fromJson(Map<String, dynamic> json) {
    final variantsJson = json['variants'] as List<dynamic>?;
    final variants = variantsJson
        ?.map((v) => ProductVariant.fromJson(v as Map<String, dynamic>))
        .toList();

    // Determine price: use variant price if available, otherwise use base price or price
    // Determine price: use variant price if available, otherwise use base price or price
    double price;
    if (variants != null && variants.isNotEmpty) {
      final defaultVariant = variants.firstWhere(
        (v) => v.isDefault,
        orElse: () => variants.first,
      );
      // Prioritize variant price, if 0 fallback to basePrice
      price = defaultVariant.price > 0
          ? defaultVariant.price
          : ((json['basePrice'] as num?)?.toDouble() ?? 0);
    } else {
      price = (json['basePrice'] as num?)?.toDouble() ??
          (json['price'] as num?)?.toDouble() ??
          0;
    }

    return DashboardProduct(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      title: (json['title'] is Map)
          ? (json['title']['en']?.toString() ??
              json['title'].values.first.toString())
          : (json['title'] as String? ?? json['name'] as String? ?? ''),
      unit: json['unit'] as String? ?? '',
      price: price,
      imageUrl: _parseProductImageUrl(json),
      categoryName: json['categoryName'] as String?,
      wholesalerName: json['wholesalerName'] as String?,
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      variants: variants,
      basePrice: (json['basePrice'] as num?)?.toDouble(),
      averageRating: (json['rating'] is Map<String, dynamic>)
          ? ((json['rating'] as Map<String, dynamic>)['average'] as num?)
              ?.toDouble()
          : (json['averageRating'] as num?)?.toDouble(),
      reviewCount: (json['rating'] is Map<String, dynamic>)
          ? ((json['rating'] as Map<String, dynamic>)['count'] as num?)?.toInt()
          : (json['reviewCount'] as num?)?.toInt(),
    );
  }
}

class WholesalerLocationPin {
  const WholesalerLocationPin({
    required this.label,
    required this.longitude,
    required this.latitude,
    this.address,
    this.city,
    this.country,
  });

  factory WholesalerLocationPin.fromJson(Map<String, dynamic> json) {
    final coords = (json['location'] as Map<String, dynamic>? ??
            const {})['coordinates'] as List<dynamic>? ??
        const [];
    final lng = coords.isNotEmpty ? (coords[0] as num?)?.toDouble() : null;
    final lat = coords.length > 1 ? (coords[1] as num?)?.toDouble() : null;
    return WholesalerLocationPin(
      label: json['label'] as String? ?? 'Location',
      longitude: lng ?? 0,
      latitude: lat ?? 0,
      address: json['address'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
    );
  }

  final String label;
  final double longitude;
  final double latitude;
  final String? address;
  final String? city;
  final String? country;
}

class SpotlightWholesaler {
  const SpotlightWholesaler({
    required this.id,
    required this.name,
    required this.businessName,
    required this.avatarUrl,
    this.coverImageUrl,
    this.city,
    this.tagline,
    this.distanceKm,
    this.hasActiveStory = false,
    this.locations = const [],
    this.stories = const [],
  });

  final String id;
  final String name;
  final String businessName;
  final String avatarUrl;
  final String? coverImageUrl;
  final String? city;
  final String? tagline;
  final double? distanceKm;
  final bool hasActiveStory;
  final List<WholesalerLocationPin> locations;
  final List<StoryMedia> stories;

  factory SpotlightWholesaler.fromJson(Map<String, dynamic> json) =>
      SpotlightWholesaler(
        id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        businessName: json['businessName'] as String? ?? '',
        avatarUrl: json['avatarUrl'] as String? ?? '',
        coverImageUrl: json['coverImageUrl'] as String?,
        city: json['city'] as String?,
        tagline: json['tagline'] as String?,
        distanceKm: (json['distanceKm'] as num?)?.toDouble(),
        hasActiveStory: json['hasActiveStory'] as bool? ?? false,
        locations: (json['locations'] as List<dynamic>? ?? [])
            .map((entry) =>
                WholesalerLocationPin.fromJson(entry as Map<String, dynamic>))
            .toList(growable: false),
        stories: (json['stories'] as List<dynamic>? ?? [])
            .map((entry) => StoryMedia.fromJson(entry as Map<String, dynamic>))
            .toList(growable: false),
      );
}

class WholesalerDirectoryPage {
  const WholesalerDirectoryPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.totalRows,
  });

  final List<SpotlightWholesaler> items;
  final int page;
  final int limit;
  final int totalRows;

  int get totalPages {
    if (totalRows == 0 || limit <= 0) return 1;
    return (totalRows / limit).ceil();
  }

  bool get hasNext => page < totalPages;
  bool get hasPrevious => page > 1;
}

class StoryMedia {
  const StoryMedia({
    required this.id,
    required this.mediaUrl,
    required this.thumbnailUrl,
    required this.isVideo,
    required this.expiresAt,
    this.productId,
    this.product,
    this.dealId,
    this.deal,
  });

  final String id;
  final String mediaUrl;
  final String thumbnailUrl;
  final bool isVideo;
  final DateTime expiresAt;
  // Optional product/deal linking
  final String? productId;
  final StoryLinkedProduct? product;
  final String? dealId;
  final StoryLinkedDeal? deal;

  factory StoryMedia.fromJson(Map<String, dynamic> json) => StoryMedia(
        id: json['id']?.toString() ?? '',
        mediaUrl: json['mediaUrl'] as String? ?? '',
        thumbnailUrl: json['thumbnailUrl'] as String? ??
            json['mediaUrl'] as String? ??
            '',
        isVideo: json['isVideo'] as bool? ?? false,
        expiresAt: DateTime.tryParse(json['expiresAt'] as String? ?? '') ??
            DateTime.now(),
        productId: json['productId']?.toString(),
        product: json['product'] != null
            ? StoryLinkedProduct.fromJson(
                json['product'] as Map<String, dynamic>)
            : null,
        dealId: json['dealId']?.toString(),
        deal: json['deal'] != null
            ? StoryLinkedDeal.fromJson(json['deal'] as Map<String, dynamic>)
            : null,
      );
}

class StoryLinkedProduct {
  const StoryLinkedProduct({
    required this.id,
    required this.title,
    required this.price,
    required this.imageUrl,
  });

  final String id;
  final String title;
  final double price;
  final String imageUrl;

  factory StoryLinkedProduct.fromJson(Map<String, dynamic> json) =>
      StoryLinkedProduct(
        id: json['id']?.toString() ?? '',
        title: json['title'] as String? ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        imageUrl: json['imageUrl'] as String? ?? '',
      );
}

class StoryLinkedDeal {
  const StoryLinkedDeal({
    required this.id,
    required this.title,
    required this.dealPrice,
    this.images,
  });

  final String id;
  final String title;
  final double dealPrice;
  final List<String>? images;

  factory StoryLinkedDeal.fromJson(Map<String, dynamic> json) =>
      StoryLinkedDeal(
        id: json['id']?.toString() ?? '',
        title: json['title'] as String? ?? '',
        dealPrice: (json['dealPrice'] as num?)?.toDouble() ?? 0.0,
        images: (json['images'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList(),
      );
}

class StoryGroup {
  const StoryGroup({
    required this.wholesalerId,
    required this.wholesalerName,
    required this.avatarUrl,
    required this.stories,
    this.distanceKm,
    this.locations = const [],
  });

  final String wholesalerId;
  final String wholesalerName;
  final String avatarUrl;
  final List<StoryMedia> stories;
  final double? distanceKm;
  final List<WholesalerLocationPin> locations;

  factory StoryGroup.fromJson(Map<String, dynamic> json) => StoryGroup(
        wholesalerId: json['wholesalerId']?.toString() ?? '',
        wholesalerName: json['wholesalerName'] as String? ?? '',
        avatarUrl: json['avatarUrl'] as String? ?? '',
        stories: (json['stories'] as List<dynamic>? ?? [])
            .map((entry) => StoryMedia.fromJson(entry as Map<String, dynamic>))
            .toList(),
        distanceKm: (json['distanceKm'] as num?)?.toDouble(),
        locations: (json['locations'] as List<dynamic>? ?? [])
            .map((entry) =>
                WholesalerLocationPin.fromJson(entry as Map<String, dynamic>))
            .toList(growable: false),
      );
}

class TopCategory {
  const TopCategory({
    required this.id,
    required this.name,
    required this.totalProducts,
    required this.imageUrl,
    this.slug,
  });

  final String id;
  final String name;
  final int totalProducts;
  final String imageUrl;
  final String? slug;

  factory TopCategory.fromJson(Map<String, dynamic> json) => TopCategory(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        totalProducts: json['totalProducts'] as int? ?? 0,
        imageUrl: json['imageUrl'] as String? ?? '',
        slug: json['slug'] as String?,
      );
}

class WholesalerProfile {
  const WholesalerProfile({
    required this.wholesaler,
    required this.featuredProducts,
    required this.topCategories,
  });

  final SpotlightWholesaler wholesaler;
  final List<DashboardProduct> featuredProducts;
  final List<TopCategory> topCategories;

  factory WholesalerProfile.fromJson(Map<String, dynamic> json) =>
      WholesalerProfile(
        wholesaler: SpotlightWholesaler.fromJson(
          json['wholesaler'] as Map<String, dynamic>? ?? const {},
        ),
        featuredProducts: (json['featuredProducts'] as List<dynamic>? ?? [])
            .map((item) =>
                DashboardProduct.fromJson(item as Map<String, dynamic>))
            .toList(),
        topCategories: (json['topCategories'] as List<dynamic>? ?? [])
            .map((item) => TopCategory.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
}

class ProductDetail {
  const ProductDetail({
    required this.id,
    required this.title,
    this.description,
    required this.unit,
    required this.price,
    this.stock,
    required this.imageUrl,
    this.category,
    this.wholesaler,
    this.variants,
    this.basePrice,
    this.images,
  });

  final String id;
  final String title;
  final String? description;
  final String unit;
  final double price; // Current/default variant price or base price
  final int? stock; // Current/default variant stock or total stock
  final String imageUrl;
  final List<String>? images; // Product image gallery
  final DashboardCategory? category;
  final SpotlightWholesaler? wholesaler;
  final List<ProductVariant>? variants;
  final double? basePrice;

  // Get the default or first variant
  ProductVariant? get defaultVariant {
    if (variants == null || variants!.isEmpty) return null;
    return variants!.firstWhere(
      (v) => v.isDefault,
      orElse: () => variants!.first,
    );
  }

  // Get price from default variant or use base price
  double get displayPrice {
    final variant = defaultVariant;
    if (variant != null) return variant.price;
    return basePrice ?? price;
  }

  // Get stock from default variant or use total stock
  int? get displayStock {
    final variant = defaultVariant;
    if (variant != null) return variant.availableStock;
    return stock;
  }

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    final variantsJson = json['variants'] as List<dynamic>?;
    final variants = variantsJson
        ?.map((v) => ProductVariant.fromJson(v as Map<String, dynamic>))
        .toList();

    // Determine price and stock from variant if available
    double price;
    int? stock;
    if (variants != null && variants.isNotEmpty) {
      final defaultVariant = variants.firstWhere(
        (v) => v.isDefault,
        orElse: () => variants.first,
      );
      price = defaultVariant.price;
      stock = defaultVariant.availableStock;
    } else {
      price = (json['basePrice'] as num?)?.toDouble() ??
          (json['price'] as num?)?.toDouble() ??
          0;
      stock = json['stock'] as int?;
    }

    // Same image logic as DashboardProduct – use shared _parseProductImageUrl
    final imagesJson = json['images'] as List<dynamic>?;
    List<String>? images;
    if (imagesJson != null && imagesJson.isNotEmpty) {
      images = imagesJson
          .map((e) {
            if (e is String) return e;
            if (e is Map && e['url'] != null) return e['url'].toString();
            return '';
          })
          .where((s) => s.isNotEmpty)
          .toList();
      if (images.isEmpty) images = null;
    }
    final imageUrl = _parseProductImageUrl(json);

    return ProductDetail(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: (json['title'] is Map)
          ? (json['title']['en']?.toString() ??
              json['title'].values.first.toString())
          : (json['title'] as String? ?? json['name'] as String? ?? ''),
      description: (json['description'] is Map)
          ? (json['description']['en']?.toString() ??
              json['description'].values.first.toString())
          : (json['description'] as String?),
      unit: json['unit'] as String? ?? '',
      price: price,
      stock: stock,
      imageUrl: imageUrl,
      images: images,
      category: json['category'] != null
          ? DashboardCategory.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      wholesaler: json['wholesaler'] != null
          ? SpotlightWholesaler.fromJson(
              json['wholesaler'] as Map<String, dynamic>)
          : null,
      variants: variants,
      basePrice: (json['basePrice'] as num?)?.toDouble(),
    );
  }
}

class ProductsPage {
  const ProductsPage({
    required this.items,
    this.page = 1,
    this.limit = 24,
    this.totalRows = 0,
    this.totalPages = 1,
  });

  final List<DashboardProduct> items;
  final int page;
  final int limit;
  final int totalRows;
  final int totalPages;

  bool get hasNext => page < totalPages;
  bool get hasPrevious => page > 1;
}

class CategoryDetail {
  const CategoryDetail({
    required this.category,
    required this.products,
    this.page = 1,
    this.limit = 24,
    this.totalRows = 0,
    this.totalPages = 1,
  });

  final DashboardCategory category;
  final List<DashboardProduct> products;
  final int page;
  final int limit;
  final int totalRows;
  final int totalPages;

  bool get hasNext => page < totalPages;
  bool get hasPrevious => page > 1;

  factory CategoryDetail.fromJson(Map<String, dynamic> json,
          {Map<String, dynamic>? meta}) =>
      CategoryDetail(
        category: DashboardCategory.fromJson(
            json['category'] as Map<String, dynamic>? ?? const {}),
        products: (json['products'] as List<dynamic>? ?? [])
            .map((item) =>
                DashboardProduct.fromJson(item as Map<String, dynamic>))
            .toList(),
        page: meta?['page'] as int? ?? json['page'] as int? ?? 1,
        limit: meta?['limit'] as int? ?? json['limit'] as int? ?? 24,
        totalRows: meta?['totalRows'] as int? ?? json['totalRows'] as int? ?? 0,
        totalPages:
            meta?['totalPages'] as int? ?? json['totalPages'] as int? ?? 1,
      );
}

class DashboardSnapshot {
  const DashboardSnapshot({
    required this.categories,
    required this.activeDeals,
    required this.nearbyWholesalers,
    required this.storyGroups,
    this.activeShopsCount = 0,
    this.activeMembersCount = 0,
  });

  final List<DashboardCategory> categories;
  final List<Deal> activeDeals;
  final List<SpotlightWholesaler> nearbyWholesalers;
  final List<StoryGroup> storyGroups;
  final int activeShopsCount;
  final int activeMembersCount;

  factory DashboardSnapshot.fromJson(Map<String, dynamic> json) =>
      DashboardSnapshot(
        categories: (json['categories'] as List<dynamic>? ?? [])
            .map((category) =>
                DashboardCategory.fromJson(category as Map<String, dynamic>))
            .toList(),
        activeDeals: (json['activeDeals'] as List<dynamic>? ?? [])
            .map((item) => Deal.fromJson(item as Map<String, dynamic>))
            .toList(),
        nearbyWholesalers: (json['nearbyWholesalers'] as List<dynamic>? ??
                json['spotlight'] as List<dynamic>? ??
                [])
            .map((item) =>
                SpotlightWholesaler.fromJson(item as Map<String, dynamic>))
            .toList(),
        storyGroups: (json['stories'] as List<dynamic>? ?? [])
            .map((group) => StoryGroup.fromJson(group as Map<String, dynamic>))
            .toList(),
        activeShopsCount: (json['activeShopsCount'] as num?)?.toInt() ?? 0,
        activeMembersCount: (json['activeMembersCount'] as num?)?.toInt() ?? 0,
      );
}
