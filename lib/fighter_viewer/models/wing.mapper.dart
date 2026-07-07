// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'wing.dart';

class WingMapper extends ClassMapperBase<Wing> {
  WingMapper._();

  static WingMapper? _instance;
  static WingMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = WingMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'Wing';

  static String _$id(Wing v) => v.id;
  static const Field<Wing, String> _f$id = Field('id', _$id);
  static String? _$variant(Wing v) => v.variant;
  static const Field<Wing, String> _f$variant = Field(
    'variant',
    _$variant,
    opt: true,
  );
  static String? _$tags(Wing v) => v.tags;
  static const Field<Wing, String> _f$tags = Field('tags', _$tags, opt: true);
  static int? _$tier(Wing v) => v.tier;
  static const Field<Wing, int> _f$tier = Field('tier', _$tier, opt: true);
  static double? _$rarity(Wing v) => v.rarity;
  static const Field<Wing, double> _f$rarity = Field(
    'rarity',
    _$rarity,
    opt: true,
  );
  static int? _$fleetPts(Wing v) => v.fleetPts;
  static const Field<Wing, int> _f$fleetPts = Field(
    'fleetPts',
    _$fleetPts,
    key: r'fleet pts',
    opt: true,
  );
  static int? _$opCost(Wing v) => v.opCost;
  static const Field<Wing, int> _f$opCost = Field(
    'opCost',
    _$opCost,
    key: r'op cost',
    opt: true,
  );
  static String? _$formation(Wing v) => v.formation;
  static const Field<Wing, String> _f$formation = Field(
    'formation',
    _$formation,
    opt: true,
  );
  static double? _$range(Wing v) => v.range;
  static const Field<Wing, double> _f$range = Field(
    'range',
    _$range,
    opt: true,
  );
  static int? _$numCraft(Wing v) => v.numCraft;
  static const Field<Wing, int> _f$numCraft = Field(
    'numCraft',
    _$numCraft,
    key: r'num',
    opt: true,
  );
  static String? _$role(Wing v) => v.role;
  static const Field<Wing, String> _f$role = Field('role', _$role, opt: true);
  static String? _$roleDesc(Wing v) => v.roleDesc;
  static const Field<Wing, String> _f$roleDesc = Field(
    'roleDesc',
    _$roleDesc,
    key: r'role desc',
    opt: true,
  );
  static int? _$refit(Wing v) => v.refit;
  static const Field<Wing, int> _f$refit = Field('refit', _$refit, opt: true);
  static double? _$baseValue(Wing v) => v.baseValue;
  static const Field<Wing, double> _f$baseValue = Field(
    'baseValue',
    _$baseValue,
    key: r'base value',
    opt: true,
  );
  static String? _$hullId(Wing v) => v.hullId;
  static const Field<Wing, String> _f$hullId = Field(
    'hullId',
    _$hullId,
    hook: SkipSerializationHook(),
  );
  static ModVariant? _$modVariant(Wing v) => v.modVariant;
  static const Field<Wing, ModVariant> _f$modVariant = Field(
    'modVariant',
    _$modVariant,
    hook: SkipSerializationHook(),
  );

  @override
  final MappableFields<Wing> fields = const {
    #id: _f$id,
    #variant: _f$variant,
    #tags: _f$tags,
    #tier: _f$tier,
    #rarity: _f$rarity,
    #fleetPts: _f$fleetPts,
    #opCost: _f$opCost,
    #formation: _f$formation,
    #range: _f$range,
    #numCraft: _f$numCraft,
    #role: _f$role,
    #roleDesc: _f$roleDesc,
    #refit: _f$refit,
    #baseValue: _f$baseValue,
    #hullId: _f$hullId,
    #modVariant: _f$modVariant,
  };

