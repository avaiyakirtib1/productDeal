class ManagerStats {
  const ManagerStats({
    required this.totalProducts,
    required this.activeDeals,
    this.closedDeals = 0,
    required this.pendingOrders,
    required this.totalRevenue,
    this.activeShops = 0,
    this.activeMembers = 0,
    this.inactiveMembersCount = 0,
    this.recentOrders = const [],
    this.revenueDetail,
  });

  factory ManagerStats.fromJson(Map<String, dynamic> json) {
    final revenueDetailJson = json['revenueDetail'] as Map<String, dynamic>?;
    return ManagerStats(
      totalProducts: (json['totalProducts'] as num?)?.toInt() ?? 0,
      activeDeals: (json['activeDeals'] as num?)?.toInt() ?? 0,
      closedDeals: (json['closedDeals'] as num?)?.toInt() ?? 0,
      pendingOrders: (json['pendingOrders'] as num?)?.toInt() ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0,
      activeShops: (json['activeShops'] as num?)?.toInt() ?? 0,
      activeMembers: (json['activeMembers'] as num?)?.toInt() ?? 0,
      inactiveMembersCount:
          (json['inactiveMembersCount'] as num?)?.toInt() ?? 0,
      recentOrders: (json['recentOrders'] as List<dynamic>? ?? [])
          .map((item) => RecentOrder.fromJson(item as Map<String, dynamic>))
          .toList(),
      revenueDetail: revenueDetailJson != null
          ? RevenueDetail.fromJson(revenueDetailJson)
          : null,
    );
  }

  final int totalProducts;
  final int activeDeals;
  final int closedDeals;
  final int pendingOrders;
  final double totalRevenue;
  final int activeShops;
  final int activeMembers;
  final int inactiveMembersCount;
  final List<RecentOrder> recentOrders;
  final RevenueDetail? revenueDetail;
}

/// Revenue calculation breakdown for Revenue Detail page.
/// Admin: sees platform cut (1%). Wholesaler: sees full amount.
class RevenueDetail {
  const RevenueDetail({
    required this.productOrdersRevenue,
    required this.dealOrdersRevenue,
    required this.platformCut,
    required this.commissionRate,
    required this.isAdmin,
  });

  factory RevenueDetail.fromJson(Map<String, dynamic> json) {
    return RevenueDetail(
      productOrdersRevenue:
          (json['productOrdersRevenue'] as num?)?.toDouble() ?? 0,
      dealOrdersRevenue: (json['dealOrdersRevenue'] as num?)?.toDouble() ?? 0,
      platformCut: (json['platformCut'] as num?)?.toDouble() ?? 0,
      commissionRate: (json['commissionRate'] as num?)?.toDouble() ?? 0.01,
      isAdmin: json['isAdmin'] as bool? ?? false,
    );
  }

  final double productOrdersRevenue;
  final double dealOrdersRevenue;
  final double platformCut;
  final double commissionRate;
  final bool isAdmin;

  double get totalGross =>
      productOrdersRevenue + dealOrdersRevenue;

  /// Amount shown: admin = platform cut, owner = full gross
  double get displayAmount => isAdmin ? platformCut : totalGross;
}

/// Single order in revenue list (product or deal)
class RevenueOrderItem {
  const RevenueOrderItem({
    required this.id,
    required this.type,
    required this.orderId,
    required this.totalAmount,
    required this.yourAmount,
    required this.buyerName,
    required this.deliveredAt,
    this.dealId,
    this.dealTitle,
    this.itemCount,
  });

  factory RevenueOrderItem.fromJson(Map<String, dynamic> json) {
    return RevenueOrderItem(
      id: json['id']?.toString() ?? '',
      type: json['type'] as String? ?? 'product',
      orderId: json['orderId']?.toString() ?? json['id']?.toString() ?? '',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      yourAmount: (json['yourAmount'] as num?)?.toDouble() ?? 0,
      buyerName: json['buyerName'] as String? ?? 'Unknown',
      deliveredAt: DateTime.tryParse(json['deliveredAt'] as String? ?? '') ??
          DateTime.now(),
      dealId: json['dealId']?.toString(),
      dealTitle: json['dealTitle'] as String?,
      itemCount: (json['itemCount'] as num?)?.toInt(),
    );
  }

  final String id;
  final String type; // 'product' | 'deal'
  final String orderId;
  final double totalAmount;
  final double yourAmount;
  final String buyerName;
  final DateTime deliveredAt;
  final String? dealId;
  final String? dealTitle;
  final int? itemCount;
}

/// Page of revenue orders
class RevenueOrdersPage {
  const RevenueOrdersPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.totalRows,
    required this.totalPages,
  });

  final List<RevenueOrderItem> items;
  final int page;
  final int limit;
  final int totalRows;
  final int totalPages;
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

