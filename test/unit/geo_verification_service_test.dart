import 'package:flutter_test/flutter_test.dart';
import 'package:bholix/core/services/geo_verification_service.dart';
import 'package:bholix/core/schema/geo_filter.dart';

void main() {
  group('GeoVerificationService', () {
    test('validatePostalCode validates 6-digit Indian PIN codes', () {
      final service = GeoVerificationService();
      expect(service.validatePostalCode('110001'), isTrue);
      expect(service.validatePostalCode('11001'), isFalse);
      expect(service.validatePostalCode('abcdef'), isFalse);
    });

    test('validateAddressForm checks street, pin, and city', () {
      final service = GeoVerificationService();
      expect(
        service.validateAddressForm(
          streetAddress: 'Connaught Place',
          postalCode: '110001',
          city: 'New Delhi',
        ),
        isTrue,
      );

      expect(
        service.validateAddressForm(
          streetAddress: '',
          postalCode: '110001',
          city: 'New Delhi',
        ),
        isFalse,
      );
    });

    test('buildDeliverySchema builds valid JSON-LD structure', () {
      final service = GeoVerificationService();
      const loc = LocationData(
        lat: '28.6139',
        lon: '77.2090',
        pin: '110001',
        city: 'New Delhi',
        state: 'Delhi',
        country: 'India',
      );

      final schema = service.buildDeliverySchema(
        location: loc,
        streetAddress: '123 Main St',
      );

      expect(schema['@type'], 'ParcelDelivery');
      expect(schema['deliveryAddress']['postalCode'], '110001');
      expect(schema['deliveryLocation']['geo']['latitude'], '28.6139');
    });
  });
}
