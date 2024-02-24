// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../models/file_download.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$FileDownload {
  String get url => throw _privateConstructorUsedError;
  String? get name => throw _privateConstructorUsedError;
  double? get downloadPercentage => throw _privateConstructorUsedError;
  String? get downloadPath => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $FileDownloadCopyWith<FileDownload> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FileDownloadCopyWith<$Res> {
  factory $FileDownloadCopyWith(
          FileDownload value, $Res Function(FileDownload) then) =
      _$FileDownloadCopyWithImpl<$Res, FileDownload>;
  @useResult
  $Res call(
      {String url,
      String? name,
      double? downloadPercentage,
      String? downloadPath,
      String? error});
}

/// @nodoc
class _$FileDownloadCopyWithImpl<$Res, $Val extends FileDownload>
    implements $FileDownloadCopyWith<$Res> {
  _$FileDownloadCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? url = null,
    Object? name = freezed,
    Object? downloadPercentage = freezed,
    Object? downloadPath = freezed,
    Object? error = freezed,
  }) {
    return _then(_value.copyWith(
      url: null == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      downloadPercentage: freezed == downloadPercentage
          ? _value.downloadPercentage
          : downloadPercentage // ignore: cast_nullable_to_non_nullable
              as double?,
      downloadPath: freezed == downloadPath
          ? _value.downloadPath
          : downloadPath // ignore: cast_nullable_to_non_nullable
              as String?,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FileDownloadImplCopyWith<$Res>
    implements $FileDownloadCopyWith<$Res> {
  factory _$$FileDownloadImplCopyWith(
          _$FileDownloadImpl value, $Res Function(_$FileDownloadImpl) then) =
      __$$FileDownloadImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String url,
      String? name,
      double? downloadPercentage,
      String? downloadPath,
      String? error});
}

/// @nodoc
class __$$FileDownloadImplCopyWithImpl<$Res>
    extends _$FileDownloadCopyWithImpl<$Res, _$FileDownloadImpl>
    implements _$$FileDownloadImplCopyWith<$Res> {
  __$$FileDownloadImplCopyWithImpl(
      _$FileDownloadImpl _value, $Res Function(_$FileDownloadImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? url = null,
    Object? name = freezed,
    Object? downloadPercentage = freezed,
    Object? downloadPath = freezed,
    Object? error = freezed,
  }) {
    return _then(_$FileDownloadImpl(
      url: null == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      downloadPercentage: freezed == downloadPercentage
          ? _value.downloadPercentage
          : downloadPercentage // ignore: cast_nullable_to_non_nullable
              as double?,
      downloadPath: freezed == downloadPath
          ? _value.downloadPath
          : downloadPath // ignore: cast_nullable_to_non_nullable
              as String?,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$FileDownloadImpl implements _FileDownload {
  _$FileDownloadImpl(
      {required this.url,
      this.name,
      this.downloadPercentage,
      this.downloadPath,
      this.error});

  @override
  final String url;
  @override
  final String? name;
  @override
  final double? downloadPercentage;
  @override
  final String? downloadPath;
  @override
  final String? error;

  @override
  String toString() {
    return 'FileDownload(url: $url, name: $name, downloadPercentage: $downloadPercentage, downloadPath: $downloadPath, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FileDownloadImpl &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.downloadPercentage, downloadPercentage) ||
                other.downloadPercentage == downloadPercentage) &&
            (identical(other.downloadPath, downloadPath) ||
                other.downloadPath == downloadPath) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, url, name, downloadPercentage, downloadPath, error);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$FileDownloadImplCopyWith<_$FileDownloadImpl> get copyWith =>
      __$$FileDownloadImplCopyWithImpl<_$FileDownloadImpl>(this, _$identity);
}

abstract class _FileDownload implements FileDownload {
  factory _FileDownload(
      {required final String url,
      final String? name,
      final double? downloadPercentage,
      final String? downloadPath,
      final String? error}) = _$FileDownloadImpl;

  @override
  String get url;
  @override
  String? get name;
  @override
  double? get downloadPercentage;
  @override
  String? get downloadPath;
  @override
  String? get error;
  @override
  @JsonKey(ignore: true)
  _$$FileDownloadImplCopyWith<_$FileDownloadImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
