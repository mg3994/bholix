import 'package:flutter_test/flutter_test.dart';
import 'package:bholix/core/services/apps_script_service.dart';

void main() {
  group('AppsScriptService', () {
    test('singleton instance returns same object', () {
      final s1 = AppsScriptService.getInstance();
      final s2 = AppsScriptService.getInstance();
      expect(identical(s1, s2), isTrue);
    });

    test('dummy response for createOrder when url is placeholder', () async {
      final service = AppsScriptService.getInstance();
      service.setUrl('YOUR_APPS_SCRIPT_URL_HERE');

      final result = await service.createOrder({
        'items': [
          {'postId': '123', 'qty': 1}
        ]
      });

      expect(result['status'], 'success');
      expect(result['orderId'], startsWith('ORDER_'));
      expect(result['received'], isNotNull);
    });

    test('dummy response for getPlaceSuggestions when url is placeholder', () async {
      final service = AppsScriptService.getInstance();
      service.setUrl('YOUR_APPS_SCRIPT_URL_HERE');

      final result = await service.getPlaceSuggestions('New');

      expect(result['status'], 'success');
      expect(result['suggestions'], isA<List>());
    });
  });
}
