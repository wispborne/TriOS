// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../models/mod_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ModInfo _$ModInfoFromJson(Map<String, dynamic> json) {
  return _ModInfo.fromJson(json);
}

/// @nodoc
mixin _$ModInfo {
  String get id => throw _privateConstructorUsedError;
  String? get name => throw _privateConstructorUsedError;
  @JsonConverterVersionNullable()
  Version? get version => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String? get gameVersion => throw _privateConstructorUsedError;
  String? get author => throw _privateConstructorUsedError;
  List<Dependency> get dependencies => throw _privateConstructorUsedError;
  String? get originalGameVersion => throw _privateConstructorUsedError;
  @JsonConverterBool()
  bool get isUtility => throw _privateConstructorUsedError;
  @JsonConverterBool()
  bool get isTotalConversion => throw _privateConstructorUsedError;

  /// Serializes this ModInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ModInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ModInfoCopyWith<ModInfo> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ModInfoCopyWith<$Res> {
  factory $ModInfoCopyWith(ModInfo value, $Res Function(ModInfo) then) =
      _$ModInfoCopyWithImpl<$Res, ModInfo>;
  @useResult
  $Res call(
      {String id,
      String? name,
      @JsonConverterVersionNullable() Version? version,
      String? description,
      String? gameVersion,
      String? author,
      List<Dependency> dependencies,
      String? originalGameVersion,
      @JsonConverterBool() bool isUtility,
      @JsonConverterBool() bool isTotalConversion});
}

/// @nodoc
class _$ModInfoCopyWithImpl<$Res, $Val extends ModInfo>
    implements $ModInfoCopyWith<$Res> {
  _$ModInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ModInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = freezed,
    Object? version = freezed,
    Object? description = freezed,
    Object? gameVersion = freezed,
    Object? author = freezed,
    Object? dependencies = null,
    Object? originalGameVersion = freezed,
    Object? isUtility = null,
    Object? isTotalConversion = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      version: freezed == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as Version?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      gameVersion: freezed == gameVersion
          ? _value.gameVersion
          : gameVersion // ignore: cast_nullable_to_non_nullable
              as String?,
      author: freezed == author
          ? _value.author
          : author // ignore: cast_nullable_to_non_nullable
              as String?,
      dependencies: null == dependencies
          ? _value.dependencies
          : dependencies // ignore: cast_nullable_to_non_nullable
              as List<Dependency>,
      originalGameVersion: freezed == originalGameVersion
          ? _value.originalGameVersion
          : originalGameVersion // ignore: cast_nullable_to_non_nullable
              as String?,
      isUtility: null == isUtility
          ? _value.isUtility
          : isUtility // ignore: cast_nullable_to_non_nullable
              as bool,
      isTotalConversion: null == isTotalConversion
          ? _value.isTotalConversion
          : isTotalConversion // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ModInfoImplCopyWith<$Res> implements $ModInfoCopyWith<$Res> {
  factory _$$ModInfoImplCopyWith(
          _$ModInfoImpl value, $Res Function(_$ModInfoImpl) then) =
      __$$ModInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String? name,
      @JsonConverterVersionNullable() Version? version,
      String? description,
      String? gameVersion,
      String? author,
      List<Dependency> dependencies,
      String? originalGameVersion,
      @JsonConverterBool() bool isUtility,
      @JsonConverterBool() bool isTotalConversion});
}

