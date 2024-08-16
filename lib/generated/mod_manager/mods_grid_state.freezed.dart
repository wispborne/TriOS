// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../mod_manager/mods_grid_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ModsGridState _$ModsGridStateFromJson(Map<String, dynamic> json) {
  return _ModsGridState.fromJson(json);
}

/// @nodoc
mixin _$ModsGridState {
  bool get isGroupEnabledExpanded => throw _privateConstructorUsedError;
  bool get isGroupDisabledExpanded => throw _privateConstructorUsedError;

  /// Serializes this ModsGridState to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ModsGridState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ModsGridStateCopyWith<ModsGridState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ModsGridStateCopyWith<$Res> {
  factory $ModsGridStateCopyWith(
          ModsGridState value, $Res Function(ModsGridState) then) =
      _$ModsGridStateCopyWithImpl<$Res, ModsGridState>;
  @useResult
  $Res call({bool isGroupEnabledExpanded, bool isGroupDisabledExpanded});
}

/// @nodoc
class _$ModsGridStateCopyWithImpl<$Res, $Val extends ModsGridState>
    implements $ModsGridStateCopyWith<$Res> {
  _$ModsGridStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ModsGridState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isGroupEnabledExpanded = null,
    Object? isGroupDisabledExpanded = null,
  }) {
    return _then(_value.copyWith(
      isGroupEnabledExpanded: null == isGroupEnabledExpanded
          ? _value.isGroupEnabledExpanded
          : isGroupEnabledExpanded // ignore: cast_nullable_to_non_nullable
              as bool,
      isGroupDisabledExpanded: null == isGroupDisabledExpanded
          ? _value.isGroupDisabledExpanded
          : isGroupDisabledExpanded // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ModsGridStateImplCopyWith<$Res>
    implements $ModsGridStateCopyWith<$Res> {
  factory _$$ModsGridStateImplCopyWith(
          _$ModsGridStateImpl value, $Res Function(_$ModsGridStateImpl) then) =
      __$$ModsGridStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool isGroupEnabledExpanded, bool isGroupDisabledExpanded});
}

/// @nodoc
class __$$ModsGridStateImplCopyWithImpl<$Res>
    extends _$ModsGridStateCopyWithImpl<$Res, _$ModsGridStateImpl>
    implements _$$ModsGridStateImplCopyWith<$Res> {
  __$$ModsGridStateImplCopyWithImpl(
      _$ModsGridStateImpl _value, $Res Function(_$ModsGridStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of ModsGridState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isGroupEnabledExpanded = null,
    Object? isGroupDisabledExpanded = null,
  }) {
    return _then(_$ModsGridStateImpl(
      isGroupEnabledExpanded: null == isGroupEnabledExpanded
          ? _value.isGroupEnabledExpanded
          : isGroupEnabledExpanded // ignore: cast_nullable_to_non_nullable
              as bool,
      isGroupDisabledExpanded: null == isGroupDisabledExpanded
          ? _value.isGroupDisabledExpanded
          : isGroupDisabledExpanded // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ModsGridStateImpl implements _ModsGridState {
  _$ModsGridStateImpl(
      {this.isGroupEnabledExpanded = true,
      this.isGroupDisabledExpanded = true});

  factory _$ModsGridStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$ModsGridStateImplFromJson(json);

  @override
  @JsonKey()
  final bool isGroupEnabledExpanded;
  @override
  @JsonKey()
  final bool isGroupDisabledExpanded;

  @override
  String toString() {
    return 'ModsGridState(isGroupEnabledExpanded: $isGroupEnabledExpanded, isGroupDisabledExpanded: $isGroupDisabledExpanded)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ModsGridStateImpl &&
            (identical(other.isGroupEnabledExpanded, isGroupEnabledExpanded) ||
                other.isGroupEnabledExpanded == isGroupEnabledExpanded) &&
            (identical(
                    other.isGroupDisabledExpanded, isGroupDisabledExpanded) ||
                other.isGroupDisabledExpanded == isGroupDisabledExpanded));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, isGroupEnabledExpanded, isGroupDisabledExpanded);

  /// Create a copy of ModsGridState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ModsGridStateImplCopyWith<_$ModsGridStateImpl> get copyWith =>
      __$$ModsGridStateImplCopyWithImpl<_$ModsGridStateImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ModsGridStateImplToJson(
      this,
    );
  }
}

abstract class _ModsGridState implements ModsGridState {
  factory _ModsGridState(
      {final bool isGroupEnabledExpanded,
      final bool isGroupDisabledExpanded}) = _$ModsGridStateImpl;

  factory _ModsGridState.fromJson(Map<String, dynamic> json) =
      _$ModsGridStateImpl.fromJson;

  @override
  bool get isGroupEnabledExpanded;
  @override
  bool get isGroupDisabledExpanded;

  /// Create a copy of ModsGridState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ModsGridStateImplCopyWith<_$ModsGridStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
