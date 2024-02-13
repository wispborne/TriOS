// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../settings/settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Settings _$SettingsFromJson(Map<String, dynamic> json) {
  return _Settings.fromJson(json);
}

/// @nodoc
mixin _$Settings {
  String? get gameDir => throw _privateConstructorUsedError;
  String? get modsDir => throw _privateConstructorUsedError;
  List<String>? get enabledModIds => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SettingsCopyWith<Settings> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SettingsCopyWith<$Res> {
  factory $SettingsCopyWith(Settings value, $Res Function(Settings) then) =
      _$SettingsCopyWithImpl<$Res, Settings>;
  @useResult
  $Res call({String? gameDir, String? modsDir, List<String>? enabledModIds});
}

/// @nodoc
class _$SettingsCopyWithImpl<$Res, $Val extends Settings>
    implements $SettingsCopyWith<$Res> {
  _$SettingsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? gameDir = freezed,
    Object? modsDir = freezed,
    Object? enabledModIds = freezed,
  }) {
    return _then(_value.copyWith(
      gameDir: freezed == gameDir
          ? _value.gameDir
          : gameDir // ignore: cast_nullable_to_non_nullable
              as String?,
      modsDir: freezed == modsDir
          ? _value.modsDir
          : modsDir // ignore: cast_nullable_to_non_nullable
              as String?,
      enabledModIds: freezed == enabledModIds
          ? _value.enabledModIds
          : enabledModIds // ignore: cast_nullable_to_non_nullable
              as List<String>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SettingsImplCopyWith<$Res>
    implements $SettingsCopyWith<$Res> {
  factory _$$SettingsImplCopyWith(
          _$SettingsImpl value, $Res Function(_$SettingsImpl) then) =
      __$$SettingsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String? gameDir, String? modsDir, List<String>? enabledModIds});
}

/// @nodoc
class __$$SettingsImplCopyWithImpl<$Res>
    extends _$SettingsCopyWithImpl<$Res, _$SettingsImpl>
    implements _$$SettingsImplCopyWith<$Res> {
  __$$SettingsImplCopyWithImpl(
      _$SettingsImpl _value, $Res Function(_$SettingsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? gameDir = freezed,
    Object? modsDir = freezed,
    Object? enabledModIds = freezed,
  }) {
    return _then(_$SettingsImpl(
      gameDir: freezed == gameDir
          ? _value.gameDir
          : gameDir // ignore: cast_nullable_to_non_nullable
              as String?,
      modsDir: freezed == modsDir
          ? _value.modsDir
          : modsDir // ignore: cast_nullable_to_non_nullable
              as String?,
      enabledModIds: freezed == enabledModIds
          ? _value._enabledModIds
          : enabledModIds // ignore: cast_nullable_to_non_nullable
              as List<String>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SettingsImpl with DiagnosticableTreeMixin implements _Settings {
  _$SettingsImpl(
      {this.gameDir, this.modsDir, final List<String>? enabledModIds})
      : _enabledModIds = enabledModIds;

  factory _$SettingsImpl.fromJson(Map<String, dynamic> json) =>
      _$$SettingsImplFromJson(json);

  @override
  final String? gameDir;
  @override
  final String? modsDir;
  final List<String>? _enabledModIds;
  @override
  List<String>? get enabledModIds {
    final value = _enabledModIds;
    if (value == null) return null;
    if (_enabledModIds is EqualUnmodifiableListView) return _enabledModIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'Settings(gameDir: $gameDir, modsDir: $modsDir, enabledModIds: $enabledModIds)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'Settings'))
      ..add(DiagnosticsProperty('gameDir', gameDir))
      ..add(DiagnosticsProperty('modsDir', modsDir))
      ..add(DiagnosticsProperty('enabledModIds', enabledModIds));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SettingsImpl &&
            (identical(other.gameDir, gameDir) || other.gameDir == gameDir) &&
            (identical(other.modsDir, modsDir) || other.modsDir == modsDir) &&
            const DeepCollectionEquality()
                .equals(other._enabledModIds, _enabledModIds));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, gameDir, modsDir,
      const DeepCollectionEquality().hash(_enabledModIds));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SettingsImplCopyWith<_$SettingsImpl> get copyWith =>
      __$$SettingsImplCopyWithImpl<_$SettingsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SettingsImplToJson(
      this,
    );
  }
}

abstract class _Settings implements Settings {
  factory _Settings(
      {final String? gameDir,
      final String? modsDir,
      final List<String>? enabledModIds}) = _$SettingsImpl;

  factory _Settings.fromJson(Map<String, dynamic> json) =
      _$SettingsImpl.fromJson;

  @override
  String? get gameDir;
  @override
  String? get modsDir;
  @override
  List<String>? get enabledModIds;
  @override
  @JsonKey(ignore: true)
  _$$SettingsImplCopyWith<_$SettingsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
