import 'package:flutter_test/flutter_test.dart';
import 'package:bholix/core/wishlist/wishlist_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WishlistRepository', () {
    test('instantiates successfully', () {
      final repo = WishlistRepository();
      expect(repo, isNotNull);
    });
  });
}
