// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'hullmod.dart';

class HullmodMapper extends ClassMapperBase<Hullmod> {
  HullmodMapper._();

  static HullmodMapper? _instance;
  static HullmodMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = HullmodMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'Hullmod';

  static String _$id(Hullmod v) => v.id;
  static const Field<Hullmod, String> _f$id = Field('id', _$id);
  static String? _$name(Hullmod v) => v.name;
  static const Field<Hullmod, String> _f$name = Field(
    'name',
    _$name,
    opt: true,
  );
  static int? _$tier(Hullmod v) => v.tier;
  static const Field<Hullmod, int> _f$tier = Field('tier', _$tier, opt: true);
  static double? _$rarity(Hullmod v) => v.rarity;
  static const Field<Hullmod, double> _f$rarity = Field(
    'rarity',
    _$rarity,
    opt: true,
  );
  static String? _$techManufacturer(Hullmod v) => v.techManufacturer;
  static const Field<Hullmod, String> _f$techManufacturer = Field(
    'techManufacturer',
    _$techManufacturer,
    key: r'tech/manufacturer',
    opt: true,
  );
  static String? _$tags(Hullmod v) => v.tags;
  static const Field<Hullmod, String> _f$tags = Field(
    'tags',
    _$tags,
    opt: true,
  );
  static String? _$uiTags(Hullmod v) => v.uiTags;
  static const Field<Hullmod, String> _f$uiTags = Field(
    'uiTags',
    _$uiTags,
    opt: true,
  );
  static double? _$baseValue(Hullmod v) => v.baseValue;
  static const Field<Hullmod, double> _f$baseValue = Field(
    'baseValue',
    _$baseValue,
    key: r'base value',
    opt: true,
  );
  static bool? _$unlocked(Hullmod v) => v.unlocked;
  static const Field<Hullmod, bool> _f$unlocked = Field(
    'unlocked',
    _$unlocked,
    opt: true,
  );
  static bool? _$hidden(Hullmod v) => v.hidden;
  static const Field<Hullmod, bool> _f$hidden = Field(
    'hidden',
    _$hidden,
    opt: true,
  );
  static bool? _$hiddenEverywhere(Hullmod v) => v.hiddenEverywhere;
  static const Field<Hullmod, bool> _f$hiddenEverywhere = Field(
    'hiddenEverywhere',
    _$hiddenEverywhere,
    opt: true,
  );
  static int? _$costFrigate(Hullmod v) => v.costFrigate;
  static const Field<Hullmod, int> _f$costFrigate = Field(
    'costFrigate',
    _$costFrigate,
    key: r'cost_frigate',
    opt: true,
  );
  static int? _$costDest(Hullmod v) => v.costDest;
  static const Field<Hullmod, int> _f$costDest = Field(
    'costDest',
    _$costDest,
    key: r'cost_dest',
    opt: true,
  );
  static int? _$costCruiser(Hullmod v) => v.costCruiser;
  static const Field<Hullmod, int> _f$costCruiser = Field(
    'costCruiser',
    _$costCruiser,
    key: r'cost_cruiser',
    opt: true,
  );
  static int? _$costCapital(Hullmod v) => v.costCapital;
  static const Field<Hullmod, int> _f$costCapital = Field(
    'costCapital',
    _$costCapital,
    key: r'cost_capital',
    opt: true,
  );
  static String? _$script(Hullmod v) => v.script;
  static const Field<Hullmod, String> _f$script = Field(
    'script',
    _$script,
    opt: true,
  );
  static String? _$desc(Hullmod v) => v.desc;
  static const Field<Hullmod, String> _f$desc = Field(
    'desc',
    _$desc,
    opt: true,
  );
  static String? _$shortDescription(Hullmod v) => v.shortDescription;
  static const Field<Hullmod, String> _f$shortDescription = Field(
    'shortDescription',
    _$shortDescription,
    key: r'short',
    opt: true,
  );
  static String? _$sModDesc(Hullmod v) => v.sModDesc;
  static const Field<Hullmod, String> _f$sModDesc = Field(
    'sModDesc',
    _$sModDesc,
    opt: true,
  );
  static String? _$sprite(Hullmod v) => v.sprite;
  static const Field<Hullmod, String> _f$sprite = Field(
    'sprite',
    _$sprite,
    opt: true,
  );
  static ModVariant? _$modVariant(Hullmod v) => v.modVariant;
  static const Field<Hullmod, ModVariant> _f$modVariant = Field(
    'modVariant',
    _$modVariant,
    hook: SkipSerializationHook(),
  );
  static File _$csvFile(Hullmod v) => v.csvFile;
  static const Field<Hullmod, File> _f$csvFile = Field(
    'csvFile',
    _$csvFile,
    hook: FileHook(),
  );
  static Set<String> _$tagsAsSet(Hullmod v) => v.tagsAsSet;
  static const Field<Hullmod, Set<String>> _f$tagsAsSet = Field(
    'tagsAsSet',
    _$tagsAsSet,
    mode: FieldMode.member,
  );
  static Set<String> _$uiTagsAsSet(Hullmod v) => v.uiTagsAsSet;
  static const Field<Hullmod, Set<String>> _f$uiTagsAsSet = Field(
    'uiTagsAsSet',
    _$uiTagsAsSet,
    mode: FieldMode.member,
  );

