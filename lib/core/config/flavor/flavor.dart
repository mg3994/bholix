import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart' show Color, Locale, ThemeMode, Colors;

part 'flavor_interface.dart';

class Flavor implements FlavorInterface {
  // ignore: unused_element_parameter
  const Flavor._(this.name, [this._customUrl]);

  @override
  final String name;
  final String? _customUrl;

  static String get localhost =>
      (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
      ? '10.0.2.2'
      : 'localhost';

  static const Flavor development = Flavor._('development');
  static const Flavor staging = Flavor._('staging');
  static const Flavor production = Flavor._('production');

  @override
  String get baseUrl {
    const envUrl = String.fromEnvironment('SERVER_URL');
    if (envUrl.isNotEmpty) return envUrl;
    if (_customUrl != null) return _customUrl;
    return 'http://$localhost:8080';
  }

  @override
  Locale get defaultLocale => switch (this) {
    Flavor.development => const Locale('en'), // choose as per your need
    Flavor.staging => const Locale('en'), // choose as per your need
    _ => const Locale('en'), // choose as per your need
  };

  @override
  ThemeMode get defaultThemeMode => switch (this) {
    Flavor.development => ThemeMode.system, // choose as per your need
    Flavor.staging => ThemeMode.system, // choose as per your need
    _ => ThemeMode.system, // choose as per your need
  };

  @override
  Color get defaultThemeSeedColor => switch (this) {
    Flavor.development => Colors.blue, // choose as per your need
    Flavor.staging => Colors.green, // choose as per your need
    _ => Colors.orange, // choose as per your need
  };
}
