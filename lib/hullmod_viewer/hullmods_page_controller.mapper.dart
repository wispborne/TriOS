// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'hullmods_page_controller.dart';

class HullmodSpoilerLevelMapper extends EnumMapper<HullmodSpoilerLevel> {
  HullmodSpoilerLevelMapper._();

  static HullmodSpoilerLevelMapper? _instance;
  static HullmodSpoilerLevelMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = HullmodSpoilerLevelMapper._());
    }
    return _instance!;
  }

  static HullmodSpoilerLevel fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  HullmodSpoilerLevel decode(dynamic value) {
    switch (value) {
      case r'noSpoilers':
        return HullmodSpoilerLevel.noSpoilers;
      case r'showAllSpoilers':
        return HullmodSpoilerLevel.showAllSpoilers;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(HullmodSpoilerLevel self) {
    switch (self) {
      case HullmodSpoilerLevel.noSpoilers:
        return r'noSpoilers';
      case HullmodSpoilerLevel.showAllSpoilers:
        return r'showAllSpoilers';
    }
  }
}

extension HullmodSpoilerLevelMapperExtension on HullmodSpoilerLevel {
  String toValue() {
    HullmodSpoilerLevelMapper.ensureInitialized();
    return MapperContainer.globals.toValue<HullmodSpoilerLevel>(this) as String;
  }
}

class HullmodsPageStatePersistedMapper
    extends ClassMapperBase<HullmodsPageStatePersisted> {
  HullmodsPageStatePersistedMapper._();

  static HullmodsPageStatePersistedMapper? _instance;
  static HullmodsPageStatePersistedMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(
        _instance = HullmodsPageStatePersistedMapper._(),
      );
    }
    return _instance!;
  }

  @override
  final String id = 'HullmodsPageStatePersisted';

  static bool _$splitPane(HullmodsPageStatePersisted v) => v.splitPane;
  static const Field<HullmodsPageStatePersisted, bool> _f$splitPane = Field(
    'splitPane',
    _$splitPane,
    opt: true,
    def: false,
  );
  static bool _$useContainFit(HullmodsPageStatePersisted v) => v.useContainFit;
  static const Field<HullmodsPageStatePersisted, bool> _f$useContainFit = Field(
    'useContainFit',
    _$useContainFit,
    opt: true,
    def: false,
  );
  static bool _$showFilters(HullmodsPageStatePersisted v) => v.showFilters;
  static const Field<HullmodsPageStatePersisted, bool> _f$showFilters = Field(
    'showFilters',
    _$showFilters,
    opt: true,
    def: false,
  );

  @override
  final MappableFields<HullmodsPageStatePersisted> fields = const {
    #splitPane: _f$splitPane,
    #useContainFit: _f$useContainFit,
    #showFilters: _f$showFilters,
  };

  static HullmodsPageStatePersisted _instantiate(DecodingData data) {
    return HullmodsPageStatePersisted(
      splitPane: data.dec(_f$splitPane),
      useContainFit: data.dec(_f$useContainFit),
      showFilters: data.dec(_f$showFilters),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static HullmodsPageStatePersisted fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<HullmodsPageStatePersisted>(map);
  }

  static HullmodsPageStatePersisted fromJson(String json) {
    return ensureInitialized().decodeJson<HullmodsPageStatePersisted>(json);
  }
}

mixin HullmodsPageStatePersistedMappable {
  String toJson() {
    return HullmodsPageStatePersistedMapper.ensureInitialized()
        .encodeJson<HullmodsPageStatePersisted>(
          this as HullmodsPageStatePersisted,
        );
  }

  Map<String, dynamic> toMap() {
    return HullmodsPageStatePersistedMapper.ensureInitialized()
        .encodeMap<HullmodsPageStatePersisted>(
          this as HullmodsPageStatePersisted,
        );
  }

  HullmodsPageStatePersistedCopyWith<
    HullmodsPageStatePersisted,
    HullmodsPageStatePersisted,
    HullmodsPageStatePersisted
  >
  get copyWith =>
      _HullmodsPageStatePersistedCopyWithImpl<
        HullmodsPageStatePersisted,
        HullmodsPageStatePersisted
      >(this as HullmodsPageStatePersisted, $identity, $identity);
  @override
  String toString() {
    return HullmodsPageStatePersistedMapper.ensureInitialized().stringifyValue(
      this as HullmodsPageStatePersisted,
    );
  }

  @override
  bool operator ==(Object other) {
    return HullmodsPageStatePersistedMapper.ensureInitialized().equalsValue(
      this as HullmodsPageStatePersisted,
      other,
    );
  }

  @override
  int get hashCode {
    return HullmodsPageStatePersistedMapper.ensureInitialized().hashValue(
      this as HullmodsPageStatePersisted,
    );
  }
}

