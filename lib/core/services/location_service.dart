import 'dart:convert';
import 'dart:io';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';

import '../schema/geo_filter.dart';

// Re-export LocationData so consumers can import it from either location.
export '../schema/geo_filter.dart' show LocationData;

/// Service for acquiring, persisting, and searching geographic locations.
class LocationService {
  static const _fileName = 'antinna_location.json';

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  /// Requests device location permission, obtains the current GPS position,
  /// reverse-geocodes it, and returns a populated [LocationData].
  ///
  /// Returns `null` if permission is denied or an error occurs.
  Future<LocationData?> getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isEmpty) return null;

      final Placemark p = placemarks.first;
      return LocationData(
        lat: position.latitude.toString(),
        lon: position.longitude.toString(),
        pin: p.postalCode ?? '',
        city: p.locality ?? '',
        state: p.administrativeArea ?? '',
        country: p.country ?? '',
      );
    } catch (_) {
      return null;
    }
  }

  /// Persists [loc] to the local documents directory.
  Future<void> saveLocation(LocationData loc) async {
    final file = await _file();
    await file.writeAsString(jsonEncode(loc.toJson()));
  }

  /// Loads a previously saved [LocationData] from disk.
  ///
  /// Returns `null` if no file exists or the file cannot be parsed.
  Future<LocationData?> loadLocation() async {
    try {
      final file = await _file();
      if (!file.existsSync()) return null;
      final raw = await file.readAsString();
      return LocationData.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  /// Searches for locations matching [query] and returns up to 5 results.
  Future<List<LocationData>> searchLocation(String query) async {
    try {
      final List<Location> locations = await locationFromAddress(query);
      final results = <LocationData>[];

      for (final loc in locations.take(5)) {
        try {
          final List<Placemark> placemarks =
              await placemarkFromCoordinates(loc.latitude, loc.longitude);
          if (placemarks.isEmpty) continue;
          final Placemark p = placemarks.first;
          results.add(LocationData(
            lat: loc.latitude.toString(),
            lon: loc.longitude.toString(),
            pin: p.postalCode ?? '',
            city: p.locality ?? '',
            state: p.administrativeArea ?? '',
            country: p.country ?? '',
          ));
        } catch (_) {
          continue;
        }
      }

      return results;
    } catch (_) {
      return [];
    }
  }
}
