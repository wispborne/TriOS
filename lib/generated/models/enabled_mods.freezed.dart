// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../models/enabled_mods.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

EnabledMods _$EnabledModsFromJson(Map<String, dynamic> json) {
  return _EnabledMods.fromJson(json);
}

/// @nodoc
mixin _$EnabledMods {
  Set<String> get enabledMods => throw _privateConstructorUsedError;

  /// Serializes this EnabledMods to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of EnabledMods
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EnabledModsCopyWith<EnabledMods> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EnabledModsCopyWith<$Res> {
  factory $EnabledModsCopyWith(
          EnabledMods value, $Res Function(EnabledMods) then) =
      _$EnabledModsCopyWithImpl<$Res, EnabledMods>;
  @useResult
  $Res call({Set<String> enabledMods});
}

/// @nodoc
class _$EnabledModsCopyWithImpl<$Res, $Val extends EnabledMods>
    implements $EnabledModsCopyWith<$Res> {
  _$EnabledModsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EnabledMods
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? enabledMods = null,
  }) {
    return _then(_value.copyWith(
      enabledMods: null == enabledMods
          ? _value.enabledMods
          : enabledMods // ignore: cast_nullable_to_non_nullable
              as Set<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$EnabledModsImplCopyWith<$Res>
    implements $EnabledModsCopyWith<$Res> {
  factory _$$EnabledModsImplCopyWith(
          _$EnabledModsImpl value, $Res Function(_$EnabledModsImpl) then) =
      __$$EnabledModsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({Set<String> enabledMods});
}

/// @nodoc
class __$$EnabledModsImplCopyWithImpl<$Res>
    extends _$EnabledModsCopyWithImpl<$Res, _$EnabledModsImpl>
    implements _$$EnabledModsImplCopyWith<$Res> {
  __$$EnabledModsImplCopyWithImpl(
      _$EnabledModsImpl _value, $Res Function(_$EnabledModsImpl) _then)
      : super(_value, _then);

  /// Create a copy of EnabledMods
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? enabledMods = null,
  }) {
    return _then(_$EnabledModsImpl(
      null == enabledMods
          ? _value._enabledMods
          : enabledMods // ignore: cast_nullable_to_non_nullable
              as Set<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$EnabledModsImpl implements _EnabledMods {
  const _$EnabledModsImpl(final Set<String> enabledMods)
      : _enabledMods = enabledMods;

  factory _$EnabledModsImpl.fromJson(Map<String, dynamic> json) =>
      _$$EnabledModsImplFromJson(json);

  final Set<String> _enabledMods;
  @override
  Set<String> get enabledMods {
    if (_enabledMods is EqualUnmodifiableSetView) return _enabledMods;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_enabledMods);
  }

  @override
  String toString() {
    return 'EnabledMods(enabledMods: $enabledMods)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EnabledModsImpl &&
            const DeepCollectionEquality()
                .equals(other._enabledMods, _enabledMods));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, const DeepCollectionEquality().hash(_enabledMods));

  /// Create a copy of EnabledMods
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EnabledModsImplCopyWith<_$EnabledModsImpl> get copyWith =>
      __$$EnabledModsImplCopyWithImpl<_$EnabledModsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$EnabledModsImplToJson(
      this,
    );
  }
}

abstract class _EnabledMods implements EnabledMods {
  const factory _EnabledMods(final Set<String> enabledMods) = _$EnabledModsImpl;

  factory _EnabledMods.fromJson(Map<String, dynamic> json) =
      _$EnabledModsImpl.fromJson;

  @override
  Set<String> get enabledMods;

  /// Create a copy of EnabledMods
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EnabledModsImplCopyWith<_$EnabledModsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
