part of 'build_mode_interface.dart';

/// Enums are implicitly constant and can implement interface classes.
enum BuildMode() implements BuildModeInterface {
  debug,
  profile,
  release;

  static const BuildMode current =
      kProfileMode //bool.fromEnvironment('dart.vm.profile')
      ? BuildMode.profile
      : kReleaseMode //bool.fromEnvironment('dart.vm.product')
      ? BuildMode.release
      : BuildMode.debug;
}
