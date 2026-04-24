// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'mod_browser_page_controller.dart';

class CatalogPageStatePersistedMapper
    extends ClassMapperBase<CatalogPageStatePersisted> {
  CatalogPageStatePersistedMapper._();

  static CatalogPageStatePersistedMapper? _instance;
  static CatalogPageStatePersistedMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(
        _instance = CatalogPageStatePersistedMapper._(),
      );
    }
    return _instance!;
  }

  @override
  final String id = 'CatalogPageStatePersisted';

  static bool _$showFilters(CatalogPageStatePersisted v) => v.showFilters;
  static const Field<CatalogPageStatePersisted, bool> _f$showFilters = Field(
    'showFilters',
    _$showFilters,
    opt: true,
    def: false,
  );

  @override
  final MappableFields<CatalogPageStatePersisted> fields = const {
    #showFilters: _f$showFilters,
  };

  static CatalogPageStatePersisted _instantiate(DecodingData data) {
    return CatalogPageStatePersisted(showFilters: data.dec(_f$showFilters));
  }

  @override
  final Function instantiate = _instantiate;

  static CatalogPageStatePersisted fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<CatalogPageStatePersisted>(map);
  }

  static CatalogPageStatePersisted fromJson(String json) {
    return ensureInitialized().decodeJson<CatalogPageStatePersisted>(json);
  }
}

mixin CatalogPageStatePersistedMappable {
  String toJson() {
    return CatalogPageStatePersistedMapper.ensureInitialized()
        .encodeJson<CatalogPageStatePersisted>(
          this as CatalogPageStatePersisted,
        );
  }

  Map<String, dynamic> toMap() {
    return CatalogPageStatePersistedMapper.ensureInitialized()
        .encodeMap<CatalogPageStatePersisted>(
          this as CatalogPageStatePersisted,
        );
  }

  CatalogPageStatePersistedCopyWith<
    CatalogPageStatePersisted,
    CatalogPageStatePersisted,
    CatalogPageStatePersisted
  >
  get copyWith =>
      _CatalogPageStatePersistedCopyWithImpl<
        CatalogPageStatePersisted,
        CatalogPageStatePersisted
      >(this as CatalogPageStatePersisted, $identity, $identity);
  @override
  String toString() {
    return CatalogPageStatePersistedMapper.ensureInitialized().stringifyValue(
      this as CatalogPageStatePersisted,
    );
  }

  @override
  bool operator ==(Object other) {
    return CatalogPageStatePersistedMapper.ensureInitialized().equalsValue(
      this as CatalogPageStatePersisted,
      other,
    );
  }

  @override
  int get hashCode {
    return CatalogPageStatePersistedMapper.ensureInitialized().hashValue(
      this as CatalogPageStatePersisted,
    );
  }
}

