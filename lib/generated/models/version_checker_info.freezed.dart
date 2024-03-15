// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../models/version_checker_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

VersionCheckerInfo _$VersionCheckerInfoFromJson(Map<String, dynamic> json) {
  return _VersionCheckerInfo.fromJson(json);
}

/// @nodoc
mixin _$VersionCheckerInfo {
  String? get masterVersionFile => throw _privateConstructorUsedError;
  String? get modNexusId => throw _privateConstructorUsedError;
  String? get modThreadId => throw _privateConstructorUsedError;
  @VersionJsonConverterNullable()
  Version? get modVersion => throw _privateConstructorUsedError;
  String? get directDownloadUrl => throw _privateConstructorUsedError;
  String? get changelogUrl => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $VersionCheckerInfoCopyWith<VersionCheckerInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VersionCheckerInfoCopyWith<$Res> {
  factory $VersionCheckerInfoCopyWith(
          VersionCheckerInfo value, $Res Function(VersionCheckerInfo) then) =
      _$VersionCheckerInfoCopyWithImpl<$Res, VersionCheckerInfo>;
  @useResult
  $Res call(
      {String? masterVersionFile,
      String? modNexusId,
      String? modThreadId,
      @VersionJsonConverterNullable() Version? modVersion,
      String? directDownloadUrl,
      String? changelogUrl});
}

/// @nodoc
class _$VersionCheckerInfoCopyWithImpl<$Res, $Val extends VersionCheckerInfo>
    implements $VersionCheckerInfoCopyWith<$Res> {
  _$VersionCheckerInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? masterVersionFile = freezed,
    Object? modNexusId = freezed,
    Object? modThreadId = freezed,
    Object? modVersion = freezed,
    Object? directDownloadUrl = freezed,
    Object? changelogUrl = freezed,
  }) {
    return _then(_value.copyWith(
      masterVersionFile: freezed == masterVersionFile
          ? _value.masterVersionFile
          : masterVersionFile // ignore: cast_nullable_to_non_nullable
              as String?,
      modNexusId: freezed == modNexusId
          ? _value.modNexusId
          : modNexusId // ignore: cast_nullable_to_non_nullable
              as String?,
      modThreadId: freezed == modThreadId
          ? _value.modThreadId
          : modThreadId // ignore: cast_nullable_to_non_nullable
              as String?,
      modVersion: freezed == modVersion
          ? _value.modVersion
          : modVersion // ignore: cast_nullable_to_non_nullable
              as Version?,
      directDownloadUrl: freezed == directDownloadUrl
          ? _value.directDownloadUrl
          : directDownloadUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      changelogUrl: freezed == changelogUrl
          ? _value.changelogUrl
          : changelogUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$VersionCheckerInfoImplCopyWith<$Res>
    implements $VersionCheckerInfoCopyWith<$Res> {
  factory _$$VersionCheckerInfoImplCopyWith(_$VersionCheckerInfoImpl value,
          $Res Function(_$VersionCheckerInfoImpl) then) =
      __$$VersionCheckerInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? masterVersionFile,
      String? modNexusId,
      String? modThreadId,
      @VersionJsonConverterNullable() Version? modVersion,
      String? directDownloadUrl,
      String? changelogUrl});
}

/// @nodoc
class __$$VersionCheckerInfoImplCopyWithImpl<$Res>
    extends _$VersionCheckerInfoCopyWithImpl<$Res, _$VersionCheckerInfoImpl>
    implements _$$VersionCheckerInfoImplCopyWith<$Res> {
  __$$VersionCheckerInfoImplCopyWithImpl(_$VersionCheckerInfoImpl _value,
      $Res Function(_$VersionCheckerInfoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? masterVersionFile = freezed,
    Object? modNexusId = freezed,
    Object? modThreadId = freezed,
    Object? modVersion = freezed,
    Object? directDownloadUrl = freezed,
    Object? changelogUrl = freezed,
  }) {
    return _then(_$VersionCheckerInfoImpl(
      masterVersionFile: freezed == masterVersionFile
          ? _value.masterVersionFile
          : masterVersionFile // ignore: cast_nullable_to_non_nullable
              as String?,
      modNexusId: freezed == modNexusId
          ? _value.modNexusId
          : modNexusId // ignore: cast_nullable_to_non_nullable
              as String?,
      modThreadId: freezed == modThreadId
          ? _value.modThreadId
          : modThreadId // ignore: cast_nullable_to_non_nullable
              as String?,
      modVersion: freezed == modVersion
          ? _value.modVersion
          : modVersion // ignore: cast_nullable_to_non_nullable
              as Version?,
      directDownloadUrl: freezed == directDownloadUrl
          ? _value.directDownloadUrl
          : directDownloadUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      changelogUrl: freezed == changelogUrl
          ? _value.changelogUrl
          : changelogUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$VersionCheckerInfoImpl extends _VersionCheckerInfo {
  const _$VersionCheckerInfoImpl(
      {this.masterVersionFile,
      this.modNexusId,
      this.modThreadId,
      @VersionJsonConverterNullable() this.modVersion,
      this.directDownloadUrl,
      this.changelogUrl})
      : super._();

  factory _$VersionCheckerInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$VersionCheckerInfoImplFromJson(json);

  @override
  final String? masterVersionFile;
  @override
  final String? modNexusId;
  @override
  final String? modThreadId;
  @override
  @VersionJsonConverterNullable()
  final Version? modVersion;
  @override
  final String? directDownloadUrl;
  @override
  final String? changelogUrl;

  @override
  String toString() {
    return 'VersionCheckerInfo(masterVersionFile: $masterVersionFile, modNexusId: $modNexusId, modThreadId: $modThreadId, modVersion: $modVersion, directDownloadUrl: $directDownloadUrl, changelogUrl: $changelogUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VersionCheckerInfoImpl &&
            (identical(other.masterVersionFile, masterVersionFile) ||
                other.masterVersionFile == masterVersionFile) &&
            (identical(other.modNexusId, modNexusId) ||
                other.modNexusId == modNexusId) &&
            (identical(other.modThreadId, modThreadId) ||
                other.modThreadId == modThreadId) &&
            (identical(other.modVersion, modVersion) ||
                other.modVersion == modVersion) &&
            (identical(other.directDownloadUrl, directDownloadUrl) ||
                other.directDownloadUrl == directDownloadUrl) &&
            (identical(other.changelogUrl, changelogUrl) ||
                other.changelogUrl == changelogUrl));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, masterVersionFile, modNexusId,
      modThreadId, modVersion, directDownloadUrl, changelogUrl);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$VersionCheckerInfoImplCopyWith<_$VersionCheckerInfoImpl> get copyWith =>
      __$$VersionCheckerInfoImplCopyWithImpl<_$VersionCheckerInfoImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VersionCheckerInfoImplToJson(
      this,
    );
  }
}

abstract class _VersionCheckerInfo extends VersionCheckerInfo {
  const factory _VersionCheckerInfo(
      {final String? masterVersionFile,
      final String? modNexusId,
      final String? modThreadId,
      @VersionJsonConverterNullable() final Version? modVersion,
      final String? directDownloadUrl,
      final String? changelogUrl}) = _$VersionCheckerInfoImpl;
  const _VersionCheckerInfo._() : super._();

  factory _VersionCheckerInfo.fromJson(Map<String, dynamic> json) =
      _$VersionCheckerInfoImpl.fromJson;

  @override
  String? get masterVersionFile;
  @override
  String? get modNexusId;
  @override
  String? get modThreadId;
  @override
  @VersionJsonConverterNullable()
  Version? get modVersion;
  @override
  String? get directDownloadUrl;
  @override
  String? get changelogUrl;
  @override
  @JsonKey(ignore: true)
  _$$VersionCheckerInfoImplCopyWith<_$VersionCheckerInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
