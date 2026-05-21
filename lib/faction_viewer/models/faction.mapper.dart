// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'faction.dart';

class FactionMapper extends ClassMapperBase<Faction> {
  FactionMapper._();

  static FactionMapper? _instance;
  static FactionMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = FactionMapper._());
      FactionDoctrineMapper.ensureInitialized();
      FactionSourceMapper.ensureInitialized();
      SourceContributionMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'Faction';

  static String _$id(Faction v) => v.id;
  static const Field<Faction, String> _f$id = Field('id', _$id);
  static String _$displayName(Faction v) => v.displayName;
  static const Field<Faction, String> _f$displayName = Field(
    'displayName',
    _$displayName,
  );
  static String? _$displayNameWithArticle(Faction v) =>
      v.displayNameWithArticle;
  static const Field<Faction, String> _f$displayNameWithArticle = Field(
    'displayNameWithArticle',
    _$displayNameWithArticle,
    opt: true,
  );
  static String? _$displayNameLong(Faction v) => v.displayNameLong;
  static const Field<Faction, String> _f$displayNameLong = Field(
    'displayNameLong',
    _$displayNameLong,
    opt: true,
  );
  static String? _$displayNameLongWithArticle(Faction v) =>
      v.displayNameLongWithArticle;
  static const Field<Faction, String> _f$displayNameLongWithArticle = Field(
    'displayNameLongWithArticle',
    _$displayNameLongWithArticle,
    opt: true,
  );
  static List<int> _$color(Faction v) => v.color;
  static const Field<Faction, List<int>> _f$color = Field(
    'color',
    _$color,
    opt: true,
    def: const [255, 255, 255, 255],
  );
  static List<int>? _$baseUIColor(Faction v) => v.baseUIColor;
  static const Field<Faction, List<int>> _f$baseUIColor = Field(
    'baseUIColor',
    _$baseUIColor,
    opt: true,
  );
  static List<int>? _$darkUIColor(Faction v) => v.darkUIColor;
  static const Field<Faction, List<int>> _f$darkUIColor = Field(
    'darkUIColor',
    _$darkUIColor,
    opt: true,
  );
  static List<int>? _$gridUIColor(Faction v) => v.gridUIColor;
  static const Field<Faction, List<int>> _f$gridUIColor = Field(
    'gridUIColor',
    _$gridUIColor,
    opt: true,
  );
  static List<int>? _$brightUIColor(Faction v) => v.brightUIColor;
  static const Field<Faction, List<int>> _f$brightUIColor = Field(
    'brightUIColor',
    _$brightUIColor,
    opt: true,
  );
  static String? _$logo(Faction v) => v.logo;
  static const Field<Faction, String> _f$logo = Field(
    'logo',
    _$logo,
    opt: true,
  );
  static String? _$crest(Faction v) => v.crest;
  static const Field<Faction, String> _f$crest = Field(
    'crest',
    _$crest,
    opt: true,
  );
  static bool _$showInIntelTab(Faction v) => v.showInIntelTab;
  static const Field<Faction, bool> _f$showInIntelTab = Field(
    'showInIntelTab',
    _$showInIntelTab,
    opt: true,
    def: true,
  );
  static String? _$shipNamePrefix(Faction v) => v.shipNamePrefix;
  static const Field<Faction, String> _f$shipNamePrefix = Field(
    'shipNamePrefix',
    _$shipNamePrefix,
    opt: true,
  );
  static Map<String, dynamic>? _$shipNameSources(Faction v) =>
      v.shipNameSources;
  static const Field<Faction, Map<String, dynamic>> _f$shipNameSources = Field(
    'shipNameSources',
    _$shipNameSources,
    opt: true,
  );
  static FactionDoctrine? _$doctrine(Faction v) => v.doctrine;
  static const Field<Faction, FactionDoctrine> _f$doctrine = Field(
    'doctrine',
    _$doctrine,
    opt: true,
  );
  static List<String> _$knownShipIds(Faction v) => v.knownShipIds;
  static const Field<Faction, List<String>> _f$knownShipIds = Field(
    'knownShipIds',
    _$knownShipIds,
    opt: true,
    def: const [],
  );
  static List<String> _$priorityShipIds(Faction v) => v.priorityShipIds;
  static const Field<Faction, List<String>> _f$priorityShipIds = Field(
    'priorityShipIds',
    _$priorityShipIds,
    opt: true,
    def: const [],
  );
  static List<String> _$knownWeaponIds(Faction v) => v.knownWeaponIds;
  static const Field<Faction, List<String>> _f$knownWeaponIds = Field(
    'knownWeaponIds',
    _$knownWeaponIds,
    opt: true,
    def: const [],
  );
  static List<String> _$priorityWeaponIds(Faction v) => v.priorityWeaponIds;
  static const Field<Faction, List<String>> _f$priorityWeaponIds = Field(
    'priorityWeaponIds',
    _$priorityWeaponIds,
    opt: true,
    def: const [],
  );
  static List<String> _$knownFighterIds(Faction v) => v.knownFighterIds;
  static const Field<Faction, List<String>> _f$knownFighterIds = Field(
    'knownFighterIds',
    _$knownFighterIds,
    opt: true,
    def: const [],
  );
  static List<String> _$priorityFighterIds(Faction v) => v.priorityFighterIds;
  static const Field<Faction, List<String>> _f$priorityFighterIds = Field(
    'priorityFighterIds',
    _$priorityFighterIds,
    opt: true,
    def: const [],
  );
  static List<String> _$knownHullModIds(Faction v) => v.knownHullModIds;
  static const Field<Faction, List<String>> _f$knownHullModIds = Field(
    'knownHullModIds',
    _$knownHullModIds,
    opt: true,
    def: const [],
  );
  static List<String> _$knownShipTags(Faction v) => v.knownShipTags;
  static const Field<Faction, List<String>> _f$knownShipTags = Field(
    'knownShipTags',
    _$knownShipTags,
    opt: true,
    def: const [],
  );
  static List<String> _$knownWeaponTags(Faction v) => v.knownWeaponTags;
  static const Field<Faction, List<String>> _f$knownWeaponTags = Field(
    'knownWeaponTags',
    _$knownWeaponTags,
    opt: true,
    def: const [],
  );
  static List<String> _$knownFighterTags(Faction v) => v.knownFighterTags;
  static const Field<Faction, List<String>> _f$knownFighterTags = Field(
    'knownFighterTags',
    _$knownFighterTags,
    opt: true,
    def: const [],
  );
  static List<String> _$knownHullModTags(Faction v) => v.knownHullModTags;
  static const Field<Faction, List<String>> _f$knownHullModTags = Field(
    'knownHullModTags',
    _$knownHullModTags,
    opt: true,
    def: const [],
  );
  static List<String> _$malePortraits(Faction v) => v.malePortraits;
  static const Field<Faction, List<String>> _f$malePortraits = Field(
    'malePortraits',
    _$malePortraits,
    opt: true,
    def: const [],
  );
  static List<String> _$femalePortraits(Faction v) => v.femalePortraits;
  static const Field<Faction, List<String>> _f$femalePortraits = Field(
    'femalePortraits',
    _$femalePortraits,
    opt: true,
    def: const [],
  );
  static List<String> _$illegalCommodities(Faction v) => v.illegalCommodities;
  static const Field<Faction, List<String>> _f$illegalCommodities = Field(
    'illegalCommodities',
    _$illegalCommodities,
    opt: true,
    def: const [],
  );
  static Map<String, dynamic> _$customFlags(Faction v) => v.customFlags;
  static const Field<Faction, Map<String, dynamic>> _f$customFlags = Field(
    'customFlags',
    _$customFlags,
    opt: true,
    def: const {},
  );
  static Map<String, String>? _$music(Faction v) => v.music;
  static const Field<Faction, Map<String, String>> _f$music = Field(
    'music',
    _$music,
    opt: true,
  );
  static List<FactionSource> _$sources(Faction v) => v.sources;
  static const Field<Faction, List<FactionSource>> _f$sources = Field(
    'sources',
    _$sources,
    opt: true,
    def: const [],
    hook: SkipSerializationHook(),
  );
  static Map<String, List<SourceContribution>> _$sectionAttributions(
    Faction v,
  ) => v.sectionAttributions;
  static const Field<Faction, Map<String, List<SourceContribution>>>
  _f$sectionAttributions = Field(
    'sectionAttributions',
    _$sectionAttributions,
    opt: true,
    def: const {},
    hook: SkipSerializationHook(),
  );
  static Map<String, Map<String, String>> _$itemAttributions(Faction v) =>
      v.itemAttributions;
  static const Field<Faction, Map<String, Map<String, String>>>
  _f$itemAttributions = Field(
    'itemAttributions',
    _$itemAttributions,
    opt: true,
    def: const {},
    hook: SkipSerializationHook(),
  );

  @override
  final MappableFields<Faction> fields = const {
    #id: _f$id,
    #displayName: _f$displayName,
    #displayNameWithArticle: _f$displayNameWithArticle,
    #displayNameLong: _f$displayNameLong,
    #displayNameLongWithArticle: _f$displayNameLongWithArticle,
    #color: _f$color,
    #baseUIColor: _f$baseUIColor,
    #darkUIColor: _f$darkUIColor,
    #gridUIColor: _f$gridUIColor,
    #brightUIColor: _f$brightUIColor,
    #logo: _f$logo,
    #crest: _f$crest,
    #showInIntelTab: _f$showInIntelTab,
    #shipNamePrefix: _f$shipNamePrefix,
    #shipNameSources: _f$shipNameSources,
    #doctrine: _f$doctrine,
    #knownShipIds: _f$knownShipIds,
    #priorityShipIds: _f$priorityShipIds,
    #knownWeaponIds: _f$knownWeaponIds,
    #priorityWeaponIds: _f$priorityWeaponIds,
    #knownFighterIds: _f$knownFighterIds,
    #priorityFighterIds: _f$priorityFighterIds,
    #knownHullModIds: _f$knownHullModIds,
    #knownShipTags: _f$knownShipTags,
    #knownWeaponTags: _f$knownWeaponTags,
    #knownFighterTags: _f$knownFighterTags,
    #knownHullModTags: _f$knownHullModTags,
    #malePortraits: _f$malePortraits,
    #femalePortraits: _f$femalePortraits,
    #illegalCommodities: _f$illegalCommodities,
    #customFlags: _f$customFlags,
    #music: _f$music,
    #sources: _f$sources,
    #sectionAttributions: _f$sectionAttributions,
    #itemAttributions: _f$itemAttributions,
  };

  static Faction _instantiate(DecodingData data) {
    return Faction(
      id: data.dec(_f$id),
      displayName: data.dec(_f$displayName),
      displayNameWithArticle: data.dec(_f$displayNameWithArticle),
      displayNameLong: data.dec(_f$displayNameLong),
      displayNameLongWithArticle: data.dec(_f$displayNameLongWithArticle),
      color: data.dec(_f$color),
      baseUIColor: data.dec(_f$baseUIColor),
      darkUIColor: data.dec(_f$darkUIColor),
      gridUIColor: data.dec(_f$gridUIColor),
      brightUIColor: data.dec(_f$brightUIColor),
      logo: data.dec(_f$logo),
      crest: data.dec(_f$crest),
      showInIntelTab: data.dec(_f$showInIntelTab),
      shipNamePrefix: data.dec(_f$shipNamePrefix),
      shipNameSources: data.dec(_f$shipNameSources),
      doctrine: data.dec(_f$doctrine),
      knownShipIds: data.dec(_f$knownShipIds),
      priorityShipIds: data.dec(_f$priorityShipIds),
      knownWeaponIds: data.dec(_f$knownWeaponIds),
      priorityWeaponIds: data.dec(_f$priorityWeaponIds),
      knownFighterIds: data.dec(_f$knownFighterIds),
      priorityFighterIds: data.dec(_f$priorityFighterIds),
      knownHullModIds: data.dec(_f$knownHullModIds),
      knownShipTags: data.dec(_f$knownShipTags),
      knownWeaponTags: data.dec(_f$knownWeaponTags),
      knownFighterTags: data.dec(_f$knownFighterTags),
      knownHullModTags: data.dec(_f$knownHullModTags),
      malePortraits: data.dec(_f$malePortraits),
      femalePortraits: data.dec(_f$femalePortraits),
      illegalCommodities: data.dec(_f$illegalCommodities),
      customFlags: data.dec(_f$customFlags),
      music: data.dec(_f$music),
      sources: data.dec(_f$sources),
      sectionAttributions: data.dec(_f$sectionAttributions),
      itemAttributions: data.dec(_f$itemAttributions),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static Faction fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<Faction>(map);
  }

  static Faction fromJson(String json) {
    return ensureInitialized().decodeJson<Faction>(json);
  }
}