  static Wing _instantiate(DecodingData data) {
    return Wing(
      id: data.dec(_f$id),
      variant: data.dec(_f$variant),
      tags: data.dec(_f$tags),
      tier: data.dec(_f$tier),
      rarity: data.dec(_f$rarity),
      fleetPts: data.dec(_f$fleetPts),
      opCost: data.dec(_f$opCost),
      formation: data.dec(_f$formation),
      range: data.dec(_f$range),
      numCraft: data.dec(_f$numCraft),
      role: data.dec(_f$role),
      roleDesc: data.dec(_f$roleDesc),
      refit: data.dec(_f$refit),
      baseValue: data.dec(_f$baseValue),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static Wing fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<Wing>(map);
  }

  static Wing fromJson(String json) {
    return ensureInitialized().decodeJson<Wing>(json);
  }
}

mixin WingMappable {
  String toJson() {
    return WingMapper.ensureInitialized().encodeJson<Wing>(this as Wing);
  }

  Map<String, dynamic> toMap() {
    return WingMapper.ensureInitialized().encodeMap<Wing>(this as Wing);
  }

  WingCopyWith<Wing, Wing, Wing> get copyWith =>
      _WingCopyWithImpl<Wing, Wing>(this as Wing, $identity, $identity);
  @override
  String toString() {
    return WingMapper.ensureInitialized().stringifyValue(this as Wing);
  }

  @override
  bool operator ==(Object other) {
    return WingMapper.ensureInitialized().equalsValue(this as Wing, other);
  }

  @override
  int get hashCode {
    return WingMapper.ensureInitialized().hashValue(this as Wing);
  }
}

extension WingValueCopy<$R, $Out> on ObjectCopyWith<$R, Wing, $Out> {
  WingCopyWith<$R, Wing, $Out> get $asWing =>
      $base.as((v, t, t2) => _WingCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class WingCopyWith<$R, $In extends Wing, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    String? id,
    String? variant,
    String? tags,
    int? tier,
    double? rarity,
    int? fleetPts,
    int? opCost,
    String? formation,
    double? range,
    int? numCraft,
    String? role,
    String? roleDesc,
    int? refit,
    double? baseValue,
  });
  WingCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _WingCopyWithImpl<$R, $Out> extends ClassCopyWithBase<$R, Wing, $Out>
    implements WingCopyWith<$R, Wing, $Out> {
  _WingCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<Wing> $mapper = WingMapper.ensureInitialized();
  @override
  $R call({
    String? id,
    Object? variant = $none,
    Object? tags = $none,
    Object? tier = $none,
    Object? rarity = $none,
    Object? fleetPts = $none,
    Object? opCost = $none,
    Object? formation = $none,
    Object? range = $none,
    Object? numCraft = $none,
    Object? role = $none,
    Object? roleDesc = $none,
    Object? refit = $none,
    Object? baseValue = $none,
  }) => $apply(
    FieldCopyWithData({
      if (id != null) #id: id,
      if (variant != $none) #variant: variant,
      if (tags != $none) #tags: tags,
      if (tier != $none) #tier: tier,
      if (rarity != $none) #rarity: rarity,
      if (fleetPts != $none) #fleetPts: fleetPts,
      if (opCost != $none) #opCost: opCost,
      if (formation != $none) #formation: formation,
      if (range != $none) #range: range,
      if (numCraft != $none) #numCraft: numCraft,
      if (role != $none) #role: role,
      if (roleDesc != $none) #roleDesc: roleDesc,
      if (refit != $none) #refit: refit,
      if (baseValue != $none) #baseValue: baseValue,
    }),
  );
  @override
  Wing $make(CopyWithData data) => Wing(
    id: data.get(#id, or: $value.id),
    variant: data.get(#variant, or: $value.variant),
    tags: data.get(#tags, or: $value.tags),
    tier: data.get(#tier, or: $value.tier),
    rarity: data.get(#rarity, or: $value.rarity),
    fleetPts: data.get(#fleetPts, or: $value.fleetPts),
    opCost: data.get(#opCost, or: $value.opCost),
    formation: data.get(#formation, or: $value.formation),
    range: data.get(#range, or: $value.range),
    numCraft: data.get(#numCraft, or: $value.numCraft),
    role: data.get(#role, or: $value.role),
    roleDesc: data.get(#roleDesc, or: $value.roleDesc),
    refit: data.get(#refit, or: $value.refit),
    baseValue: data.get(#baseValue, or: $value.baseValue),
  );

  @override
  WingCopyWith<$R2, Wing, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _WingCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

