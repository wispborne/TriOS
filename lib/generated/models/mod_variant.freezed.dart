// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../models/mod_variant.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ModVariant {
  ModInfo get modInfo => throw _privateConstructorUsedError;
  VersionCheckerInfo? get versionCheckerInfo =>
      throw _privateConstructorUsedError;
  Directory get modFolder => throw _privateConstructorUsedError;
  bool get hasNonBrickedModInfo => throw _privateConstructorUsedError;

  /// Create a copy of ModVariant
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ModVariantCopyWith<ModVariant> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ModVariantCopyWith<$Res> {
  factory $ModVariantCopyWith(
          ModVariant value, $Res Function(ModVariant) then) =
      _$ModVariantCopyWithImpl<$Res, ModVariant>;
  @useResult
  $Res call(
      {ModInfo modInfo,
      VersionCheckerInfo? versionCheckerInfo,
      Directory modFolder,
      bool hasNonBrickedModInfo});

  $ModInfoCopyWith<$Res> get modInfo;
  $VersionCheckerInfoCopyWith<$Res>? get versionCheckerInfo;
}

/// @nodoc
class _$ModVariantCopyWithImpl<$Res, $Val extends ModVariant>
    implements $ModVariantCopyWith<$Res> {
  _$ModVariantCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ModVariant
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? modInfo = null,
    Object? versionCheckerInfo = freezed,
    Object? modFolder = null,
    Object? hasNonBrickedModInfo = null,
  }) {
    return _then(_value.copyWith(
      modInfo: null == modInfo
          ? _value.modInfo
          : modInfo // ignore: cast_nullable_to_non_nullable
              as ModInfo,
      versionCheckerInfo: freezed == versionCheckerInfo
          ? _value.versionCheckerInfo
          : versionCheckerInfo // ignore: cast_nullable_to_non_nullable
              as VersionCheckerInfo?,
      modFolder: null == modFolder
          ? _value.modFolder
          : modFolder // ignore: cast_nullable_to_non_nullable
              as Directory,
      hasNonBrickedModInfo: null == hasNonBrickedModInfo
          ? _value.hasNonBrickedModInfo
          : hasNonBrickedModInfo // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }

  /// Create a copy of ModVariant
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ModInfoCopyWith<$Res> get modInfo {
    return $ModInfoCopyWith<$Res>(_value.modInfo, (value) {
      return _then(_value.copyWith(modInfo: value) as $Val);
    });
  }

  /// Create a copy of ModVariant
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $VersionCheckerInfoCopyWith<$Res>? get versionCheckerInfo {
    if (_value.versionCheckerInfo == null) {
      return null;
    }

    return $VersionCheckerInfoCopyWith<$Res>(_value.versionCheckerInfo!,
        (value) {
      return _then(_value.copyWith(versionCheckerInfo: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ModVariantImplCopyWith<$Res>
    implements $ModVariantCopyWith<$Res> {
  factory _$$ModVariantImplCopyWith(
          _$ModVariantImpl value, $Res Function(_$ModVariantImpl) then) =
      __$$ModVariantImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {ModInfo modInfo,
      VersionCheckerInfo? versionCheckerInfo,
      Directory modFolder,
      bool hasNonBrickedModInfo});

  @override
  $ModInfoCopyWith<$Res> get modInfo;
  @override
  $VersionCheckerInfoCopyWith<$Res>? get versionCheckerInfo;
}

/// @nodoc
class __$$ModVariantImplCopyWithImpl<$Res>
    extends _$ModVariantCopyWithImpl<$Res, _$ModVariantImpl>
    implements _$$ModVariantImplCopyWith<$Res> {
  __$$ModVariantImplCopyWithImpl(
      _$ModVariantImpl _value, $Res Function(_$ModVariantImpl) _then)
      : super(_value, _then);

  /// Create a copy of ModVariant
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? modInfo = null,
    Object? versionCheckerInfo = freezed,
    Object? modFolder = null,
    Object? hasNonBrickedModInfo = null,
  }) {
    return _then(_$ModVariantImpl(
      modInfo: null == modInfo
          ? _value.modInfo
          : modInfo // ignore: cast_nullable_to_non_nullable
              as ModInfo,
      versionCheckerInfo: freezed == versionCheckerInfo
          ? _value.versionCheckerInfo
          : versionCheckerInfo // ignore: cast_nullable_to_non_nullable
              as VersionCheckerInfo?,
      modFolder: null == modFolder
          ? _value.modFolder
          : modFolder // ignore: cast_nullable_to_non_nullable
              as Directory,
      hasNonBrickedModInfo: null == hasNonBrickedModInfo
          ? _value.hasNonBrickedModInfo
          : hasNonBrickedModInfo // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$ModVariantImpl extends _ModVariant {
  const _$ModVariantImpl(
      {required this.modInfo,
      required this.versionCheckerInfo,
      required this.modFolder,
      required this.hasNonBrickedModInfo})
      : super._();

  @override
  final ModInfo modInfo;
  @override
  final VersionCheckerInfo? versionCheckerInfo;
  @override
  final Directory modFolder;
  @override
  final bool hasNonBrickedModInfo;

  @override
  String toString() {
    return 'ModVariant(modInfo: $modInfo, versionCheckerInfo: $versionCheckerInfo, modFolder: $modFolder, hasNonBrickedModInfo: $hasNonBrickedModInfo)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ModVariantImpl &&
            (identical(other.modInfo, modInfo) || other.modInfo == modInfo) &&
            (identical(other.versionCheckerInfo, versionCheckerInfo) ||
                other.versionCheckerInfo == versionCheckerInfo) &&
            (identical(other.modFolder, modFolder) ||
                other.modFolder == modFolder) &&
            (identical(other.hasNonBrickedModInfo, hasNonBrickedModInfo) ||
                other.hasNonBrickedModInfo == hasNonBrickedModInfo));
  }

  @override
  int get hashCode => Object.hash(runtimeType, modInfo, versionCheckerInfo,
      modFolder, hasNonBrickedModInfo);

  /// Create a copy of ModVariant
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ModVariantImplCopyWith<_$ModVariantImpl> get copyWith =>
      __$$ModVariantImplCopyWithImpl<_$ModVariantImpl>(this, _$identity);
}

abstract class _ModVariant extends ModVariant {
  const factory _ModVariant(
      {required final ModInfo modInfo,
      required final VersionCheckerInfo? versionCheckerInfo,
      required final Directory modFolder,
      required final bool hasNonBrickedModInfo}) = _$ModVariantImpl;
  const _ModVariant._() : super._();

  @override
  ModInfo get modInfo;
  @override
  VersionCheckerInfo? get versionCheckerInfo;
  @override
  Directory get modFolder;
  @override
  bool get hasNonBrickedModInfo;

  /// Create a copy of ModVariant
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ModVariantImplCopyWith<_$ModVariantImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