extension CatalogPageStatePersistedValueCopy<$R, $Out>
    on ObjectCopyWith<$R, CatalogPageStatePersisted, $Out> {
  CatalogPageStatePersistedCopyWith<$R, CatalogPageStatePersisted, $Out>
  get $asCatalogPageStatePersisted => $base.as(
    (v, t, t2) => _CatalogPageStatePersistedCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class CatalogPageStatePersistedCopyWith<
  $R,
  $In extends CatalogPageStatePersisted,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({bool? showFilters});
  CatalogPageStatePersistedCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _CatalogPageStatePersistedCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, CatalogPageStatePersisted, $Out>
    implements
        CatalogPageStatePersistedCopyWith<$R, CatalogPageStatePersisted, $Out> {
  _CatalogPageStatePersistedCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<CatalogPageStatePersisted> $mapper =
      CatalogPageStatePersistedMapper.ensureInitialized();
  @override
  $R call({bool? showFilters}) => $apply(
    FieldCopyWithData({if (showFilters != null) #showFilters: showFilters}),
  );
  @override
  CatalogPageStatePersisted $make(CopyWithData data) =>
      CatalogPageStatePersisted(
        showFilters: data.get(#showFilters, or: $value.showFilters),
      );

  @override
  CatalogPageStatePersistedCopyWith<$R2, CatalogPageStatePersisted, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _CatalogPageStatePersistedCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class CatalogPageStateMapper extends ClassMapperBase<CatalogPageState> {
  CatalogPageStateMapper._();

  static CatalogPageStateMapper? _instance;
  static CatalogPageStateMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = CatalogPageStateMapper._());
      CatalogPageStatePersistedMapper.ensureInitialized();
      ScrapedModMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'CatalogPageState';

  static CatalogPageStatePersisted _$persisted(CatalogPageState v) =>
      v.persisted;
  static const Field<CatalogPageState, CatalogPageStatePersisted> _f$persisted =
      Field(
        'persisted',
        _$persisted,
        opt: true,
        def: const CatalogPageStatePersisted(),
      );
  static List<ScrapedMod> _$allMods(CatalogPageState v) => v.allMods;
  static const Field<CatalogPageState, List<ScrapedMod>> _f$allMods = Field(
    'allMods',
    _$allMods,
    opt: true,
    def: const [],
  );
  static List<ScrapedMod> _$displayedMods(CatalogPageState v) =>
      v.displayedMods;
  static const Field<CatalogPageState, List<ScrapedMod>> _f$displayedMods =
      Field('displayedMods', _$displayedMods, opt: true, def: const []);
  static String _$currentSearchQuery(CatalogPageState v) =>
      v.currentSearchQuery;
  static const Field<CatalogPageState, String> _f$currentSearchQuery = Field(
    'currentSearchQuery',
    _$currentSearchQuery,
    opt: true,
    def: '',
  );
  static CatalogSortKey _$selectedSort(CatalogPageState v) => v.selectedSort;
  static const Field<CatalogPageState, CatalogSortKey> _f$selectedSort = Field(
    'selectedSort',
    _$selectedSort,
    opt: true,
    def: CatalogSortKey.mostViewed,
  );
  static bool _$isLoading(CatalogPageState v) => v.isLoading;
  static const Field<CatalogPageState, bool> _f$isLoading = Field(
    'isLoading',
    _$isLoading,
    opt: true,
    def: false,
  );

  @override
  final MappableFields<CatalogPageState> fields = const {
    #persisted: _f$persisted,
    #allMods: _f$allMods,
    #displayedMods: _f$displayedMods,
    #currentSearchQuery: _f$currentSearchQuery,
    #selectedSort: _f$selectedSort,
    #isLoading: _f$isLoading,
  };

  static CatalogPageState _instantiate(DecodingData data) {
    return CatalogPageState(
      persisted: data.dec(_f$persisted),
      allMods: data.dec(_f$allMods),
      displayedMods: data.dec(_f$displayedMods),
      currentSearchQuery: data.dec(_f$currentSearchQuery),
      selectedSort: data.dec(_f$selectedSort),
      isLoading: data.dec(_f$isLoading),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static CatalogPageState fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<CatalogPageState>(map);
  }

  static CatalogPageState fromJson(String json) {
    return ensureInitialized().decodeJson<CatalogPageState>(json);
  }
}

mixin CatalogPageStateMappable {
  String toJson() {
    return CatalogPageStateMapper.ensureInitialized()
        .encodeJson<CatalogPageState>(this as CatalogPageState);
  }

  Map<String, dynamic> toMap() {
    return CatalogPageStateMapper.ensureInitialized()
        .encodeMap<CatalogPageState>(this as CatalogPageState);
  }

  CatalogPageStateCopyWith<CatalogPageState, CatalogPageState, CatalogPageState>
  get copyWith =>
      _CatalogPageStateCopyWithImpl<CatalogPageState, CatalogPageState>(
        this as CatalogPageState,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return CatalogPageStateMapper.ensureInitialized().stringifyValue(
      this as CatalogPageState,
    );
  }

  @override
  bool operator ==(Object other) {
    return CatalogPageStateMapper.ensureInitialized().equalsValue(
      this as CatalogPageState,
      other,
    );
  }

  @override
  int get hashCode {
    return CatalogPageStateMapper.ensureInitialized().hashValue(
      this as CatalogPageState,
    );
  }
}

extension CatalogPageStateValueCopy<$R, $Out>
    on ObjectCopyWith<$R, CatalogPageState, $Out> {
  CatalogPageStateCopyWith<$R, CatalogPageState, $Out>
  get $asCatalogPageState =>
      $base.as((v, t, t2) => _CatalogPageStateCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class CatalogPageStateCopyWith<$R, $In extends CatalogPageState, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  CatalogPageStatePersistedCopyWith<
    $R,
    CatalogPageStatePersisted,
    CatalogPageStatePersisted
  >
  get persisted;
  ListCopyWith<$R, ScrapedMod, ScrapedModCopyWith<$R, ScrapedMod, ScrapedMod>>
  get allMods;
  ListCopyWith<$R, ScrapedMod, ScrapedModCopyWith<$R, ScrapedMod, ScrapedMod>>
  get displayedMods;
  $R call({
    CatalogPageStatePersisted? persisted,
    List<ScrapedMod>? allMods,
    List<ScrapedMod>? displayedMods,
    String? currentSearchQuery,
    CatalogSortKey? selectedSort,
    bool? isLoading,
  });
  CatalogPageStateCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _CatalogPageStateCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, CatalogPageState, $Out>
    implements CatalogPageStateCopyWith<$R, CatalogPageState, $Out> {
  _CatalogPageStateCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<CatalogPageState> $mapper =
      CatalogPageStateMapper.ensureInitialized();
  @override
  CatalogPageStatePersistedCopyWith<
    $R,
    CatalogPageStatePersisted,
    CatalogPageStatePersisted
  >
  get persisted => $value.persisted.copyWith.$chain((v) => call(persisted: v));
  @override
  ListCopyWith<$R, ScrapedMod, ScrapedModCopyWith<$R, ScrapedMod, ScrapedMod>>
  get allMods => ListCopyWith(
    $value.allMods,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(allMods: v),
  );
  @override
  ListCopyWith<$R, ScrapedMod, ScrapedModCopyWith<$R, ScrapedMod, ScrapedMod>>
  get displayedMods => ListCopyWith(
    $value.displayedMods,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(displayedMods: v),
  );
  @override
  $R call({
    CatalogPageStatePersisted? persisted,
    List<ScrapedMod>? allMods,
    List<ScrapedMod>? displayedMods,
    String? currentSearchQuery,
    CatalogSortKey? selectedSort,
    bool? isLoading,
  }) => $apply(
    FieldCopyWithData({
      if (persisted != null) #persisted: persisted,
      if (allMods != null) #allMods: allMods,
      if (displayedMods != null) #displayedMods: displayedMods,
      if (currentSearchQuery != null) #currentSearchQuery: currentSearchQuery,
      if (selectedSort != null) #selectedSort: selectedSort,
      if (isLoading != null) #isLoading: isLoading,
    }),
  );
  @override
  CatalogPageState $make(CopyWithData data) => CatalogPageState(
    persisted: data.get(#persisted, or: $value.persisted),
    allMods: data.get(#allMods, or: $value.allMods),
    displayedMods: data.get(#displayedMods, or: $value.displayedMods),
    currentSearchQuery: data.get(
      #currentSearchQuery,
      or: $value.currentSearchQuery,
    ),
    selectedSort: data.get(#selectedSort, or: $value.selectedSort),
    isLoading: data.get(#isLoading, or: $value.isLoading),
  );

  @override
  CatalogPageStateCopyWith<$R2, CatalogPageState, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _CatalogPageStateCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

