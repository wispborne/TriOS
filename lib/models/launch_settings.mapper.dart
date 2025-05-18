// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'launch_settings.dart';

class LaunchSettingsMapper extends ClassMapperBase<LaunchSettings> {
  LaunchSettingsMapper._();

  static LaunchSettingsMapper? _instance;
  static LaunchSettingsMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = LaunchSettingsMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'LaunchSettings';

  static bool? _$isFullscreen(LaunchSettings v) => v.isFullscreen;
  static const Field<LaunchSettings, bool> _f$isFullscreen =
      Field('isFullscreen', _$isFullscreen, opt: true);
  static bool? _$hasSound(LaunchSettings v) => v.hasSound;
  static const Field<LaunchSettings, bool> _f$hasSound =
      Field('hasSound', _$hasSound, opt: true);
  static int? _$resolutionWidth(LaunchSettings v) => v.resolutionWidth;
  static const Field<LaunchSettings, int> _f$resolutionWidth =
      Field('resolutionWidth', _$resolutionWidth, opt: true);
  static int? _$resolutionHeight(LaunchSettings v) => v.resolutionHeight;
  static const Field<LaunchSettings, int> _f$resolutionHeight =
      Field('resolutionHeight', _$resolutionHeight, opt: true);
  static int? _$numAASamples(LaunchSettings v) => v.numAASamples;
  static const Field<LaunchSettings, int> _f$numAASamples =
      Field('numAASamples', _$numAASamples, opt: true);
  static double? _$screenScaling(LaunchSettings v) => v.screenScaling;
  static const Field<LaunchSettings, double> _f$screenScaling =
      Field('screenScaling', _$screenScaling, opt: true);

  @override
  final MappableFields<LaunchSettings> fields = const {
    #isFullscreen: _f$isFullscreen,
    #hasSound: _f$hasSound,
    #resolutionWidth: _f$resolutionWidth,
    #resolutionHeight: _f$resolutionHeight,
    #numAASamples: _f$numAASamples,
    #screenScaling: _f$screenScaling,
  };

  static LaunchSettings _instantiate(DecodingData data) {
    return LaunchSettings(
        isFullscreen: data.dec(_f$isFullscreen),
        hasSound: data.dec(_f$hasSound),
        resolutionWidth: data.dec(_f$resolutionWidth),
        resolutionHeight: data.dec(_f$resolutionHeight),
        numAASamples: data.dec(_f$numAASamples),
        screenScaling: data.dec(_f$screenScaling));
  }

  @override
  final Function instantiate = _instantiate;

  static LaunchSettings fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<LaunchSettings>(map);
  }

  static LaunchSettings fromJson(String json) {
    return ensureInitialized().decodeJson<LaunchSettings>(json);
  }
}

mixin LaunchSettingsMappable {
  String toJson() {
    return LaunchSettingsMapper.ensureInitialized()
        .encodeJson<LaunchSettings>(this as LaunchSettings);
  }

  Map<String, dynamic> toMap() {
    return LaunchSettingsMapper.ensureInitialized()
        .encodeMap<LaunchSettings>(this as LaunchSettings);
  }

  LaunchSettingsCopyWith<LaunchSettings, LaunchSettings, LaunchSettings>
      get copyWith =>
          _LaunchSettingsCopyWithImpl<LaunchSettings, LaunchSettings>(
              this as LaunchSettings, $identity, $identity);
  @override
  String toString() {
    return LaunchSettingsMapper.ensureInitialized()
        .stringifyValue(this as LaunchSettings);
  }

  @override
  bool operator ==(Object other) {
    return LaunchSettingsMapper.ensureInitialized()
        .equalsValue(this as LaunchSettings, other);
  }

  @override
  int get hashCode {
    return LaunchSettingsMapper.ensureInitialized()
        .hashValue(this as LaunchSettings);
  }
}

extension LaunchSettingsValueCopy<$R, $Out>
    on ObjectCopyWith<$R, LaunchSettings, $Out> {
  LaunchSettingsCopyWith<$R, LaunchSettings, $Out> get $asLaunchSettings =>
      $base.as((v, t, t2) => _LaunchSettingsCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class LaunchSettingsCopyWith<$R, $In extends LaunchSettings, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call(
      {bool? isFullscreen,
      bool? hasSound,
      int? resolutionWidth,
      int? resolutionHeight,
      int? numAASamples,
      double? screenScaling});
  LaunchSettingsCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
      Then<$Out2, $R2> t);
}

class _LaunchSettingsCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, LaunchSettings, $Out>
    implements LaunchSettingsCopyWith<$R, LaunchSettings, $Out> {
  _LaunchSettingsCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<LaunchSettings> $mapper =
      LaunchSettingsMapper.ensureInitialized();
  @override
  $R call(
          {Object? isFullscreen = $none,
          Object? hasSound = $none,
          Object? resolutionWidth = $none,
          Object? resolutionHeight = $none,
          Object? numAASamples = $none,
          Object? screenScaling = $none}) =>
      $apply(FieldCopyWithData({
        if (isFullscreen != $none) #isFullscreen: isFullscreen,
        if (hasSound != $none) #hasSound: hasSound,
        if (resolutionWidth != $none) #resolutionWidth: resolutionWidth,
        if (resolutionHeight != $none) #resolutionHeight: resolutionHeight,
        if (numAASamples != $none) #numAASamples: numAASamples,
        if (screenScaling != $none) #screenScaling: screenScaling
      }));
  @override
  LaunchSettings $make(CopyWithData data) => LaunchSettings(
      isFullscreen: data.get(#isFullscreen, or: $value.isFullscreen),
      hasSound: data.get(#hasSound, or: $value.hasSound),
      resolutionWidth: data.get(#resolutionWidth, or: $value.resolutionWidth),
      resolutionHeight:
          data.get(#resolutionHeight, or: $value.resolutionHeight),
      numAASamples: data.get(#numAASamples, or: $value.numAASamples),
      screenScaling: data.get(#screenScaling, or: $value.screenScaling));

  @override
  LaunchSettingsCopyWith<$R2, LaunchSettings, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _LaunchSettingsCopyWithImpl<$R2, $Out2>($value, $cast, t);
}
