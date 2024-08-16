// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../models/mod.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$Mod {
  String get id => throw _privateConstructorUsedError;
  bool get isEnabledInGame => throw _privateConstructorUsedError;
  List<ModVariant> get modVariants => throw _privateConstructorUsedError;

  /// Create a copy of Mod
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ModCopyWith<Mod> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ModCopyWith<$Res> {
  factory $ModCopyWith(Mod value, $Res Function(Mod) then) =
      _$ModCopyWithImpl<$Res, Mod>;
  @useResult
  $Res call({String id, bool isEnabledInGame, List<ModVariant> modVariants});
}

/// @nodoc
class _$ModCopyWithImpl<$Res, $Val extends Mod> implements $ModCopyWith<$Res> {
  _$ModCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Mod
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? isEnabledInGame = null,
    Object? modVariants = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      isEnabledInGame: null == isEnabledInGame
          ? _value.isEnabledInGame
          : isEnabledInGame // ignore: cast_nullable_to_non_nullable
              as bool,
      modVariants: null == modVariants
          ? _value.modVariants
          : modVariants // ignore: cast_nullable_to_non_nullable
              as List<ModVariant>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ModImplCopyWith<$Res> implements $ModCopyWith<$Res> {
  factory _$$ModImplCopyWith(_$ModImpl value, $Res Function(_$ModImpl) then) =
      __$$ModImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, bool isEnabledInGame, List<ModVariant> modVariants});
}

/// @nodoc
class __$$ModImplCopyWithImpl<$Res> extends _$ModCopyWithImpl<$Res, _$ModImpl>
    implements _$$ModImplCopyWith<$Res> {
  __$$ModImplCopyWithImpl(_$ModImpl _value, $Res Function(_$ModImpl) _then)
      : super(_value, _then);

  /// Create a copy of Mod
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? isEnabledInGame = null,
    Object? modVariants = null,
  }) {
    return _then(_$ModImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      isEnabledInGame: null == isEnabledInGame
          ? _value.isEnabledInGame
          : isEnabledInGame // ignore: cast_nullable_to_non_nullable
              as bool,
      modVariants: null == modVariants
          ? _value._modVariants
          : modVariants // ignore: cast_nullable_to_non_nullable
              as List<ModVariant>,
    ));
  }
}

/// @nodoc

class _$ModImpl extends _Mod {
  const _$ModImpl(
      {required this.id,
      required this.isEnabledInGame,
      required final List<ModVariant> modVariants})
      : _modVariants = modVariants,
        super._();

  @override
  final String id;
  @override
  final bool isEnabledInGame;
  final List<ModVariant> _modVariants;
  @override
  List<ModVariant> get modVariants {
    if (_modVariants is EqualUnmodifiableListView) return _modVariants;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_modVariants);
  }

  @override
  String toString() {
    return 'Mod(id: $id, isEnabledInGame: $isEnabledInGame, modVariants: $modVariants)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ModImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.isEnabledInGame, isEnabledInGame) ||
                other.isEnabledInGame == isEnabledInGame) &&
            const DeepCollectionEquality()
                .equals(other._modVariants, _modVariants));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, isEnabledInGame,
      const DeepCollectionEquality().hash(_modVariants));

  /// Create a copy of Mod
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ModImplCopyWith<_$ModImpl> get copyWith =>
      __$$ModImplCopyWithImpl<_$ModImpl>(this, _$identity);
}

abstract class _Mod extends Mod {
  const factory _Mod(
      {required final String id,
      required final bool isEnabledInGame,
      required final List<ModVariant> modVariants}) = _$ModImpl;
  const _Mod._() : super._();

  @override
  String get id;
  @override
  bool get isEnabledInGame;
  @override
  List<ModVariant> get modVariants;

  /// Create a copy of Mod
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ModImplCopyWith<_$ModImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
