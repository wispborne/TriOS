// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'mod.dart';

class ModMapper extends ClassMapperBase<Mod> {
  ModMapper._();

  static ModMapper? _instance;
  static ModMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ModMapper._());
      ModVariantMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'Mod';

  static String _$id(Mod v) => v.id;
  static const Field<Mod, String> _f$id = Field('id', _$id);
  static bool _$isEnabledInGame(Mod v) => v.isEnabledInGame;
  static const Field<Mod, bool> _f$isEnabledInGame =
      Field('isEnabledInGame', _$isEnabledInGame);
  static List<ModVariant> _$modVariants(Mod v) => v.modVariants;
  static const Field<Mod, List<ModVariant>> _f$modVariants =
      Field('modVariants', _$modVariants);

  @override
  final MappableFields<Mod> fields = const {
    #id: _f$id,
    #isEnabledInGame: _f$isEnabledInGame,
    #modVariants: _f$modVariants,
  };

  static Mod _instantiate(DecodingData data) {
    return Mod(
        id: data.dec(_f$id),
        isEnabledInGame: data.dec(_f$isEnabledInGame),
        modVariants: data.dec(_f$modVariants));
  }

  @override
  final Function instantiate = _instantiate;

  static Mod fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<Mod>(map);
  }

  static Mod fromJson(String json) {
    return ensureInitialized().decodeJson<Mod>(json);
  }
}

mixin ModMappable {
  String toJson() {
    return ModMapper.ensureInitialized().encodeJson<Mod>(this as Mod);
  }

  Map<String, dynamic> toMap() {
    return ModMapper.ensureInitialized().encodeMap<Mod>(this as Mod);
  }

  ModCopyWith<Mod, Mod, Mod> get copyWith =>
      _ModCopyWithImpl(this as Mod, $identity, $identity);
  @override
  String toString() {
    return ModMapper.ensureInitialized().stringifyValue(this as Mod);
  }

  @override
  bool operator ==(Object other) {
    return ModMapper.ensureInitialized().equalsValue(this as Mod, other);
  }

  @override
  int get hashCode {
    return ModMapper.ensureInitialized().hashValue(this as Mod);
  }
}

extension ModValueCopy<$R, $Out> on ObjectCopyWith<$R, Mod, $Out> {
  ModCopyWith<$R, Mod, $Out> get $asMod =>
      $base.as((v, t, t2) => _ModCopyWithImpl(v, t, t2));
}

abstract class ModCopyWith<$R, $In extends Mod, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, ModVariant, ModVariantCopyWith<$R, ModVariant, ModVariant>>
      get modVariants;
  $R call({String? id, bool? isEnabledInGame, List<ModVariant>? modVariants});
  ModCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ModCopyWithImpl<$R, $Out> extends ClassCopyWithBase<$R, Mod, $Out>
    implements ModCopyWith<$R, Mod, $Out> {
  _ModCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<Mod> $mapper = ModMapper.ensureInitialized();
  @override
  ListCopyWith<$R, ModVariant, ModVariantCopyWith<$R, ModVariant, ModVariant>>
      get modVariants => ListCopyWith($value.modVariants,
          (v, t) => v.copyWith.$chain(t), (v) => call(modVariants: v));
  @override
  $R call({String? id, bool? isEnabledInGame, List<ModVariant>? modVariants}) =>
      $apply(FieldCopyWithData({
        if (id != null) #id: id,
        if (isEnabledInGame != null) #isEnabledInGame: isEnabledInGame,
        if (modVariants != null) #modVariants: modVariants
      }));
  @override
  Mod $make(CopyWithData data) => Mod(
      id: data.get(#id, or: $value.id),
      isEnabledInGame: data.get(#isEnabledInGame, or: $value.isEnabledInGame),
      modVariants: data.get(#modVariants, or: $value.modVariants));

  @override
  ModCopyWith<$R2, Mod, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _ModCopyWithImpl($value, $cast, t);
}
