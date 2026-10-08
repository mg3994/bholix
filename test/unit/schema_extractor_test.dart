import 'dart:ui' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:bholix/core/schema/schema_extractor.dart';

void main() {
  group('SchemaExtractor', () {
    test('getLocalizedValue with plain string and localized map', () {
      expect(SchemaExtractor.getLocalizedValue('Hello', null), 'Hello');

      final localizedList = [
        {'@language': 'es', '@value': 'Hola'},
        {'@language': 'en', '@value': 'Hello'},
      ];
      expect(
        SchemaExtractor.getLocalizedValue(localizedList, const Locale('es')),
        'Hola',
      );
      expect(
        SchemaExtractor.getLocalizedValue(localizedList, const Locale('fr')),
        'Hola', // Fallback to first @value in list
      );
    });

    test('extractName and extractDescription', () {
      final schema = <String, dynamic>{
        'name': 'Wireless Headphones',
        'description': 'Noise cancelling bluetooth headphones',
      };
      expect(SchemaExtractor.extractName(schema), 'Wireless Headphones');
      expect(
        SchemaExtractor.extractDescription(schema),
        'Noise cancelling bluetooth headphones',
      );
    });

    test('extractImage and extractImages', () {
      final schema = <String, dynamic>{
        'image': [
          {'url': 'https://example.com/img1.jpg'},
          'https://example.com/img2.jpg',
        ],
      };
      expect(SchemaExtractor.extractImage(schema), 'https://example.com/img1.jpg');
      expect(SchemaExtractor.extractImages(schema), [
        'https://example.com/img1.jpg',
        'https://example.com/img2.jpg',
      ]);
    });

    test('extractPrice and extractPriceCurrency from offers', () {
      final schema = <String, dynamic>{
        'offers': {
          'price': 1499.0,
          'priceCurrency': 'INR',
          'availability': 'https://schema.org/InStock',
        },
      };
      expect(SchemaExtractor.extractPrice(schema), '1499.0');
      expect(SchemaExtractor.extractPriceCurrency(schema), 'INR');
      expect(
        SchemaExtractor.extractStockLevel(schema),
        'https://schema.org/InStock',
      );
    });

    test('extractVariants and extractAddons', () {
      final schema = <String, dynamic>{
        'hasVariant': [
          {'name': 'Black', 'sku': 'WH-BLK'},
          {'name': 'White', 'sku': 'WH-WHT'},
        ],
        'addOn': [
          {'name': 'Carrying Case', 'price': 299.0},
        ],
      };
      final variants = SchemaExtractor.extractVariants(schema);
      expect(variants.length, 2);
      expect(variants[0]['name'], 'Black');

      final addons = SchemaExtractor.extractAddons(schema);
      expect(addons.length, 1);
      expect(addons[0]['name'], 'Carrying Case');
    });

    test('extractPackages from hasOfferCatalog', () {
      final schema = <String, dynamic>{
        'hasOfferCatalog': [
          {
            'itemListElement': [
              {'name': 'Basic Plan', 'price': 499},
              {'name': 'Pro Plan', 'price': 999},
            ],
          },
        ],
      };
      final packages = SchemaExtractor.extractPackages(schema);
      expect(packages.length, 2);
      expect(packages[0]['name'], 'Basic Plan');
      expect(packages[1]['name'], 'Pro Plan');
    });

    test('extractAreaServed normalises string postal codes to objects', () {
      final schema = <String, dynamic>{
        'areaServed': [
          '560001',
          {'@type': 'City', 'name': 'Bengaluru'},
        ],
      };
      final areas = SchemaExtractor.extractAreaServed(schema);
      expect(areas.length, 2);
      expect(areas[0]['@type'], 'PostalCode');
      expect(areas[0]['postalCode'], '560001');
      expect(areas[1]['@type'], 'City');
      expect(areas[1]['name'], 'Bengaluru');
    });

    test('getArray and normalizeName', () {
      expect(SchemaExtractor.getArray(null), isEmpty);
      expect(SchemaExtractor.getArray('abc'), ['abc']);
      expect(SchemaExtractor.getArray([1, 2]), [1, 2]);

      expect(SchemaExtractor.normalizeName('  Basic Plan  '), 'basic plan');
    });

    test('extractJsonLd unescapes and parses HTML script tag', () {
      const html = '''
        <div>
          <script type="application/ld+json">
            {"@type": "Product", "name": "Test &amp; Product"}
          </script>
        </div>
      ''';
      final json = SchemaExtractor.extractJsonLd(html);
      expect(json, isNotNull);
      expect(json!['@type'], 'Product');
      expect(json['name'], 'Test & Product');
    });

    test('findMatchingVariant scores and returns best variant', () {
      final parent = {
        'hasVariant': [
          {
            'name': 'Red M',
            'additionalProperty': [
              {'name': 'Color', 'value': 'Red'},
              {'name': 'Size', 'value': 'M'},
            ],
          },
          {
            'name': 'Blue L',
            'additionalProperty': [
              {'name': 'Color', 'value': 'Blue'},
              {'name': 'Size', 'value': 'L'},
            ],
          },
        ],
      };
      final match = SchemaExtractor.findMatchingVariant(
        parent,
        {'Color': 'Blue', 'Size': 'L'},
        'Color',
      );
      expect(match, isNotNull);
      expect(match!['name'], 'Blue L');
    });

    test('extractAvailability, extractEligibleQuantity, extractInventoryLevel', () {
      expect(
        SchemaExtractor.extractAvailability({'availability': 'InStock'}),
        'InStock',
      );
      expect(
        SchemaExtractor.extractEligibleQuantity({'eligibleQuantity': {'minValue': 2, 'maxValue': 10}}),
        {'minValue': 2, 'maxValue': 10},
      );
      expect(
        SchemaExtractor.extractInventoryLevel({'inventoryLevel': {'value': 42}}),
        42,
      );
    });

    test('findAllServices and findMatchingServicePackage', () {
      final catalog = {
        'hasOfferCatalog': [
          {
            'name': 'Consulting Package',
            'itemListElement': [
              {'@type': 'Service', 'name': 'SEO Audit'},
              {'@type': 'Service', 'name': 'App Development'},
            ],
          },
        ],
      };
      final services = SchemaExtractor.findAllServices(catalog);
      expect(services.length, 2);
      expect(services[0]['name'], 'SEO Audit');

      final pkg = SchemaExtractor.findMatchingServicePackage(catalog, 'SEO Audit');
      expect(pkg, isNotNull);
      expect(pkg!['name'], 'SEO Audit');
    });

    test('getLocalizedValue with single map object containing @language and @value', () {
      final mapVal = {'@language': 'hi', '@value': 'नमस्ते'};
      expect(SchemaExtractor.getLocalizedValue(mapVal, const Locale('hi')), 'नमस्ते');
      expect(SchemaExtractor.getLocalizedValue(mapVal, const Locale('en')), 'नमस्ते');
    });

    test('getLocalizedValue with defaultLanguage parameter', () {
      final localizedList = [
        {'@language': 'fr', '@value': 'Bonjour'},
        {'@language': 'de', '@value': 'Guten Tag'},
      ];
      expect(
        SchemaExtractor.getLocalizedValue(localizedList, null, 'de'),
        'Guten Tag',
      );
    });

    test('extractAdvanceBookingRequirement', () {
      final offerWithHours = {
        'advanceBookingRequirement': {
          'value': 24,
          'unitCode': 'HUR',
        },
      };
      expect(
        SchemaExtractor.extractAdvanceBookingRequirement(offerWithHours),
        '24 Hours',
      );

      final offerWithDays = {
        'advanceBookingRequirement': {
          'value': 2,
          'unitCode': 'DAY',
        },
      };
      expect(
        SchemaExtractor.extractAdvanceBookingRequirement(offerWithDays),
        '2 Days',
      );

      expect(
        SchemaExtractor.extractAdvanceBookingRequirement({'advanceBookingRequirement': '48 hours'}),
        '48 hours',
      );
    });
  });
}


