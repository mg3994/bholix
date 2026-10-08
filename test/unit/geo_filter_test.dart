import 'package:flutter_test/flutter_test.dart';
import 'package:bholix/core/schema/geo_filter.dart';

void main() {
  group('GeoFilter.isServiceable', () {
    const loc = LocationData(
      lat: '12.9716',
      lon: '77.5946',
      pin: '560001',
      city: 'Bengaluru',
      state: 'Karnataka',
      country: 'India',
    );

    test('returns true when areaServed is null or empty', () {
      expect(GeoFilter.isServiceable(null, loc), isTrue);
      expect(GeoFilter.isServiceable([], loc), isTrue);
    });

    test('matches country', () {
      final area = [
        {'@type': 'Country', 'name': 'India'},
      ];
      expect(GeoFilter.isServiceable(area, loc), isTrue);

      final otherArea = [
        {'@type': 'Country', 'name': 'Canada'},
      ];
      expect(GeoFilter.isServiceable(otherArea, loc), isFalse);
    });

    test('matches postalCode or string PIN', () {
      expect(GeoFilter.isServiceable(['560001'], loc), isTrue);
      expect(
        GeoFilter.isServiceable([
          {'@type': 'PostalCode', 'postalCode': '560001'}
        ], loc),
        isTrue,
      );
      expect(GeoFilter.isServiceable(['110001'], loc), isFalse);
    });

    test('matches city case-insensitively', () {
      expect(
        GeoFilter.isServiceable([
          {'@type': 'City', 'name': 'bengaluru'}
        ], loc),
        isTrue,
      );
      expect(
        GeoFilter.isServiceable([
          {'@type': 'City', 'name': 'Mumbai'}
        ], loc),
        isFalse,
      );
    });

    test('matches state', () {
      expect(
        GeoFilter.isServiceable([
          {'@type': 'State', 'name': 'Karnataka'}
        ], loc),
        isTrue,
      );
    });
  });
}
