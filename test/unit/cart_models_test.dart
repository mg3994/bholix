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
  });
}
