/// Add-on item attached to an [OrderItem] (e.g. extra toppings, accessories).
class CartAddon {
  final String name;
  final double price;
  final int qty;

  const CartAddon({
    required this.name,
    required this.price,
    required this.qty,
  });

  factory CartAddon.fromJson(Map<String, dynamic> json) {
    return CartAddon(
      name: (json['name'] as String?) ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      qty: (json['qty'] as int?) ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'price': price,
        'qty': qty,
      };
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
    this.addons = const [],
  });

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
      addons: addons ?? this.addons,
    );
  }
}

/// The user's current cart, holding a list of [OrderItem]s.
///
/// TODO: Drift table integration for cross-session persistence.
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

  /// Sum of (price + addons total) × qty for every item.
  double get totalPrice {
    return items.fold(0.0, (sum, item) {
      final addonsTotal = item.addons.fold(
        0.0,
        (s, a) => s + a.price * a.qty,
      );
      return sum + (item.price + addonsTotal) * item.qty;
    });
  }
}
