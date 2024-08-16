// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../mod_profiles/models/mod_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ModProfiles _$ModProfilesFromJson(Map<String, dynamic> json) {
  return _ModProfiles.fromJson(json);
}

/// @nodoc
mixin _$ModProfiles {
  List<ModProfile> get modProfiles => throw _privateConstructorUsedError;

  /// Serializes this ModProfiles to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ModProfiles
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ModProfilesCopyWith<ModProfiles> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ModProfilesCopyWith<$Res> {
  factory $ModProfilesCopyWith(
          ModProfiles value, $Res Function(ModProfiles) then) =
      _$ModProfilesCopyWithImpl<$Res, ModProfiles>;
  @useResult
  $Res call({List<ModProfile> modProfiles});
}

/// @nodoc
class _$ModProfilesCopyWithImpl<$Res, $Val extends ModProfiles>
    implements $ModProfilesCopyWith<$Res> {
  _$ModProfilesCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ModProfiles
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? modProfiles = null,
  }) {
    return _then(_value.copyWith(
      modProfiles: null == modProfiles
          ? _value.modProfiles
          : modProfiles // ignore: cast_nullable_to_non_nullable
              as List<ModProfile>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ModProfilesImplCopyWith<$Res>
    implements $ModProfilesCopyWith<$Res> {
  factory _$$ModProfilesImplCopyWith(
          _$ModProfilesImpl value, $Res Function(_$ModProfilesImpl) then) =
      __$$ModProfilesImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<ModProfile> modProfiles});
}

/// @nodoc
class __$$ModProfilesImplCopyWithImpl<$Res>
    extends _$ModProfilesCopyWithImpl<$Res, _$ModProfilesImpl>
    implements _$$ModProfilesImplCopyWith<$Res> {
  __$$ModProfilesImplCopyWithImpl(
      _$ModProfilesImpl _value, $Res Function(_$ModProfilesImpl) _then)
      : super(_value, _then);

  /// Create a copy of ModProfiles
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? modProfiles = null,
  }) {
    return _then(_$ModProfilesImpl(
      modProfiles: null == modProfiles
          ? _value._modProfiles
          : modProfiles // ignore: cast_nullable_to_non_nullable
              as List<ModProfile>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ModProfilesImpl implements _ModProfiles {
  const _$ModProfilesImpl({required final List<ModProfile> modProfiles})
      : _modProfiles = modProfiles;

  factory _$ModProfilesImpl.fromJson(Map<String, dynamic> json) =>
      _$$ModProfilesImplFromJson(json);

  final List<ModProfile> _modProfiles;
  @override
  List<ModProfile> get modProfiles {
    if (_modProfiles is EqualUnmodifiableListView) return _modProfiles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_modProfiles);
  }

  @override
  String toString() {
    return 'ModProfiles(modProfiles: $modProfiles)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ModProfilesImpl &&
            const DeepCollectionEquality()
                .equals(other._modProfiles, _modProfiles));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, const DeepCollectionEquality().hash(_modProfiles));

  /// Create a copy of ModProfiles
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ModProfilesImplCopyWith<_$ModProfilesImpl> get copyWith =>
      __$$ModProfilesImplCopyWithImpl<_$ModProfilesImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ModProfilesImplToJson(
      this,
    );
  }
}

abstract class _ModProfiles implements ModProfiles {
  const factory _ModProfiles({required final List<ModProfile> modProfiles}) =
      _$ModProfilesImpl;

  factory _ModProfiles.fromJson(Map<String, dynamic> json) =
      _$ModProfilesImpl.fromJson;

  @override
  List<ModProfile> get modProfiles;

