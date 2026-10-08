import 'dart:math' as math;

/// Add-on item attached to an [OrderItem] (e.g. extra toppings, accessories, personalization).
class CartAddon {
  final String name;
  final double price;
  final int qty;
  final String? itemKey;
  final int? minValue;
  final int? maxValue;
  final int? inventoryLevel;
  final String? availability;
  final bool isUnavailable;

  const CartAddon({
    required this.name,
    required this.price,
    required this.qty,
    this.itemKey,
    this.minValue,
    this.maxValue,
    this.inventoryLevel,
    this.availability,
    this.isUnavailable = false,
  });

  factory CartAddon.fromJson(Map<String, dynamic> json) {
    return CartAddon(
      name: (json['name'] as String?) ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      qty: (json['qty'] as int?) ?? 1,
      itemKey: json['itemKey'] as String?,
      minValue: (json['minValue'] as num?)?.toInt(),
      maxValue: (json['maxValue'] as num?)?.toInt(),
      inventoryLevel: (json['inventoryLevel'] as num?)?.toInt(),
      availability: json['availability'] as String?,
      isUnavailable: (json['isUnavailable'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'price': price,
        'qty': qty,
        if (itemKey != null) 'itemKey': itemKey,
        if (minValue != null) 'minValue': minValue,
        if (maxValue != null) 'maxValue': maxValue,
        if (inventoryLevel != null) 'inventoryLevel': inventoryLevel,
        if (availability != null) 'availability': availability,
        if (isUnavailable) 'isUnavailable': true,
      };

  CartAddon copyWith({
    String? name,
    double? price,
    int? qty,
    String? itemKey,
    int? minValue,
    int? maxValue,
    int? inventoryLevel,
    String? availability,
    bool? isUnavailable,
  }) {
    return CartAddon(
      name: name ?? this.name,
      price: price ?? this.price,
      qty: qty ?? this.qty,
      itemKey: itemKey ?? this.itemKey,
      minValue: minValue ?? this.minValue,
      maxValue: maxValue ?? this.maxValue,
      inventoryLevel: inventoryLevel ?? this.inventoryLevel,
      availability: availability ?? this.availability,
      isUnavailable: isUnavailable ?? this.isUnavailable,
    );
  }
}

/// A single line item in a cart/order, derived from a Blogger product post.
class OrderItem {
  final String postId;
  final String postUrl;
  final String name;
  final String imageUrl;
  final double price;
  final String priceCurrency;
  final int qty;
  final String? variantId;
  final String? packageId;
  final String? itemKey;
  final int? minValue;
  final int? maxValue;
  final int? inventoryLevel;
  final String? availability;
  final bool isUnavailable;
  final List<CartAddon> addons;

  const OrderItem({
    required this.postId,
    required this.postUrl,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.priceCurrency,
    required this.qty,
    this.variantId,
    this.packageId,
    this.itemKey,
    this.minValue,
    this.maxValue,
    this.inventoryLevel,
    this.availability,
    this.isUnavailable = false,
    this.addons = const [],
  });

  /// True if the item is neither flagged as currently unavailable nor out of stock.
  bool get isOrderable =>
      !isUnavailable &&
      availability != 'https://schema.org/OutOfStock' &&
      availability != 'https://schema.org/SoldOut';

  /// Generates a unique deduplication itemKey matching Antinna TypeScript engine:
  /// `${url}::${type}::${sku}::${name}::${variantString}`
  static String generateItemKey({
    required String url,
    String type = 'Product',
    String sku = '',
    String name = '',
    Map<String, String>? variants,
  }) {
    var cleanUrl = url.split('?')[0].split('#')[0].toLowerCase();
    if (cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }

    var variantString = '';
    if (variants != null && variants.isNotEmpty) {
      final sortedKeys = variants.keys.toList()..sort();
      variantString = sortedKeys.map((k) => '$k:${variants[k]}').join('|');
    }

    return '$cleanUrl::$type::$sku::$name::$variantString';
  }

  /// Calculates dynamically scaled max quantity for a nested add-on based on
  /// parent order quantity and inventory level constraints.
  int? getScaledAddonMax(CartAddon addon) {
    final max = addon.maxValue;
    final inventory = addon.inventoryLevel;
    final scaledMax = max != null ? max * qty : null;

    if (scaledMax != null && inventory != null) {
      return math.min(scaledMax, inventory);
    }
    return scaledMax ?? inventory;
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      postId: (json['postId'] as String?) ?? '',
      postUrl: (json['postUrl'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      imageUrl: (json['imageUrl'] as String?) ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      priceCurrency: (json['priceCurrency'] as String?) ?? 'INR',
      qty: (json['qty'] as int?) ?? 1,
      variantId: json['variantId'] as String?,
      packageId: json['packageId'] as String?,
      itemKey: json['itemKey'] as String?,
      minValue: (json['minValue'] as num?)?.toInt(),
      maxValue: (json['maxValue'] as num?)?.toInt(),
      inventoryLevel: (json['inventoryLevel'] as num?)?.toInt(),
      availability: json['availability'] as String?,
      isUnavailable: (json['isUnavailable'] as bool?) ?? false,
      addons: ((json['addons'] as List?)
              ?.map((a) => CartAddon.fromJson(a as Map<String, dynamic>))
              .toList()) ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'postId': postId,
        'postUrl': postUrl,
        'name': name,
        'imageUrl': imageUrl,
        'price': price,
        'priceCurrency': priceCurrency,
        'qty': qty,
        if (variantId != null) 'variantId': variantId,
        if (packageId != null) 'packageId': packageId,
        if (itemKey != null) 'itemKey': itemKey,
        if (minValue != null) 'minValue': minValue,
        if (maxValue != null) 'maxValue': maxValue,
        if (inventoryLevel != null) 'inventoryLevel': inventoryLevel,
        if (availability != null) 'availability': availability,
        if (isUnavailable) 'isUnavailable': true,
        'addons': addons.map((a) => a.toJson()).toList(),
      };

  OrderItem copyWith({
    String? postId,
    String? postUrl,
    String? name,
    String? imageUrl,
    double? price,
    String? priceCurrency,
    int? qty,
    String? variantId,
    String? packageId,
    String? itemKey,
    int? minValue,
    int? maxValue,
    int? inventoryLevel,
    String? availability,
    bool? isUnavailable,
    List<CartAddon>? addons,
  }) {
    return OrderItem(
      postId: postId ?? this.postId,
      postUrl: postUrl ?? this.postUrl,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      priceCurrency: priceCurrency ?? this.priceCurrency,
      qty: qty ?? this.qty,
      variantId: variantId ?? this.variantId,
      packageId: packageId ?? this.packageId,
      itemKey: itemKey ?? this.itemKey,
      minValue: minValue ?? this.minValue,
      maxValue: maxValue ?? this.maxValue,
      inventoryLevel: inventoryLevel ?? this.inventoryLevel,
      availability: availability ?? this.availability,
      isUnavailable: isUnavailable ?? this.isUnavailable,
      addons: addons ?? this.addons,
    );
  }
}

/// The user's current cart, holding a list of [OrderItem]s.
class CartOrder {
  final List<OrderItem> items;
  final String priceCurrency;

  const CartOrder({
    required this.items,
    required this.priceCurrency,
  });

  factory CartOrder.empty() =>
      const CartOrder(items: [], priceCurrency: 'INR');

  factory CartOrder.fromJson(Map<String, dynamic> json) {
    return CartOrder(
      items: ((json['items'] as List?)
              ?.map((i) => OrderItem.fromJson(i as Map<String, dynamic>))
              .toList()) ??
          [],
      priceCurrency: (json['priceCurrency'] as String?) ?? 'INR',
    );
  }

  Map<String, dynamic> toJson() => {
        'items': items.map((i) => i.toJson()).toList(),
        'priceCurrency': priceCurrency,
      };

  /// Sum of (price + addons total) × qty for every orderable item.
  /// Items marked unavailable or OutOfStock are excluded.
  double get totalPrice {
    return items.where((item) => item.isOrderable).fold(0.0, (sum, item) {
      final addonsTotal = item.addons.where((a) => !a.isUnavailable).fold(
        0.0,
        (s, a) => s + a.price * a.qty,
      );
      return sum + (item.price + addonsTotal) * item.qty;
    });
  }
}
