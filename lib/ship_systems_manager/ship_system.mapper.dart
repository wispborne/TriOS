// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'ship_system.dart';

class ShipSystemMapper extends ClassMapperBase<ShipSystem> {
  ShipSystemMapper._();

  static ShipSystemMapper? _instance;
  static ShipSystemMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ShipSystemMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'ShipSystem';

  static String _$id(ShipSystem v) => v.id;
  static const Field<ShipSystem, String> _f$id = Field('id', _$id);
  static String? _$name(ShipSystem v) => v.name;
  static const Field<ShipSystem, String> _f$name = Field(
    'name',
    _$name,
    opt: true,
  );
  static double? _$fluxPerSecond(ShipSystem v) => v.fluxPerSecond;
  static const Field<ShipSystem, double> _f$fluxPerSecond = Field(
    'fluxPerSecond',
    _$fluxPerSecond,
    key: r'flux/second',
    opt: true,
  );
  static double? _$fsBaseRate(ShipSystem v) => v.fsBaseRate;
  static const Field<ShipSystem, double> _f$fsBaseRate = Field(
    'fsBaseRate',
    _$fsBaseRate,
    key: r'f/s (base rate)',
    opt: true,
  );
  static double? _$fsBaseCap(ShipSystem v) => v.fsBaseCap;
  static const Field<ShipSystem, double> _f$fsBaseCap = Field(
    'fsBaseCap',
    _$fsBaseCap,
    key: r'f/s (base cap)',
    opt: true,
  );
  static double? _$fluxUse(ShipSystem v) => v.fluxUse;
  static const Field<ShipSystem, double> _f$fluxUse = Field(
    'fluxUse',
    _$fluxUse,
    key: r'flux/use',
    opt: true,
  );
  static double? _$fuBaseRate(ShipSystem v) => v.fuBaseRate;
  static const Field<ShipSystem, double> _f$fuBaseRate = Field(
    'fuBaseRate',
    _$fuBaseRate,
    key: r'f/u (base rate)',
    opt: true,
  );
  static double? _$fuBaseCap(ShipSystem v) => v.fuBaseCap;
  static const Field<ShipSystem, double> _f$fuBaseCap = Field(
    'fuBaseCap',
    _$fuBaseCap,
    key: r'f/u (base cap)',
    opt: true,
  );
  static double? _$crUse(ShipSystem v) => v.crUse;
  static const Field<ShipSystem, double> _f$crUse = Field(
    'crUse',
    _$crUse,
    key: r'cr/u',
    opt: true,
  );
  static double? _$maxUses(ShipSystem v) => v.maxUses;
  static const Field<ShipSystem, double> _f$maxUses = Field(
    'maxUses',
    _$maxUses,
    key: r'max uses',
    opt: true,
  );
  static double? _$regen(ShipSystem v) => v.regen;
  static const Field<ShipSystem, double> _f$regen = Field(
    'regen',
    _$regen,
    opt: true,
  );
  static double? _$regenFlat(ShipSystem v) => v.regenFlat;
  static const Field<ShipSystem, double> _f$regenFlat = Field(
    'regenFlat',
    _$regenFlat,
    key: r'regen flat',
    opt: true,
  );
  static double? _$down(ShipSystem v) => v.down;
  static const Field<ShipSystem, double> _f$down = Field(
    'down',
    _$down,
    opt: true,
  );
  static double? _$cooldown(ShipSystem v) => v.cooldown;
  static const Field<ShipSystem, double> _f$cooldown = Field(
    'cooldown',
    _$cooldown,
    opt: true,
  );
  static bool? _$toggle(ShipSystem v) => v.toggle;
  static const Field<ShipSystem, bool> _f$toggle = Field(
    'toggle',
    _$toggle,
    opt: true,
  );
  static bool? _$noDissipation(ShipSystem v) => v.noDissipation;
  static const Field<ShipSystem, bool> _f$noDissipation = Field(
    'noDissipation',
    _$noDissipation,
    opt: true,
  );
  static bool? _$noHardDissipation(ShipSystem v) => v.noHardDissipation;
  static const Field<ShipSystem, bool> _f$noHardDissipation = Field(
    'noHardDissipation',
    _$noHardDissipation,
    opt: true,
  );
  static bool? _$hardFlux(ShipSystem v) => v.hardFlux;
  static const Field<ShipSystem, bool> _f$hardFlux = Field(
    'hardFlux',
    _$hardFlux,
    opt: true,
  );
  static bool? _$noFiring(ShipSystem v) => v.noFiring;
  static const Field<ShipSystem, bool> _f$noFiring = Field(
    'noFiring',
    _$noFiring,
    opt: true,
  );
  static bool? _$noTurning(ShipSystem v) => v.noTurning;
  static const Field<ShipSystem, bool> _f$noTurning = Field(
    'noTurning',
    _$noTurning,
    opt: true,
  );
  static bool? _$noStrafing(ShipSystem v) => v.noStrafing;
  static const Field<ShipSystem, bool> _f$noStrafing = Field(
    'noStrafing',
    _$noStrafing,
    opt: true,
  );
  static bool? _$noAccel(ShipSystem v) => v.noAccel;
  static const Field<ShipSystem, bool> _f$noAccel = Field(
    'noAccel',
    _$noAccel,
    opt: true,
  );
  static bool? _$noShield(ShipSystem v) => v.noShield;
  static const Field<ShipSystem, bool> _f$noShield = Field(
    'noShield',
    _$noShield,
    opt: true,
  );
  static bool? _$noVent(ShipSystem v) => v.noVent;
  static const Field<ShipSystem, bool> _f$noVent = Field(
    'noVent',
    _$noVent,
    opt: true,
  );
  static bool? _$isPhaseCloak(ShipSystem v) => v.isPhaseCloak;
  static const Field<ShipSystem, bool> _f$isPhaseCloak = Field(
    'isPhaseCloak',
    _$isPhaseCloak,
    opt: true,
  );
  static String? _$tags(ShipSystem v) => v.tags;
  static const Field<ShipSystem, String> _f$tags = Field(
    'tags',
    _$tags,
    opt: true,
  );
  static String? _$icon(ShipSystem v) => v.icon;
  static const Field<ShipSystem, String> _f$icon = Field(
    'icon',
    _$icon,
    opt: true,
  );
  static ModVariant? _$modVariant(ShipSystem v) => v.modVariant;
  static const Field<ShipSystem, ModVariant> _f$modVariant = Field(
    'modVariant',
    _$modVariant,
    hook: SkipSerializationHook(),
  );

