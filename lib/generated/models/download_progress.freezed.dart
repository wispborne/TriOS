// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../models/download_progress.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$DownloadProgress {
  int get bytesReceived => throw _privateConstructorUsedError;
  int get bytesTotal => throw _privateConstructorUsedError;
  bool get isIndeterminate => throw _privateConstructorUsedError;
  String? get customStatus => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $DownloadProgressCopyWith<DownloadProgress> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DownloadProgressCopyWith<$Res> {
  factory $DownloadProgressCopyWith(
          DownloadProgress value, $Res Function(DownloadProgress) then) =
      _$DownloadProgressCopyWithImpl<$Res, DownloadProgress>;
  @useResult
  $Res call(
      {int bytesReceived,
      int bytesTotal,
      bool isIndeterminate,
      String? customStatus});
}

/// @nodoc
class _$DownloadProgressCopyWithImpl<$Res, $Val extends DownloadProgress>
    implements $DownloadProgressCopyWith<$Res> {
  _$DownloadProgressCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? bytesReceived = null,
    Object? bytesTotal = null,
    Object? isIndeterminate = null,
    Object? customStatus = freezed,
  }) {
    return _then(_value.copyWith(
      bytesReceived: null == bytesReceived
          ? _value.bytesReceived
          : bytesReceived // ignore: cast_nullable_to_non_nullable
              as int,
      bytesTotal: null == bytesTotal
          ? _value.bytesTotal
          : bytesTotal // ignore: cast_nullable_to_non_nullable
              as int,
      isIndeterminate: null == isIndeterminate
          ? _value.isIndeterminate
          : isIndeterminate // ignore: cast_nullable_to_non_nullable
              as bool,
      customStatus: freezed == customStatus
          ? _value.customStatus
          : customStatus // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DownloadProgressImplCopyWith<$Res>
    implements $DownloadProgressCopyWith<$Res> {
  factory _$$DownloadProgressImplCopyWith(_$DownloadProgressImpl value,
          $Res Function(_$DownloadProgressImpl) then) =
      __$$DownloadProgressImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int bytesReceived,
      int bytesTotal,
      bool isIndeterminate,
      String? customStatus});
}

/// @nodoc
class __$$DownloadProgressImplCopyWithImpl<$Res>
    extends _$DownloadProgressCopyWithImpl<$Res, _$DownloadProgressImpl>
    implements _$$DownloadProgressImplCopyWith<$Res> {
  __$$DownloadProgressImplCopyWithImpl(_$DownloadProgressImpl _value,
      $Res Function(_$DownloadProgressImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? bytesReceived = null,
    Object? bytesTotal = null,
    Object? isIndeterminate = null,
    Object? customStatus = freezed,
  }) {
    return _then(_$DownloadProgressImpl(
      null == bytesReceived
          ? _value.bytesReceived
          : bytesReceived // ignore: cast_nullable_to_non_nullable
              as int,
      null == bytesTotal
          ? _value.bytesTotal
          : bytesTotal // ignore: cast_nullable_to_non_nullable
              as int,
      isIndeterminate: null == isIndeterminate
          ? _value.isIndeterminate
          : isIndeterminate // ignore: cast_nullable_to_non_nullable
              as bool,
      customStatus: freezed == customStatus
          ? _value.customStatus
          : customStatus // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$DownloadProgressImpl extends _DownloadProgress {
  const _$DownloadProgressImpl(this.bytesReceived, this.bytesTotal,
      {this.isIndeterminate = false, this.customStatus})
      : super._();

  @override
  final int bytesReceived;
  @override
  final int bytesTotal;
  @override
  @JsonKey()
  final bool isIndeterminate;
  @override
  final String? customStatus;

  @override
  String toString() {
    return 'DownloadProgress(bytesReceived: $bytesReceived, bytesTotal: $bytesTotal, isIndeterminate: $isIndeterminate, customStatus: $customStatus)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DownloadProgressImpl &&
            (identical(other.bytesReceived, bytesReceived) ||
                other.bytesReceived == bytesReceived) &&
            (identical(other.bytesTotal, bytesTotal) ||
                other.bytesTotal == bytesTotal) &&
            (identical(other.isIndeterminate, isIndeterminate) ||
                other.isIndeterminate == isIndeterminate) &&
            (identical(other.customStatus, customStatus) ||
                other.customStatus == customStatus));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, bytesReceived, bytesTotal, isIndeterminate, customStatus);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DownloadProgressImplCopyWith<_$DownloadProgressImpl> get copyWith =>
      __$$DownloadProgressImplCopyWithImpl<_$DownloadProgressImpl>(
          this, _$identity);
}

abstract class _DownloadProgress extends DownloadProgress {
  const factory _DownloadProgress(final int bytesReceived, final int bytesTotal,
      {final bool isIndeterminate,
      final String? customStatus}) = _$DownloadProgressImpl;
  const _DownloadProgress._() : super._();

  @override
  int get bytesReceived;
  @override
  int get bytesTotal;
  @override
  bool get isIndeterminate;
  @override
  String? get customStatus;
  @override
  @JsonKey(ignore: true)
  _$$DownloadProgressImplCopyWith<_$DownloadProgressImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
