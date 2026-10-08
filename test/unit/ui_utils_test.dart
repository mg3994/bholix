import 'package:flutter_test/flutter_test.dart';
import 'package:bholix/core/utils/ui_utils.dart';

void main() {
  group('UiUtils', () {
    setUp(() {
      UiUtils.clearToastHistory();
    });

    test('showToast records toast message in history', () {
      UiUtils.showToast('Item added to cart', ToastType.success);
      expect(UiUtils.toastHistory.length, 1);
      expect(UiUtils.toastHistory.first.message, 'Item added to cart');
      expect(UiUtils.toastHistory.first.type, ToastType.success);
    });

    test('clearToastHistory empties history', () {
      UiUtils.showToast('Error occurred', ToastType.error);
      expect(UiUtils.toastHistory.length, 1);
      UiUtils.clearToastHistory();
      expect(UiUtils.toastHistory, isEmpty);
    });
  });
}
