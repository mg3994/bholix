import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service mirroring Antinna AppsScriptService for backend order creation
/// and geo/location metrics processing via Google Apps Script web apps.
class AppsScriptService {
  static final AppsScriptService _instance = AppsScriptService._internal();
  factory AppsScriptService() => _instance;
  AppsScriptService._internal();

  static AppsScriptService getInstance() => _instance;

  String _url = 'YOUR_APPS_SCRIPT_URL_HERE';

  void setUrl(String url) {
    _url = url;
  }

  String get url => _url;

  /// Sends a POST request to the Apps Script backend.
  Future<Map<String, dynamic>> callAction(
    String action, {
    Map<String, dynamic>? params,
    Map<String, dynamic>? payload,
    String? authToken,
  }) async {
    if (_url == 'YOUR_APPS_SCRIPT_URL_HERE') {
      return _getDummyResponse(action, payload);
    }

    try {
      final uri = Uri.parse(_url).replace(queryParameters: {
        'action': action,
        ...?params,
      });

      final headers = {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(payload ?? {}),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        return {'status': 'success', 'data': decoded};
      } else {
        return {'status': 'error', 'statusCode': response.statusCode};
      }
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  /// Submits an order payload to the backend.
  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> orderData, {String? authToken}) async {
    return callAction('createOrder', payload: orderData, authToken: authToken);
  }

  /// Fetches place suggestions.
  Future<Map<String, dynamic>> getPlaceSuggestions(String inputToken, {String? authToken}) async {
    return callAction('getPlaceSuggestions', params: {'input': inputToken}, authToken: authToken);
  }

  Map<String, dynamic> _getDummyResponse(String action, Map<String, dynamic>? payload) {
    switch (action) {
      case 'createOrder':
        return {
          'status': 'success',
          'orderId': 'ORDER_${DateTime.now().millisecondsSinceEpoch}',
          'message': 'Dummy order created successfully.',
          'received': payload,
        };
      case 'getPlaceSuggestions':
        return {
          'status': 'success',
          'suggestions': [
            {'description': 'Sample Location 1, City'},
            {'description': 'Sample Location 2, City'},
          ],
        };
      default:
        return {'status': 'success', 'action': action};
    }
  }
}
