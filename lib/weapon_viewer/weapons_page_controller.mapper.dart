// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
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

  static bool _$splitPane(WeaponsPageStatePersisted v) => v.splitPane;
  static const Field<WeaponsPageStatePersisted, bool> _f$splitPane = Field(
    'splitPane',
    _$splitPane,
    opt: true,
    def: false,
  );
  static bool _$useContainFit(WeaponsPageStatePersisted v) => v.useContainFit;
  static const Field<WeaponsPageStatePersisted, bool> _f$useContainFit = Field(
    'useContainFit',
    _$useContainFit,
    opt: true,
    def: false,
  );
  static bool _$showFilters(WeaponsPageStatePersisted v) => v.showFilters;
  static const Field<WeaponsPageStatePersisted, bool> _f$showFilters = Field(
    'showFilters',
    _$showFilters,
    opt: true,
    def: false,
  );

  @override
  final MappableFields<WeaponsPageStatePersisted> fields = const {
    #splitPane: _f$splitPane,
    #useContainFit: _f$useContainFit,
    #showFilters: _f$showFilters,
  };

  static WeaponsPageStatePersisted _instantiate(DecodingData data) {
    return WeaponsPageStatePersisted(
      splitPane: data.dec(_f$splitPane),
      useContainFit: data.dec(_f$useContainFit),
      showFilters: data.dec(_f$showFilters),
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
  $R call({bool? splitPane, bool? useContainFit, bool? showFilters});
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
  $R call({bool? splitPane, bool? useContainFit, bool? showFilters}) => $apply(
    FieldCopyWithData({
      if (splitPane != null) #splitPane: splitPane,
      if (useContainFit != null) #useContainFit: useContainFit,
      if (showFilters != null) #showFilters: showFilters,
    }),
  );
  @override
  WeaponsPageStatePersisted $make(CopyWithData data) =>
      WeaponsPageStatePersisted(
        splitPane: data.get(#splitPane, or: $value.splitPane),
        useContainFit: data.get(#useContainFit, or: $value.useContainFit),
        showFilters: data.get(#showFilters, or: $value.showFilters),
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
  static bool _$isLoading(WeaponsPageState v) => v.isLoading;
  static const Field<WeaponsPageState, bool> _f$isLoading = Field(
    'isLoading',
    _$isLoading,
    opt: true,
    def: false,
  );

  @override
  final MappableFields<WeaponsPageState> fields = const {
    #persisted: _f$persisted,
    #allWeapons: _f$allWeapons,
    #filteredWeapons: _f$filteredWeapons,
    #weaponsBeforeGridFilter: _f$weaponsBeforeGridFilter,
    #weaponSearchIndices: _f$weaponSearchIndices,
    #currentSearchQuery: _f$currentSearchQuery,
    #isLoading: _f$isLoading,
  };

  static WeaponsPageState _instantiate(DecodingData data) {
    return WeaponsPageState(
      persisted: data.dec(_f$persisted),
      allWeapons: data.dec(_f$allWeapons),
      filteredWeapons: data.dec(_f$filteredWeapons),
      weaponsBeforeGridFilter: data.dec(_f$weaponsBeforeGridFilter),
      weaponSearchIndices: data.dec(_f$weaponSearchIndices),
      currentSearchQuery: data.dec(_f$currentSearchQuery),
      isLoading: data.dec(_f$isLoading),
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
    List<Weapon>? allWeapons,
    List<Weapon>? filteredWeapons,
    List<Weapon>? weaponsBeforeGridFilter,
    Map<String, List<String>>? weaponSearchIndices,
    String? currentSearchQuery,
    bool? isLoading,
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
    List<Weapon>? allWeapons,
    List<Weapon>? filteredWeapons,
    List<Weapon>? weaponsBeforeGridFilter,
    Map<String, List<String>>? weaponSearchIndices,
    String? currentSearchQuery,
    bool? isLoading,
  }) => $apply(
    FieldCopyWithData({
      if (persisted != null) #persisted: persisted,
      if (allWeapons != null) #allWeapons: allWeapons,
      if (filteredWeapons != null) #filteredWeapons: filteredWeapons,
      if (weaponsBeforeGridFilter != null)
        #weaponsBeforeGridFilter: weaponsBeforeGridFilter,
      if (weaponSearchIndices != null)
        #weaponSearchIndices: weaponSearchIndices,
      if (currentSearchQuery != null) #currentSearchQuery: currentSearchQuery,
      if (isLoading != null) #isLoading: isLoading,
    }),
  );
  @override
  WeaponsPageState $make(CopyWithData data) => WeaponsPageState(
    persisted: data.get(#persisted, or: $value.persisted),
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
    isLoading: data.get(#isLoading, or: $value.isLoading),
  );

  @override
  WeaponsPageStateCopyWith<$R2, WeaponsPageState, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _WeaponsPageStateCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