class ManagerProductsPage {
  const ManagerProductsPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.totalRows,
  });

  factory ManagerProductsPage.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as List<dynamic>? ?? [];
    final meta = json['meta'] as Map<String, dynamic>? ?? const {};
    return ManagerProductsPage(
      items: data
          .map((item) => ManagerProduct.fromJson(item as Map<String, dynamic>))
          .toList(),
      page: meta['page'] as int? ?? 1,
      limit: meta['limit'] as int? ?? 20,
      totalRows: meta['totalRows'] as int? ?? data.length,
    );
  }

  final List<ManagerProduct> items;
  final int page;
  final int limit;
  final int totalRows;
}

class ManagerProduct {
  const ManagerProduct({
    required this.id,
    required this.title,
    required this.price,
    required this.stock,
    required this.status,
    this.imageUrl,
    this.variantCount,
    this.wholesalerId,
  });

  factory ManagerProduct.fromJson(Map<String, dynamic> json) {
    // Handle title being either String or Map (multilingual)
    String title = '';
    final titleRaw = json['title'] ?? json['name'];
    if (titleRaw is Map) {
      // Prioritize 'en', then first available, or empty
      title = titleRaw['en']?.toString() ??
          titleRaw.values.firstOrNull?.toString() ??
          '';
    } else {
      title = titleRaw?.toString() ?? '';
    }

    return ManagerProduct(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      title: title,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'pending',
      imageUrl: json['imageUrl'] as String? ??
          (json['images'] as List<dynamic>?)?.firstOrNull?.toString(),
      variantCount: (json['variantCount'] as num?)?.toInt() ??
          (json['variants'] as List<dynamic>?)?.length,
      wholesalerId: json['wholesalerId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'stock': stock,
      'status': status,
      'imageUrl': imageUrl,
      'variantCount': variantCount,
      if (wholesalerId != null) 'wholesalerId': wholesalerId,
    };
  }

  final String id;
  final String title;
  final double price;
  final int stock;
  final String status;
  final String? imageUrl;
  final int? variantCount;
  final String? wholesalerId;
}

class ManagerDealsPage {
  const ManagerDealsPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.totalRows,
  });

  factory ManagerDealsPage.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as List<dynamic>? ?? [];
    final meta = json['meta'] as Map<String, dynamic>? ?? const {};
    return ManagerDealsPage(
      items: data
          .map((item) => ManagerDeal.fromJson(item as Map<String, dynamic>))
          .toList(),
      page: meta['page'] as int? ?? 1,
      limit: meta['limit'] as int? ?? 20,
      totalRows: meta['totalRows'] as int? ?? data.length,
    );
  }

  final List<ManagerDeal> items;
  final int page;
  final int limit;
  final int totalRows;
}

class ManagerDeal {
  const ManagerDeal({
    required this.id,
    required this.title,
    required this.dealPrice,
    required this.status,
    required this.orderCount,
    required this.receivedQuantity,
    required this.targetQuantity,
    this.progressPercent = 0,
  });

  factory ManagerDeal.fromJson(Map<String, dynamic> json) {
    // Handle title being either String or Map (multilingual)
    String title = '';
    final titleRaw = json['title'];
    if (titleRaw is Map) {
      // Prioritize 'en', then first available, or empty
      title = titleRaw['en']?.toString() ??
          titleRaw.values.firstOrNull?.toString() ??
          '';
    } else {
      title = titleRaw?.toString() ?? '';
    }

    return ManagerDeal(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      title: title,
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

class ManagerOrdersPage {
  const ManagerOrdersPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.totalRows,
  });

  factory ManagerOrdersPage.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as List<dynamic>? ?? [];
    final meta = json['meta'] as Map<String, dynamic>? ?? const {};
    return ManagerOrdersPage(
      items: data
          .map((item) => ManagerOrder.fromJson(item as Map<String, dynamic>))
          .toList(),
      page: meta['page'] as int? ?? 1,
      limit: meta['limit'] as int? ?? 20,
      totalRows: meta['totalRows'] as int? ?? data.length,
    );
  }

  final List<ManagerOrder> items;
  final int page;
  final int limit;
  final int totalRows;
}

class ManagerOrder {
  const ManagerOrder({
    required this.id,
    required this.totalAmount,
    required this.status,
    required this.itemCount,
    required this.createdAt,
    this.buyerName,
    this.paymentStatus,
    this.paymentMethod,
    this.paymentReportedByBuyerAt,
  });

  factory ManagerOrder.fromJson(Map<String, dynamic> json) {
    final buyer = json['buyer'];
    return ManagerOrder(
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
      paymentStatus: json['paymentStatus'] as String? ?? 'pending',
      paymentMethod: json['paymentMethod'] as String? ?? 'cash_on_delivery',
      paymentReportedByBuyerAt: json['paymentReportedByBuyerAt'] != null
          ? DateTime.tryParse(json['paymentReportedByBuyerAt'] as String)
          : null,
    );
  }

  final String id;
  final double totalAmount;
  final String status;
  final int itemCount;
  final DateTime createdAt;
  final String? buyerName;
  final String? paymentStatus;
  final String? paymentMethod;
  final DateTime? paymentReportedByBuyerAt;
}
