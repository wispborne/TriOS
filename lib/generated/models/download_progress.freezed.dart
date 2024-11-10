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
mixin _$TriOSDownloadProgress {
  int get bytesReceived => throw _privateConstructorUsedError;
  int get bytesTotal => throw _privateConstructorUsedError;
  bool get isIndeterminate => throw _privateConstructorUsedError;
  String? get customStatus => throw _privateConstructorUsedError;

  /// Create a copy of TriOSDownloadProgress
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TriOSDownloadProgressCopyWith<TriOSDownloadProgress> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TriOSDownloadProgressCopyWith<$Res> {
  factory $TriOSDownloadProgressCopyWith(TriOSDownloadProgress value,
          $Res Function(TriOSDownloadProgress) then) =
      _$TriOSDownloadProgressCopyWithImpl<$Res, TriOSDownloadProgress>;
  @useResult
  $Res call(
      {int bytesReceived,
      int bytesTotal,
      bool isIndeterminate,
      String? customStatus});
}

/// @nodoc
class _$TriOSDownloadProgressCopyWithImpl<$Res,
        $Val extends TriOSDownloadProgress>
    implements $TriOSDownloadProgressCopyWith<$Res> {
  _$TriOSDownloadProgressCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TriOSDownloadProgress
  /// with the given fields replaced by the non-null parameter values.
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
abstract class _$$TriOSDownloadProgressImplCopyWith<$Res>
    implements $TriOSDownloadProgressCopyWith<$Res> {
  factory _$$TriOSDownloadProgressImplCopyWith(
          _$TriOSDownloadProgressImpl value,
          $Res Function(_$TriOSDownloadProgressImpl) then) =
      __$$TriOSDownloadProgressImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int bytesReceived,
      int bytesTotal,
      bool isIndeterminate,
      String? customStatus});
}

/// @nodoc
class __$$TriOSDownloadProgressImplCopyWithImpl<$Res>
    extends _$TriOSDownloadProgressCopyWithImpl<$Res,
        _$TriOSDownloadProgressImpl>
    implements _$$TriOSDownloadProgressImplCopyWith<$Res> {
  __$$TriOSDownloadProgressImplCopyWithImpl(_$TriOSDownloadProgressImpl _value,
      $Res Function(_$TriOSDownloadProgressImpl) _then)
      : super(_value, _then);

  /// Create a copy of TriOSDownloadProgress
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? bytesReceived = null,
    Object? bytesTotal = null,
    Object? isIndeterminate = null,
    Object? customStatus = freezed,
  }) {
    return _then(_$TriOSDownloadProgressImpl(
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

class _$TriOSDownloadProgressImpl extends _TriOSDownloadProgress {
  const _$TriOSDownloadProgressImpl(this.bytesReceived, this.bytesTotal,
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
    return 'TriOSDownloadProgress(bytesReceived: $bytesReceived, bytesTotal: $bytesTotal, isIndeterminate: $isIndeterminate, customStatus: $customStatus)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TriOSDownloadProgressImpl &&
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

  /// Create a copy of TriOSDownloadProgress
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TriOSDownloadProgressImplCopyWith<_$TriOSDownloadProgressImpl>
      get copyWith => __$$TriOSDownloadProgressImplCopyWithImpl<
          _$TriOSDownloadProgressImpl>(this, _$identity);
}

abstract class _TriOSDownloadProgress extends TriOSDownloadProgress {
  const factory _TriOSDownloadProgress(
      final int bytesReceived, final int bytesTotal,
      {final bool isIndeterminate,
      final String? customStatus}) = _$TriOSDownloadProgressImpl;
  const _TriOSDownloadProgress._() : super._();

  @override
  int get bytesReceived;
  @override
  int get bytesTotal;
  @override
  bool get isIndeterminate;
  @override
  String? get customStatus;

  /// Create a copy of TriOSDownloadProgress
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TriOSDownloadProgressImplCopyWith<_$TriOSDownloadProgressImpl>
      get copyWith => throw _privateConstructorUsedError;
}
