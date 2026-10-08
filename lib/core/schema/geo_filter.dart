/// Simple location data passed to the geo filter.
///
/// NOTE: Once `lib/features/location/location_service.dart` exists this
/// placeholder should be replaced by importing the canonical LocationData from
/// there.  Both classes should have identical field names so callsites need no
/// changes.
class LocationData {
  final String lat;
  final String lon;
  final String pin;
  final String city;
  final String state;
  final String country;

  const LocationData({
    this.lat = '',
    this.lon = '',
    this.pin = '',
    this.city = '',
    this.state = '',
    this.country = '',
  });

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      lat: (json['lat'] as String?) ?? '',
      lon: (json['lon'] as String?) ?? '',
      pin: (json['pin'] as String?) ?? '',
      city: (json['city'] as String?) ?? '',
      state: (json['state'] as String?) ?? '',
      country: (json['country'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lon': lon,
        'pin': pin,
        'city': city,
        'state': state,
        'country': country,
      };
}

/// Filters Schema.org areaServed entries against a user's current location.
class GeoFilter {
  /// Returns true when the product described by [areaServed] can be served to
  /// [location].
  ///
  /// Rules:
  /// - null / empty areaServed → serviceable everywhere → true.
  /// - Country match      → immediately true (country-wide availability).
  /// - PostalCode match   → true.
  /// - City / AdministrativeArea match → true (case-insensitive).
  /// - State match        → true (case-insensitive).
  /// - Plain String entry → treated as a postal code.
  /// - No match after all entries → false.
  static bool isServiceable(dynamic areaServed, LocationData location) {
    if (areaServed == null) return true;

    final List<dynamic> areas =
        areaServed is List ? areaServed : [areaServed];

    if (areas.isEmpty) return true;

    for (final entry in areas) {
      if (entry is String) {
        // Treat bare string as a postal code.
        if (location.pin.isNotEmpty && entry == location.pin) return true;
        continue;
      }

      if (entry is! Map) continue;

      final type = (entry['@type'] as String?) ?? '';
      final name = (entry['name'] as String?) ?? '';
      final postalCode = (entry['postalCode'] as String?) ?? '';

      switch (type) {
        case 'Country':
          if (location.country.isNotEmpty &&
              name.toLowerCase() == location.country.toLowerCase()) {
            // Country-wide: immediately serviceable.
            return true;
          }

        case 'PostalCode':
          if (location.pin.isNotEmpty) {
            final code = postalCode.isNotEmpty ? postalCode : name;
            if (code == location.pin) return true;
          }

        case 'City':
        case 'AdministrativeArea':
          if (location.city.isNotEmpty &&
              name.toLowerCase() == location.city.toLowerCase()) {
            return true;
          }

        case 'State':
          if (location.state.isNotEmpty &&
              name.toLowerCase() == location.state.toLowerCase()) {
            return true;
          }
      }
    }

    return false;
  }
}
