import 'package:flutter_test/flutter_test.dart';
import 'package:bholix/core/services/blogger_service.dart';

void main() {
  group('BloggerDataService Graph & @id Merging', () {
    test('toGraphDocument deduplicates and deep-merges nodes with the same @id', () {
      final service = BloggerDataService();

      final node1 = <String, dynamic>{
        '@id': 'product-1',
        '@type': 'Product',
        'name': 'Base Product',
        'offers': {'price': 100},
      };

      final node2 = <String, dynamic>{
        '@id': 'product-1',
        '@type': 'Product',
        'description': 'Merged Description',
        'offers': {'priceCurrency': 'INR'},
      };

      final graphDoc = service.toGraphDocument([node1, node2]);

      expect(graphDoc['@graph'], isA<List>());
      final graph = graphDoc['@graph'] as List;
      expect(graph.length, 1);

      final mergedNode = graph.first as Map<String, dynamic>;
      expect(mergedNode['@id'], 'product-1');
      expect(mergedNode['name'], 'Base Product');
      expect(mergedNode['description'], 'Merged Description');
      // Offers should be deep-merged: price from node1, priceCurrency from node2
      expect(mergedNode['offers'], {'price': 100, 'priceCurrency': 'INR'});
    });
  });
}
