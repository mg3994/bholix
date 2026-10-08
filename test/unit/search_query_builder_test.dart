import 'package:flutter_test/flutter_test.dart';
import 'package:bholix/core/schema/geo_filter.dart';
import 'package:bholix/core/services/search_query_builder.dart';

void main() {
  group('SearchQueryBuilder', () {
    test('build creates query string with keywords and labels', () {
      final query = SearchQueryBuilder.build(
        keywords: ['pizza', 'cheese'],
        labels: ['food', 'deals'],
      );

      expect(query, 'pizza cheese label:food label:deals');
    });

    test('build appends postalCode or addressLocality from location', () {
      final queryWithPin = SearchQueryBuilder.build(
        keywords: ['pizza'],
        location: const LocationData(
          lat: '',
          lon: '',
          pin: '560001',
          city: 'Bengaluru',
          state: '',
          country: '',
        ),
      );

      expect(queryWithPin, 'pizza postalCode:560001');

      final queryWithCityOnly = SearchQueryBuilder.build(
        keywords: ['pizza'],
        location: const LocationData(
          lat: '',
          lon: '',
          pin: '',
          city: 'Bengaluru',
          state: '',
          country: '',
        ),
      );

      expect(queryWithCityOnly, 'pizza addressLocality:Bengaluru');
    });

    test('buildFeedUrl forms proper feed Uri', () {
      final url = SearchQueryBuilder.buildFeedUrl(
        blogId: '12345',
        labels: ['electronics', 'deals'],
        keywords: ['phone'],
        maxResults: 10,
        startIndex: 1,
      );

      expect(url, contains('https://www.blogger.com/feeds/12345/posts/default/-/electronics/deals'));
      expect(url, contains('alt=json'));
      expect(url, contains('max-results=10'));
      expect(url, contains('start-index=1'));
      expect(url, contains('q=phone'));
    });
  });
}
