import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dashboard/data/models/dashboard_models.dart';

// Import ProductVariant if not already imported

class CartItem {
  const CartItem({
    required this.productId,
    required this.title,
    required this.unit,
    required this.price,
    required this.imageUrl,
    required this.wholesalerId,
    required this.wholesalerName,
    required this.quantity,
    this.variantId,
    this.variantSku,
    this.variantAttributes,
  });

  final String productId;
  final String title;
  final String unit;
  final double price;
  final String imageUrl;
  final String? wholesalerId;
  final String? wholesalerName;
  final int quantity;
  final String? variantId; // Variant ID if product has variants
  final String? variantSku; // Variant SKU for display
  final Map<String, dynamic>?
      variantAttributes; // Variant attributes for display

  double get lineTotal => price * quantity;

  // Unique key for cart items (productId + variantId if variant exists)
  String get cartKey => variantId != null ? '$productId:$variantId' : productId;

  CartItem copyWith({
    int? quantity,
  }) {
    return CartItem(
      productId: productId,
      title: title,
      unit: unit,
      price: price,
      imageUrl: imageUrl,
      wholesalerId: wholesalerId,
      wholesalerName: wholesalerName,
      quantity: quantity ?? this.quantity,
      variantId: variantId,
      variantSku: variantSku,
      variantAttributes: variantAttributes,
    );
  }
}

class CartState {
  const CartState(this.items);

  final UnmodifiableMapView<String, CartItem>
      items; // Key is cartKey (productId:variantId or productId)

  int get totalItems =>
      items.values.fold(0, (sum, item) => sum + item.quantity);

  double get totalAmount =>
      items.values.fold(0, (sum, item) => sum + item.lineTotal);
}

class CartController extends StateNotifier<CartState> {
  CartController()
      : super(
          CartState(UnmodifiableMapView({})),
        );

  void addProduct(ProductDetail product,
      {int quantity = 1, String? variantId}) {
    final current = Map<String, CartItem>.from(state.items);

    // Use variant if provided, otherwise use default variant
    ProductVariant? selectedVariant;
    if (variantId != null && product.variants != null) {
      selectedVariant = product.variants!.firstWhere(
        (v) => v.id == variantId,
        orElse: () => product.defaultVariant ?? product.variants!.first,
      );
    } else {
      selectedVariant = product.defaultVariant;
    }

    final cartKey = selectedVariant != null
        ? '${product.id}:${selectedVariant.id}'
        : product.id;

    final existing = current[cartKey];
    final newQuantity = (existing?.quantity ?? 0) + quantity;

    final price = selectedVariant?.price ?? product.displayPrice;
    final imageUrl = selectedVariant?.images?.isNotEmpty == true
        ? selectedVariant!.images!.first
        : product.imageUrl;

    current[cartKey] = CartItem(
      productId: product.id,
      title: product.title,
      unit: product.unit,
      price: price,
      imageUrl: imageUrl,
      wholesalerId: product.wholesaler?.id,
      wholesalerName: product.wholesaler?.businessName,
      quantity: newQuantity.clamp(1, 999),
      variantId: selectedVariant?.id,
      variantSku: selectedVariant?.sku,
      variantAttributes: selectedVariant?.attributes,
    );

    state = CartState(UnmodifiableMapView(current));
  }

  void addDashboardProduct(DashboardProduct product,
      {int quantity = 1, String? variantId}) {
    final current = Map<String, CartItem>.from(state.items);

    // Use variant if provided, otherwise use default variant or first variant
    ProductVariant? selectedVariant;
    if (variantId != null && product.variants != null) {
      selectedVariant = product.variants!.firstWhere(
        (v) => v.id == variantId,
        orElse: () => product.defaultVariant ?? product.variants!.first,
      );
    } else if (product.variants != null && product.variants!.isNotEmpty) {
      // If product has variants but no variantId provided, select first variant
      selectedVariant = product.defaultVariant ?? product.variants!.first;
    } else {
      selectedVariant = null;
    }

    final cartKey = selectedVariant != null
        ? '${product.id}:${selectedVariant.id}'
        : product.id;

    final existing = current[cartKey];
    final newQuantity = (existing?.quantity ?? 0) + quantity;

    final price = selectedVariant?.price ?? product.displayPrice;
    final imageUrl = selectedVariant?.images?.isNotEmpty == true
        ? selectedVariant!.images!.first
        : product.imageUrl;

    current[cartKey] = CartItem(
      productId: product.id,
      title: product.title,
      unit: product.unit,
      price: price,
      imageUrl: imageUrl,
      wholesalerId: null,
      wholesalerName: product.wholesalerName,
      quantity: newQuantity.clamp(1, 999),
      variantId: selectedVariant?.id,
      variantSku: selectedVariant?.sku,
      variantAttributes: selectedVariant?.attributes,
    );

    state = CartState(UnmodifiableMapView(current));
  }

  void updateQuantity(String cartKey, int quantity) {
    final current = Map<String, CartItem>.from(state.items);
    final existing = current[cartKey];
    if (existing == null) return;
    if (quantity <= 0) {
      current.remove(cartKey);
    } else {
      current[cartKey] = existing.copyWith(quantity: quantity.clamp(1, 999));
    }
    state = CartState(UnmodifiableMapView(current));
  }

  void removeProduct(String cartKey) {
    final current = Map<String, CartItem>.from(state.items);
    current.remove(cartKey);
    state = CartState(UnmodifiableMapView(current));
  }

  void clear() {
    state = CartState(UnmodifiableMapView({}));
  }
}

final cartControllerProvider = StateNotifierProvider<CartController, CartState>(
  (ref) => CartController(),
  name: 'CartControllerProvider',
);
