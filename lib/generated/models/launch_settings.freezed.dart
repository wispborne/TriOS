// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../models/launch_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

LaunchSettings _$LaunchSettingsFromJson(Map<String, dynamic> json) {
  return _LaunchSettings.fromJson(json);
}

/// @nodoc
mixin _$LaunchSettings {
  bool? get isFullscreen => throw _privateConstructorUsedError;
  bool? get hasSound => throw _privateConstructorUsedError;
  int? get resolutionWidth => throw _privateConstructorUsedError;
  int? get resolutionHeight => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $LaunchSettingsCopyWith<LaunchSettings> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LaunchSettingsCopyWith<$Res> {
  factory $LaunchSettingsCopyWith(
          LaunchSettings value, $Res Function(LaunchSettings) then) =
      _$LaunchSettingsCopyWithImpl<$Res, LaunchSettings>;
  @useResult
  $Res call(
      {bool? isFullscreen,
      bool? hasSound,
      int? resolutionWidth,
      int? resolutionHeight});
}

/// @nodoc
class _$LaunchSettingsCopyWithImpl<$Res, $Val extends LaunchSettings>
    implements $LaunchSettingsCopyWith<$Res> {
  _$LaunchSettingsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isFullscreen = freezed,
    Object? hasSound = freezed,
    Object? resolutionWidth = freezed,
    Object? resolutionHeight = freezed,
  }) {
    return _then(_value.copyWith(
      isFullscreen: freezed == isFullscreen
          ? _value.isFullscreen
          : isFullscreen // ignore: cast_nullable_to_non_nullable
              as bool?,
      hasSound: freezed == hasSound
          ? _value.hasSound
          : hasSound // ignore: cast_nullable_to_non_nullable
              as bool?,
      resolutionWidth: freezed == resolutionWidth
          ? _value.resolutionWidth
          : resolutionWidth // ignore: cast_nullable_to_non_nullable
              as int?,
      resolutionHeight: freezed == resolutionHeight
          ? _value.resolutionHeight
          : resolutionHeight // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LaunchSettingsImplCopyWith<$Res>
    implements $LaunchSettingsCopyWith<$Res> {
  factory _$$LaunchSettingsImplCopyWith(_$LaunchSettingsImpl value,
          $Res Function(_$LaunchSettingsImpl) then) =
      __$$LaunchSettingsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool? isFullscreen,
      bool? hasSound,
      int? resolutionWidth,
      int? resolutionHeight});
}

/// @nodoc
class __$$LaunchSettingsImplCopyWithImpl<$Res>
    extends _$LaunchSettingsCopyWithImpl<$Res, _$LaunchSettingsImpl>
    implements _$$LaunchSettingsImplCopyWith<$Res> {
  __$$LaunchSettingsImplCopyWithImpl(
      _$LaunchSettingsImpl _value, $Res Function(_$LaunchSettingsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isFullscreen = freezed,
    Object? hasSound = freezed,
    Object? resolutionWidth = freezed,
    Object? resolutionHeight = freezed,
  }) {
    return _then(_$LaunchSettingsImpl(
      isFullscreen: freezed == isFullscreen
          ? _value.isFullscreen
          : isFullscreen // ignore: cast_nullable_to_non_nullable
              as bool?,
      hasSound: freezed == hasSound
          ? _value.hasSound
          : hasSound // ignore: cast_nullable_to_non_nullable
              as bool?,
      resolutionWidth: freezed == resolutionWidth
          ? _value.resolutionWidth
          : resolutionWidth // ignore: cast_nullable_to_non_nullable
              as int?,
      resolutionHeight: freezed == resolutionHeight
          ? _value.resolutionHeight
          : resolutionHeight // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LaunchSettingsImpl extends _LaunchSettings {
  const _$LaunchSettingsImpl(
      {this.isFullscreen,
      this.hasSound,
      this.resolutionWidth,
      this.resolutionHeight})
      : super._();

  factory _$LaunchSettingsImpl.fromJson(Map<String, dynamic> json) =>
      _$$LaunchSettingsImplFromJson(json);

  @override
  final bool? isFullscreen;
  @override
  final bool? hasSound;
  @override
  final int? resolutionWidth;
  @override
  final int? resolutionHeight;

  @override
  String toString() {
    return 'LaunchSettings(isFullscreen: $isFullscreen, hasSound: $hasSound, resolutionWidth: $resolutionWidth, resolutionHeight: $resolutionHeight)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LaunchSettingsImpl &&
            (identical(other.isFullscreen, isFullscreen) ||
                other.isFullscreen == isFullscreen) &&
            (identical(other.hasSound, hasSound) ||
                other.hasSound == hasSound) &&
            (identical(other.resolutionWidth, resolutionWidth) ||
                other.resolutionWidth == resolutionWidth) &&
            (identical(other.resolutionHeight, resolutionHeight) ||
                other.resolutionHeight == resolutionHeight));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, isFullscreen, hasSound, resolutionWidth, resolutionHeight);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LaunchSettingsImplCopyWith<_$LaunchSettingsImpl> get copyWith =>
      __$$LaunchSettingsImplCopyWithImpl<_$LaunchSettingsImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LaunchSettingsImplToJson(
      this,
    );
  }
}

abstract class _LaunchSettings extends LaunchSettings {
  const factory _LaunchSettings(
      {final bool? isFullscreen,
      final bool? hasSound,
      final int? resolutionWidth,
      final int? resolutionHeight}) = _$LaunchSettingsImpl;
  const _LaunchSettings._() : super._();

  factory _LaunchSettings.fromJson(Map<String, dynamic> json) =
      _$LaunchSettingsImpl.fromJson;

  @override
  bool? get isFullscreen;
  @override
  bool? get hasSound;
  @override
  int? get resolutionWidth;
  @override
  int? get resolutionHeight;
  @override
  @JsonKey(ignore: true)
  _$$LaunchSettingsImplCopyWith<_$LaunchSettingsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
