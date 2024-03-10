import 'package:freezed_annotation/freezed_annotation.dart';

part '../generated/models/launch_settings.freezed.dart';
part '../generated/models/launch_settings.g.dart';

@freezed
class LaunchSettings with _$LaunchSettings {
  const LaunchSettings._();

  const factory LaunchSettings({
    final bool? isFullscreen,
    final bool? hasSound,
    final int? resolutionWidth,
    final int? resolutionHeight,
  }) = _LaunchSettings;

  factory LaunchSettings.fromJson(Map<String, Object?> json) => _$LaunchSettingsFromJson(json);

  LaunchSettings overrideWith(LaunchSettings? other) {
    return LaunchSettings(
      isFullscreen: other?.isFullscreen ?? isFullscreen,
      hasSound: other?.hasSound ?? hasSound,
      resolutionWidth: other?.resolutionWidth ?? resolutionWidth,
      resolutionHeight: other?.resolutionHeight ?? resolutionHeight,
    );
  }
}