/// @nodoc
class __$$ModInfoImplCopyWithImpl<$Res>
    extends _$ModInfoCopyWithImpl<$Res, _$ModInfoImpl>
    implements _$$ModInfoImplCopyWith<$Res> {
  __$$ModInfoImplCopyWithImpl(
      _$ModInfoImpl _value, $Res Function(_$ModInfoImpl) _then)
      : super(_value, _then);

  /// Create a copy of ModInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = freezed,
    Object? version = freezed,
    Object? description = freezed,
    Object? gameVersion = freezed,
    Object? author = freezed,
    Object? dependencies = null,
    Object? originalGameVersion = freezed,
    Object? isUtility = null,
    Object? isTotalConversion = null,
  }) {
    return _then(_$ModInfoImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      version: freezed == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as Version?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      gameVersion: freezed == gameVersion
          ? _value.gameVersion
          : gameVersion // ignore: cast_nullable_to_non_nullable
              as String?,
      author: freezed == author
          ? _value.author
          : author // ignore: cast_nullable_to_non_nullable
              as String?,
      dependencies: null == dependencies
          ? _value._dependencies
          : dependencies // ignore: cast_nullable_to_non_nullable
              as List<Dependency>,
      originalGameVersion: freezed == originalGameVersion
          ? _value.originalGameVersion
          : originalGameVersion // ignore: cast_nullable_to_non_nullable
              as String?,
      isUtility: null == isUtility
          ? _value.isUtility
          : isUtility // ignore: cast_nullable_to_non_nullable
              as bool,
      isTotalConversion: null == isTotalConversion
          ? _value.isTotalConversion
          : isTotalConversion // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ModInfoImpl extends _ModInfo {
  const _$ModInfoImpl(
      {required this.id,
      this.name,
      @JsonConverterVersionNullable() this.version,
      this.description,
      this.gameVersion,
      this.author,
      final List<Dependency> dependencies = const [],
      this.originalGameVersion,
      @JsonConverterBool() this.isUtility = false,
      @JsonConverterBool() this.isTotalConversion = false})
      : _dependencies = dependencies,
        super._();

  factory _$ModInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$ModInfoImplFromJson(json);

  @override
  final String id;
  @override
  final String? name;
  @override
  @JsonConverterVersionNullable()
  final Version? version;
  @override
  final String? description;
  @override
  final String? gameVersion;
  @override
  final String? author;
  final List<Dependency> _dependencies;
  @override
  @JsonKey()
  List<Dependency> get dependencies {
    if (_dependencies is EqualUnmodifiableListView) return _dependencies;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_dependencies);
  }

  @override
  final String? originalGameVersion;
  @override
  @JsonKey()
  @JsonConverterBool()
  final bool isUtility;
  @override
  @JsonKey()
  @JsonConverterBool()
  final bool isTotalConversion;

  @override
  String toString() {
    return 'ModInfo(id: $id, name: $name, version: $version, description: $description, gameVersion: $gameVersion, author: $author, dependencies: $dependencies, originalGameVersion: $originalGameVersion, isUtility: $isUtility, isTotalConversion: $isTotalConversion)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ModInfoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.gameVersion, gameVersion) ||
                other.gameVersion == gameVersion) &&
            (identical(other.author, author) || other.author == author) &&
            const DeepCollectionEquality()
                .equals(other._dependencies, _dependencies) &&
            (identical(other.originalGameVersion, originalGameVersion) ||
                other.originalGameVersion == originalGameVersion) &&
            (identical(other.isUtility, isUtility) ||
                other.isUtility == isUtility) &&
            (identical(other.isTotalConversion, isTotalConversion) ||
                other.isTotalConversion == isTotalConversion));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      version,
      description,
      gameVersion,
      author,
      const DeepCollectionEquality().hash(_dependencies),
      originalGameVersion,
      isUtility,
      isTotalConversion);

  /// Create a copy of ModInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ModInfoImplCopyWith<_$ModInfoImpl> get copyWith =>
      __$$ModInfoImplCopyWithImpl<_$ModInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ModInfoImplToJson(
      this,
    );
  }
}

abstract class _ModInfo extends ModInfo {
  const factory _ModInfo(
      {required final String id,
      final String? name,
      @JsonConverterVersionNullable() final Version? version,
      final String? description,
      final String? gameVersion,
      final String? author,
      final List<Dependency> dependencies,
      final String? originalGameVersion,
      @JsonConverterBool() final bool isUtility,
      @JsonConverterBool() final bool isTotalConversion}) = _$ModInfoImpl;
  const _ModInfo._() : super._();

  factory _ModInfo.fromJson(Map<String, dynamic> json) = _$ModInfoImpl.fromJson;

  @override
  String get id;
  @override
  String? get name;
  @override
  @JsonConverterVersionNullable()
  Version? get version;
  @override
  String? get description;
  @override
  String? get gameVersion;
  @override
  String? get author;
  @override
  List<Dependency> get dependencies;
  @override
  String? get originalGameVersion;
  @override
  @JsonConverterBool()
  bool get isUtility;
  @override
  @JsonConverterBool()
  bool get isTotalConversion;

  /// Create a copy of ModInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ModInfoImplCopyWith<_$ModInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
