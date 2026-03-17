class WholesalerStats {
  const WholesalerStats({
    required this.totalProducts,
    required this.activeDeals,
    required this.pendingOrders,
    required this.totalRevenue,
    this.recentOrders = const [],
  });

  factory WholesalerStats.fromJson(Map<String, dynamic> json) {
    return WholesalerStats(
      totalProducts: (json['totalProducts'] as num?)?.toInt() ?? 0,
      activeDeals: (json['activeDeals'] as num?)?.toInt() ?? 0,
      pendingOrders: (json['pendingOrders'] as num?)?.toInt() ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0,
      recentOrders: (json['recentOrders'] as List<dynamic>? ?? [])
          .map((item) => RecentOrder.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  final int totalProducts;
  final int activeDeals;
  final int pendingOrders;
  final double totalRevenue;
  final List<RecentOrder> recentOrders;
}

class RecentOrder {
  const RecentOrder({
    required this.id,
    required this.totalAmount,
    required this.status,
    required this.itemCount,
    required this.createdAt,
  });

  factory RecentOrder.fromJson(Map<String, dynamic> json) {
    return RecentOrder(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'pending',
      itemCount: (json['itemCount'] as num?)?.toInt() ??
          (json['items'] as List<dynamic>?)?.length ??
          0,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  final String id;
  final double totalAmount;
  final String status;
  final int itemCount;
  final DateTime createdAt;
}

class WholesalerProductsPage {
  const WholesalerProductsPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.totalRows,
  });

  factory WholesalerProductsPage.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as List<dynamic>? ?? [];
    final meta = json['meta'] as Map<String, dynamic>? ?? const {};
    return WholesalerProductsPage(
      items: data
          .map((item) =>
              WholesalerProduct.fromJson(item as Map<String, dynamic>))
          .toList(),
      page: meta['page'] as int? ?? 1,
      limit: meta['limit'] as int? ?? 20,
      totalRows: meta['totalRows'] as int? ?? data.length,
    );
  }

  final List<WholesalerProduct> items;
  final int page;
  final int limit;
  final int totalRows;
}

class WholesalerProduct {
  const WholesalerProduct({
    required this.id,
    required this.title,
    required this.price,
    required this.stock,
    required this.status,
    this.imageUrl,
    this.variantCount,
  });

  factory WholesalerProduct.fromJson(Map<String, dynamic> json) {
    return WholesalerProduct(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['title'] as String? ?? json['name'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'pending',
      imageUrl: json['imageUrl'] as String? ??
          (json['images'] as List<dynamic>?)?.firstOrNull?.toString(),
      variantCount: (json['variantCount'] as num?)?.toInt() ??
          (json['variants'] as List<dynamic>?)?.length,
    );
  }

  final String id;
  final String title;
  final double price;
  final int stock;
  final String status;
  final String? imageUrl;
  final int? variantCount;
}

class WholesalerDealsPage {
  const WholesalerDealsPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.totalRows,
  });

  factory WholesalerDealsPage.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as List<dynamic>? ?? [];
    final meta = json['meta'] as Map<String, dynamic>? ?? const {};
    return WholesalerDealsPage(
      items: data
          .map((item) => WholesalerDeal.fromJson(item as Map<String, dynamic>))
          .toList(),
      page: meta['page'] as int? ?? 1,
      limit: meta['limit'] as int? ?? 20,
      totalRows: meta['totalRows'] as int? ?? data.length,
    );
  }

  final List<WholesalerDeal> items;
  final int page;
  final int limit;
  final int totalRows;
}

class WholesalerDeal {
  const WholesalerDeal({
    required this.id,
    required this.title,
    required this.dealPrice,
    required this.status,
    required this.orderCount,
    required this.receivedQuantity,
    required this.targetQuantity,
    this.progressPercent = 0,
  });

  factory WholesalerDeal.fromJson(Map<String, dynamic> json) {
    return WholesalerDeal(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      dealPrice: (json['dealPrice'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'draft',
      orderCount: (json['orderCount'] as num?)?.toInt() ?? 0,
      receivedQuantity: (json['receivedQuantity'] as num?)?.toInt() ?? 0,
      targetQuantity: (json['targetQuantity'] as num?)?.toInt() ?? 0,
      progressPercent: (json['progressPercent'] as num?)?.toDouble() ?? 0,
    );
  }

  final String id;
  final String title;
  final double dealPrice;
  final String status;
  final int orderCount;
  final int receivedQuantity;
  final int targetQuantity;
  final double progressPercent;
}

class WholesalerOrdersPage {
  const WholesalerOrdersPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.totalRows,
  });

  factory WholesalerOrdersPage.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as List<dynamic>? ?? [];
    final meta = json['meta'] as Map<String, dynamic>? ?? const {};
    return WholesalerOrdersPage(
      items: data
          .map((item) => WholesalerOrder.fromJson(item as Map<String, dynamic>))
          .toList(),
      page: meta['page'] as int? ?? 1,
      limit: meta['limit'] as int? ?? 20,
      totalRows: meta['totalRows'] as int? ?? data.length,
    );
  }

  final List<WholesalerOrder> items;
  final int page;
  final int limit;
  final int totalRows;
}

class WholesalerOrder {
  const WholesalerOrder({
    required this.id,
    required this.totalAmount,
    required this.status,
    required this.itemCount,
    required this.createdAt,
    this.buyerName,
  });

  factory WholesalerOrder.fromJson(Map<String, dynamic> json) {
    final buyer = json['buyer'];
    return WholesalerOrder(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'pending',
      itemCount: (json['itemCount'] as num?)?.toInt() ??
          (json['items'] as List<dynamic>?)?.length ??
          0,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      buyerName: buyer is Map<String, dynamic>
          ? (buyer['fullName'] as String? ?? buyer['name'] as String?)
          : null,
    );
  }

  final String id;
  final double totalAmount;
  final String status;
  final int itemCount;
  final DateTime createdAt;
  final String? buyerName;
}