mixin FactionMappable {
  String toJson() {
    return FactionMapper.ensureInitialized().encodeJson<Faction>(
      this as Faction,
    );
  }

  Map<String, dynamic> toMap() {
    return FactionMapper.ensureInitialized().encodeMap<Faction>(
      this as Faction,
    );
  }

  FactionCopyWith<Faction, Faction, Faction> get copyWith =>
      _FactionCopyWithImpl<Faction, Faction>(
        this as Faction,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return FactionMapper.ensureInitialized().stringifyValue(this as Faction);
  }

  @override
  bool operator ==(Object other) {
    return FactionMapper.ensureInitialized().equalsValue(
      this as Faction,
      other,
    );
  }

  @override
  int get hashCode {
    return FactionMapper.ensureInitialized().hashValue(this as Faction);
  }
}

extension FactionValueCopy<$R, $Out> on ObjectCopyWith<$R, Faction, $Out> {
  FactionCopyWith<$R, Faction, $Out> get $asFaction =>
      $base.as((v, t, t2) => _FactionCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class FactionCopyWith<$R, $In extends Faction, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, int, ObjectCopyWith<$R, int, int>> get color;
  ListCopyWith<$R, int, ObjectCopyWith<$R, int, int>>? get baseUIColor;
  ListCopyWith<$R, int, ObjectCopyWith<$R, int, int>>? get darkUIColor;
  ListCopyWith<$R, int, ObjectCopyWith<$R, int, int>>? get gridUIColor;
  ListCopyWith<$R, int, ObjectCopyWith<$R, int, int>>? get brightUIColor;
  MapCopyWith<$R, String, dynamic, ObjectCopyWith<$R, dynamic, dynamic>?>?
  get shipNameSources;
  FactionDoctrineCopyWith<$R, FactionDoctrine, FactionDoctrine>? get doctrine;
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get knownShipIds;
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>
  get priorityShipIds;
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>
  get knownWeaponIds;
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>
  get priorityWeaponIds;
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>
  get knownFighterIds;
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>
  get priorityFighterIds;
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>
  get knownHullModIds;
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>
  get knownShipTags;
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>
  get knownWeaponTags;
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>
  get knownFighterTags;
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>
  get knownHullModTags;
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>
  get malePortraits;
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>
  get femalePortraits;
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>
  get illegalCommodities;
  MapCopyWith<$R, String, dynamic, ObjectCopyWith<$R, dynamic, dynamic>?>
  get customFlags;
  MapCopyWith<$R, String, String, ObjectCopyWith<$R, String, String>>?
  get music;
  ListCopyWith<
    $R,
    FactionSource,
    FactionSourceCopyWith<$R, FactionSource, FactionSource>
  >
  get sources;
  MapCopyWith<
    $R,
    String,
    List<SourceContribution>,
    ObjectCopyWith<$R, List<SourceContribution>, List<SourceContribution>>
  >
  get sectionAttributions;
  MapCopyWith<
    $R,
    String,
    Map<String, String>,
    ObjectCopyWith<$R, Map<String, String>, Map<String, String>>
  >
  get itemAttributions;
  $R call({
    String? id,
    String? displayName,
    String? displayNameWithArticle,
    String? displayNameLong,
    String? displayNameLongWithArticle,
    List<int>? color,
    List<int>? baseUIColor,
    List<int>? darkUIColor,
    List<int>? gridUIColor,
    List<int>? brightUIColor,
    String? logo,
    String? crest,
    bool? showInIntelTab,
    String? shipNamePrefix,
    Map<String, dynamic>? shipNameSources,
    FactionDoctrine? doctrine,
    List<String>? knownShipIds,
    List<String>? priorityShipIds,
    List<String>? knownWeaponIds,
    List<String>? priorityWeaponIds,
    List<String>? knownFighterIds,
    List<String>? priorityFighterIds,
    List<String>? knownHullModIds,
    List<String>? knownShipTags,
    List<String>? knownWeaponTags,
    List<String>? knownFighterTags,
    List<String>? knownHullModTags,
    List<String>? malePortraits,
    List<String>? femalePortraits,
    List<String>? illegalCommodities,
    Map<String, dynamic>? customFlags,
    Map<String, String>? music,
    List<FactionSource>? sources,
    Map<String, List<SourceContribution>>? sectionAttributions,
    Map<String, Map<String, String>>? itemAttributions,
  });
  FactionCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _FactionCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, Faction, $Out>
    implements FactionCopyWith<$R, Faction, $Out> {
  _FactionCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<Faction> $mapper =
      FactionMapper.ensureInitialized();
  @override
  ListCopyWith<$R, int, ObjectCopyWith<$R, int, int>> get color => ListCopyWith(
    $value.color,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(color: v),
  );
  @override
  ListCopyWith<$R, int, ObjectCopyWith<$R, int, int>>? get baseUIColor =>
      $value.baseUIColor != null
      ? ListCopyWith(
          $value.baseUIColor!,
          (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(baseUIColor: v),
        )
      : null;
  @override
  ListCopyWith<$R, int, ObjectCopyWith<$R, int, int>>? get darkUIColor =>
      $value.darkUIColor != null
      ? ListCopyWith(
          $value.darkUIColor!,
          (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(darkUIColor: v),
        )
      : null;
  @override
  ListCopyWith<$R, int, ObjectCopyWith<$R, int, int>>? get gridUIColor =>
      $value.gridUIColor != null
      ? ListCopyWith(
          $value.gridUIColor!,
          (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(gridUIColor: v),
        )
      : null;
  @override
  ListCopyWith<$R, int, ObjectCopyWith<$R, int, int>>? get brightUIColor =>
      $value.brightUIColor != null
      ? ListCopyWith(
          $value.brightUIColor!,
          (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(brightUIColor: v),
        )
      : null;
  @override
  MapCopyWith<$R, String, dynamic, ObjectCopyWith<$R, dynamic, dynamic>?>?
  get shipNameSources => $value.shipNameSources != null
      ? MapCopyWith(
          $value.shipNameSources!,
          (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(shipNameSources: v),
        )
      : null;
  @override
  FactionDoctrineCopyWith<$R, FactionDoctrine, FactionDoctrine>? get doctrine =>
      $value.doctrine?.copyWith.$chain((v) => call(doctrine: v));
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>
  get knownShipIds => ListCopyWith(
    $value.knownShipIds,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(knownShipIds: v),
  );
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>
  get priorityShipIds => ListCopyWith(
    $value.priorityShipIds,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(priorityShipIds: v),
  );
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>
  get knownWeaponIds => ListCopyWith(
    $value.knownWeaponIds,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(knownWeaponIds: v),
  );
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>
  get priorityWeaponIds => ListCopyWith(
    $value.priorityWeaponIds,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(priorityWeaponIds: v),
  );
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>
  get knownFighterIds => ListCopyWith(
    $value.knownFighterIds,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(knownFighterIds: v),
  );
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>
  get priorityFighterIds => ListCopyWith(
    $value.priorityFighterIds,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(priorityFighterIds: v),
  );
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>
  get knownHullModIds => ListCopyWith(
    $value.knownHullModIds,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(knownHullModIds: v),
  );
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>
  get knownShipTags => ListCopyWith(
    $value.knownShipTags,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(knownShipTags: v),
  );
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>
  get knownWeaponTags => ListCopyWith(
    $value.knownWeaponTags,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(knownWeaponTags: v),
  );
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>
  get knownFighterTags => ListCopyWith(
    $value.knownFighterTags,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(knownFighterTags: v),
  );
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>
  get knownHullModTags => ListCopyWith(
    $value.knownHullModTags,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(knownHullModTags: v),
  );
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>
  get malePortraits => ListCopyWith(
    $value.malePortraits,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(malePortraits: v),
  );
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>
  get femalePortraits => ListCopyWith(
    $value.femalePortraits,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(femalePortraits: v),
  );
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>
  get illegalCommodities => ListCopyWith(
    $value.illegalCommodities,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(illegalCommodities: v),
  );
  @override
  MapCopyWith<$R, String, dynamic, ObjectCopyWith<$R, dynamic, dynamic>?>
  get customFlags => MapCopyWith(
    $value.customFlags,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(customFlags: v),
  );
  @override
  MapCopyWith<$R, String, String, ObjectCopyWith<$R, String, String>>?
  get music => $value.music != null
      ? MapCopyWith(
          $value.music!,
          (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(music: v),
        )
      : null;
  @override
  ListCopyWith<
    $R,
    FactionSource,
    FactionSourceCopyWith<$R, FactionSource, FactionSource>
  >
  get sources => ListCopyWith(
    $value.sources,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(sources: v),
  );
  @override
  MapCopyWith<
    $R,
    String,
    List<SourceContribution>,
    ObjectCopyWith<$R, List<SourceContribution>, List<SourceContribution>>
  >
  get sectionAttributions => MapCopyWith(
    $value.sectionAttributions,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(sectionAttributions: v),
  );
  @override
  MapCopyWith<
    $R,
    String,
    Map<String, String>,
    ObjectCopyWith<$R, Map<String, String>, Map<String, String>>
  >
  get itemAttributions => MapCopyWith(
    $value.itemAttributions,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(itemAttributions: v),
  );
  @override
  $R call({
    String? id,
    String? displayName,
    Object? displayNameWithArticle = $none,
    Object? displayNameLong = $none,
    Object? displayNameLongWithArticle = $none,
    List<int>? color,
    Object? baseUIColor = $none,
    Object? darkUIColor = $none,
    Object? gridUIColor = $none,
    Object? brightUIColor = $none,
    Object? logo = $none,
    Object? crest = $none,
    bool? showInIntelTab,
    Object? shipNamePrefix = $none,
    Object? shipNameSources = $none,
    Object? doctrine = $none,
    List<String>? knownShipIds,
    List<String>? priorityShipIds,
    List<String>? knownWeaponIds,
    List<String>? priorityWeaponIds,
    List<String>? knownFighterIds,
    List<String>? priorityFighterIds,
    List<String>? knownHullModIds,
    List<String>? knownShipTags,
    List<String>? knownWeaponTags,
    List<String>? knownFighterTags,
    List<String>? knownHullModTags,
    List<String>? malePortraits,
    List<String>? femalePortraits,
    List<String>? illegalCommodities,
    Map<String, dynamic>? customFlags,
    Object? music = $none,
    List<FactionSource>? sources,
    Map<String, List<SourceContribution>>? sectionAttributions,
    Map<String, Map<String, String>>? itemAttributions,
  }) => $apply(
    FieldCopyWithData({
      if (id != null) #id: id,
      if (displayName != null) #displayName: displayName,
      if (displayNameWithArticle != $none)
        #displayNameWithArticle: displayNameWithArticle,
      if (displayNameLong != $none) #displayNameLong: displayNameLong,
      if (displayNameLongWithArticle != $none)
        #displayNameLongWithArticle: displayNameLongWithArticle,
      if (color != null) #color: color,
      if (baseUIColor != $none) #baseUIColor: baseUIColor,
      if (darkUIColor != $none) #darkUIColor: darkUIColor,
      if (gridUIColor != $none) #gridUIColor: gridUIColor,
      if (brightUIColor != $none) #brightUIColor: brightUIColor,
      if (logo != $none) #logo: logo,
      if (crest != $none) #crest: crest,
      if (showInIntelTab != null) #showInIntelTab: showInIntelTab,
      if (shipNamePrefix != $none) #shipNamePrefix: shipNamePrefix,
      if (shipNameSources != $none) #shipNameSources: shipNameSources,
      if (doctrine != $none) #doctrine: doctrine,
      if (knownShipIds != null) #knownShipIds: knownShipIds,
      if (priorityShipIds != null) #priorityShipIds: priorityShipIds,
      if (knownWeaponIds != null) #knownWeaponIds: knownWeaponIds,
      if (priorityWeaponIds != null) #priorityWeaponIds: priorityWeaponIds,
      if (knownFighterIds != null) #knownFighterIds: knownFighterIds,
      if (priorityFighterIds != null) #priorityFighterIds: priorityFighterIds,
      if (knownHullModIds != null) #knownHullModIds: knownHullModIds,
      if (knownShipTags != null) #knownShipTags: knownShipTags,
      if (knownWeaponTags != null) #knownWeaponTags: knownWeaponTags,
      if (knownFighterTags != null) #knownFighterTags: knownFighterTags,
      if (knownHullModTags != null) #knownHullModTags: knownHullModTags,
      if (malePortraits != null) #malePortraits: malePortraits,
      if (femalePortraits != null) #femalePortraits: femalePortraits,
      if (illegalCommodities != null) #illegalCommodities: illegalCommodities,
      if (customFlags != null) #customFlags: customFlags,
      if (music != $none) #music: music,
      if (sources != null) #sources: sources,
      if (sectionAttributions != null)
        #sectionAttributions: sectionAttributions,
      if (itemAttributions != null) #itemAttributions: itemAttributions,
    }),
  );
  @override
  Faction $make(CopyWithData data) => Faction(
    id: data.get(#id, or: $value.id),
    displayName: data.get(#displayName, or: $value.displayName),
    displayNameWithArticle: data.get(
      #displayNameWithArticle,
      or: $value.displayNameWithArticle,
    ),
    displayNameLong: data.get(#displayNameLong, or: $value.displayNameLong),
    displayNameLongWithArticle: data.get(
      #displayNameLongWithArticle,
      or: $value.displayNameLongWithArticle,
    ),
    color: data.get(#color, or: $value.color),
    baseUIColor: data.get(#baseUIColor, or: $value.baseUIColor),
    darkUIColor: data.get(#darkUIColor, or: $value.darkUIColor),
    gridUIColor: data.get(#gridUIColor, or: $value.gridUIColor),
    brightUIColor: data.get(#brightUIColor, or: $value.brightUIColor),
    logo: data.get(#logo, or: $value.logo),
    crest: data.get(#crest, or: $value.crest),
    showInIntelTab: data.get(#showInIntelTab, or: $value.showInIntelTab),
    shipNamePrefix: data.get(#shipNamePrefix, or: $value.shipNamePrefix),
    shipNameSources: data.get(#shipNameSources, or: $value.shipNameSources),
    doctrine: data.get(#doctrine, or: $value.doctrine),
    knownShipIds: data.get(#knownShipIds, or: $value.knownShipIds),
    priorityShipIds: data.get(#priorityShipIds, or: $value.priorityShipIds),
    knownWeaponIds: data.get(#knownWeaponIds, or: $value.knownWeaponIds),
    priorityWeaponIds: data.get(
      #priorityWeaponIds,
      or: $value.priorityWeaponIds,
    ),
    knownFighterIds: data.get(#knownFighterIds, or: $value.knownFighterIds),
    priorityFighterIds: data.get(
      #priorityFighterIds,
      or: $value.priorityFighterIds,
    ),
    knownHullModIds: data.get(#knownHullModIds, or: $value.knownHullModIds),
    knownShipTags: data.get(#knownShipTags, or: $value.knownShipTags),
    knownWeaponTags: data.get(#knownWeaponTags, or: $value.knownWeaponTags),
    knownFighterTags: data.get(#knownFighterTags, or: $value.knownFighterTags),
    knownHullModTags: data.get(#knownHullModTags, or: $value.knownHullModTags),
    malePortraits: data.get(#malePortraits, or: $value.malePortraits),
    femalePortraits: data.get(#femalePortraits, or: $value.femalePortraits),
    illegalCommodities: data.get(
      #illegalCommodities,
      or: $value.illegalCommodities,
    ),
    customFlags: data.get(#customFlags, or: $value.customFlags),
    music: data.get(#music, or: $value.music),
    sources: data.get(#sources, or: $value.sources),
    sectionAttributions: data.get(
      #sectionAttributions,
      or: $value.sectionAttributions,
    ),
    itemAttributions: data.get(#itemAttributions, or: $value.itemAttributions),
  );

  @override
  FactionCopyWith<$R2, Faction, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _FactionCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class FactionDoctrineMapper extends ClassMapperBase<FactionDoctrine> {
  FactionDoctrineMapper._();

  static FactionDoctrineMapper? _instance;
  static FactionDoctrineMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = FactionDoctrineMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'FactionDoctrine';

  static int _$warships(FactionDoctrine v) => v.warships;
  static const Field<FactionDoctrine, int> _f$warships = Field(
    'warships',
    _$warships,
    opt: true,
    def: 0,
  );
  static int _$carriers(FactionDoctrine v) => v.carriers;
  static const Field<FactionDoctrine, int> _f$carriers = Field(
    'carriers',
    _$carriers,
    opt: true,
    def: 0,
  );
  static int _$phaseShips(FactionDoctrine v) => v.phaseShips;
  static const Field<FactionDoctrine, int> _f$phaseShips = Field(
    'phaseShips',
    _$phaseShips,
    opt: true,
    def: 0,
  );
  static int _$officerQuality(FactionDoctrine v) => v.officerQuality;
  static const Field<FactionDoctrine, int> _f$officerQuality = Field(
    'officerQuality',
    _$officerQuality,
    opt: true,
    def: 0,
  );
  static int _$shipQuality(FactionDoctrine v) => v.shipQuality;
  static const Field<FactionDoctrine, int> _f$shipQuality = Field(
    'shipQuality',
    _$shipQuality,
    opt: true,
    def: 0,
  );
  static int _$numShips(FactionDoctrine v) => v.numShips;
  static const Field<FactionDoctrine, int> _f$numShips = Field(
    'numShips',
    _$numShips,
    opt: true,
    def: 0,
  );
  static int _$shipSize(FactionDoctrine v) => v.shipSize;
  static const Field<FactionDoctrine, int> _f$shipSize = Field(
    'shipSize',
    _$shipSize,
    opt: true,
    def: 0,
  );
  static int _$aggression(FactionDoctrine v) => v.aggression;
  static const Field<FactionDoctrine, int> _f$aggression = Field(
    'aggression',
    _$aggression,
    opt: true,
    def: 0,
  );
  static double? _$combatFreighterProbability(FactionDoctrine v) =>
      v.combatFreighterProbability;
  static const Field<FactionDoctrine, double> _f$combatFreighterProbability =
      Field(
        'combatFreighterProbability',
        _$combatFreighterProbability,
        opt: true,
      );
  static double? _$autofitRandomizeProbability(FactionDoctrine v) =>
      v.autofitRandomizeProbability;
  static const Field<FactionDoctrine, double> _f$autofitRandomizeProbability =
      Field(
        'autofitRandomizeProbability',
        _$autofitRandomizeProbability,
        opt: true,
      );

  @override
  final MappableFields<FactionDoctrine> fields = const {
    #warships: _f$warships,
    #carriers: _f$carriers,
    #phaseShips: _f$phaseShips,
    #officerQuality: _f$officerQuality,
    #shipQuality: _f$shipQuality,
    #numShips: _f$numShips,
    #shipSize: _f$shipSize,
    #aggression: _f$aggression,
    #combatFreighterProbability: _f$combatFreighterProbability,
    #autofitRandomizeProbability: _f$autofitRandomizeProbability,
  };

  static FactionDoctrine _instantiate(DecodingData data) {
    return FactionDoctrine(
      warships: data.dec(_f$warships),
      carriers: data.dec(_f$carriers),
      phaseShips: data.dec(_f$phaseShips),
      officerQuality: data.dec(_f$officerQuality),
      shipQuality: data.dec(_f$shipQuality),
      numShips: data.dec(_f$numShips),
      shipSize: data.dec(_f$shipSize),
      aggression: data.dec(_f$aggression),
      combatFreighterProbability: data.dec(_f$combatFreighterProbability),
      autofitRandomizeProbability: data.dec(_f$autofitRandomizeProbability),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static FactionDoctrine fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<FactionDoctrine>(map);
  }

  static FactionDoctrine fromJson(String json) {
    return ensureInitialized().decodeJson<FactionDoctrine>(json);
  }
}

mixin FactionDoctrineMappable {
  String toJson() {
    return FactionDoctrineMapper.ensureInitialized()
        .encodeJson<FactionDoctrine>(this as FactionDoctrine);
  }

  Map<String, dynamic> toMap() {
    return FactionDoctrineMapper.ensureInitialized().encodeMap<FactionDoctrine>(
      this as FactionDoctrine,
    );
  }

  FactionDoctrineCopyWith<FactionDoctrine, FactionDoctrine, FactionDoctrine>
  get copyWith =>
      _FactionDoctrineCopyWithImpl<FactionDoctrine, FactionDoctrine>(
        this as FactionDoctrine,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return FactionDoctrineMapper.ensureInitialized().stringifyValue(
      this as FactionDoctrine,
    );
  }

  @override
  bool operator ==(Object other) {
    return FactionDoctrineMapper.ensureInitialized().equalsValue(
      this as FactionDoctrine,
      other,
    );
  }

  @override
  int get hashCode {
    return FactionDoctrineMapper.ensureInitialized().hashValue(
      this as FactionDoctrine,
    );
  }
}

extension FactionDoctrineValueCopy<$R, $Out>
    on ObjectCopyWith<$R, FactionDoctrine, $Out> {
  FactionDoctrineCopyWith<$R, FactionDoctrine, $Out> get $asFactionDoctrine =>
      $base.as((v, t, t2) => _FactionDoctrineCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class FactionDoctrineCopyWith<$R, $In extends FactionDoctrine, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    int? warships,
    int? carriers,
    int? phaseShips,
    int? officerQuality,
    int? shipQuality,
    int? numShips,
    int? shipSize,
    int? aggression,
    double? combatFreighterProbability,
    double? autofitRandomizeProbability,
  });
  FactionDoctrineCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _FactionDoctrineCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, FactionDoctrine, $Out>
    implements FactionDoctrineCopyWith<$R, FactionDoctrine, $Out> {
  _FactionDoctrineCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<FactionDoctrine> $mapper =
      FactionDoctrineMapper.ensureInitialized();
  @override
  $R call({
    int? warships,
    int? carriers,
    int? phaseShips,
    int? officerQuality,
    int? shipQuality,
    int? numShips,
    int? shipSize,
    int? aggression,
    Object? combatFreighterProbability = $none,
    Object? autofitRandomizeProbability = $none,
  }) => $apply(
    FieldCopyWithData({
      if (warships != null) #warships: warships,
      if (carriers != null) #carriers: carriers,
      if (phaseShips != null) #phaseShips: phaseShips,
      if (officerQuality != null) #officerQuality: officerQuality,
      if (shipQuality != null) #shipQuality: shipQuality,
      if (numShips != null) #numShips: numShips,
      if (shipSize != null) #shipSize: shipSize,
      if (aggression != null) #aggression: aggression,
      if (combatFreighterProbability != $none)
        #combatFreighterProbability: combatFreighterProbability,
      if (autofitRandomizeProbability != $none)
        #autofitRandomizeProbability: autofitRandomizeProbability,
    }),
  );
  @override
  FactionDoctrine $make(CopyWithData data) => FactionDoctrine(
    warships: data.get(#warships, or: $value.warships),
    carriers: data.get(#carriers, or: $value.carriers),
    phaseShips: data.get(#phaseShips, or: $value.phaseShips),
    officerQuality: data.get(#officerQuality, or: $value.officerQuality),
    shipQuality: data.get(#shipQuality, or: $value.shipQuality),
    numShips: data.get(#numShips, or: $value.numShips),
    shipSize: data.get(#shipSize, or: $value.shipSize),
    aggression: data.get(#aggression, or: $value.aggression),
    combatFreighterProbability: data.get(
      #combatFreighterProbability,
      or: $value.combatFreighterProbability,
    ),
    autofitRandomizeProbability: data.get(
      #autofitRandomizeProbability,
      or: $value.autofitRandomizeProbability,
    ),
  );

  @override
  FactionDoctrineCopyWith<$R2, FactionDoctrine, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _FactionDoctrineCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class FactionSourceMapper extends ClassMapperBase<FactionSource> {
  FactionSourceMapper._();

  static FactionSourceMapper? _instance;
  static FactionSourceMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = FactionSourceMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'FactionSource';

  static String _$name(FactionSource v) => v.name;
  static const Field<FactionSource, String> _f$name = Field('name', _$name);
  static dynamic _$modVariant(FactionSource v) => v.modVariant;
  static const Field<FactionSource, dynamic> _f$modVariant = Field(
    'modVariant',
    _$modVariant,
    opt: true,
    hook: SkipSerializationHook(),
  );

  @override
  final MappableFields<FactionSource> fields = const {
    #name: _f$name,
    #modVariant: _f$modVariant,
  };

  static FactionSource _instantiate(DecodingData data) {
    return FactionSource(
      name: data.dec(_f$name),
      modVariant: data.dec(_f$modVariant),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static FactionSource fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<FactionSource>(map);
  }

  static FactionSource fromJson(String json) {
    return ensureInitialized().decodeJson<FactionSource>(json);
  }
}

mixin FactionSourceMappable {
  String toJson() {
    return FactionSourceMapper.ensureInitialized().encodeJson<FactionSource>(
      this as FactionSource,
    );
  }

  Map<String, dynamic> toMap() {
    return FactionSourceMapper.ensureInitialized().encodeMap<FactionSource>(
      this as FactionSource,
    );
  }

  FactionSourceCopyWith<FactionSource, FactionSource, FactionSource>
  get copyWith => _FactionSourceCopyWithImpl<FactionSource, FactionSource>(
    this as FactionSource,
    $identity,
    $identity,
  );
  @override
  String toString() {
    return FactionSourceMapper.ensureInitialized().stringifyValue(
      this as FactionSource,
    );
  }

  @override
  bool operator ==(Object other) {
    return FactionSourceMapper.ensureInitialized().equalsValue(
      this as FactionSource,
      other,
    );
  }

  @override
  int get hashCode {
    return FactionSourceMapper.ensureInitialized().hashValue(
      this as FactionSource,
    );
  }
}

extension FactionSourceValueCopy<$R, $Out>
    on ObjectCopyWith<$R, FactionSource, $Out> {
  FactionSourceCopyWith<$R, FactionSource, $Out> get $asFactionSource =>
      $base.as((v, t, t2) => _FactionSourceCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class FactionSourceCopyWith<$R, $In extends FactionSource, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({String? name, dynamic modVariant});
  FactionSourceCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _FactionSourceCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, FactionSource, $Out>
    implements FactionSourceCopyWith<$R, FactionSource, $Out> {
  _FactionSourceCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<FactionSource> $mapper =
      FactionSourceMapper.ensureInitialized();
  @override
  $R call({String? name, Object? modVariant = $none}) => $apply(
    FieldCopyWithData({
      if (name != null) #name: name,
      if (modVariant != $none) #modVariant: modVariant,
    }),
  );
  @override
  FactionSource $make(CopyWithData data) => FactionSource(
    name: data.get(#name, or: $value.name),
    modVariant: data.get(#modVariant, or: $value.modVariant),
  );

  @override
  FactionSourceCopyWith<$R2, FactionSource, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _FactionSourceCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class SourceContributionMapper extends ClassMapperBase<SourceContribution> {
  SourceContributionMapper._();

  static SourceContributionMapper? _instance;
  static SourceContributionMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = SourceContributionMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'SourceContribution';

  static String _$source(SourceContribution v) => v.source;
  static const Field<SourceContribution, String> _f$source = Field(
    'source',
    _$source,
  );
  static int _$count(SourceContribution v) => v.count;
  static const Field<SourceContribution, int> _f$count = Field(
    'count',
    _$count,
  );

  @override
  final MappableFields<SourceContribution> fields = const {
    #source: _f$source,
    #count: _f$count,
  };

  static SourceContribution _instantiate(DecodingData data) {
    return SourceContribution(
      source: data.dec(_f$source),
      count: data.dec(_f$count),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static SourceContribution fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<SourceContribution>(map);
  }

  static SourceContribution fromJson(String json) {
    return ensureInitialized().decodeJson<SourceContribution>(json);
  }
}

mixin SourceContributionMappable {
  String toJson() {
    return SourceContributionMapper.ensureInitialized()
        .encodeJson<SourceContribution>(this as SourceContribution);
  }

  Map<String, dynamic> toMap() {
    return SourceContributionMapper.ensureInitialized()
        .encodeMap<SourceContribution>(this as SourceContribution);
  }

  SourceContributionCopyWith<
    SourceContribution,
    SourceContribution,
    SourceContribution
  >
  get copyWith =>
      _SourceContributionCopyWithImpl<SourceContribution, SourceContribution>(
        this as SourceContribution,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return SourceContributionMapper.ensureInitialized().stringifyValue(
      this as SourceContribution,
    );
  }

  @override
  bool operator ==(Object other) {
    return SourceContributionMapper.ensureInitialized().equalsValue(
      this as SourceContribution,
      other,
    );
  }

  @override
  int get hashCode {
    return SourceContributionMapper.ensureInitialized().hashValue(
      this as SourceContribution,
    );
  }
}

extension SourceContributionValueCopy<$R, $Out>
    on ObjectCopyWith<$R, SourceContribution, $Out> {
  SourceContributionCopyWith<$R, SourceContribution, $Out>
  get $asSourceContribution => $base.as(
    (v, t, t2) => _SourceContributionCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class SourceContributionCopyWith<
  $R,
  $In extends SourceContribution,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({String? source, int? count});
  SourceContributionCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _SourceContributionCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, SourceContribution, $Out>
    implements SourceContributionCopyWith<$R, SourceContribution, $Out> {
  _SourceContributionCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<SourceContribution> $mapper =
      SourceContributionMapper.ensureInitialized();
  @override
  $R call({String? source, int? count}) => $apply(
    FieldCopyWithData({
      if (source != null) #source: source,
      if (count != null) #count: count,
    }),
  );
  @override
  SourceContribution $make(CopyWithData data) => SourceContribution(
    source: data.get(#source, or: $value.source),
    count: data.get(#count, or: $value.count),
  );

  @override
  SourceContributionCopyWith<$R2, SourceContribution, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _SourceContributionCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

