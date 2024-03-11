// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../models/mod_info_json.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

EnabledModsJsonMode _$EnabledModsJsonModeFromJson(Map<String, dynamic> json) {
  return _EnabledModsJsonMode.fromJson(json);
}

/// @nodoc
mixin _$EnabledModsJsonMode {
  List<String> get enabledMods => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $EnabledModsJsonModeCopyWith<EnabledModsJsonMode> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EnabledModsJsonModeCopyWith<$Res> {
  factory $EnabledModsJsonModeCopyWith(
          EnabledModsJsonMode value, $Res Function(EnabledModsJsonMode) then) =
      _$EnabledModsJsonModeCopyWithImpl<$Res, EnabledModsJsonMode>;
  @useResult
  $Res call({List<String> enabledMods});
}

/// @nodoc
class _$EnabledModsJsonModeCopyWithImpl<$Res, $Val extends EnabledModsJsonMode>
    implements $EnabledModsJsonModeCopyWith<$Res> {
  _$EnabledModsJsonModeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? enabledMods = null,
  }) {
    return _then(_value.copyWith(
      enabledMods: null == enabledMods
          ? _value.enabledMods
          : enabledMods // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$EnabledModsJsonModeImplCopyWith<$Res>
    implements $EnabledModsJsonModeCopyWith<$Res> {
  factory _$$EnabledModsJsonModeImplCopyWith(_$EnabledModsJsonModeImpl value,
          $Res Function(_$EnabledModsJsonModeImpl) then) =
      __$$EnabledModsJsonModeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<String> enabledMods});
}

/// @nodoc
class __$$EnabledModsJsonModeImplCopyWithImpl<$Res>
    extends _$EnabledModsJsonModeCopyWithImpl<$Res, _$EnabledModsJsonModeImpl>
    implements _$$EnabledModsJsonModeImplCopyWith<$Res> {
  __$$EnabledModsJsonModeImplCopyWithImpl(_$EnabledModsJsonModeImpl _value,
      $Res Function(_$EnabledModsJsonModeImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? enabledMods = null,
  }) {
    return _then(_$EnabledModsJsonModeImpl(
      null == enabledMods
          ? _value._enabledMods
          : enabledMods // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$EnabledModsJsonModeImpl implements _EnabledModsJsonMode {
  const _$EnabledModsJsonModeImpl(final List<String> enabledMods)
      : _enabledMods = enabledMods;

  factory _$EnabledModsJsonModeImpl.fromJson(Map<String, dynamic> json) =>
      _$$EnabledModsJsonModeImplFromJson(json);

  final List<String> _enabledMods;
  @override
  List<String> get enabledMods {
    if (_enabledMods is EqualUnmodifiableListView) return _enabledMods;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_enabledMods);
  }

  @override
  String toString() {
    return 'EnabledModsJsonMode(enabledMods: $enabledMods)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EnabledModsJsonModeImpl &&
            const DeepCollectionEquality()
                .equals(other._enabledMods, _enabledMods));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, const DeepCollectionEquality().hash(_enabledMods));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$EnabledModsJsonModeImplCopyWith<_$EnabledModsJsonModeImpl> get copyWith =>
      __$$EnabledModsJsonModeImplCopyWithImpl<_$EnabledModsJsonModeImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$EnabledModsJsonModeImplToJson(
      this,
    );
  }
}

abstract class _EnabledModsJsonMode implements EnabledModsJsonMode {
  const factory _EnabledModsJsonMode(final List<String> enabledMods) =
      _$EnabledModsJsonModeImpl;

  factory _EnabledModsJsonMode.fromJson(Map<String, dynamic> json) =
      _$EnabledModsJsonModeImpl.fromJson;

  @override
  List<String> get enabledMods;
  @override
  @JsonKey(ignore: true)
  _$$EnabledModsJsonModeImplCopyWith<_$EnabledModsJsonModeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ModInfoJsonModel_091a _$ModInfoJsonModel_091aFromJson(
    Map<String, dynamic> json) {
  return _ModInfoJsonModel_091a.fromJson(json);
}

/// @nodoc
mixin _$ModInfoJsonModel_091a {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get version => throw _privateConstructorUsedError;
  String? get gameVersion => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ModInfoJsonModel_091aCopyWith<ModInfoJsonModel_091a> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ModInfoJsonModel_091aCopyWith<$Res> {
  factory $ModInfoJsonModel_091aCopyWith(ModInfoJsonModel_091a value,
          $Res Function(ModInfoJsonModel_091a) then) =
      _$ModInfoJsonModel_091aCopyWithImpl<$Res, ModInfoJsonModel_091a>;
  @useResult
  $Res call({String id, String name, String version, String? gameVersion});
}

/// @nodoc
class _$ModInfoJsonModel_091aCopyWithImpl<$Res,
        $Val extends ModInfoJsonModel_091a>
    implements $ModInfoJsonModel_091aCopyWith<$Res> {
  _$ModInfoJsonModel_091aCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? version = null,
    Object? gameVersion = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
      gameVersion: freezed == gameVersion
          ? _value.gameVersion
          : gameVersion // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ModInfoJsonModel_091aImplCopyWith<$Res>
    implements $ModInfoJsonModel_091aCopyWith<$Res> {
  factory _$$ModInfoJsonModel_091aImplCopyWith(
          _$ModInfoJsonModel_091aImpl value,
          $Res Function(_$ModInfoJsonModel_091aImpl) then) =
      __$$ModInfoJsonModel_091aImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name, String version, String? gameVersion});
}

/// @nodoc
class __$$ModInfoJsonModel_091aImplCopyWithImpl<$Res>
    extends _$ModInfoJsonModel_091aCopyWithImpl<$Res,
        _$ModInfoJsonModel_091aImpl>
    implements _$$ModInfoJsonModel_091aImplCopyWith<$Res> {
  __$$ModInfoJsonModel_091aImplCopyWithImpl(_$ModInfoJsonModel_091aImpl _value,
      $Res Function(_$ModInfoJsonModel_091aImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? version = null,
    Object? gameVersion = freezed,
  }) {
    return _then(_$ModInfoJsonModel_091aImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
      gameVersion: freezed == gameVersion
          ? _value.gameVersion
          : gameVersion // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ModInfoJsonModel_091aImpl implements _ModInfoJsonModel_091a {
  const _$ModInfoJsonModel_091aImpl(
      {required this.id,
      required this.name,
      required this.version,
      required this.gameVersion});

  factory _$ModInfoJsonModel_091aImpl.fromJson(Map<String, dynamic> json) =>
      _$$ModInfoJsonModel_091aImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String version;
  @override
  final String? gameVersion;

  @override
  String toString() {
    return 'ModInfoJsonModel_091a(id: $id, name: $name, version: $version, gameVersion: $gameVersion)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ModInfoJsonModel_091aImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.gameVersion, gameVersion) ||
                other.gameVersion == gameVersion));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, version, gameVersion);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ModInfoJsonModel_091aImplCopyWith<_$ModInfoJsonModel_091aImpl>
      get copyWith => __$$ModInfoJsonModel_091aImplCopyWithImpl<
          _$ModInfoJsonModel_091aImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ModInfoJsonModel_091aImplToJson(
      this,
    );
  }
}

abstract class _ModInfoJsonModel_091a implements ModInfoJsonModel_091a {
  const factory _ModInfoJsonModel_091a(
      {required final String id,
      required final String name,
      required final String version,
      required final String? gameVersion}) = _$ModInfoJsonModel_091aImpl;

  factory _ModInfoJsonModel_091a.fromJson(Map<String, dynamic> json) =
      _$ModInfoJsonModel_091aImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get version;
  @override
  String? get gameVersion;
  @override
  @JsonKey(ignore: true)
  _$$ModInfoJsonModel_091aImplCopyWith<_$ModInfoJsonModel_091aImpl>
      get copyWith => throw _privateConstructorUsedError;
}

ModInfoJsonModel_095a _$ModInfoJsonModel_095aFromJson(
    Map<String, dynamic> json) {
  return _ModInfoJsonModel_095a.fromJson(json);
}

/// @nodoc
mixin _$ModInfoJsonModel_095a {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  Version_095a get version => throw _privateConstructorUsedError;
  String? get gameVersion => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ModInfoJsonModel_095aCopyWith<ModInfoJsonModel_095a> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ModInfoJsonModel_095aCopyWith<$Res> {
  factory $ModInfoJsonModel_095aCopyWith(ModInfoJsonModel_095a value,
          $Res Function(ModInfoJsonModel_095a) then) =
      _$ModInfoJsonModel_095aCopyWithImpl<$Res, ModInfoJsonModel_095a>;
  @useResult
  $Res call(
      {String id, String name, Version_095a version, String? gameVersion});

  $Version_095aCopyWith<$Res> get version;
}

/// @nodoc
class _$ModInfoJsonModel_095aCopyWithImpl<$Res,
        $Val extends ModInfoJsonModel_095a>
    implements $ModInfoJsonModel_095aCopyWith<$Res> {
  _$ModInfoJsonModel_095aCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? version = null,
    Object? gameVersion = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as Version_095a,
      gameVersion: freezed == gameVersion
          ? _value.gameVersion
          : gameVersion // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $Version_095aCopyWith<$Res> get version {
    return $Version_095aCopyWith<$Res>(_value.version, (value) {
      return _then(_value.copyWith(version: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ModInfoJsonModel_095aImplCopyWith<$Res>
    implements $ModInfoJsonModel_095aCopyWith<$Res> {
  factory _$$ModInfoJsonModel_095aImplCopyWith(
          _$ModInfoJsonModel_095aImpl value,
          $Res Function(_$ModInfoJsonModel_095aImpl) then) =
      __$$ModInfoJsonModel_095aImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id, String name, Version_095a version, String? gameVersion});

  @override
  $Version_095aCopyWith<$Res> get version;
}

/// @nodoc
class __$$ModInfoJsonModel_095aImplCopyWithImpl<$Res>
    extends _$ModInfoJsonModel_095aCopyWithImpl<$Res,
        _$ModInfoJsonModel_095aImpl>
    implements _$$ModInfoJsonModel_095aImplCopyWith<$Res> {
  __$$ModInfoJsonModel_095aImplCopyWithImpl(_$ModInfoJsonModel_095aImpl _value,
      $Res Function(_$ModInfoJsonModel_095aImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? version = null,
    Object? gameVersion = freezed,
  }) {
    return _then(_$ModInfoJsonModel_095aImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as Version_095a,
      gameVersion: freezed == gameVersion
          ? _value.gameVersion
          : gameVersion // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ModInfoJsonModel_095aImpl implements _ModInfoJsonModel_095a {
  const _$ModInfoJsonModel_095aImpl(
      {required this.id,
      required this.name,
      required this.version,
      required this.gameVersion});

  factory _$ModInfoJsonModel_095aImpl.fromJson(Map<String, dynamic> json) =>
      _$$ModInfoJsonModel_095aImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final Version_095a version;
  @override
  final String? gameVersion;

  @override
  String toString() {
    return 'ModInfoJsonModel_095a(id: $id, name: $name, version: $version, gameVersion: $gameVersion)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ModInfoJsonModel_095aImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.gameVersion, gameVersion) ||
                other.gameVersion == gameVersion));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, version, gameVersion);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ModInfoJsonModel_095aImplCopyWith<_$ModInfoJsonModel_095aImpl>
      get copyWith => __$$ModInfoJsonModel_095aImplCopyWithImpl<
          _$ModInfoJsonModel_095aImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ModInfoJsonModel_095aImplToJson(
      this,
    );
  }
}

abstract class _ModInfoJsonModel_095a implements ModInfoJsonModel_095a {
  const factory _ModInfoJsonModel_095a(
      {required final String id,
      required final String name,
      required final Version_095a version,
      required final String? gameVersion}) = _$ModInfoJsonModel_095aImpl;

  factory _ModInfoJsonModel_095a.fromJson(Map<String, dynamic> json) =
      _$ModInfoJsonModel_095aImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  Version_095a get version;
  @override
  String? get gameVersion;
  @override
  @JsonKey(ignore: true)
  _$$ModInfoJsonModel_095aImplCopyWith<_$ModInfoJsonModel_095aImpl>
      get copyWith => throw _privateConstructorUsedError;
}

Version_095a _$Version_095aFromJson(Map<String, dynamic> json) {
  return _Version_095a.fromJson(json);
}

/// @nodoc
mixin _$Version_095a {
  dynamic get major => throw _privateConstructorUsedError;
  dynamic get minor => throw _privateConstructorUsedError;
  dynamic get patch => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $Version_095aCopyWith<Version_095a> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $Version_095aCopyWith<$Res> {
  factory $Version_095aCopyWith(
          Version_095a value, $Res Function(Version_095a) then) =
      _$Version_095aCopyWithImpl<$Res, Version_095a>;
  @useResult
  $Res call({dynamic major, dynamic minor, dynamic patch});
}

/// @nodoc
class _$Version_095aCopyWithImpl<$Res, $Val extends Version_095a>
    implements $Version_095aCopyWith<$Res> {
  _$Version_095aCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? major = freezed,
    Object? minor = freezed,
    Object? patch = freezed,
  }) {
    return _then(_value.copyWith(
      major: freezed == major
          ? _value.major
          : major // ignore: cast_nullable_to_non_nullable
              as dynamic,
      minor: freezed == minor
          ? _value.minor
          : minor // ignore: cast_nullable_to_non_nullable
              as dynamic,
      patch: freezed == patch
          ? _value.patch
          : patch // ignore: cast_nullable_to_non_nullable
              as dynamic,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$Version_095aImplCopyWith<$Res>
    implements $Version_095aCopyWith<$Res> {
  factory _$$Version_095aImplCopyWith(
          _$Version_095aImpl value, $Res Function(_$Version_095aImpl) then) =
      __$$Version_095aImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({dynamic major, dynamic minor, dynamic patch});
}

/// @nodoc
class __$$Version_095aImplCopyWithImpl<$Res>
    extends _$Version_095aCopyWithImpl<$Res, _$Version_095aImpl>
    implements _$$Version_095aImplCopyWith<$Res> {
  __$$Version_095aImplCopyWithImpl(
      _$Version_095aImpl _value, $Res Function(_$Version_095aImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? major = freezed,
    Object? minor = freezed,
    Object? patch = freezed,
  }) {
    return _then(_$Version_095aImpl(
      freezed == major
          ? _value.major
          : major // ignore: cast_nullable_to_non_nullable
              as dynamic,
      freezed == minor
          ? _value.minor
          : minor // ignore: cast_nullable_to_non_nullable
              as dynamic,
      freezed == patch
          ? _value.patch
          : patch // ignore: cast_nullable_to_non_nullable
              as dynamic,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$Version_095aImpl implements _Version_095a {
  const _$Version_095aImpl(this.major, this.minor, this.patch);

  factory _$Version_095aImpl.fromJson(Map<String, dynamic> json) =>
      _$$Version_095aImplFromJson(json);

  @override
  final dynamic major;
  @override
  final dynamic minor;
  @override
  final dynamic patch;

  @override
  String toString() {
    return 'Version_095a(major: $major, minor: $minor, patch: $patch)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$Version_095aImpl &&
            const DeepCollectionEquality().equals(other.major, major) &&
            const DeepCollectionEquality().equals(other.minor, minor) &&
            const DeepCollectionEquality().equals(other.patch, patch));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(major),
      const DeepCollectionEquality().hash(minor),
      const DeepCollectionEquality().hash(patch));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$Version_095aImplCopyWith<_$Version_095aImpl> get copyWith =>
      __$$Version_095aImplCopyWithImpl<_$Version_095aImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$Version_095aImplToJson(
      this,
    );
  }
}

abstract class _Version_095a implements Version_095a {
  const factory _Version_095a(
          final dynamic major, final dynamic minor, final dynamic patch) =
      _$Version_095aImpl;

  factory _Version_095a.fromJson(Map<String, dynamic> json) =
      _$Version_095aImpl.fromJson;

  @override
  dynamic get major;
  @override
  dynamic get minor;
  @override
  dynamic get patch;
  @override
  @JsonKey(ignore: true)
  _$$Version_095aImplCopyWith<_$Version_095aImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
