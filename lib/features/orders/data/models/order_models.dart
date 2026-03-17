import '../../../../core/localization/app_localizations.dart';

class OrderItemSummary {
  const OrderItemSummary({
    required this.productId,
    required this.wholesalerId,
    required this.title,
    required this.unit,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
    this.imageUrl,
    this.variantId,
    this.variantSku,
    this.variantAttributes,
    this.itemId,
    this.status,
    this.shipmentId,
  });

  final String productId;
  final String wholesalerId;
  final String title;
  final String unit;
  final int quantity;
  final double unitPrice;
  final double totalAmount;
  final String? imageUrl;
  final String? variantId; // Variant ID if product has variants
  final String? variantSku; // Variant SKU for display
  final Map<String, dynamic>?
      variantAttributes; // Variant attributes for display
  final String? itemId; // Order item ID
  final String? status; // Item status
  final String? shipmentId; // Associated shipment ID

  factory OrderItemSummary.fromJson(Map<String, dynamic> json) {
    // Handle title: can be String (from resolved API) or Map (from create order response)
    String titleString = '';
    final titleValue = json['title'];
    if (titleValue is String) {
      titleString = titleValue;
    } else if (titleValue is Map<String, dynamic>) {
      // If it's a Map, try to get the current language or fallback to 'en'
      // For now, just use 'en' as fallback since we don't have access to current locale here
      // The API should resolve this, but handle it gracefully
      titleString = titleValue['en'] as String? ??
          (titleValue.values.isNotEmpty
              ? titleValue.values.first.toString()
              : null) ??
          'Product';
    } else if (titleValue != null) {
      titleString = titleValue.toString();
    }

    return OrderItemSummary(
      productId: json['productId']?.toString() ?? '',
      wholesalerId: json['wholesalerId']?.toString() ?? '',
      title: titleString,
      unit: json['unit'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      imageUrl: json['imageUrl'] as String?,
      variantId: json['variantId']?.toString() ?? json['variant']?.toString(),
      variantSku: json['variantSku'] as String? ?? json['sku'] as String?,
      variantAttributes: json['variantAttributes'] as Map<String, dynamic>? ??
          json['attributes'] as Map<String, dynamic>?,
      itemId: json['_id']?.toString(),
      status: json['status'] as String?,
      shipmentId: json['shipmentId']?.toString(),
    );
  }
}

enum OrderStatus {
  pendingConfirmation,
  confirmed,
  packing,
  dispatched,
  outForDelivery,
  delivered,
  cancelled,
}

extension OrderStatusName on OrderStatus {
  String get apiName {
    switch (this) {
      case OrderStatus.pendingConfirmation:
        return 'pending_confirmation';
      case OrderStatus.confirmed:
        return 'confirmed';
      case OrderStatus.packing:
        return 'packing';
      case OrderStatus.dispatched:
        return 'dispatched';
      case OrderStatus.outForDelivery:
        return 'out_for_delivery';
      case OrderStatus.delivered:
        return 'delivered';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }

  String get label {
    switch (this) {
      case OrderStatus.pendingConfirmation:
        return 'Pending confirmation';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.packing:
        return 'Packing';
      case OrderStatus.dispatched:
        return 'Dispatched';
      case OrderStatus.outForDelivery:
        return 'Out for delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Localized display name for UI. Use this instead of [label] for user-facing text.
  String localizedLabel(AppLocalizations l10n) {
    switch (this) {
      case OrderStatus.pendingConfirmation:
        return l10n.translate('orderStatusPendingConfirmation');
      case OrderStatus.confirmed:
        return l10n.translate('orderStatusConfirmed');
      case OrderStatus.packing:
        return l10n.translate('orderStatusPacking');
      case OrderStatus.dispatched:
        return l10n.translate('orderStatusDispatched');
      case OrderStatus.outForDelivery:
        return l10n.translate('orderStatusOutForDelivery');
      case OrderStatus.delivered:
        return l10n.translate('orderStatusDelivered');
      case OrderStatus.cancelled:
        return l10n.translate('orderStatusCancelled');
    }
  }
}

/// Maps raw backend order status string to localized display text.
/// Use for RecentOrder.status, OrderStatusHistoryEntry.status, or any String status from API.
String localizedOrderStatus(String? rawStatus, AppLocalizations l10n) {
  if (rawStatus == null || rawStatus.isEmpty) {
    return l10n.translate('orderStatusPendingConfirmation');
  }
  final s = rawStatus.toLowerCase().replaceAll('-', '_');
  switch (s) {
    case 'pending':
    case 'pending_confirmation':
      return l10n.translate('orderStatusPendingConfirmation');
    case 'confirmed':
      return l10n.translate('orderStatusConfirmed');
    case 'packing':
      return l10n.translate('orderStatusPacking');
    case 'dispatched':
      return l10n.translate('orderStatusDispatched');
    case 'out_for_delivery':
      return l10n.translate('orderStatusOutForDelivery');
    case 'delivered':
      return l10n.translate('orderStatusDelivered');
    case 'cancelled':
    case 'canceled':
      return l10n.translate('orderStatusCancelled');
    case 'returned':
      return l10n.translate('orderStatusReturned');
    case 'refunded':
      return l10n.translate('orderStatusRefunded');
    default:
      return l10n.translate('orderStatusPendingConfirmation');
  }
}

class OrderSummary {
  const OrderSummary({
    required this.id,
    required this.status,
    required this.totalAmount,
    required this.paymentMethod,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
    this.shippingAddress,
    this.shippingCost,
    this.totalAmountWithShipping,
    this.paymentStatus,
    this.paymentTransactionId,
    this.notes,
    this.paymentReportedByBuyerAt,
    this.paymentReportedNotes,
    this.confirmedAt,
    this.shippedAt,
    this.deliveredAt,
    this.cancelledAt,
    this.shipments,
    this.statusHistory,
  });

  final String id;
  final OrderStatus status;
  final double totalAmount;
  final String paymentMethod;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OrderItemSummary> items;
  final ShippingAddress? shippingAddress;
  final double? shippingCost;
  final double? totalAmountWithShipping;
  final String? paymentStatus;
  final String? paymentTransactionId;
  final String? notes;
  final DateTime? paymentReportedByBuyerAt;
  final String? paymentReportedNotes;
  final DateTime? confirmedAt;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final List<Shipment>? shipments;
  final List<OrderStatusHistoryEntry>? statusHistory;

  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    final statusName = json['status'] as String? ?? 'pending_confirmation';
    final status = OrderStatus.values.firstWhere(
      (s) => s.apiName == statusName,
      orElse: () => OrderStatus.pendingConfirmation,
    );

    return OrderSummary(
      id: json['id']?.toString() ?? '',
      status: status,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      paymentMethod: json['paymentMethod'] as String? ?? 'cash_on_delivery',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      items: (json['items'] as List<dynamic>? ?? [])
          .map(
              (item) => OrderItemSummary.fromJson(item as Map<String, dynamic>))
          .toList(),
      shippingAddress: json['shippingAddress'] != null
          ? ShippingAddress.fromJson(
              json['shippingAddress'] as Map<String, dynamic>)
          : null,
      shippingCost: (json['shippingCost'] as num?)?.toDouble(),
      totalAmountWithShipping:
          (json['totalAmountWithShipping'] as num?)?.toDouble(),
      paymentStatus: json['paymentStatus'] as String?,
      paymentTransactionId: json['paymentTransactionId'] as String?,
      notes: json['notes'] as String?,
      paymentReportedByBuyerAt: json['paymentReportedByBuyerAt'] != null
          ? DateTime.tryParse(json['paymentReportedByBuyerAt'] as String)
          : null,
      paymentReportedNotes: json['paymentReportedNotes'] as String?,
      confirmedAt: json['confirmedAt'] != null
          ? DateTime.tryParse(json['confirmedAt'] as String)
          : null,
      shippedAt: json['shippedAt'] != null
          ? DateTime.tryParse(json['shippedAt'] as String)
          : null,
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.tryParse(json['deliveredAt'] as String)
          : null,
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.tryParse(json['cancelledAt'] as String)
          : null,
      shipments: json['shipments'] != null
          ? (json['shipments'] as List<dynamic>)
              .map((s) => Shipment.fromJson(s as Map<String, dynamic>))
              .toList()
          : null,
      statusHistory: json['statusHistory'] != null
          ? (json['statusHistory'] as List<dynamic>)
              .map((h) =>
                  OrderStatusHistoryEntry.fromJson(h as Map<String, dynamic>))
              .toList()
          : null,
    );
  }
}

class ShippingAddress {
  const ShippingAddress({
    required this.name,
    required this.phone,
    required this.address,
    required this.city,
    required this.country,
    required this.pincode,
    this.state,
    this.landmark,
  });

  final String name;
  final String phone;
  final String address;
  final String city;
  final String country;
  final String pincode;
  final String? state;
  final String? landmark;

  factory ShippingAddress.fromJson(Map<String, dynamic> json) =>
      ShippingAddress(
        name: json['name'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        address: json['address'] as String? ?? '',
        city: json['city'] as String? ?? '',
        country: json['country'] as String? ?? '',
        pincode: json['pincode'] as String? ?? '',
        state: json['state'] as String?,
        landmark: json['landmark'] as String?,
      );

  String get fullAddress {
    final parts = <String>[address, city];
    if (state != null) parts.add(state!);
    parts.addAll([country, pincode]);
    return parts.join(', ');
  }
}

enum ShipmentStatus {
  pending,
  packed,
  shipped,
  inTransit,
  outForDelivery,
  delivered,
  failedDelivery,
  returned,
  cancelled,
}

extension ShipmentStatusName on ShipmentStatus {
  String get label {
    switch (this) {
      case ShipmentStatus.pending:
        return 'Pending';
      case ShipmentStatus.packed:
        return 'Packed';
      case ShipmentStatus.shipped:
        return 'Shipped';
      case ShipmentStatus.inTransit:
        return 'In Transit';
      case ShipmentStatus.outForDelivery:
        return 'Out for Delivery';
      case ShipmentStatus.delivered:
        return 'Delivered';
      case ShipmentStatus.failedDelivery:
        return 'Failed Delivery';
      case ShipmentStatus.returned:
        return 'Returned';
      case ShipmentStatus.cancelled:
        return 'Cancelled';
    }
  }
}

// Top-level function to parse shipment status from string
ShipmentStatus shipmentStatusFromString(String? status) {
  switch (status) {
    case 'pending':
      return ShipmentStatus.pending;
    case 'packed':
      return ShipmentStatus.packed;
    case 'shipped':
      return ShipmentStatus.shipped;
    case 'in_transit':
      return ShipmentStatus.inTransit;
    case 'out_for_delivery':
      return ShipmentStatus.outForDelivery;
    case 'delivered':
      return ShipmentStatus.delivered;
    case 'failed_delivery':
      return ShipmentStatus.failedDelivery;
    case 'returned':
      return ShipmentStatus.returned;
    case 'cancelled':
      return ShipmentStatus.cancelled;
    default:
      return ShipmentStatus.pending;
  }
}

class ShipmentItem {
  const ShipmentItem({
    required this.orderItemId,
    required this.quantity,
  });

  final String orderItemId;
  final int quantity;

  factory ShipmentItem.fromJson(Map<String, dynamic> json) => ShipmentItem(
        orderItemId: json['orderItemId']?.toString() ?? '',
        quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      );
}

class Shipment {
  const Shipment({
    required this.id,
    required this.items,
    required this.status,
    required this.createdAt,
    this.trackingNumber,
    this.carrier,
    this.trackingUrl,
    this.packedAt,
    this.shippedAt,
    this.deliveredAt,
    this.estimatedDelivery,
    this.notes,
    this.deliveryNotes,
  });

  final String id;
  final List<ShipmentItem> items;
  final ShipmentStatus status;
  final DateTime createdAt;
  final String? trackingNumber;
  final String? carrier;
  final String? trackingUrl;
  final DateTime? packedAt;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;
  final DateTime? estimatedDelivery;
  final String? notes;
  final String? deliveryNotes;

  factory Shipment.fromJson(Map<String, dynamic> json) => Shipment(
        id: json['_id']?.toString() ?? '',
        items: (json['items'] as List<dynamic>? ?? [])
            .map((item) => ShipmentItem.fromJson(item as Map<String, dynamic>))
            .toList(),
        status: shipmentStatusFromString(json['status'] as String?),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        trackingNumber: json['trackingNumber'] as String?,
        carrier: json['carrier'] as String?,
        trackingUrl: json['trackingUrl'] as String?,
        packedAt: json['packedAt'] != null
            ? DateTime.tryParse(json['packedAt'] as String)
            : null,
        shippedAt: json['shippedAt'] != null
            ? DateTime.tryParse(json['shippedAt'] as String)
            : null,
        deliveredAt: json['deliveredAt'] != null
            ? DateTime.tryParse(json['deliveredAt'] as String)
            : null,
        estimatedDelivery: json['estimatedDelivery'] != null
            ? DateTime.tryParse(json['estimatedDelivery'] as String)
            : null,
        notes: json['notes'] as String?,
        deliveryNotes: json['deliveryNotes'] as String?,
      );
}

class OrderStatusHistoryEntry {
  const OrderStatusHistoryEntry({
    required this.id,
    required this.status,
    required this.changedBy,
    required this.createdAt,
    this.itemId,
    this.reason,
    this.notes,
    this.metadata,
  });

  final String id;
  final String status;
  final UserInfo changedBy;
  final DateTime createdAt;
  final String? itemId;
  final String? reason;
  final String? notes;
  final Map<String, dynamic>? metadata;

  factory OrderStatusHistoryEntry.fromJson(Map<String, dynamic> json) =>
      OrderStatusHistoryEntry(
        id: json['_id']?.toString() ?? '',
        status: json['status'] as String? ?? '',
        changedBy: UserInfo.fromJson(
          json['changedBy'] as Map<String, dynamic>? ?? const {},
        ),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        itemId: json['itemId']?.toString(),
        reason: json['reason'] as String?,
        notes: json['notes'] as String?,
        metadata: json['metadata'] as Map<String, dynamic>?,
      );
}

class UserInfo {
  const UserInfo({
    required this.id,
    required this.fullName,
    this.role,
  });

  final String id;
  final String fullName;
  final String? role;

  factory UserInfo.fromJson(Map<String, dynamic> json) => UserInfo(
        id: json['_id']?.toString() ?? '',
        fullName: json['fullName'] as String? ?? 'Unknown',
        role: json['role'] as String?,
      );
}
