part of 'flavor.dart';

sealed class const FlavorInterface() {
  String get name; // Declare name getter for generic constraint
  String get baseUrl;
  ThemeMode get defaultThemeMode;
  Locale get defaultLocale;
  Color get defaultThemeSeedColor;

  // const FlavorInterface();
}
