import '../../../auth/data/models/auth_models.dart';

class DealProduct {
  const DealProduct({
    required this.id,
    required this.title,
    required this.price,
    this.images,
    this.variantId,
    this.variantAttributes,
    this.variantSku,
    this.variantPrice,
    this.variantImages,
    this.variantStock,
    this.variantAvailableStock,
  });

  factory DealProduct.fromJson(Map<String, dynamic> json) {
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

    final imagesRaw = json['images'] as List<dynamic>?;
    final images = imagesRaw
        ?.map((e) => e is String ? e : (_stringOrMapToString(e) ?? ''))
        .where((s) => s.isNotEmpty)
        .toList();
    final variantSku = _stringOrMapToString(json['variantSku']) ??
        _stringOrMapToString(json['sku']);
    final variantImagesRaw = json['variantImages'] as List<dynamic>? ?? imagesRaw;
    final variantImages = variantImagesRaw
        ?.map((e) => e is String ? e : (_stringOrMapToString(e) ?? ''))
        .where((s) => s.isNotEmpty)
        .toList();

    return DealProduct(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      title: title,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      images: images,
      variantId: json['variantId']?.toString() ?? json['variant']?.toString(),
      variantAttributes: json['variantAttributes'] as Map<String, dynamic>? ??
          json['attributes'] as Map<String, dynamic>?,
      variantSku: variantSku,
      variantPrice: (json['variantPrice'] as num?)?.toDouble() ??
          (json['price'] as num?)?.toDouble(),
      variantImages: variantImages ?? images,
      variantStock: (json['variantStock'] as num?)?.toInt() ??
          (json['stock'] as num?)?.toInt(),
      variantAvailableStock: (json['variantAvailableStock'] as num?)?.toInt() ??
          (json['availableStock'] as num?)?.toInt(),
    );
  }

  final String id;
  final String title;
  final double price;
  final List<String>? images;
  final String? variantId;
  final Map<String, dynamic>? variantAttributes;
  final String? variantSku;
  final double? variantPrice;
  final List<String>? variantImages;
  final int? variantStock;
  final int? variantAvailableStock;

  /// Check if this product has variant information
  bool get hasVariant => variantId != null && variantId!.isNotEmpty;

  /// Get display price (variant price if available, otherwise product price)
  double get displayPrice => variantPrice ?? price;

  /// Get display images (variant images if available, otherwise product images)
  List<String>? get displayImages => variantImages ?? images;

  /// Format variant attributes as a readable string
  String? get variantAttributesString {
    if (variantAttributes == null || variantAttributes!.isEmpty) {
      return null;
    }
    return variantAttributes!.entries
        .map((e) => '${e.key}: ${e.value}')
        .join(', ');
  }
}

/// Parses a value that may be a String or a localized Map (e.g. {en: 'x', ar: 'y'}) to a single String.
/// Used so both public (resolved) and admin (raw maps) API responses parse safely.
String? _stringOrMapToString(dynamic value) {
  if (value == null) return null;
  if (value is String) return value.isEmpty ? null : value;
  if (value is Map) {
    final v = value['en']?.toString() ?? value.values.firstOrNull?.toString();
    return (v != null && v.toString().isNotEmpty) ? v : null;
  }
  return value.toString();
}

/// Safe string for parsing; avoids 'Map is not subtype of String' when API sends Map or other types.
String _safeString(dynamic value, [String fallback = '']) {
  if (value == null) return fallback;
  if (value is String) return value;
  if (value is Map) {
    final v = value['en']?.toString() ?? value.values.firstOrNull?.toString();
    return (v != null && v.toString().isNotEmpty) ? v : fallback;
  }
  return value.toString();
}

class DealWholesaler {
  const DealWholesaler({
    required this.id,
    required this.fullName,
    this.businessName,
    this.avatarUrl,
    this.role,
  });

