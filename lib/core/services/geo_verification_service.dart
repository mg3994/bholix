import '../schema/geo_filter.dart';
import 'apps_script_service.dart';
import 'location_service.dart';

/// Service porting Antinna GeoVerificationRenderer & LocationManager logic
/// for coordinate mapping, address typeahead validation, and delivery metrics.
class GeoVerificationService {
  final LocationService _locationService;
  final AppsScriptService _appsScriptService;

  GeoVerificationService({
    LocationService? locationService,
    AppsScriptService? appsScriptService,
  })  : _locationService = locationService ?? LocationService(),
        _appsScriptService = appsScriptService ?? AppsScriptService.getInstance();

  /// Validates an Indian postal PIN code (at least 6 digits).
  bool validatePostalCode(String pin) {
    final clean = pin.trim();
    return RegExp(r'^\d{6}$').hasMatch(clean);
  }

  /// Validates delivery address form fields.
  bool validateAddressForm({
    required String streetAddress,
    required String postalCode,
    required String city,
  }) {
    return streetAddress.trim().isNotEmpty &&
        validatePostalCode(postalCode) &&
        city.trim().isNotEmpty;
  }

  /// Fetches place suggestions from backend Apps Script.
  Future<List<String>> fetchPlaceSuggestions(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final res = await _appsScriptService.getPlaceSuggestions(query);
      if (res['status'] == 'success' && res['suggestions'] is List) {
        return (res['suggestions'] as List)
            .map((s) => s['description']?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// Constructs schema-compliant delivery metadata (ParcelDelivery / PostalAddress / GeoCoordinates).
  Map<String, dynamic> buildDeliverySchema({
    required LocationData location,
    required String streetAddress,
  }) {
    return {
      '@type': 'ParcelDelivery',
      'deliveryAddress': {
        '@type': 'PostalAddress',
        'streetAddress': streetAddress,
        'addressLocality': location.city,
        'addressRegion': location.state,
        'postalCode': location.pin,
        'addressCountry': location.country.isNotEmpty ? location.country : 'IN',
      },
      'deliveryLocation': {
        '@type': 'Place',
        'geo': {
          '@type': 'GeoCoordinates',
          'latitude': location.lat,
          'longitude': location.lon,
        },
      },
    };
  }
}
