import 'package:flutter_test/flutter_test.dart';
import 'package:bholix/core/cart/cart_models.dart';

void main() {
  group('CartModels', () {
    test('CartAddon serialization and pricing', () {
      const addon = CartAddon(name: 'Extra Sauce', price: 20.0, qty: 2);
      final json = addon.toJson();
      final fromJson = CartAddon.fromJson(json);

      expect(fromJson.name, 'Extra Sauce');
      expect(fromJson.price, 20.0);
      expect(fromJson.qty, 2);
    });

    test('OrderItem calculation with addons', () {
      const item = OrderItem(
        postId: 'p1',
        postUrl: 'https://example.com/p1',
        name: 'Burger',
        imageUrl: 'https://example.com/b.jpg',
        price: 150.0,
        priceCurrency: 'INR',
        qty: 2,
        addons: [
          CartAddon(name: 'Cheese', price: 30.0, qty: 1),
          CartAddon(name: 'Fries', price: 50.0, qty: 1),
        ],
      );

      final json = item.toJson();
      final parsed = OrderItem.fromJson(json);

      expect(parsed.name, 'Burger');
      expect(parsed.qty, 2);
      expect(parsed.addons.length, 2);
    });

    test('CartOrder totalPrice calculation', () {
      final order = CartOrder(
        items: [
          const OrderItem(
            postId: 'p1',
            postUrl: 'https://example.com/p1',
            name: 'Item 1',
            imageUrl: '',
            price: 100.0,
            priceCurrency: 'INR',
            qty: 2,
            addons: [
              CartAddon(name: 'Addon 1', price: 10.0, qty: 1),
            ],
          ),
          const OrderItem(
            postId: 'p2',
            postUrl: 'https://example.com/p2',
            name: 'Item 2',
            imageUrl: '',
            price: 200.0,
            priceCurrency: 'INR',
            qty: 1,
          ),
        ],
        priceCurrency: 'INR',
      );

      // Item 1: (100 + 10) * 2 = 220
      // Item 2: 200 * 1 = 200
      // Total: 420.0
      expect(order.totalPrice, 420.0);

      final emptyOrder = CartOrder.empty();
      expect(emptyOrder.totalPrice, 0.0);
      expect(emptyOrder.items, isEmpty);
    });

    test('generateItemKey creates consistent deduplication key', () {
      final key = OrderItem.generateItemKey(
        url: 'https://demo.blogspot.com/2026/10/shoe.html?m=1',
        type: 'Product',
        sku: 'SHOE-01',
        name: 'Running Shoe',
        variants: {'size': '10', 'color': 'red'},
      );

      expect(
        key,
        'https://demo.blogspot.com/2026/10/shoe.html::Product::SHOE-01::Running Shoe::color:red|size:10',
      );
    });

    test('getScaledAddonMax scales by parent quantity and inventory limits', () {
      const parent = OrderItem(
        postId: 'p1',
        postUrl: 'https://example.com/p1',
        name: 'Phone',
        imageUrl: '',
        price: 50000,
        priceCurrency: 'INR',
        qty: 3,
      );

      const addonWithMax = CartAddon(
        name: 'Screen Guard',
        price: 500,
        qty: 1,
        maxValue: 2, // max 2 per phone => max 6 for 3 phones
        inventoryLevel: 5, // only 5 in stock
      );

      expect(parent.getScaledAddonMax(addonWithMax), 5); // clamped to inventoryLevel
    });

    test('CartOrder excludes unavailable and out of stock items from totalPrice', () {
      final order = CartOrder(
        items: [
          const OrderItem(
            postId: 'p1',
            postUrl: '',
            name: 'In Stock Item',
            imageUrl: '',
            price: 100,
            priceCurrency: 'INR',
            qty: 1,
            availability: 'https://schema.org/InStock',
          ),
          const OrderItem(
            postId: 'p2',
            postUrl: '',
            name: 'Out of Stock Item',
            imageUrl: '',
            price: 500,
            priceCurrency: 'INR',
            qty: 1,
            availability: 'https://schema.org/OutOfStock',
          ),
          const OrderItem(
            postId: 'p3',
            postUrl: '',
            name: 'Draft Item',
            imageUrl: '',
            price: 300,
            priceCurrency: 'INR',
            qty: 1,
            isUnavailable: true,
          ),
        ],
        priceCurrency: 'INR',
      );

      expect(order.totalPrice, 100.0);
    });
  });
}
