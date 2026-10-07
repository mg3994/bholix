import 'package:flutter/material.dart' show Color, Locale, ThemeMode;

import 'build_mode/build_mode_interface.dart';
import 'flavor/flavor.dart' show Flavor, FlavorInterface;

/// Uses primary constructor declaring parameters (`final F flavor`, `final B buildMode`)
/// which implicitly induces instance fields.
final class const FlavorConfig<
  F extends FlavorInterface,
  B extends BuildModeInterface
>({required final F flavor, required final B buildMode}) {
  String get baseUrl => flavor.baseUrl;

  ThemeMode get defaultThemeMode => flavor.defaultThemeMode;
  Locale get defaultLocale => flavor.defaultLocale;
  Color get defaultThemeSeedColor => flavor.defaultThemeSeedColor;
}

/// Explicitly typing the concrete `BuildMode` enum here ensures that
/// `flavorConfig.buildMode` is treated as an exhaustive enum in switch expressions.
typedef AppFlavorConfig = FlavorConfig<Flavor, BuildMode>;

const String appFlavor = String.fromEnvironment(
  'FLUTTER_APP_FLAVOR',
  defaultValue: 'production', // or development as per your need
);

const Flavor currentFlavor = appFlavor == 'dev' || appFlavor == 'development'
    ? Flavor.development
    : appFlavor == 'stg' || appFlavor == 'staging'
    ? Flavor.staging
    : Flavor.production;

/// Flavor Build Config
const AppFlavorConfig currentFBConfig = FlavorConfig(
  flavor: currentFlavor,
  buildMode: BuildMode.current,
);
