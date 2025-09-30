// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'ships_page_controller.dart';

class SpoilerLevelMapper extends EnumMapper<SpoilerLevel> {
  SpoilerLevelMapper._();

  static SpoilerLevelMapper? _instance;
  static SpoilerLevelMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = SpoilerLevelMapper._());
    }
    return _instance!;
  }

  static SpoilerLevel fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  SpoilerLevel decode(dynamic value) {
    switch (value) {
      case r'showNone':
        return SpoilerLevel.showNone;
      case r'showSlightSpoilers':
        return SpoilerLevel.showSlightSpoilers;
      case r'showAllSpoilers':
        return SpoilerLevel.showAllSpoilers;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(SpoilerLevel self) {
    switch (self) {
      case SpoilerLevel.showNone:
        return r'showNone';
      case SpoilerLevel.showSlightSpoilers:
        return r'showSlightSpoilers';
      case SpoilerLevel.showAllSpoilers:
        return r'showAllSpoilers';
    }
  }
}

extension SpoilerLevelMapperExtension on SpoilerLevel {
  String toValue() {
    SpoilerLevelMapper.ensureInitialized();
    return MapperContainer.globals.toValue<SpoilerLevel>(this) as String;
  }
}

class ShipsPageStateMapper extends ClassMapperBase<ShipsPageState> {
  ShipsPageStateMapper._();

  static ShipsPageStateMapper? _instance;
  static ShipsPageStateMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ShipsPageStateMapper._());
      ShipsPageStatePersistedMapper.ensureInitialized();
      ShipMapper.ensureInitialized();
      ShipSystemMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ShipsPageState';

  static ShipsPageStatePersisted _$persisted(ShipsPageState v) => v.persisted;
  static const Field<ShipsPageState, ShipsPageStatePersisted> _f$persisted =
      Field(
        'persisted',
        _$persisted,
        opt: true,
        def: const ShipsPageStatePersisted(),
      );
  static List<GridFilter<Ship>> _$filterCategories(ShipsPageState v) =>
      v.filterCategories;
  static const Field<ShipsPageState, List<GridFilter<Ship>>>
  _f$filterCategories = Field(
    'filterCategories',
    _$filterCategories,
    opt: true,
    def: const [],
  );
  static Map<String, List<String>> _$shipSearchIndices(ShipsPageState v) =>
      v.shipSearchIndices;
  static const Field<ShipsPageState, Map<String, List<String>>>
  _f$shipSearchIndices = Field(
    'shipSearchIndices',
    _$shipSearchIndices,
    opt: true,
    def: const {},
  );
  static Map<String, ShipSystem> _$shipSystemsMap(ShipsPageState v) =>
      v.shipSystemsMap;
  static const Field<ShipsPageState, Map<String, ShipSystem>>
  _f$shipSystemsMap = Field(
    'shipSystemsMap',
    _$shipSystemsMap,
    opt: true,
    def: const {},
  );
  static List<Ship> _$allShips(ShipsPageState v) => v.allShips;
  static const Field<ShipsPageState, List<Ship>> _f$allShips = Field(
    'allShips',
    _$allShips,
    opt: true,
    def: const [],
  );
  static List<Ship> _$filteredShips(ShipsPageState v) => v.filteredShips;
  static const Field<ShipsPageState, List<Ship>> _f$filteredShips = Field(
    'filteredShips',
    _$filteredShips,
    opt: true,
    def: const [],
  );
  static List<Ship> _$shipsBeforeGridFilter(ShipsPageState v) =>
      v.shipsBeforeGridFilter;
  static const Field<ShipsPageState, List<Ship>> _f$shipsBeforeGridFilter =
      Field(
        'shipsBeforeGridFilter',
        _$shipsBeforeGridFilter,
        opt: true,
        def: const [],
      );
  static String _$currentSearchQuery(ShipsPageState v) => v.currentSearchQuery;
  static const Field<ShipsPageState, String> _f$currentSearchQuery = Field(
    'currentSearchQuery',
    _$currentSearchQuery,
    opt: true,
    def: '',
  );
  static bool _$isLoading(ShipsPageState v) => v.isLoading;
  static const Field<ShipsPageState, bool> _f$isLoading = Field(
    'isLoading',
    _$isLoading,
    opt: true,
    def: false,
  );

  @override
  final MappableFields<ShipsPageState> fields = const {
    #persisted: _f$persisted,
    #filterCategories: _f$filterCategories,
    #shipSearchIndices: _f$shipSearchIndices,
    #shipSystemsMap: _f$shipSystemsMap,
    #allShips: _f$allShips,
    #filteredShips: _f$filteredShips,
    #shipsBeforeGridFilter: _f$shipsBeforeGridFilter,
    #currentSearchQuery: _f$currentSearchQuery,
    #isLoading: _f$isLoading,
  };

  static ShipsPageState _instantiate(DecodingData data) {
    return ShipsPageState(
      persisted: data.dec(_f$persisted),
      filterCategories: data.dec(_f$filterCategories),
      shipSearchIndices: data.dec(_f$shipSearchIndices),
      shipSystemsMap: data.dec(_f$shipSystemsMap),
      allShips: data.dec(_f$allShips),
      filteredShips: data.dec(_f$filteredShips),
      shipsBeforeGridFilter: data.dec(_f$shipsBeforeGridFilter),
      currentSearchQuery: data.dec(_f$currentSearchQuery),
      isLoading: data.dec(_f$isLoading),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ShipsPageState fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ShipsPageState>(map);
  }

  static ShipsPageState fromJson(String json) {
    return ensureInitialized().decodeJson<ShipsPageState>(json);
  }
}

mixin ShipsPageStateMappable {
  String toJson() {
    return ShipsPageStateMapper.ensureInitialized().encodeJson<ShipsPageState>(
      this as ShipsPageState,
    );
  }

  Map<String, dynamic> toMap() {
    return ShipsPageStateMapper.ensureInitialized().encodeMap<ShipsPageState>(
      this as ShipsPageState,
    );
  }

  ShipsPageStateCopyWith<ShipsPageState, ShipsPageState, ShipsPageState>
  get copyWith => _ShipsPageStateCopyWithImpl<ShipsPageState, ShipsPageState>(
    this as ShipsPageState,
    $identity,
    $identity,
  );
  @override
  String toString() {
    return ShipsPageStateMapper.ensureInitialized().stringifyValue(
      this as ShipsPageState,
    );
  }

  @override
  bool operator ==(Object other) {
    return ShipsPageStateMapper.ensureInitialized().equalsValue(
      this as ShipsPageState,
      other,
    );
  }

  @override
  int get hashCode {
    return ShipsPageStateMapper.ensureInitialized().hashValue(
      this as ShipsPageState,
    );
  }
}

extension ShipsPageStateValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ShipsPageState, $Out> {
  ShipsPageStateCopyWith<$R, ShipsPageState, $Out> get $asShipsPageState =>
      $base.as((v, t, t2) => _ShipsPageStateCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ShipsPageStateCopyWith<$R, $In extends ShipsPageState, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ShipsPageStatePersistedCopyWith<
    $R,
    ShipsPageStatePersisted,
    ShipsPageStatePersisted
  >
  get persisted;
  ListCopyWith<
    $R,
    GridFilter<Ship>,
    ObjectCopyWith<$R, GridFilter<Ship>, GridFilter<Ship>>
  >
  get filterCategories;
  MapCopyWith<
    $R,
    String,
    List<String>,
    ObjectCopyWith<$R, List<String>, List<String>>
  >
  get shipSearchIndices;
  MapCopyWith<
    $R,
    String,
    ShipSystem,
    ShipSystemCopyWith<$R, ShipSystem, ShipSystem>
  >
  get shipSystemsMap;
  ListCopyWith<$R, Ship, ShipCopyWith<$R, Ship, Ship>> get allShips;
  ListCopyWith<$R, Ship, ShipCopyWith<$R, Ship, Ship>> get filteredShips;
  ListCopyWith<$R, Ship, ShipCopyWith<$R, Ship, Ship>>
  get shipsBeforeGridFilter;
  $R call({
    ShipsPageStatePersisted? persisted,
    List<GridFilter<Ship>>? filterCategories,
    Map<String, List<String>>? shipSearchIndices,
    Map<String, ShipSystem>? shipSystemsMap,
    List<Ship>? allShips,
    List<Ship>? filteredShips,
    List<Ship>? shipsBeforeGridFilter,
    String? currentSearchQuery,
    bool? isLoading,
  });
  ShipsPageStateCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _ShipsPageStateCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ShipsPageState, $Out>
    implements ShipsPageStateCopyWith<$R, ShipsPageState, $Out> {
  _ShipsPageStateCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ShipsPageState> $mapper =
      ShipsPageStateMapper.ensureInitialized();
  @override
  ShipsPageStatePersistedCopyWith<
    $R,
    ShipsPageStatePersisted,
    ShipsPageStatePersisted
  >
  get persisted => $value.persisted.copyWith.$chain((v) => call(persisted: v));
  @override
  ListCopyWith<
    $R,
    GridFilter<Ship>,
    ObjectCopyWith<$R, GridFilter<Ship>, GridFilter<Ship>>
  >
  get filterCategories => ListCopyWith(
    $value.filterCategories,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(filterCategories: v),
  );
  @override
  MapCopyWith<
    $R,
    String,
    List<String>,
    ObjectCopyWith<$R, List<String>, List<String>>
  >
  get shipSearchIndices => MapCopyWith(
    $value.shipSearchIndices,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(shipSearchIndices: v),
  );
  @override
  MapCopyWith<
    $R,
    String,
    ShipSystem,
    ShipSystemCopyWith<$R, ShipSystem, ShipSystem>
  >
  get shipSystemsMap => MapCopyWith(
    $value.shipSystemsMap,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(shipSystemsMap: v),
  );
  @override
  ListCopyWith<$R, Ship, ShipCopyWith<$R, Ship, Ship>> get allShips =>
      ListCopyWith(
        $value.allShips,
        (v, t) => v.copyWith.$chain(t),
        (v) => call(allShips: v),
      );
  @override
  ListCopyWith<$R, Ship, ShipCopyWith<$R, Ship, Ship>> get filteredShips =>
      ListCopyWith(
        $value.filteredShips,
        (v, t) => v.copyWith.$chain(t),
        (v) => call(filteredShips: v),
      );
  @override
  ListCopyWith<$R, Ship, ShipCopyWith<$R, Ship, Ship>>
  get shipsBeforeGridFilter => ListCopyWith(
    $value.shipsBeforeGridFilter,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(shipsBeforeGridFilter: v),
  );
  @override
  $R call({
    ShipsPageStatePersisted? persisted,
    List<GridFilter<Ship>>? filterCategories,
    Map<String, List<String>>? shipSearchIndices,
    Map<String, ShipSystem>? shipSystemsMap,
    List<Ship>? allShips,
    List<Ship>? filteredShips,
    List<Ship>? shipsBeforeGridFilter,
    String? currentSearchQuery,
    bool? isLoading,
  }) => $apply(
    FieldCopyWithData({
      if (persisted != null) #persisted: persisted,
      if (filterCategories != null) #filterCategories: filterCategories,
      if (shipSearchIndices != null) #shipSearchIndices: shipSearchIndices,
      if (shipSystemsMap != null) #shipSystemsMap: shipSystemsMap,
      if (allShips != null) #allShips: allShips,
      if (filteredShips != null) #filteredShips: filteredShips,
      if (shipsBeforeGridFilter != null)
        #shipsBeforeGridFilter: shipsBeforeGridFilter,
      if (currentSearchQuery != null) #currentSearchQuery: currentSearchQuery,
      if (isLoading != null) #isLoading: isLoading,
    }),
  );
  @override
  ShipsPageState $make(CopyWithData data) => ShipsPageState(
    persisted: data.get(#persisted, or: $value.persisted),
    filterCategories: data.get(#filterCategories, or: $value.filterCategories),
    shipSearchIndices: data.get(
      #shipSearchIndices,
      or: $value.shipSearchIndices,
    ),
    shipSystemsMap: data.get(#shipSystemsMap, or: $value.shipSystemsMap),
    allShips: data.get(#allShips, or: $value.allShips),
    filteredShips: data.get(#filteredShips, or: $value.filteredShips),
    shipsBeforeGridFilter: data.get(
      #shipsBeforeGridFilter,
      or: $value.shipsBeforeGridFilter,
    ),
    currentSearchQuery: data.get(
      #currentSearchQuery,
      or: $value.currentSearchQuery,
    ),
    isLoading: data.get(#isLoading, or: $value.isLoading),
  );

  @override
  ShipsPageStateCopyWith<$R2, ShipsPageState, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ShipsPageStateCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class ShipsPageStatePersistedMapper
    extends ClassMapperBase<ShipsPageStatePersisted> {
  ShipsPageStatePersistedMapper._();

  static ShipsPageStatePersistedMapper? _instance;
  static ShipsPageStatePersistedMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(
        _instance = ShipsPageStatePersistedMapper._(),
      );
      SpoilerLevelMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ShipsPageStatePersisted';

  static bool _$showEnabled(ShipsPageStatePersisted v) => v.showEnabled;
  static const Field<ShipsPageStatePersisted, bool> _f$showEnabled = Field(
    'showEnabled',
    _$showEnabled,
    opt: true,
    def: false,
  );
  static SpoilerLevel _$spoilerLevelToShow(ShipsPageStatePersisted v) =>
      v.spoilerLevelToShow;
  static const Field<ShipsPageStatePersisted, SpoilerLevel>
  _f$spoilerLevelToShow = Field(
    'spoilerLevelToShow',
    _$spoilerLevelToShow,
    opt: true,
    def: SpoilerLevel.showNone,
  );
  static bool _$splitPane(ShipsPageStatePersisted v) => v.splitPane;
  static const Field<ShipsPageStatePersisted, bool> _f$splitPane = Field(
    'splitPane',
    _$splitPane,
    opt: true,
    def: false,
  );
  static bool _$showFilters(ShipsPageStatePersisted v) => v.showFilters;
  static const Field<ShipsPageStatePersisted, bool> _f$showFilters = Field(
    'showFilters',
    _$showFilters,
    opt: true,
    def: false,
  );

  @override
  final MappableFields<ShipsPageStatePersisted> fields = const {
    #showEnabled: _f$showEnabled,
    #spoilerLevelToShow: _f$spoilerLevelToShow,
    #splitPane: _f$splitPane,
    #showFilters: _f$showFilters,
  };

  static ShipsPageStatePersisted _instantiate(DecodingData data) {
    return ShipsPageStatePersisted(
      showEnabled: data.dec(_f$showEnabled),
      spoilerLevelToShow: data.dec(_f$spoilerLevelToShow),
      splitPane: data.dec(_f$splitPane),
      showFilters: data.dec(_f$showFilters),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ShipsPageStatePersisted fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ShipsPageStatePersisted>(map);
  }

  static ShipsPageStatePersisted fromJson(String json) {
    return ensureInitialized().decodeJson<ShipsPageStatePersisted>(json);
  }
}

mixin ShipsPageStatePersistedMappable {
  String toJson() {
    return ShipsPageStatePersistedMapper.ensureInitialized()
        .encodeJson<ShipsPageStatePersisted>(this as ShipsPageStatePersisted);
  }

  Map<String, dynamic> toMap() {
    return ShipsPageStatePersistedMapper.ensureInitialized()
        .encodeMap<ShipsPageStatePersisted>(this as ShipsPageStatePersisted);
  }

  ShipsPageStatePersistedCopyWith<
    ShipsPageStatePersisted,
    ShipsPageStatePersisted,
    ShipsPageStatePersisted
  >
  get copyWith =>
      _ShipsPageStatePersistedCopyWithImpl<
        ShipsPageStatePersisted,
        ShipsPageStatePersisted
      >(this as ShipsPageStatePersisted, $identity, $identity);
  @override
  String toString() {
    return ShipsPageStatePersistedMapper.ensureInitialized().stringifyValue(
      this as ShipsPageStatePersisted,
    );
  }

  @override
  bool operator ==(Object other) {
    return ShipsPageStatePersistedMapper.ensureInitialized().equalsValue(
      this as ShipsPageStatePersisted,
      other,
    );
  }

  @override
  int get hashCode {
    return ShipsPageStatePersistedMapper.ensureInitialized().hashValue(
      this as ShipsPageStatePersisted,
    );
  }
}

extension ShipsPageStatePersistedValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ShipsPageStatePersisted, $Out> {
  ShipsPageStatePersistedCopyWith<$R, ShipsPageStatePersisted, $Out>
  get $asShipsPageStatePersisted => $base.as(
    (v, t, t2) => _ShipsPageStatePersistedCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class ShipsPageStatePersistedCopyWith<
  $R,
  $In extends ShipsPageStatePersisted,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    bool? showEnabled,
    SpoilerLevel? spoilerLevelToShow,
    bool? splitPane,
    bool? showFilters,
  });
  ShipsPageStatePersistedCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _ShipsPageStatePersistedCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ShipsPageStatePersisted, $Out>
    implements
        ShipsPageStatePersistedCopyWith<$R, ShipsPageStatePersisted, $Out> {
  _ShipsPageStatePersistedCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ShipsPageStatePersisted> $mapper =
      ShipsPageStatePersistedMapper.ensureInitialized();
  @override
  $R call({
    bool? showEnabled,
    SpoilerLevel? spoilerLevelToShow,
    bool? splitPane,
    bool? showFilters,
  }) => $apply(
    FieldCopyWithData({
      if (showEnabled != null) #showEnabled: showEnabled,
      if (spoilerLevelToShow != null) #spoilerLevelToShow: spoilerLevelToShow,
      if (splitPane != null) #splitPane: splitPane,
      if (showFilters != null) #showFilters: showFilters,
    }),
  );
  @override
  ShipsPageStatePersisted $make(CopyWithData data) => ShipsPageStatePersisted(
    showEnabled: data.get(#showEnabled, or: $value.showEnabled),
    spoilerLevelToShow: data.get(
      #spoilerLevelToShow,
      or: $value.spoilerLevelToShow,
    ),
    splitPane: data.get(#splitPane, or: $value.splitPane),
    showFilters: data.get(#showFilters, or: $value.showFilters),
  );

  @override
  ShipsPageStatePersistedCopyWith<$R2, ShipsPageStatePersisted, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _ShipsPageStatePersistedCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