  factory DealWholesaler.fromJson(Map<String, dynamic> json) => DealWholesaler(
        id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
        fullName: _stringOrMapToString(json['fullName']) ?? '',
        businessName: _stringOrMapToString(json['businessName']),
        avatarUrl: _stringOrMapToString(json['avatarUrl']),
        role: _roleFromString(json['role']?.toString()),
      );

  static UserRole? _roleFromString(String? value) {
    if (value == null || value.isEmpty) return null;
    switch (value) {
      case 'admin':
      case 'super_admin':
        return UserRole.admin;
      case 'sub_admin':
        return UserRole.subAdmin;
      case 'wholesaler':
        return UserRole.wholesaler;
      default:
        return null;
    }
  }

  final String id;
  final String fullName;
  final String? businessName;
  final String? avatarUrl;
  /// Deal owner role: admin/sub_admin = admin's own deal (only admin can add bids); wholesaler = wholesaler deal (only kiosk can add bids)
  final UserRole? role;

  /// True if this deal is owned by admin/sub-admin (admin's own product)
  bool get isAdminOwnDeal =>
      role == UserRole.admin || role == UserRole.subAdmin;
}

enum DealType { auction, priceDrop, limitedStock }

DealType dealTypeFromString(String value) {
  return DealType.values.firstWhere(
    (type) => type.name.toLowerCase() == value.toLowerCase(),
    orElse: () => DealType.auction,
  );
}

enum DealStatus { draft, scheduled, live, ended, cancelled }

DealStatus dealStatusFromString(String value) {
  return DealStatus.values.firstWhere(
    (status) => status.name.toLowerCase() == value.toLowerCase(),
    orElse: () => DealStatus.draft,
  );
}

class DealProgress {
  const DealProgress({
    required this.received,
    required this.target,
    required this.percent,
    required this.orderCount,
  });

  factory DealProgress.fromJson(Map<String, dynamic> json) => DealProgress(
        received: (json['received'] as num?)?.toInt() ?? 0,
        target: (json['target'] as num?)?.toInt() ?? 0,
        percent: (json['percent'] as num?)?.toDouble() ?? 0,
        orderCount: (json['orderCount'] as num?)?.toInt() ?? 0,
      );

  final int received;
  final int target;
  final double percent;
  final int orderCount;
}

class Deal {
  const Deal({
    required this.id,
    required this.title,
    required this.type,
    required this.status,
    required this.startAt,
    required this.endAt,
    required this.dealPrice,
    required this.targetQuantity,
    required this.receivedQuantity,
    required this.minOrderQuantity,
    required this.orderCount,
    this.description,
    this.maxOrderQuantity,
    this.product,
    this.wholesaler,
    this.progressPercent = 0,
    this.highlighted = false,
    this.imageUrl,
    this.images,
    this.shippingBaseCost,
    this.shippingFreeThreshold,
    this.shippingPerUnitCost,
    this.shippingInfo,
    this.acceptsReservations = false,
    this.successNotificationSentAt,
    this.allowOnlinePayment = true,
  });

