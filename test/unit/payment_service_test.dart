import 'package:flutter_test/flutter_test.dart';
import 'package:bholix/core/cart/cart_models.dart';
import 'package:bholix/core/services/payment_service.dart';
import 'package:bholix/core/services/apps_script_service.dart';

void main() {
  group('PaymentService', () {
    test('initiatePayment records order and returns UPI intent parameters', () async {
      final paymentService = PaymentService();
      final order = CartOrder(
        items: [
          const OrderItem(
            postId: 'test-post-1',
            postUrl: 'https://example.com/item1',
            name: 'Test Product',
            imageUrl: 'https://example.com/img.jpg',
            price: 250.0,
            priceCurrency: 'INR',
            qty: 2,
          ),
        ],
        priceCurrency: 'INR',
      );

      final result = await paymentService.initiatePayment(
        order: order,
        verifiedLocation: {'city': 'New Delhi', 'pin': '110001'},
      );

      expect(result.success, isTrue);
      expect(result.transactionId, isNotNull);
      expect(result.rawResponse, isNotNull);
      expect(result.rawResponse!['total'], 500.0);
      expect(result.rawResponse!['upiParams']['pa'], PaymentService.defaultUpiId);
    });

    test('generateUpiDeepLink produces correct upi:// schema URL', () {
      final paymentService = PaymentService();
      final deepLink = paymentService.generateUpiDeepLink(500.0, 'INR', 'TR12345');

      expect(deepLink, startsWith('upi://pay?'));
      expect(deepLink, contains('pa=manishsharma3994%40okhdfcbank'));
      expect(deepLink, contains('am=500.00'));
      expect(deepLink, contains('tr=TR12345'));
    });
  });
}