  @override
  final MappableFields<Hullmod> fields = const {
    #id: _f$id,
    #name: _f$name,
    #tier: _f$tier,
    #rarity: _f$rarity,
    #techManufacturer: _f$techManufacturer,
    #tags: _f$tags,
    #uiTags: _f$uiTags,
    #baseValue: _f$baseValue,
    #unlocked: _f$unlocked,
    #hidden: _f$hidden,
    #hiddenEverywhere: _f$hiddenEverywhere,
    #costFrigate: _f$costFrigate,
    #costDest: _f$costDest,
    #costCruiser: _f$costCruiser,
    #costCapital: _f$costCapital,
    #script: _f$script,
    #desc: _f$desc,
    #shortDescription: _f$shortDescription,
    #sModDesc: _f$sModDesc,
    #sprite: _f$sprite,
    #modVariant: _f$modVariant,
    #csvFile: _f$csvFile,
    #tagsAsSet: _f$tagsAsSet,
    #uiTagsAsSet: _f$uiTagsAsSet,
  };

  static Hullmod _instantiate(DecodingData data) {
    return Hullmod(
      id: data.dec(_f$id),
      name: data.dec(_f$name),
      tier: data.dec(_f$tier),
      rarity: data.dec(_f$rarity),
      techManufacturer: data.dec(_f$techManufacturer),
      tags: data.dec(_f$tags),
      uiTags: data.dec(_f$uiTags),
      baseValue: data.dec(_f$baseValue),
      unlocked: data.dec(_f$unlocked),
      hidden: data.dec(_f$hidden),
      hiddenEverywhere: data.dec(_f$hiddenEverywhere),
      costFrigate: data.dec(_f$costFrigate),
      costDest: data.dec(_f$costDest),
      costCruiser: data.dec(_f$costCruiser),
      costCapital: data.dec(_f$costCapital),
      script: data.dec(_f$script),
      desc: data.dec(_f$desc),
      shortDescription: data.dec(_f$shortDescription),
      sModDesc: data.dec(_f$sModDesc),
      sprite: data.dec(_f$sprite),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static Hullmod fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<Hullmod>(map);
  }

  static Hullmod fromJson(String json) {
    return ensureInitialized().decodeJson<Hullmod>(json);
  }
}

mixin HullmodMappable {
  String toJson() {
    return HullmodMapper.ensureInitialized().encodeJson<Hullmod>(
      this as Hullmod,
    );
  }

  Map<String, dynamic> toMap() {
    return HullmodMapper.ensureInitialized().encodeMap<Hullmod>(
      this as Hullmod,
    );
  }

  HullmodCopyWith<Hullmod, Hullmod, Hullmod> get copyWith =>
      _HullmodCopyWithImpl<Hullmod, Hullmod>(
        this as Hullmod,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return HullmodMapper.ensureInitialized().stringifyValue(this as Hullmod);
  }

  @override
  bool operator ==(Object other) {
    return HullmodMapper.ensureInitialized().equalsValue(
      this as Hullmod,
      other,
    );
  }

  @override
  int get hashCode {
    return HullmodMapper.ensureInitialized().hashValue(this as Hullmod);
  }
}

extension HullmodValueCopy<$R, $Out> on ObjectCopyWith<$R, Hullmod, $Out> {
  HullmodCopyWith<$R, Hullmod, $Out> get $asHullmod =>
      $base.as((v, t, t2) => _HullmodCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class HullmodCopyWith<$R, $In extends Hullmod, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    String? id,
    String? name,
    int? tier,
    double? rarity,
    String? techManufacturer,
    String? tags,
    String? uiTags,
    double? baseValue,
    bool? unlocked,
    bool? hidden,
    bool? hiddenEverywhere,
    int? costFrigate,
    int? costDest,
    int? costCruiser,
    int? costCapital,
    String? script,
    String? desc,
    String? shortDescription,
    String? sModDesc,
    String? sprite,
  });
  HullmodCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _HullmodCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, Hullmod, $Out>
    implements HullmodCopyWith<$R, Hullmod, $Out> {
  _HullmodCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<Hullmod> $mapper =
      HullmodMapper.ensureInitialized();
  @override
  $R call({
    String? id,
    Object? name = $none,
    Object? tier = $none,
    Object? rarity = $none,
    Object? techManufacturer = $none,
    Object? tags = $none,
    Object? uiTags = $none,
    Object? baseValue = $none,
    Object? unlocked = $none,
    Object? hidden = $none,
    Object? hiddenEverywhere = $none,
    Object? costFrigate = $none,
    Object? costDest = $none,
    Object? costCruiser = $none,
    Object? costCapital = $none,
    Object? script = $none,
    Object? desc = $none,
    Object? shortDescription = $none,
    Object? sModDesc = $none,
    Object? sprite = $none,
  }) => $apply(
    FieldCopyWithData({
      if (id != null) #id: id,
      if (name != $none) #name: name,
      if (tier != $none) #tier: tier,
      if (rarity != $none) #rarity: rarity,
      if (techManufacturer != $none) #techManufacturer: techManufacturer,
      if (tags != $none) #tags: tags,
      if (uiTags != $none) #uiTags: uiTags,
      if (baseValue != $none) #baseValue: baseValue,
      if (unlocked != $none) #unlocked: unlocked,
      if (hidden != $none) #hidden: hidden,
      if (hiddenEverywhere != $none) #hiddenEverywhere: hiddenEverywhere,
      if (costFrigate != $none) #costFrigate: costFrigate,
      if (costDest != $none) #costDest: costDest,
      if (costCruiser != $none) #costCruiser: costCruiser,
      if (costCapital != $none) #costCapital: costCapital,
      if (script != $none) #script: script,
      if (desc != $none) #desc: desc,
      if (shortDescription != $none) #shortDescription: shortDescription,
      if (sModDesc != $none) #sModDesc: sModDesc,
      if (sprite != $none) #sprite: sprite,
    }),
  );
  @override
  Hullmod $make(CopyWithData data) => Hullmod(
    id: data.get(#id, or: $value.id),
    name: data.get(#name, or: $value.name),
    tier: data.get(#tier, or: $value.tier),
    rarity: data.get(#rarity, or: $value.rarity),
    techManufacturer: data.get(#techManufacturer, or: $value.techManufacturer),
    tags: data.get(#tags, or: $value.tags),
    uiTags: data.get(#uiTags, or: $value.uiTags),
    baseValue: data.get(#baseValue, or: $value.baseValue),
    unlocked: data.get(#unlocked, or: $value.unlocked),
    hidden: data.get(#hidden, or: $value.hidden),
    hiddenEverywhere: data.get(#hiddenEverywhere, or: $value.hiddenEverywhere),
    costFrigate: data.get(#costFrigate, or: $value.costFrigate),
    costDest: data.get(#costDest, or: $value.costDest),
    costCruiser: data.get(#costCruiser, or: $value.costCruiser),
    costCapital: data.get(#costCapital, or: $value.costCapital),
    script: data.get(#script, or: $value.script),
    desc: data.get(#desc, or: $value.desc),
    shortDescription: data.get(#shortDescription, or: $value.shortDescription),
    sModDesc: data.get(#sModDesc, or: $value.sModDesc),
    sprite: data.get(#sprite, or: $value.sprite),
  );

  @override
  HullmodCopyWith<$R2, Hullmod, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _HullmodCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