  @override
  final MappableFields<ShipSystem> fields = const {
    #id: _f$id,
    #name: _f$name,
    #fluxPerSecond: _f$fluxPerSecond,
    #fsBaseRate: _f$fsBaseRate,
    #fsBaseCap: _f$fsBaseCap,
    #fluxUse: _f$fluxUse,
    #fuBaseRate: _f$fuBaseRate,
    #fuBaseCap: _f$fuBaseCap,
    #crUse: _f$crUse,
    #maxUses: _f$maxUses,
    #regen: _f$regen,
    #regenFlat: _f$regenFlat,
    #down: _f$down,
    #cooldown: _f$cooldown,
    #toggle: _f$toggle,
    #noDissipation: _f$noDissipation,
    #noHardDissipation: _f$noHardDissipation,
    #hardFlux: _f$hardFlux,
    #noFiring: _f$noFiring,
    #noTurning: _f$noTurning,
    #noStrafing: _f$noStrafing,
    #noAccel: _f$noAccel,
    #noShield: _f$noShield,
    #noVent: _f$noVent,
    #isPhaseCloak: _f$isPhaseCloak,
    #tags: _f$tags,
    #icon: _f$icon,
    #modVariant: _f$modVariant,
  };

  static ShipSystem _instantiate(DecodingData data) {
    return ShipSystem(
      id: data.dec(_f$id),
      name: data.dec(_f$name),
      fluxPerSecond: data.dec(_f$fluxPerSecond),
      fsBaseRate: data.dec(_f$fsBaseRate),
      fsBaseCap: data.dec(_f$fsBaseCap),
      fluxUse: data.dec(_f$fluxUse),
      fuBaseRate: data.dec(_f$fuBaseRate),
      fuBaseCap: data.dec(_f$fuBaseCap),
      crUse: data.dec(_f$crUse),
      maxUses: data.dec(_f$maxUses),
      regen: data.dec(_f$regen),
      regenFlat: data.dec(_f$regenFlat),
      down: data.dec(_f$down),
      cooldown: data.dec(_f$cooldown),
      toggle: data.dec(_f$toggle),
      noDissipation: data.dec(_f$noDissipation),
      noHardDissipation: data.dec(_f$noHardDissipation),
      hardFlux: data.dec(_f$hardFlux),
      noFiring: data.dec(_f$noFiring),
      noTurning: data.dec(_f$noTurning),
      noStrafing: data.dec(_f$noStrafing),
      noAccel: data.dec(_f$noAccel),
      noShield: data.dec(_f$noShield),
      noVent: data.dec(_f$noVent),
      isPhaseCloak: data.dec(_f$isPhaseCloak),
      tags: data.dec(_f$tags),
      icon: data.dec(_f$icon),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ShipSystem fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ShipSystem>(map);
  }

  static ShipSystem fromJson(String json) {
    return ensureInitialized().decodeJson<ShipSystem>(json);
  }
}

mixin ShipSystemMappable {
  String toJson() {
    return ShipSystemMapper.ensureInitialized().encodeJson<ShipSystem>(
      this as ShipSystem,
    );
  }

  Map<String, dynamic> toMap() {
    return ShipSystemMapper.ensureInitialized().encodeMap<ShipSystem>(
      this as ShipSystem,
    );
  }

  ShipSystemCopyWith<ShipSystem, ShipSystem, ShipSystem> get copyWith =>
      _ShipSystemCopyWithImpl<ShipSystem, ShipSystem>(
        this as ShipSystem,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return ShipSystemMapper.ensureInitialized().stringifyValue(
      this as ShipSystem,
    );
  }

  @override
  bool operator ==(Object other) {
    return ShipSystemMapper.ensureInitialized().equalsValue(
      this as ShipSystem,
      other,
    );
  }

  @override
  int get hashCode {
    return ShipSystemMapper.ensureInitialized().hashValue(this as ShipSystem);
  }
}

extension ShipSystemValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ShipSystem, $Out> {
  ShipSystemCopyWith<$R, ShipSystem, $Out> get $asShipSystem =>
      $base.as((v, t, t2) => _ShipSystemCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ShipSystemCopyWith<$R, $In extends ShipSystem, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    String? id,
    String? name,
    double? fluxPerSecond,
    double? fsBaseRate,
    double? fsBaseCap,
    double? fluxUse,
    double? fuBaseRate,
    double? fuBaseCap,
    double? crUse,
    double? maxUses,
    double? regen,
    double? regenFlat,
    double? down,
    double? cooldown,
    bool? toggle,
    bool? noDissipation,
    bool? noHardDissipation,
    bool? hardFlux,
    bool? noFiring,
    bool? noTurning,
    bool? noStrafing,
    bool? noAccel,
    bool? noShield,
    bool? noVent,
    bool? isPhaseCloak,
    String? tags,
    String? icon,
  });
  ShipSystemCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ShipSystemCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ShipSystem, $Out>
    implements ShipSystemCopyWith<$R, ShipSystem, $Out> {
  _ShipSystemCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ShipSystem> $mapper =
      ShipSystemMapper.ensureInitialized();
  @override
  $R call({
    String? id,
    Object? name = $none,
    Object? fluxPerSecond = $none,
    Object? fsBaseRate = $none,
    Object? fsBaseCap = $none,
    Object? fluxUse = $none,
    Object? fuBaseRate = $none,
    Object? fuBaseCap = $none,
    Object? crUse = $none,
    Object? maxUses = $none,
    Object? regen = $none,
    Object? regenFlat = $none,
    Object? down = $none,
    Object? cooldown = $none,
    Object? toggle = $none,
    Object? noDissipation = $none,
    Object? noHardDissipation = $none,
    Object? hardFlux = $none,
    Object? noFiring = $none,
    Object? noTurning = $none,
    Object? noStrafing = $none,
    Object? noAccel = $none,
    Object? noShield = $none,
    Object? noVent = $none,
    Object? isPhaseCloak = $none,
    Object? tags = $none,
    Object? icon = $none,
  }) => $apply(
    FieldCopyWithData({
      if (id != null) #id: id,
      if (name != $none) #name: name,
      if (fluxPerSecond != $none) #fluxPerSecond: fluxPerSecond,
      if (fsBaseRate != $none) #fsBaseRate: fsBaseRate,
      if (fsBaseCap != $none) #fsBaseCap: fsBaseCap,
      if (fluxUse != $none) #fluxUse: fluxUse,
      if (fuBaseRate != $none) #fuBaseRate: fuBaseRate,
      if (fuBaseCap != $none) #fuBaseCap: fuBaseCap,
      if (crUse != $none) #crUse: crUse,
      if (maxUses != $none) #maxUses: maxUses,
      if (regen != $none) #regen: regen,
      if (regenFlat != $none) #regenFlat: regenFlat,
      if (down != $none) #down: down,
      if (cooldown != $none) #cooldown: cooldown,
      if (toggle != $none) #toggle: toggle,
      if (noDissipation != $none) #noDissipation: noDissipation,
      if (noHardDissipation != $none) #noHardDissipation: noHardDissipation,
      if (hardFlux != $none) #hardFlux: hardFlux,
      if (noFiring != $none) #noFiring: noFiring,
      if (noTurning != $none) #noTurning: noTurning,
      if (noStrafing != $none) #noStrafing: noStrafing,
      if (noAccel != $none) #noAccel: noAccel,
      if (noShield != $none) #noShield: noShield,
      if (noVent != $none) #noVent: noVent,
      if (isPhaseCloak != $none) #isPhaseCloak: isPhaseCloak,
      if (tags != $none) #tags: tags,
      if (icon != $none) #icon: icon,
    }),
  );
  @override
  ShipSystem $make(CopyWithData data) => ShipSystem(
    id: data.get(#id, or: $value.id),
    name: data.get(#name, or: $value.name),
    fluxPerSecond: data.get(#fluxPerSecond, or: $value.fluxPerSecond),
    fsBaseRate: data.get(#fsBaseRate, or: $value.fsBaseRate),
    fsBaseCap: data.get(#fsBaseCap, or: $value.fsBaseCap),
    fluxUse: data.get(#fluxUse, or: $value.fluxUse),
    fuBaseRate: data.get(#fuBaseRate, or: $value.fuBaseRate),
    fuBaseCap: data.get(#fuBaseCap, or: $value.fuBaseCap),
    crUse: data.get(#crUse, or: $value.crUse),
    maxUses: data.get(#maxUses, or: $value.maxUses),
    regen: data.get(#regen, or: $value.regen),
    regenFlat: data.get(#regenFlat, or: $value.regenFlat),
    down: data.get(#down, or: $value.down),
    cooldown: data.get(#cooldown, or: $value.cooldown),
    toggle: data.get(#toggle, or: $value.toggle),
    noDissipation: data.get(#noDissipation, or: $value.noDissipation),
    noHardDissipation: data.get(
      #noHardDissipation,
      or: $value.noHardDissipation,
    ),
    hardFlux: data.get(#hardFlux, or: $value.hardFlux),
    noFiring: data.get(#noFiring, or: $value.noFiring),
    noTurning: data.get(#noTurning, or: $value.noTurning),
    noStrafing: data.get(#noStrafing, or: $value.noStrafing),
    noAccel: data.get(#noAccel, or: $value.noAccel),
    noShield: data.get(#noShield, or: $value.noShield),
    noVent: data.get(#noVent, or: $value.noVent),
    isPhaseCloak: data.get(#isPhaseCloak, or: $value.isPhaseCloak),
    tags: data.get(#tags, or: $value.tags),
    icon: data.get(#icon, or: $value.icon),
  );

  @override
  ShipSystemCopyWith<$R2, ShipSystem, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ShipSystemCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