extension HullmodsPageStatePersistedValueCopy<$R, $Out>
    on ObjectCopyWith<$R, HullmodsPageStatePersisted, $Out> {
  HullmodsPageStatePersistedCopyWith<$R, HullmodsPageStatePersisted, $Out>
  get $asHullmodsPageStatePersisted => $base.as(
    (v, t, t2) => _HullmodsPageStatePersistedCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class HullmodsPageStatePersistedCopyWith<
  $R,
  $In extends HullmodsPageStatePersisted,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({bool? splitPane, bool? useContainFit, bool? showFilters});
  HullmodsPageStatePersistedCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _HullmodsPageStatePersistedCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, HullmodsPageStatePersisted, $Out>
    implements
        HullmodsPageStatePersistedCopyWith<
          $R,
          HullmodsPageStatePersisted,
          $Out
        > {
  _HullmodsPageStatePersistedCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<HullmodsPageStatePersisted> $mapper =
      HullmodsPageStatePersistedMapper.ensureInitialized();
  @override
  $R call({bool? splitPane, bool? useContainFit, bool? showFilters}) => $apply(
    FieldCopyWithData({
      if (splitPane != null) #splitPane: splitPane,
      if (useContainFit != null) #useContainFit: useContainFit,
      if (showFilters != null) #showFilters: showFilters,
    }),
  );
  @override
  HullmodsPageStatePersisted $make(CopyWithData data) =>
      HullmodsPageStatePersisted(
        splitPane: data.get(#splitPane, or: $value.splitPane),
        useContainFit: data.get(#useContainFit, or: $value.useContainFit),
        showFilters: data.get(#showFilters, or: $value.showFilters),
      );

  @override
  HullmodsPageStatePersistedCopyWith<$R2, HullmodsPageStatePersisted, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _HullmodsPageStatePersistedCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class HullmodsPageStateMapper extends ClassMapperBase<HullmodsPageState> {
  HullmodsPageStateMapper._();

  static HullmodsPageStateMapper? _instance;
  static HullmodsPageStateMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = HullmodsPageStateMapper._());
      HullmodsPageStatePersistedMapper.ensureInitialized();
      HullmodMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'HullmodsPageState';

  static HullmodsPageStatePersisted _$persisted(HullmodsPageState v) =>
      v.persisted;
  static const Field<HullmodsPageState, HullmodsPageStatePersisted>
  _f$persisted = Field(
    'persisted',
    _$persisted,
    opt: true,
    def: const HullmodsPageStatePersisted(),
  );
  static List<Hullmod> _$allHullmods(HullmodsPageState v) => v.allHullmods;
  static const Field<HullmodsPageState, List<Hullmod>> _f$allHullmods = Field(
    'allHullmods',
    _$allHullmods,
    opt: true,
    def: const [],
  );
  static List<Hullmod> _$filteredHullmods(HullmodsPageState v) =>
      v.filteredHullmods;
  static const Field<HullmodsPageState, List<Hullmod>> _f$filteredHullmods =
      Field('filteredHullmods', _$filteredHullmods, opt: true, def: const []);
  static List<Hullmod> _$hullmodsBeforeGridFilter(HullmodsPageState v) =>
      v.hullmodsBeforeGridFilter;
  static const Field<HullmodsPageState, List<Hullmod>>
  _f$hullmodsBeforeGridFilter = Field(
    'hullmodsBeforeGridFilter',
    _$hullmodsBeforeGridFilter,
    opt: true,
    def: const [],
  );
  static Map<String, List<String>> _$hullmodSearchIndices(
    HullmodsPageState v,
  ) => v.hullmodSearchIndices;
  static const Field<HullmodsPageState, Map<String, List<String>>>
  _f$hullmodSearchIndices = Field(
    'hullmodSearchIndices',
    _$hullmodSearchIndices,
    opt: true,
    def: const {},
  );
  static String _$currentSearchQuery(HullmodsPageState v) =>
      v.currentSearchQuery;
  static const Field<HullmodsPageState, String> _f$currentSearchQuery = Field(
    'currentSearchQuery',
    _$currentSearchQuery,
    opt: true,
    def: '',
  );
  static bool _$isLoading(HullmodsPageState v) => v.isLoading;
  static const Field<HullmodsPageState, bool> _f$isLoading = Field(
    'isLoading',
    _$isLoading,
    opt: true,
    def: false,
  );

  @override
  final MappableFields<HullmodsPageState> fields = const {
    #persisted: _f$persisted,
    #allHullmods: _f$allHullmods,
    #filteredHullmods: _f$filteredHullmods,
    #hullmodsBeforeGridFilter: _f$hullmodsBeforeGridFilter,
    #hullmodSearchIndices: _f$hullmodSearchIndices,
    #currentSearchQuery: _f$currentSearchQuery,
    #isLoading: _f$isLoading,
  };

  static HullmodsPageState _instantiate(DecodingData data) {
    return HullmodsPageState(
      persisted: data.dec(_f$persisted),
      allHullmods: data.dec(_f$allHullmods),
      filteredHullmods: data.dec(_f$filteredHullmods),
      hullmodsBeforeGridFilter: data.dec(_f$hullmodsBeforeGridFilter),
      hullmodSearchIndices: data.dec(_f$hullmodSearchIndices),
      currentSearchQuery: data.dec(_f$currentSearchQuery),
      isLoading: data.dec(_f$isLoading),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static HullmodsPageState fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<HullmodsPageState>(map);
  }

  static HullmodsPageState fromJson(String json) {
    return ensureInitialized().decodeJson<HullmodsPageState>(json);
  }
}

mixin HullmodsPageStateMappable {
  String toJson() {
    return HullmodsPageStateMapper.ensureInitialized()
        .encodeJson<HullmodsPageState>(this as HullmodsPageState);
  }

  Map<String, dynamic> toMap() {
    return HullmodsPageStateMapper.ensureInitialized()
        .encodeMap<HullmodsPageState>(this as HullmodsPageState);
  }

  HullmodsPageStateCopyWith<
    HullmodsPageState,
    HullmodsPageState,
    HullmodsPageState
  >
  get copyWith =>
      _HullmodsPageStateCopyWithImpl<HullmodsPageState, HullmodsPageState>(
        this as HullmodsPageState,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return HullmodsPageStateMapper.ensureInitialized().stringifyValue(
      this as HullmodsPageState,
    );
  }

  @override
  bool operator ==(Object other) {
    return HullmodsPageStateMapper.ensureInitialized().equalsValue(
      this as HullmodsPageState,
      other,
    );
  }

  @override
  int get hashCode {
    return HullmodsPageStateMapper.ensureInitialized().hashValue(
      this as HullmodsPageState,
    );
  }
}

extension HullmodsPageStateValueCopy<$R, $Out>
    on ObjectCopyWith<$R, HullmodsPageState, $Out> {
  HullmodsPageStateCopyWith<$R, HullmodsPageState, $Out>
  get $asHullmodsPageState => $base.as(
    (v, t, t2) => _HullmodsPageStateCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class HullmodsPageStateCopyWith<
  $R,
  $In extends HullmodsPageState,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  HullmodsPageStatePersistedCopyWith<
    $R,
    HullmodsPageStatePersisted,
    HullmodsPageStatePersisted
  >
  get persisted;
  ListCopyWith<$R, Hullmod, HullmodCopyWith<$R, Hullmod, Hullmod>>
  get allHullmods;
  ListCopyWith<$R, Hullmod, HullmodCopyWith<$R, Hullmod, Hullmod>>
  get filteredHullmods;
  ListCopyWith<$R, Hullmod, HullmodCopyWith<$R, Hullmod, Hullmod>>
  get hullmodsBeforeGridFilter;
  MapCopyWith<
    $R,
    String,
    List<String>,
    ObjectCopyWith<$R, List<String>, List<String>>
  >
  get hullmodSearchIndices;
  $R call({
    HullmodsPageStatePersisted? persisted,
    List<Hullmod>? allHullmods,
    List<Hullmod>? filteredHullmods,
    List<Hullmod>? hullmodsBeforeGridFilter,
    Map<String, List<String>>? hullmodSearchIndices,
    String? currentSearchQuery,
    bool? isLoading,
  });
  HullmodsPageStateCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _HullmodsPageStateCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, HullmodsPageState, $Out>
    implements HullmodsPageStateCopyWith<$R, HullmodsPageState, $Out> {
  _HullmodsPageStateCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<HullmodsPageState> $mapper =
      HullmodsPageStateMapper.ensureInitialized();
  @override
  HullmodsPageStatePersistedCopyWith<
    $R,
    HullmodsPageStatePersisted,
    HullmodsPageStatePersisted
  >
  get persisted => $value.persisted.copyWith.$chain((v) => call(persisted: v));
  @override
  ListCopyWith<$R, Hullmod, HullmodCopyWith<$R, Hullmod, Hullmod>>
  get allHullmods => ListCopyWith(
    $value.allHullmods,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(allHullmods: v),
  );
  @override
  ListCopyWith<$R, Hullmod, HullmodCopyWith<$R, Hullmod, Hullmod>>
  get filteredHullmods => ListCopyWith(
    $value.filteredHullmods,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(filteredHullmods: v),
  );
  @override
  ListCopyWith<$R, Hullmod, HullmodCopyWith<$R, Hullmod, Hullmod>>
  get hullmodsBeforeGridFilter => ListCopyWith(
    $value.hullmodsBeforeGridFilter,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(hullmodsBeforeGridFilter: v),
  );
  @override
  MapCopyWith<
    $R,
    String,
    List<String>,
    ObjectCopyWith<$R, List<String>, List<String>>
  >
  get hullmodSearchIndices => MapCopyWith(
    $value.hullmodSearchIndices,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(hullmodSearchIndices: v),
  );
  @override
  $R call({
    HullmodsPageStatePersisted? persisted,
    List<Hullmod>? allHullmods,
    List<Hullmod>? filteredHullmods,
    List<Hullmod>? hullmodsBeforeGridFilter,
    Map<String, List<String>>? hullmodSearchIndices,
    String? currentSearchQuery,
    bool? isLoading,
  }) => $apply(
    FieldCopyWithData({
      if (persisted != null) #persisted: persisted,
      if (allHullmods != null) #allHullmods: allHullmods,
      if (filteredHullmods != null) #filteredHullmods: filteredHullmods,
      if (hullmodsBeforeGridFilter != null)
        #hullmodsBeforeGridFilter: hullmodsBeforeGridFilter,
      if (hullmodSearchIndices != null)
        #hullmodSearchIndices: hullmodSearchIndices,
      if (currentSearchQuery != null) #currentSearchQuery: currentSearchQuery,
      if (isLoading != null) #isLoading: isLoading,
    }),
  );
  @override
  HullmodsPageState $make(CopyWithData data) => HullmodsPageState(
    persisted: data.get(#persisted, or: $value.persisted),
    allHullmods: data.get(#allHullmods, or: $value.allHullmods),
    filteredHullmods: data.get(#filteredHullmods, or: $value.filteredHullmods),
    hullmodsBeforeGridFilter: data.get(
      #hullmodsBeforeGridFilter,
      or: $value.hullmodsBeforeGridFilter,
    ),
    hullmodSearchIndices: data.get(
      #hullmodSearchIndices,
      or: $value.hullmodSearchIndices,
    ),
    currentSearchQuery: data.get(
      #currentSearchQuery,
      or: $value.currentSearchQuery,
    ),
    isLoading: data.get(#isLoading, or: $value.isLoading),
  );

  @override
  HullmodsPageStateCopyWith<$R2, HullmodsPageState, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _HullmodsPageStateCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