  /// Create a copy of ModProfiles
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ModProfilesImplCopyWith<_$ModProfilesImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ShallowModVariant _$ShallowModVariantFromJson(Map<String, dynamic> json) {
  return _ShallowModVariant.fromJson(json);
}

/// @nodoc
mixin _$ShallowModVariant {
  String get modId => throw _privateConstructorUsedError;
  String? get modName => throw _privateConstructorUsedError;
  String get smolVariantId => throw _privateConstructorUsedError;
  @JsonConverterVersionNullable()
  Version? get version => throw _privateConstructorUsedError;

  /// Serializes this ShallowModVariant to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ShallowModVariant
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ShallowModVariantCopyWith<ShallowModVariant> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ShallowModVariantCopyWith<$Res> {
  factory $ShallowModVariantCopyWith(
          ShallowModVariant value, $Res Function(ShallowModVariant) then) =
      _$ShallowModVariantCopyWithImpl<$Res, ShallowModVariant>;
  @useResult
  $Res call(
      {String modId,
      String? modName,
      String smolVariantId,
      @JsonConverterVersionNullable() Version? version});
}

/// @nodoc
class _$ShallowModVariantCopyWithImpl<$Res, $Val extends ShallowModVariant>
    implements $ShallowModVariantCopyWith<$Res> {
  _$ShallowModVariantCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ShallowModVariant
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? modId = null,
    Object? modName = freezed,
    Object? smolVariantId = null,
    Object? version = freezed,
  }) {
    return _then(_value.copyWith(
      modId: null == modId
          ? _value.modId
          : modId // ignore: cast_nullable_to_non_nullable
              as String,
      modName: freezed == modName
          ? _value.modName
          : modName // ignore: cast_nullable_to_non_nullable
              as String?,
      smolVariantId: null == smolVariantId
          ? _value.smolVariantId
          : smolVariantId // ignore: cast_nullable_to_non_nullable
              as String,
      version: freezed == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as Version?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ShallowModVariantImplCopyWith<$Res>
    implements $ShallowModVariantCopyWith<$Res> {
  factory _$$ShallowModVariantImplCopyWith(_$ShallowModVariantImpl value,
          $Res Function(_$ShallowModVariantImpl) then) =
      __$$ShallowModVariantImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String modId,
      String? modName,
      String smolVariantId,
      @JsonConverterVersionNullable() Version? version});
}

/// @nodoc
class __$$ShallowModVariantImplCopyWithImpl<$Res>
    extends _$ShallowModVariantCopyWithImpl<$Res, _$ShallowModVariantImpl>
    implements _$$ShallowModVariantImplCopyWith<$Res> {
  __$$ShallowModVariantImplCopyWithImpl(_$ShallowModVariantImpl _value,
      $Res Function(_$ShallowModVariantImpl) _then)
      : super(_value, _then);

  /// Create a copy of ShallowModVariant
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? modId = null,
    Object? modName = freezed,
    Object? smolVariantId = null,
    Object? version = freezed,
  }) {
    return _then(_$ShallowModVariantImpl(
      modId: null == modId
          ? _value.modId
          : modId // ignore: cast_nullable_to_non_nullable
              as String,
      modName: freezed == modName
          ? _value.modName
          : modName // ignore: cast_nullable_to_non_nullable
              as String?,
      smolVariantId: null == smolVariantId
          ? _value.smolVariantId
          : smolVariantId // ignore: cast_nullable_to_non_nullable
              as String,
      version: freezed == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as Version?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ShallowModVariantImpl implements _ShallowModVariant {
  const _$ShallowModVariantImpl(
      {required this.modId,
      this.modName,
      required this.smolVariantId,
      @JsonConverterVersionNullable() this.version});

  factory _$ShallowModVariantImpl.fromJson(Map<String, dynamic> json) =>
      _$$ShallowModVariantImplFromJson(json);

  @override
  final String modId;
  @override
  final String? modName;
  @override
  final String smolVariantId;
  @override
  @JsonConverterVersionNullable()
  final Version? version;

  @override
  String toString() {
    return 'ShallowModVariant(modId: $modId, modName: $modName, smolVariantId: $smolVariantId, version: $version)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ShallowModVariantImpl &&
            (identical(other.modId, modId) || other.modId == modId) &&
            (identical(other.modName, modName) || other.modName == modName) &&
            (identical(other.smolVariantId, smolVariantId) ||
                other.smolVariantId == smolVariantId) &&
            (identical(other.version, version) || other.version == version));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, modId, modName, smolVariantId, version);

  /// Create a copy of ShallowModVariant
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ShallowModVariantImplCopyWith<_$ShallowModVariantImpl> get copyWith =>
      __$$ShallowModVariantImplCopyWithImpl<_$ShallowModVariantImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ShallowModVariantImplToJson(
      this,
    );
  }
}

abstract class _ShallowModVariant implements ShallowModVariant {
  const factory _ShallowModVariant(
          {required final String modId,
          final String? modName,
          required final String smolVariantId,
          @JsonConverterVersionNullable() final Version? version}) =
      _$ShallowModVariantImpl;

  factory _ShallowModVariant.fromJson(Map<String, dynamic> json) =
      _$ShallowModVariantImpl.fromJson;

  @override
  String get modId;
  @override
  String? get modName;
  @override
  String get smolVariantId;
  @override
  @JsonConverterVersionNullable()
  Version? get version;

  /// Create a copy of ShallowModVariant
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ShallowModVariantImplCopyWith<_$ShallowModVariantImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ModProfile _$ModProfileFromJson(Map<String, dynamic> json) {
  return _ModProfile.fromJson(json);
}

/// @nodoc
mixin _$ModProfile {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  int get sortOrder => throw _privateConstructorUsedError;
  List<ShallowModVariant> get enabledModVariants =>
      throw _privateConstructorUsedError;
  DateTime? get dateCreated => throw _privateConstructorUsedError;
  DateTime? get dateModified => throw _privateConstructorUsedError;

  /// Serializes this ModProfile to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ModProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ModProfileCopyWith<ModProfile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ModProfileCopyWith<$Res> {
  factory $ModProfileCopyWith(
          ModProfile value, $Res Function(ModProfile) then) =
      _$ModProfileCopyWithImpl<$Res, ModProfile>;
  @useResult
  $Res call(
      {String id,
      String name,
      String description,
      int sortOrder,
      List<ShallowModVariant> enabledModVariants,
      DateTime? dateCreated,
      DateTime? dateModified});
}

/// @nodoc
class _$ModProfileCopyWithImpl<$Res, $Val extends ModProfile>
    implements $ModProfileCopyWith<$Res> {
  _$ModProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ModProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? sortOrder = null,
    Object? enabledModVariants = null,
    Object? dateCreated = freezed,
    Object? dateModified = freezed,
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
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
      enabledModVariants: null == enabledModVariants
          ? _value.enabledModVariants
          : enabledModVariants // ignore: cast_nullable_to_non_nullable
              as List<ShallowModVariant>,
      dateCreated: freezed == dateCreated
          ? _value.dateCreated
          : dateCreated // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      dateModified: freezed == dateModified
          ? _value.dateModified
          : dateModified // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ModProfileImplCopyWith<$Res>
    implements $ModProfileCopyWith<$Res> {
  factory _$$ModProfileImplCopyWith(
          _$ModProfileImpl value, $Res Function(_$ModProfileImpl) then) =
      __$$ModProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String description,
      int sortOrder,
      List<ShallowModVariant> enabledModVariants,
      DateTime? dateCreated,
      DateTime? dateModified});
}

/// @nodoc
class __$$ModProfileImplCopyWithImpl<$Res>
    extends _$ModProfileCopyWithImpl<$Res, _$ModProfileImpl>
    implements _$$ModProfileImplCopyWith<$Res> {
  __$$ModProfileImplCopyWithImpl(
      _$ModProfileImpl _value, $Res Function(_$ModProfileImpl) _then)
      : super(_value, _then);

  /// Create a copy of ModProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? sortOrder = null,
    Object? enabledModVariants = null,
    Object? dateCreated = freezed,
    Object? dateModified = freezed,
  }) {
    return _then(_$ModProfileImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
      enabledModVariants: null == enabledModVariants
          ? _value._enabledModVariants
          : enabledModVariants // ignore: cast_nullable_to_non_nullable
              as List<ShallowModVariant>,
      dateCreated: freezed == dateCreated
          ? _value.dateCreated
          : dateCreated // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      dateModified: freezed == dateModified
          ? _value.dateModified
          : dateModified // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ModProfileImpl implements _ModProfile {
  const _$ModProfileImpl(
      {required this.id,
      required this.name,
      required this.description,
      required this.sortOrder,
      required final List<ShallowModVariant> enabledModVariants,
      this.dateCreated,
      this.dateModified})
      : _enabledModVariants = enabledModVariants;

  factory _$ModProfileImpl.fromJson(Map<String, dynamic> json) =>
      _$$ModProfileImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String description;
  @override
  final int sortOrder;
  final List<ShallowModVariant> _enabledModVariants;
  @override
  List<ShallowModVariant> get enabledModVariants {
    if (_enabledModVariants is EqualUnmodifiableListView)
      return _enabledModVariants;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_enabledModVariants);
  }

  @override
  final DateTime? dateCreated;
  @override
  final DateTime? dateModified;

  @override
  String toString() {
    return 'ModProfile(id: $id, name: $name, description: $description, sortOrder: $sortOrder, enabledModVariants: $enabledModVariants, dateCreated: $dateCreated, dateModified: $dateModified)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ModProfileImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder) &&
            const DeepCollectionEquality()
                .equals(other._enabledModVariants, _enabledModVariants) &&
            (identical(other.dateCreated, dateCreated) ||
                other.dateCreated == dateCreated) &&
            (identical(other.dateModified, dateModified) ||
                other.dateModified == dateModified));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      description,
      sortOrder,
      const DeepCollectionEquality().hash(_enabledModVariants),
      dateCreated,
      dateModified);

  /// Create a copy of ModProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ModProfileImplCopyWith<_$ModProfileImpl> get copyWith =>
      __$$ModProfileImplCopyWithImpl<_$ModProfileImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ModProfileImplToJson(
      this,
    );
  }
}

abstract class _ModProfile implements ModProfile {
  const factory _ModProfile(
      {required final String id,
      required final String name,
      required final String description,
      required final int sortOrder,
      required final List<ShallowModVariant> enabledModVariants,
      final DateTime? dateCreated,
      final DateTime? dateModified}) = _$ModProfileImpl;

  factory _ModProfile.fromJson(Map<String, dynamic> json) =
      _$ModProfileImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get description;
  @override
  int get sortOrder;
  @override
  List<ShallowModVariant> get enabledModVariants;
  @override
  DateTime? get dateCreated;
  @override
  DateTime? get dateModified;

  /// Create a copy of ModProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ModProfileImplCopyWith<_$ModProfileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