  factory Deal.fromJson(Map<String, dynamic> json) {
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

    // Handle description being either String or Map (multilingual)
    String? description;
    final descriptionRaw = json['description'];
    if (descriptionRaw is Map) {
      // Prioritize 'en', then first available, or null
      final descValue = descriptionRaw['en']?.toString() ??
          descriptionRaw.values.firstOrNull?.toString();
      description = descValue?.isNotEmpty == true ? descValue : null;
    } else if (descriptionRaw != null) {
      description = descriptionRaw.toString();
    }

    return Deal(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      title: title,
      description: description,
      type: dealTypeFromString(_safeString(json['type'], 'auction')),
      status: dealStatusFromString(_safeString(json['status'], 'draft')),
      // Parse dates as UTC and convert to local for display
      startAt: DateTime.tryParse(_safeString(json['startAt']))?.toLocal() ??
          DateTime.now(),
      endAt: DateTime.tryParse(_safeString(json['endAt']))?.toLocal() ??
          DateTime.now(),
      dealPrice: (json['dealPrice'] as num?)?.toDouble() ?? 0,
      targetQuantity: (json['targetQuantity'] as num?)?.toInt() ?? 0,
      receivedQuantity: (json['receivedQuantity'] as num?)?.toInt() ?? 0,
      minOrderQuantity: (json['minOrderQuantity'] as num?)?.toInt() ?? 0,
      maxOrderQuantity: (json['maxOrderQuantity'] as num?)?.toInt(),
      orderCount: (json['orderCount'] as num?)?.toInt() ?? 0,
      progressPercent: (json['progressPercent'] as num?)?.toDouble() ?? 0,
      highlighted: json['highlighted'] as bool? ?? false,
      product: json['product'] != null
          ? DealProduct.fromJson(
              json['product'] as Map<String, dynamic>,
            )
          : null,
      wholesaler: json['wholesaler'] != null
          ? DealWholesaler.fromJson(
              json['wholesaler'] as Map<String, dynamic>,
            )
          : null,
      imageUrl: _stringOrMapToString(json['imageUrl']),
      images:
          (json['images'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      shippingBaseCost: (json['shippingBaseCost'] as num?)?.toDouble(),
      shippingFreeThreshold: (json['shippingFreeThreshold'] as num?)?.toInt(),
      shippingPerUnitCost: (json['shippingPerUnitCost'] as num?)?.toDouble(),
      shippingInfo: json['shippingInfo'] != null
          ? DealShippingInfo.fromJson(
              json['shippingInfo'] as Map<String, dynamic>)
          : null,
      acceptsReservations: json['acceptsReservations'] as bool? ?? false,
      successNotificationSentAt: json['successNotificationSentAt'] != null
          ? DateTime.tryParse(_safeString(json['successNotificationSentAt']))
          : null,
      allowOnlinePayment: json['allowOnlinePayment'] as bool? ?? true,
    );
  }

  final String id;
  final String title;
  final String? description;
  final DealType type;
  final DealStatus status;
  final DateTime startAt;
  final DateTime endAt;
  final double dealPrice;
  final int targetQuantity;
  final int receivedQuantity;
  final int minOrderQuantity;
  final int? maxOrderQuantity;
  final int orderCount;
  final double progressPercent;
  final bool highlighted;
  final DealProduct? product;
  final DealWholesaler? wholesaler;
  final String? imageUrl;
  final List<String>? images;
  final double? shippingBaseCost;
  final int? shippingFreeThreshold;
  final double? shippingPerUnitCost;
  final DealShippingInfo? shippingInfo;
  final bool acceptsReservations;
  final DateTime? successNotificationSentAt;
  final bool allowOnlinePayment;

  bool get isActive => status == DealStatus.live;
  bool get isEnded =>
      status == DealStatus.ended || status == DealStatus.cancelled;

  /// Deal has reached target and participants were notified (for final payment flow)
  bool get hasSucceeded => successNotificationSentAt != null;
  Duration get timeRemaining => endAt.difference(DateTime.now());
  bool get hasLessThanOneHour =>
      timeRemaining.inHours <= 1 && timeRemaining.inSeconds > 0;

  /// Calculate shipping cost for a given quantity
  double calculateShippingCost(int quantity) {
    // If no shipping cost configured, return 0 (free shipping)
    if (shippingBaseCost == null && shippingFreeThreshold == null) {
      return 0;
    }

    // Check if quantity qualifies for free shipping
    if (shippingFreeThreshold != null && quantity >= shippingFreeThreshold!) {
      return 0;
    }

    // Calculate shipping cost
    double cost = shippingBaseCost ?? 0;

    // Add per-unit cost if configured
    final perUnit = shippingPerUnitCost ?? 0;
    cost += perUnit * quantity;

    return cost;
  }

  /// Structured shipping info for localized display.
  /// Use [DealShippingDisplay.format] in UI with l10n.
  DealShippingDisplay? get shippingDisplay {
    if (shippingInfo?.description != null) {
      return DealShippingDisplay.custom(shippingInfo!.description!);
    }

    if (shippingBaseCost == null && shippingFreeThreshold == null) {
      return null;
    }

    final base = shippingBaseCost ?? 0;
    final perUnit = shippingPerUnitCost ?? 0;
    final threshold = shippingFreeThreshold;

    if (threshold != null) {
      if (base > 0 || perUnit > 0) {
        return DealShippingDisplay.withFreeThreshold(
          base: base,
          perUnit: perUnit,
          threshold: threshold,
        );
      } else {
        return DealShippingDisplay.freeForThreshold(threshold: threshold);
      }
    } else if (base > 0 || perUnit > 0) {
      return DealShippingDisplay.baseAndPerUnit(
        base: base,
        perUnit: perUnit,
      );
    }

    return null;
  }

}

/// Structured shipping info for localized display.
/// Call [format] with l10n strings and formatPrice from the UI.
class DealShippingDisplay {
  const DealShippingDisplay._({
    this.customText,
    this.base,
    this.perUnit,
    this.threshold,
    this.formatType,
  });

  /// Custom description from API (display as-is).
  factory DealShippingDisplay.custom(String text) =>
      DealShippingDisplay._(customText: text);

  /// "Shipping: €X (Free for Y+ units)"
  factory DealShippingDisplay.withFreeThreshold({
    required double base,
    required double perUnit,
    required int threshold,
  }) =>
      DealShippingDisplay._(
        base: base,
        perUnit: perUnit,
        threshold: threshold,
        formatType: DealShippingFormatType.withFreeThreshold,
      );

  /// "Free shipping for X+ units"
  factory DealShippingDisplay.freeForThreshold({required int threshold}) =>
      DealShippingDisplay._(
        threshold: threshold,
        formatType: DealShippingFormatType.freeForThreshold,
      );

  /// "Shipping: €X" or "Shipping: €X + €Y per unit"
  factory DealShippingDisplay.baseAndPerUnit({
    required double base,
    required double perUnit,
  }) =>
      DealShippingDisplay._(
        base: base,
        perUnit: perUnit,
        formatType: DealShippingFormatType.baseAndPerUnit,
      );

  final String? customText;
  final double? base;
  final double? perUnit;
  final int? threshold;
  final DealShippingFormatType? formatType;

  /// Format with localized strings. Pass l10n getters and context.formatPriceEurOnly.
  String format({
    required String shippingWithFreeThreshold,
    required String freeShippingForThreshold,
    required String shippingBaseOnly,
    required String shippingWithPerUnit,
    required String Function(double) formatPrice,
  }) {
    if (customText != null) return customText!;
    switch (formatType) {
      case DealShippingFormatType.withFreeThreshold:
        return shippingWithFreeThreshold
            .replaceAll('{amount}', formatPrice(base! + perUnit!))
            .replaceAll('{threshold}', threshold.toString());
      case DealShippingFormatType.freeForThreshold:
        return freeShippingForThreshold
            .replaceAll('{threshold}', threshold.toString());
      case DealShippingFormatType.baseAndPerUnit:
        if (perUnit! > 0) {
          return shippingWithPerUnit
              .replaceAll('{base}', formatPrice(base!))
              .replaceAll('{perUnit}', formatPrice(perUnit!));
        }
        return shippingBaseOnly.replaceAll('{amount}', formatPrice(base!));
      default:
        return customText ?? '';
    }
  }

  /// Fallback when l10n not available (e.g. tests).
  String formatFallback() {
    return format(
      shippingWithFreeThreshold: 'Shipping: {amount} (Free for {threshold}+ units)',
      freeShippingForThreshold: 'Free shipping for {threshold}+ units',
      shippingBaseOnly: 'Shipping: {amount}',
      shippingWithPerUnit: 'Shipping: {base} + {perUnit} per unit',
      formatPrice: (v) => '€${v.toStringAsFixed(2)}',
    );
  }
}

enum DealShippingFormatType {
  withFreeThreshold,
  freeForThreshold,
  baseAndPerUnit,
}

class DealDetail extends Deal {
  const DealDetail({
    required super.id,
    required super.title,
    required super.type,
    required super.status,
    required super.startAt,
    required super.endAt,
    required super.dealPrice,
    required super.targetQuantity,
    required super.receivedQuantity,
    required super.minOrderQuantity,
    required super.orderCount,
    this.progress,
    super.description,
    super.maxOrderQuantity,
    super.product,
    super.wholesaler,
    super.progressPercent,
    super.highlighted,
    super.imageUrl,
    super.images,
    super.shippingBaseCost,
    super.shippingFreeThreshold,
    super.shippingPerUnitCost,
    super.shippingInfo,
    super.acceptsReservations,
    super.successNotificationSentAt,
  });

  factory DealDetail.fromJson(Map<String, dynamic> json) {
    final base = Deal.fromJson(json);
    return DealDetail(
      id: base.id,
      title: base.title,
      type: base.type,
      status: base.status,
      startAt: base.startAt,
      endAt: base.endAt,
      dealPrice: base.dealPrice,
      targetQuantity: base.targetQuantity,
      receivedQuantity: base.receivedQuantity,
      minOrderQuantity: base.minOrderQuantity,
      orderCount: base.orderCount,
      description: base.description,
      maxOrderQuantity: base.maxOrderQuantity,
      product: base.product,
      wholesaler: base.wholesaler,
      progressPercent: base.progressPercent,
      highlighted: base.highlighted,
      imageUrl: base.imageUrl,
      images: base.images,
      progress: json['progress'] != null
          ? DealProgress.fromJson(json['progress'] as Map<String, dynamic>)
          : null,
      shippingBaseCost: base.shippingBaseCost,
      shippingFreeThreshold: base.shippingFreeThreshold,
      shippingPerUnitCost: base.shippingPerUnitCost,
      shippingInfo: base.shippingInfo,
      acceptsReservations: base.acceptsReservations,
      successNotificationSentAt: base.successNotificationSentAt,
    );
  }

  final DealProgress? progress;
}

class DealShippingInfo {
  const DealShippingInfo({
    required this.baseCost,
    this.freeThreshold,
    this.perUnitCost,
    this.description,
  });

  factory DealShippingInfo.fromJson(Map<String, dynamic> json) =>
      DealShippingInfo(
        baseCost: (json['baseCost'] as num?)?.toDouble() ?? 0,
        freeThreshold: (json['freeThreshold'] as num?)?.toInt(),
        perUnitCost: (json['perUnitCost'] as num?)?.toDouble(),
        description: _stringOrMapToString(json['description']),
      );

  final double baseCost;
  final int? freeThreshold;
  final double? perUnitCost;
  final String? description;
}

enum DealOrderStatus {
  pending,
  confirmed,
  shipped,
  delivered,
  cancelled,
  refunded
}

DealOrderStatus dealOrderStatusFromString(String value) {
  return DealOrderStatus.values.firstWhere(
    (status) => status.name.toLowerCase() == value.toLowerCase(),
    orElse: () => DealOrderStatus.pending,
  );
}

class DealOrder {
  const DealOrder({
    required this.id,
    required this.dealId,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
    required this.status,
    this.shippingCost = 0,
    required this.createdAt,
    this.deal,
    this.notes,
    this.trackingNumber,
    this.carrier,
    this.trackingUrl,
    this.shippedAt,
    this.deliveredAt,
    this.confirmedAt,
    this.cancelledAt,
    this.buyer,
    this.paymentMethodAtOrder,
    this.orderType,
    this.paymentStatus,
    this.paymentReportedByBuyerAt,
    this.paymentReportedNotes,
  });

  factory DealOrder.fromJson(Map<String, dynamic> json) => DealOrder(
        id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
        dealId: json['deal']?.toString() ?? json['dealId']?.toString() ?? '',
        quantity: (json['quantity'] as num?)?.toInt() ?? 0,
        unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
        shippingCost: (json['shippingCost'] as num?)?.toDouble() ?? 0,
        totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
        status:
            dealOrderStatusFromString(json['status'] as String? ?? 'pending'),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        deal: json['deal'] is Map<String, dynamic>
            ? Deal.fromJson(json['deal'] as Map<String, dynamic>)
            : null,
        notes: json['notes'] as String?,
        trackingNumber: json['trackingNumber'] as String?,
        carrier: json['carrier'] as String?,
        trackingUrl: json['trackingUrl'] as String?,
        shippedAt: json['shippedAt'] != null
            ? DateTime.tryParse(json['shippedAt'] as String)
            : null,
        deliveredAt: json['deliveredAt'] != null
            ? DateTime.tryParse(json['deliveredAt'] as String)
            : null,
        confirmedAt: json['confirmedAt'] != null
            ? DateTime.tryParse(json['confirmedAt'] as String)
            : null,
        cancelledAt: json['cancelledAt'] != null
            ? DateTime.tryParse(json['cancelledAt'] as String)
            : null,
        buyer: json['buyer'] != null
            ? DealOrderBuyer.fromJson(json['buyer'] as Map<String, dynamic>)
            : null,
        paymentMethodAtOrder: _paymentMethodFromString(json['paymentMethodAtOrder'] as String?),
        orderType: _orderTypeFromString(json['orderType'] as String?),
        paymentStatus: _paymentStatusFromString(json['paymentStatus'] as String?),
        paymentReportedByBuyerAt: json['paymentReportedByBuyerAt'] != null
            ? DateTime.tryParse(json['paymentReportedByBuyerAt'] as String)
            : null,
        paymentReportedNotes: json['paymentReportedNotes'] as String?,
      );

  final String id;
  final String dealId;
  final int quantity;
  final double unitPrice;
  final double shippingCost;
  final double totalAmount;
  final DealOrderStatus status;
  final DateTime createdAt;
  final Deal? deal;
  final String? notes;
  final String? trackingNumber;
  final String? carrier;
  final String? trackingUrl;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;
  final DateTime? confirmedAt;
  final DateTime? cancelledAt;
  final DealOrderBuyer? buyer;
  final String? paymentMethodAtOrder; // 'invoice' | 'card'
  final String? orderType; // 'reservation' | 'commitment'
  final String? paymentStatus; // 'pending' | 'completed' | 'failed'
  final DateTime? paymentReportedByBuyerAt;
  final String? paymentReportedNotes;

  bool get isPaid => paymentStatus == 'completed';
}

String? _paymentMethodFromString(String? v) =>
    (v == 'invoice' || v == 'card') ? v : null;
String? _orderTypeFromString(String? v) =>
    (v == 'reservation' || v == 'commitment') ? v : null;
String? _paymentStatusFromString(String? v) =>
    (v == 'pending' || v == 'completed' || v == 'failed') ? v : null;

class DealOrderBuyer {
  const DealOrderBuyer({
    this.name,
    this.businessName,
    this.email,
  });

  factory DealOrderBuyer.fromJson(Map<String, dynamic> json) =>
      DealOrderBuyer(
        name: _stringOrMapToString(json['name']),
        businessName: _stringOrMapToString(json['businessName']),
        email: json['email'] is String ? json['email'] as String? : null,
      );

  final String? name;
  final String? businessName;
  final String? email;
}

class DealListPage {
  const DealListPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.totalRows,
  });

  factory DealListPage.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as List<dynamic>? ?? [];
    final meta = json['meta'] as Map<String, dynamic>? ?? const {};
    return DealListPage(
      items: data
          .map((item) => Deal.fromJson(item as Map<String, dynamic>))
          .toList(),
      page: meta['page'] as int? ?? 1,
      limit: meta['limit'] as int? ?? 20,
      totalRows: meta['totalRows'] as int? ?? data.length,
    );
  }

  final List<Deal> items;
  final int page;
  final int limit;
  final int totalRows;
}
