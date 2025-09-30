// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'weapons_page_controller.dart';

class WeaponSpoilerLevelMapper extends EnumMapper<WeaponSpoilerLevel> {
  WeaponSpoilerLevelMapper._();

  static WeaponSpoilerLevelMapper? _instance;
  static WeaponSpoilerLevelMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = WeaponSpoilerLevelMapper._());
    }
    return _instance!;
  }

  static WeaponSpoilerLevel fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  WeaponSpoilerLevel decode(dynamic value) {
    switch (value) {
      case r'noSpoilers':
        return WeaponSpoilerLevel.noSpoilers;
      case r'showAllSpoilers':
        return WeaponSpoilerLevel.showAllSpoilers;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(WeaponSpoilerLevel self) {
    switch (self) {
      case WeaponSpoilerLevel.noSpoilers:
        return r'noSpoilers';
      case WeaponSpoilerLevel.showAllSpoilers:
        return r'showAllSpoilers';
    }
  }
}

extension WeaponSpoilerLevelMapperExtension on WeaponSpoilerLevel {
  String toValue() {
    WeaponSpoilerLevelMapper.ensureInitialized();
    return MapperContainer.globals.toValue<WeaponSpoilerLevel>(this) as String;
  }
}

class WeaponsPageStatePersistedMapper
    extends ClassMapperBase<WeaponsPageStatePersisted> {
  WeaponsPageStatePersistedMapper._();

  static WeaponsPageStatePersistedMapper? _instance;
  static WeaponsPageStatePersistedMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(
        _instance = WeaponsPageStatePersistedMapper._(),
      );
    }
    return _instance!;
  }

  @override
  final String id = 'WeaponsPageStatePersisted';

  static bool _$showEnabled(WeaponsPageStatePersisted v) => v.showEnabled;
  static const Field<WeaponsPageStatePersisted, bool> _f$showEnabled = Field(
    'showEnabled',
    _$showEnabled,
    opt: true,
    def: false,
  );
  static bool _$showHidden(WeaponsPageStatePersisted v) => v.showHidden;
  static const Field<WeaponsPageStatePersisted, bool> _f$showHidden = Field(
    'showHidden',
    _$showHidden,
    opt: true,
    def: false,
  );
  static bool _$splitPane(WeaponsPageStatePersisted v) => v.splitPane;
  static const Field<WeaponsPageStatePersisted, bool> _f$splitPane = Field(
    'splitPane',
    _$splitPane,
    opt: true,
    def: false,
  );

  @override
  final MappableFields<WeaponsPageStatePersisted> fields = const {
    #showEnabled: _f$showEnabled,
    #showHidden: _f$showHidden,
    #splitPane: _f$splitPane,
  };

  static WeaponsPageStatePersisted _instantiate(DecodingData data) {
    return WeaponsPageStatePersisted(
      showEnabled: data.dec(_f$showEnabled),
      showHidden: data.dec(_f$showHidden),
      splitPane: data.dec(_f$splitPane),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static WeaponsPageStatePersisted fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<WeaponsPageStatePersisted>(map);
  }

  static WeaponsPageStatePersisted fromJson(String json) {
    return ensureInitialized().decodeJson<WeaponsPageStatePersisted>(json);
  }
}

mixin WeaponsPageStatePersistedMappable {
  String toJson() {
    return WeaponsPageStatePersistedMapper.ensureInitialized()
        .encodeJson<WeaponsPageStatePersisted>(
          this as WeaponsPageStatePersisted,
        );
  }

  Map<String, dynamic> toMap() {
    return WeaponsPageStatePersistedMapper.ensureInitialized()
        .encodeMap<WeaponsPageStatePersisted>(
          this as WeaponsPageStatePersisted,
        );
  }

  WeaponsPageStatePersistedCopyWith<
    WeaponsPageStatePersisted,
    WeaponsPageStatePersisted,
    WeaponsPageStatePersisted
  >
  get copyWith =>
      _WeaponsPageStatePersistedCopyWithImpl<
        WeaponsPageStatePersisted,
        WeaponsPageStatePersisted
      >(this as WeaponsPageStatePersisted, $identity, $identity);
  @override
  String toString() {
    return WeaponsPageStatePersistedMapper.ensureInitialized().stringifyValue(
      this as WeaponsPageStatePersisted,
    );
  }

  @override
  bool operator ==(Object other) {
    return WeaponsPageStatePersistedMapper.ensureInitialized().equalsValue(
      this as WeaponsPageStatePersisted,
      other,
    );
  }

  @override
  int get hashCode {
    return WeaponsPageStatePersistedMapper.ensureInitialized().hashValue(
      this as WeaponsPageStatePersisted,
    );
  }
}

