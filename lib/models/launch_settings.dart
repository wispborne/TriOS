import 'package:dart_mappable/dart_mappable.dart';

part 'launch_settings.mapper.dart';

@MappableClass()
class LaunchSettings with LaunchSettingsMappable {
  final bool? isFullscreen;
  final bool? hasSound;
  final int? resolutionWidth;
  final int? resolutionHeight;
  final int? numAASamples;
  final double? screenScaling;

  const LaunchSettings({
    this.isFullscreen,
    this.hasSound,
    this.resolutionWidth,
    this.resolutionHeight,
    this.numAASamples,
    this.screenScaling,
  });

  /// Overrides the current settings with values from another instance.
  LaunchSettings overrideWith(LaunchSettings? other) {
    return LaunchSettings(
      isFullscreen: other?.isFullscreen ?? isFullscreen,
      hasSound: other?.hasSound ?? hasSound,
      resolutionWidth: other?.resolutionWidth ?? resolutionWidth,
      resolutionHeight: other?.resolutionHeight ?? resolutionHeight,
      numAASamples: other?.numAASamples ?? numAASamples,
      screenScaling: other?.screenScaling ?? screenScaling,
    );
  }
}
