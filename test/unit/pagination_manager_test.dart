import 'package:flutter_test/flutter_test.dart';
import 'package:bholix/core/services/pagination_manager.dart';

void main() {
  group('PaginationManager', () {
    test('initializes with default values', () {
      final pm = PaginationManager(maxResults: 10);
      expect(pm.startIndex, 1);
      expect(pm.hasMore, isTrue);
      expect(pm.isLoading, isFalse);
    });

    test('advances startIndex and detects end of pagination', () {
      final pm = PaginationManager(maxResults: 10);
      pm.advance(10);
      expect(pm.startIndex, 11);
      expect(pm.hasMore, isTrue);

      pm.advance(5); // fetched fewer than maxResults
      expect(pm.hasMore, isFalse);
    });

    test('resets state correctly', () {
      final pm = PaginationManager(maxResults: 10);
      pm.advance(10);
      pm.reset();
      expect(pm.startIndex, 1);
      expect(pm.hasMore, isTrue);
      expect(pm.isLoading, isFalse);
    });
  });
}