extension WeaponsPageStatePersistedValueCopy<$R, $Out>
    on ObjectCopyWith<$R, WeaponsPageStatePersisted, $Out> {
  WeaponsPageStatePersistedCopyWith<$R, WeaponsPageStatePersisted, $Out>
  get $asWeaponsPageStatePersisted => $base.as(
    (v, t, t2) => _WeaponsPageStatePersistedCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class WeaponsPageStatePersistedCopyWith<
  $R,
  $In extends WeaponsPageStatePersisted,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({bool? showEnabled, bool? showHidden, bool? splitPane});
  WeaponsPageStatePersistedCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _WeaponsPageStatePersistedCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, WeaponsPageStatePersisted, $Out>
    implements
        WeaponsPageStatePersistedCopyWith<$R, WeaponsPageStatePersisted, $Out> {
  _WeaponsPageStatePersistedCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<WeaponsPageStatePersisted> $mapper =
      WeaponsPageStatePersistedMapper.ensureInitialized();
  @override
  $R call({bool? showEnabled, bool? showHidden, bool? splitPane}) => $apply(
    FieldCopyWithData({
      if (showEnabled != null) #showEnabled: showEnabled,
      if (showHidden != null) #showHidden: showHidden,
      if (splitPane != null) #splitPane: splitPane,
    }),
  );
  @override
  WeaponsPageStatePersisted $make(CopyWithData data) =>
      WeaponsPageStatePersisted(
        showEnabled: data.get(#showEnabled, or: $value.showEnabled),
        showHidden: data.get(#showHidden, or: $value.showHidden),
        splitPane: data.get(#splitPane, or: $value.splitPane),
      );

  @override
  WeaponsPageStatePersistedCopyWith<$R2, WeaponsPageStatePersisted, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _WeaponsPageStatePersistedCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class WeaponsPageStateMapper extends ClassMapperBase<WeaponsPageState> {
  WeaponsPageStateMapper._();

  static WeaponsPageStateMapper? _instance;
  static WeaponsPageStateMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = WeaponsPageStateMapper._());
      WeaponsPageStatePersistedMapper.ensureInitialized();
      WeaponMapper.ensureInitialized();
      WeaponSpoilerLevelMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'WeaponsPageState';

  static WeaponsPageStatePersisted _$persisted(WeaponsPageState v) =>
      v.persisted;
  static const Field<WeaponsPageState, WeaponsPageStatePersisted> _f$persisted =
      Field(
        'persisted',
        _$persisted,
        opt: true,
        def: const WeaponsPageStatePersisted(),
      );
  static List<GridFilter<Weapon>> _$filterCategories(WeaponsPageState v) =>
      v.filterCategories;
  static const Field<WeaponsPageState, List<GridFilter<Weapon>>>
  _f$filterCategories = Field(
    'filterCategories',
    _$filterCategories,
    opt: true,
    def: const [],
  );
  static List<Weapon> _$allWeapons(WeaponsPageState v) => v.allWeapons;
  static const Field<WeaponsPageState, List<Weapon>> _f$allWeapons = Field(
    'allWeapons',
    _$allWeapons,
    opt: true,
    def: const [],
  );
  static List<Weapon> _$filteredWeapons(WeaponsPageState v) =>
      v.filteredWeapons;
  static const Field<WeaponsPageState, List<Weapon>> _f$filteredWeapons = Field(
    'filteredWeapons',
    _$filteredWeapons,
    opt: true,
    def: const [],
  );
  static List<Weapon> _$weaponsBeforeGridFilter(WeaponsPageState v) =>
      v.weaponsBeforeGridFilter;
  static const Field<WeaponsPageState, List<Weapon>>
  _f$weaponsBeforeGridFilter = Field(
    'weaponsBeforeGridFilter',
    _$weaponsBeforeGridFilter,
    opt: true,
    def: const [],
  );
  static Map<String, List<String>> _$weaponSearchIndices(WeaponsPageState v) =>
      v.weaponSearchIndices;
  static const Field<WeaponsPageState, Map<String, List<String>>>
  _f$weaponSearchIndices = Field(
    'weaponSearchIndices',
    _$weaponSearchIndices,
    opt: true,
    def: const {},
  );
  static String _$currentSearchQuery(WeaponsPageState v) =>
      v.currentSearchQuery;
  static const Field<WeaponsPageState, String> _f$currentSearchQuery = Field(
    'currentSearchQuery',
    _$currentSearchQuery,
    opt: true,
    def: '',
  );
  static bool _$showFilters(WeaponsPageState v) => v.showFilters;
  static const Field<WeaponsPageState, bool> _f$showFilters = Field(
    'showFilters',
    _$showFilters,
    opt: true,
    def: false,
  );
  static bool _$isLoading(WeaponsPageState v) => v.isLoading;
  static const Field<WeaponsPageState, bool> _f$isLoading = Field(
    'isLoading',
    _$isLoading,
    opt: true,
    def: false,
  );
  static WeaponSpoilerLevel _$weaponSpoilerLevel(WeaponsPageState v) =>
      v.weaponSpoilerLevel;
  static const Field<WeaponsPageState, WeaponSpoilerLevel>
  _f$weaponSpoilerLevel = Field(
    'weaponSpoilerLevel',
    _$weaponSpoilerLevel,
    opt: true,
    def: WeaponSpoilerLevel.noSpoilers,
  );

  @override
  final MappableFields<WeaponsPageState> fields = const {
    #persisted: _f$persisted,
    #filterCategories: _f$filterCategories,
    #allWeapons: _f$allWeapons,
    #filteredWeapons: _f$filteredWeapons,
    #weaponsBeforeGridFilter: _f$weaponsBeforeGridFilter,
    #weaponSearchIndices: _f$weaponSearchIndices,
    #currentSearchQuery: _f$currentSearchQuery,
    #showFilters: _f$showFilters,
    #isLoading: _f$isLoading,
    #weaponSpoilerLevel: _f$weaponSpoilerLevel,
  };

  static WeaponsPageState _instantiate(DecodingData data) {
    return WeaponsPageState(
      persisted: data.dec(_f$persisted),
      filterCategories: data.dec(_f$filterCategories),
      allWeapons: data.dec(_f$allWeapons),
      filteredWeapons: data.dec(_f$filteredWeapons),
      weaponsBeforeGridFilter: data.dec(_f$weaponsBeforeGridFilter),
      weaponSearchIndices: data.dec(_f$weaponSearchIndices),
      currentSearchQuery: data.dec(_f$currentSearchQuery),
      showFilters: data.dec(_f$showFilters),
      isLoading: data.dec(_f$isLoading),
      weaponSpoilerLevel: data.dec(_f$weaponSpoilerLevel),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static WeaponsPageState fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<WeaponsPageState>(map);
  }

  static WeaponsPageState fromJson(String json) {
    return ensureInitialized().decodeJson<WeaponsPageState>(json);
  }
}

mixin WeaponsPageStateMappable {
  String toJson() {
    return WeaponsPageStateMapper.ensureInitialized()
        .encodeJson<WeaponsPageState>(this as WeaponsPageState);
  }

  Map<String, dynamic> toMap() {
    return WeaponsPageStateMapper.ensureInitialized()
        .encodeMap<WeaponsPageState>(this as WeaponsPageState);
  }

  WeaponsPageStateCopyWith<WeaponsPageState, WeaponsPageState, WeaponsPageState>
  get copyWith =>
      _WeaponsPageStateCopyWithImpl<WeaponsPageState, WeaponsPageState>(
        this as WeaponsPageState,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return WeaponsPageStateMapper.ensureInitialized().stringifyValue(
      this as WeaponsPageState,
    );
  }

  @override
  bool operator ==(Object other) {
    return WeaponsPageStateMapper.ensureInitialized().equalsValue(
      this as WeaponsPageState,
      other,
    );
  }

  @override
  int get hashCode {
    return WeaponsPageStateMapper.ensureInitialized().hashValue(
      this as WeaponsPageState,
    );
  }
}

extension WeaponsPageStateValueCopy<$R, $Out>
    on ObjectCopyWith<$R, WeaponsPageState, $Out> {
  WeaponsPageStateCopyWith<$R, WeaponsPageState, $Out>
  get $asWeaponsPageState =>
      $base.as((v, t, t2) => _WeaponsPageStateCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class WeaponsPageStateCopyWith<$R, $In extends WeaponsPageState, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  WeaponsPageStatePersistedCopyWith<
    $R,
    WeaponsPageStatePersisted,
    WeaponsPageStatePersisted
  >
  get persisted;
  ListCopyWith<
    $R,
    GridFilter<Weapon>,
    ObjectCopyWith<$R, GridFilter<Weapon>, GridFilter<Weapon>>
  >
  get filterCategories;
  ListCopyWith<$R, Weapon, WeaponCopyWith<$R, Weapon, Weapon>> get allWeapons;
  ListCopyWith<$R, Weapon, WeaponCopyWith<$R, Weapon, Weapon>>
  get filteredWeapons;
  ListCopyWith<$R, Weapon, WeaponCopyWith<$R, Weapon, Weapon>>
  get weaponsBeforeGridFilter;
  MapCopyWith<
    $R,
    String,
    List<String>,
    ObjectCopyWith<$R, List<String>, List<String>>
  >
  get weaponSearchIndices;
  $R call({
    WeaponsPageStatePersisted? persisted,
    List<GridFilter<Weapon>>? filterCategories,
    List<Weapon>? allWeapons,
    List<Weapon>? filteredWeapons,
    List<Weapon>? weaponsBeforeGridFilter,
    Map<String, List<String>>? weaponSearchIndices,
    String? currentSearchQuery,
    bool? showFilters,
    bool? isLoading,
    WeaponSpoilerLevel? weaponSpoilerLevel,
  });
  WeaponsPageStateCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _WeaponsPageStateCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, WeaponsPageState, $Out>
    implements WeaponsPageStateCopyWith<$R, WeaponsPageState, $Out> {
  _WeaponsPageStateCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<WeaponsPageState> $mapper =
      WeaponsPageStateMapper.ensureInitialized();
  @override
  WeaponsPageStatePersistedCopyWith<
    $R,
    WeaponsPageStatePersisted,
    WeaponsPageStatePersisted
  >
  get persisted => $value.persisted.copyWith.$chain((v) => call(persisted: v));
  @override
  ListCopyWith<
    $R,
    GridFilter<Weapon>,
    ObjectCopyWith<$R, GridFilter<Weapon>, GridFilter<Weapon>>
  >
  get filterCategories => ListCopyWith(
    $value.filterCategories,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(filterCategories: v),
  );
  @override
  ListCopyWith<$R, Weapon, WeaponCopyWith<$R, Weapon, Weapon>> get allWeapons =>
      ListCopyWith(
        $value.allWeapons,
        (v, t) => v.copyWith.$chain(t),
        (v) => call(allWeapons: v),
      );
  @override
  ListCopyWith<$R, Weapon, WeaponCopyWith<$R, Weapon, Weapon>>
  get filteredWeapons => ListCopyWith(
    $value.filteredWeapons,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(filteredWeapons: v),
  );
  @override
  ListCopyWith<$R, Weapon, WeaponCopyWith<$R, Weapon, Weapon>>
  get weaponsBeforeGridFilter => ListCopyWith(
    $value.weaponsBeforeGridFilter,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(weaponsBeforeGridFilter: v),
  );
  @override
  MapCopyWith<
    $R,
    String,
    List<String>,
    ObjectCopyWith<$R, List<String>, List<String>>
  >
  get weaponSearchIndices => MapCopyWith(
    $value.weaponSearchIndices,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(weaponSearchIndices: v),
  );
  @override
  $R call({
    WeaponsPageStatePersisted? persisted,
    List<GridFilter<Weapon>>? filterCategories,
    List<Weapon>? allWeapons,
    List<Weapon>? filteredWeapons,
    List<Weapon>? weaponsBeforeGridFilter,
    Map<String, List<String>>? weaponSearchIndices,
    String? currentSearchQuery,
    bool? showFilters,
    bool? isLoading,
    WeaponSpoilerLevel? weaponSpoilerLevel,
  }) => $apply(
    FieldCopyWithData({
      if (persisted != null) #persisted: persisted,
      if (filterCategories != null) #filterCategories: filterCategories,
      if (allWeapons != null) #allWeapons: allWeapons,
      if (filteredWeapons != null) #filteredWeapons: filteredWeapons,
      if (weaponsBeforeGridFilter != null)
        #weaponsBeforeGridFilter: weaponsBeforeGridFilter,
      if (weaponSearchIndices != null)
        #weaponSearchIndices: weaponSearchIndices,
      if (currentSearchQuery != null) #currentSearchQuery: currentSearchQuery,
      if (showFilters != null) #showFilters: showFilters,
      if (isLoading != null) #isLoading: isLoading,
      if (weaponSpoilerLevel != null) #weaponSpoilerLevel: weaponSpoilerLevel,
    }),
  );
  @override
  WeaponsPageState $make(CopyWithData data) => WeaponsPageState(
    persisted: data.get(#persisted, or: $value.persisted),
    filterCategories: data.get(#filterCategories, or: $value.filterCategories),
    allWeapons: data.get(#allWeapons, or: $value.allWeapons),
    filteredWeapons: data.get(#filteredWeapons, or: $value.filteredWeapons),
    weaponsBeforeGridFilter: data.get(
      #weaponsBeforeGridFilter,
      or: $value.weaponsBeforeGridFilter,
    ),
    weaponSearchIndices: data.get(
      #weaponSearchIndices,
      or: $value.weaponSearchIndices,
    ),
    currentSearchQuery: data.get(
      #currentSearchQuery,
      or: $value.currentSearchQuery,
    ),
    showFilters: data.get(#showFilters, or: $value.showFilters),
    isLoading: data.get(#isLoading, or: $value.isLoading),
    weaponSpoilerLevel: data.get(
      #weaponSpoilerLevel,
      or: $value.weaponSpoilerLevel,
    ),
  );

  @override
  WeaponsPageStateCopyWith<$R2, WeaponsPageState, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _WeaponsPageStateCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

