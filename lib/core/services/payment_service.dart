import '../cart/cart_models.dart';
import '../schema/schema_extractor.dart';
import 'apps_script_service.dart';

/// Result of a payment transaction attempt.
class PaymentResult {
  final bool success;
  final String? transactionId;
  final String? message;
  final Map<String, dynamic>? rawResponse;

  const PaymentResult({
    required this.success,
    this.transactionId,
    this.message,
    this.rawResponse,
  });
}

/// Service porting Google Pay, UPI, and Apple Pay payment processing logic
/// from Antinna Engine (GooglePayService.ts).
class PaymentService {
  static const String merchantId = 'BCR2DN5TVPLKL4KZ';
  static const String merchantName = 'Antinna';
  static const String defaultUpiId = 'manishsharma3994@okhdfcbank';

  final AppsScriptService _appsScriptService;

  PaymentService({AppsScriptService? appsScriptService})
      : _appsScriptService = appsScriptService ?? AppsScriptService.getInstance();

  /// Initiates payment flow (UPI / Google Pay / Apple Pay / Card) for the given order.
  /// First records the order in the backend via AppsScriptService, then executes payment.
  Future<PaymentResult> initiatePayment({
    required CartOrder order,
    Map<String, dynamic>? verifiedLocation,
    String? preferredGateway,
  }) async {
    try {
      // 1. Record order in backend via AppsScriptService
      final orderPayload = {
        ...order.toJson(),
        'verifiedLocation': verifiedLocation,
        'merchantId': merchantId,
        'merchantName': merchantName,
      };

      final backendRes = await _appsScriptService.createOrder(orderPayload);
      if (backendRes['status'] != 'success') {
        return PaymentResult(
          success: false,
          message: 'Failed to record order in backend: ${backendRes['message']}',
        );
      }

      final transactionId = backendRes['orderId'] ?? 'TR${DateTime.now().millisecondsSinceEpoch}';

      // 2. Construct UPI / Google Pay / Apple Pay payment metadata matching Antinna engine
      final upiParams = {
        'pa': defaultUpiId,
        'pn': merchantName,
        'tr': transactionId,
        'am': order.totalPrice.toStringAsFixed(2),
        'cu': order.priceCurrency,
        'tn': 'Order from $merchantName',
        'mc': '5251',
      };

      // 3. Return payment intent data and response
      return PaymentResult(
        success: true,
        transactionId: transactionId,
        message: 'Payment intent initialized successfully.',
        rawResponse: {
          'upiParams': upiParams,
          'gateway': preferredGateway ?? 'google_pay_upi',
          'total': order.totalPrice,
          'currency': order.priceCurrency,
          'backendResponse': backendRes,
        },
      );
    } catch (e) {
      return PaymentResult(
        success: false,
        message: 'Payment Exception: $e',
      );
    }
  }

  /// Generates UPI deep link URL for mobile intent launching.
  String generateUpiDeepLink(double amount, String currency, String transactionId) {
    final queryParams = {
      'pa': defaultUpiId,
      'pn': merchantName,
      'tr': transactionId,
      'am': amount.toStringAsFixed(2),
      'cu': currency,
      'tn': 'Order from $merchantName',
      'mc': '5251',
    };
    final queryString = queryParams.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    return 'upi://pay?$queryString';
  }
}
