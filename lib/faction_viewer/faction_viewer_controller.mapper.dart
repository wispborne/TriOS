// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'faction_viewer_controller.dart';

class FactionViewModeMapper extends EnumMapper<FactionViewMode> {
  FactionViewModeMapper._();

  static FactionViewModeMapper? _instance;
  static FactionViewModeMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = FactionViewModeMapper._());
    }
    return _instance!;
  }

  static FactionViewMode fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  FactionViewMode decode(dynamic value) {
    switch (value) {
      case r'gallery':
        return FactionViewMode.gallery;
      case r'grid':
        return FactionViewMode.grid;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(FactionViewMode self) {
    switch (self) {
      case FactionViewMode.gallery:
        return r'gallery';
      case FactionViewMode.grid:
        return r'grid';
    }
  }
}

extension FactionViewModeMapperExtension on FactionViewMode {
  String toValue() {
    FactionViewModeMapper.ensureInitialized();
    return MapperContainer.globals.toValue<FactionViewMode>(this) as String;
  }
}

class FactionGallerySortFieldMapper
    extends EnumMapper<FactionGallerySortField> {
  FactionGallerySortFieldMapper._();

  static FactionGallerySortFieldMapper? _instance;
  static FactionGallerySortFieldMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(
        _instance = FactionGallerySortFieldMapper._(),
      );
    }
    return _instance!;
  }

  static FactionGallerySortField fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  FactionGallerySortField decode(dynamic value) {
    switch (value) {
      case r'name':
        return FactionGallerySortField.name;
      case r'ships':
        return FactionGallerySortField.ships;
      case r'weapons':
        return FactionGallerySortField.weapons;
      case r'aggression':
        return FactionGallerySortField.aggression;
      case r'shipQuality':
        return FactionGallerySortField.shipQuality;
      case r'officerQuality':
        return FactionGallerySortField.officerQuality;
      case r'source':
        return FactionGallerySortField.source;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(FactionGallerySortField self) {
    switch (self) {
      case FactionGallerySortField.name:
        return r'name';
      case FactionGallerySortField.ships:
        return r'ships';
      case FactionGallerySortField.weapons:
        return r'weapons';
      case FactionGallerySortField.aggression:
        return r'aggression';
      case FactionGallerySortField.shipQuality:
        return r'shipQuality';
      case FactionGallerySortField.officerQuality:
        return r'officerQuality';
      case FactionGallerySortField.source:
        return r'source';
    }
  }
}

extension FactionGallerySortFieldMapperExtension on FactionGallerySortField {
  String toValue() {
    FactionGallerySortFieldMapper.ensureInitialized();
    return MapperContainer.globals.toValue<FactionGallerySortField>(this)
        as String;
  }
}

class FactionViewerStatePersistedMapper
    extends ClassMapperBase<FactionViewerStatePersisted> {
  FactionViewerStatePersistedMapper._();

  static FactionViewerStatePersistedMapper? _instance;
  static FactionViewerStatePersistedMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(
        _instance = FactionViewerStatePersistedMapper._(),
      );
      FactionViewModeMapper.ensureInitialized();
      FactionGallerySortFieldMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'FactionViewerStatePersisted';

  static FactionViewMode _$viewMode(FactionViewerStatePersisted v) =>
      v.viewMode;
  static const Field<FactionViewerStatePersisted, FactionViewMode> _f$viewMode =
      Field('viewMode', _$viewMode, opt: true, def: FactionViewMode.gallery);
  static bool _$showFilters(FactionViewerStatePersisted v) => v.showFilters;
  static const Field<FactionViewerStatePersisted, bool> _f$showFilters = Field(
    'showFilters',
    _$showFilters,
    opt: true,
    def: false,
  );
  static FactionGallerySortField _$gallerySortField(
    FactionViewerStatePersisted v,
  ) => v.gallerySortField;
  static const Field<FactionViewerStatePersisted, FactionGallerySortField>
  _f$gallerySortField = Field(
    'gallerySortField',
    _$gallerySortField,
    opt: true,
    def: FactionGallerySortField.ships,
  );
  static bool _$gallerySortAscending(FactionViewerStatePersisted v) =>
      v.gallerySortAscending;
  static const Field<FactionViewerStatePersisted, bool>
  _f$gallerySortAscending = Field(
    'gallerySortAscending',
    _$gallerySortAscending,
    opt: true,
    def: false,
  );

  @override
  final MappableFields<FactionViewerStatePersisted> fields = const {
    #viewMode: _f$viewMode,
    #showFilters: _f$showFilters,
    #gallerySortField: _f$gallerySortField,
    #gallerySortAscending: _f$gallerySortAscending,
  };

  static FactionViewerStatePersisted _instantiate(DecodingData data) {
    return FactionViewerStatePersisted(
      viewMode: data.dec(_f$viewMode),
      showFilters: data.dec(_f$showFilters),
      gallerySortField: data.dec(_f$gallerySortField),
      gallerySortAscending: data.dec(_f$gallerySortAscending),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static FactionViewerStatePersisted fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<FactionViewerStatePersisted>(map);
  }

  static FactionViewerStatePersisted fromJson(String json) {
    return ensureInitialized().decodeJson<FactionViewerStatePersisted>(json);
  }
}

mixin FactionViewerStatePersistedMappable {
  String toJson() {
    return FactionViewerStatePersistedMapper.ensureInitialized()
        .encodeJson<FactionViewerStatePersisted>(
          this as FactionViewerStatePersisted,
        );
  }

  Map<String, dynamic> toMap() {
    return FactionViewerStatePersistedMapper.ensureInitialized()
        .encodeMap<FactionViewerStatePersisted>(
          this as FactionViewerStatePersisted,
        );
  }

  FactionViewerStatePersistedCopyWith<
    FactionViewerStatePersisted,
    FactionViewerStatePersisted,
    FactionViewerStatePersisted
  >
  get copyWith =>
      _FactionViewerStatePersistedCopyWithImpl<
        FactionViewerStatePersisted,
        FactionViewerStatePersisted
      >(this as FactionViewerStatePersisted, $identity, $identity);
  @override
  String toString() {
    return FactionViewerStatePersistedMapper.ensureInitialized().stringifyValue(
      this as FactionViewerStatePersisted,
    );
  }

  @override
  bool operator ==(Object other) {
    return FactionViewerStatePersistedMapper.ensureInitialized().equalsValue(
      this as FactionViewerStatePersisted,
      other,
    );
  }

  @override
  int get hashCode {
    return FactionViewerStatePersistedMapper.ensureInitialized().hashValue(
      this as FactionViewerStatePersisted,
    );
  }
}

extension FactionViewerStatePersistedValueCopy<$R, $Out>
    on ObjectCopyWith<$R, FactionViewerStatePersisted, $Out> {
  FactionViewerStatePersistedCopyWith<$R, FactionViewerStatePersisted, $Out>
  get $asFactionViewerStatePersisted => $base.as(
    (v, t, t2) => _FactionViewerStatePersistedCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class FactionViewerStatePersistedCopyWith<
  $R,
  $In extends FactionViewerStatePersisted,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    FactionViewMode? viewMode,
    bool? showFilters,
    FactionGallerySortField? gallerySortField,
    bool? gallerySortAscending,
  });
  FactionViewerStatePersistedCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _FactionViewerStatePersistedCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, FactionViewerStatePersisted, $Out>
    implements
        FactionViewerStatePersistedCopyWith<
          $R,
          FactionViewerStatePersisted,
          $Out
        > {
  _FactionViewerStatePersistedCopyWithImpl(
    super.value,
    super.then,
    super.then2,
  );

  @override
  late final ClassMapperBase<FactionViewerStatePersisted> $mapper =
      FactionViewerStatePersistedMapper.ensureInitialized();
  @override
  $R call({
    FactionViewMode? viewMode,
    bool? showFilters,
    FactionGallerySortField? gallerySortField,
    bool? gallerySortAscending,
  }) => $apply(
    FieldCopyWithData({
      if (viewMode != null) #viewMode: viewMode,
      if (showFilters != null) #showFilters: showFilters,
      if (gallerySortField != null) #gallerySortField: gallerySortField,
      if (gallerySortAscending != null)
        #gallerySortAscending: gallerySortAscending,
    }),
  );
  @override
  FactionViewerStatePersisted $make(CopyWithData data) =>
      FactionViewerStatePersisted(
        viewMode: data.get(#viewMode, or: $value.viewMode),
        showFilters: data.get(#showFilters, or: $value.showFilters),
        gallerySortField: data.get(
          #gallerySortField,
          or: $value.gallerySortField,
        ),
        gallerySortAscending: data.get(
          #gallerySortAscending,
          or: $value.gallerySortAscending,
        ),
      );

  @override
  FactionViewerStatePersistedCopyWith<$R2, FactionViewerStatePersisted, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _FactionViewerStatePersistedCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class FactionViewerStateMapper extends ClassMapperBase<FactionViewerState> {
  FactionViewerStateMapper._();

  static FactionViewerStateMapper? _instance;
  static FactionViewerStateMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = FactionViewerStateMapper._());
      FactionViewerStatePersistedMapper.ensureInitialized();
      FactionMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'FactionViewerState';

  static FactionViewerStatePersisted _$persisted(FactionViewerState v) =>
      v.persisted;
  static const Field<FactionViewerState, FactionViewerStatePersisted>
  _f$persisted = Field(
    'persisted',
    _$persisted,
    opt: true,
    def: const FactionViewerStatePersisted(),
  );
  static List<Faction> _$allFactions(FactionViewerState v) => v.allFactions;
  static const Field<FactionViewerState, List<Faction>> _f$allFactions = Field(
    'allFactions',
    _$allFactions,
    opt: true,
    def: const [],
  );
  static List<Faction> _$filteredFactions(FactionViewerState v) =>
      v.filteredFactions;
  static const Field<FactionViewerState, List<Faction>> _f$filteredFactions =
      Field('filteredFactions', _$filteredFactions, opt: true, def: const []);
  static String _$searchQuery(FactionViewerState v) => v.searchQuery;
  static const Field<FactionViewerState, String> _f$searchQuery = Field(
    'searchQuery',
    _$searchQuery,
    opt: true,
    def: '',
  );
  static bool _$isLoading(FactionViewerState v) => v.isLoading;
  static const Field<FactionViewerState, bool> _f$isLoading = Field(
    'isLoading',
    _$isLoading,
    opt: true,
    def: false,
  );

  @override
  final MappableFields<FactionViewerState> fields = const {
    #persisted: _f$persisted,
    #allFactions: _f$allFactions,
    #filteredFactions: _f$filteredFactions,
    #searchQuery: _f$searchQuery,
    #isLoading: _f$isLoading,
  };

  static FactionViewerState _instantiate(DecodingData data) {
    return FactionViewerState(
      persisted: data.dec(_f$persisted),
      allFactions: data.dec(_f$allFactions),
      filteredFactions: data.dec(_f$filteredFactions),
      searchQuery: data.dec(_f$searchQuery),
      isLoading: data.dec(_f$isLoading),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static FactionViewerState fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<FactionViewerState>(map);
  }

  static FactionViewerState fromJson(String json) {
    return ensureInitialized().decodeJson<FactionViewerState>(json);
  }
}

mixin FactionViewerStateMappable {
  String toJson() {
    return FactionViewerStateMapper.ensureInitialized()
        .encodeJson<FactionViewerState>(this as FactionViewerState);
  }

  Map<String, dynamic> toMap() {
    return FactionViewerStateMapper.ensureInitialized()
        .encodeMap<FactionViewerState>(this as FactionViewerState);
  }

  FactionViewerStateCopyWith<
    FactionViewerState,
    FactionViewerState,
    FactionViewerState
  >
  get copyWith =>
      _FactionViewerStateCopyWithImpl<FactionViewerState, FactionViewerState>(
        this as FactionViewerState,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return FactionViewerStateMapper.ensureInitialized().stringifyValue(
      this as FactionViewerState,
    );
  }

  @override
  bool operator ==(Object other) {
    return FactionViewerStateMapper.ensureInitialized().equalsValue(
      this as FactionViewerState,
      other,
    );
  }

  @override
  int get hashCode {
    return FactionViewerStateMapper.ensureInitialized().hashValue(
      this as FactionViewerState,
    );
  }
}

extension FactionViewerStateValueCopy<$R, $Out>
    on ObjectCopyWith<$R, FactionViewerState, $Out> {
  FactionViewerStateCopyWith<$R, FactionViewerState, $Out>
  get $asFactionViewerState => $base.as(
    (v, t, t2) => _FactionViewerStateCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class FactionViewerStateCopyWith<
  $R,
  $In extends FactionViewerState,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  FactionViewerStatePersistedCopyWith<
    $R,
    FactionViewerStatePersisted,
    FactionViewerStatePersisted
  >
  get persisted;
  ListCopyWith<$R, Faction, FactionCopyWith<$R, Faction, Faction>>
  get allFactions;
  ListCopyWith<$R, Faction, FactionCopyWith<$R, Faction, Faction>>
  get filteredFactions;
  $R call({
    FactionViewerStatePersisted? persisted,
    List<Faction>? allFactions,
    List<Faction>? filteredFactions,
    String? searchQuery,
    bool? isLoading,
  });
  FactionViewerStateCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _FactionViewerStateCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, FactionViewerState, $Out>
    implements FactionViewerStateCopyWith<$R, FactionViewerState, $Out> {
  _FactionViewerStateCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<FactionViewerState> $mapper =
      FactionViewerStateMapper.ensureInitialized();
  @override
  FactionViewerStatePersistedCopyWith<
    $R,
    FactionViewerStatePersisted,
    FactionViewerStatePersisted
  >
  get persisted => $value.persisted.copyWith.$chain((v) => call(persisted: v));
  @override
  ListCopyWith<$R, Faction, FactionCopyWith<$R, Faction, Faction>>
  get allFactions => ListCopyWith(
    $value.allFactions,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(allFactions: v),
  );
  @override
  ListCopyWith<$R, Faction, FactionCopyWith<$R, Faction, Faction>>
  get filteredFactions => ListCopyWith(
    $value.filteredFactions,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(filteredFactions: v),
  );
  @override
  $R call({
    FactionViewerStatePersisted? persisted,
    List<Faction>? allFactions,
    List<Faction>? filteredFactions,
    String? searchQuery,
    bool? isLoading,
  }) => $apply(
    FieldCopyWithData({
      if (persisted != null) #persisted: persisted,
      if (allFactions != null) #allFactions: allFactions,
      if (filteredFactions != null) #filteredFactions: filteredFactions,
      if (searchQuery != null) #searchQuery: searchQuery,
      if (isLoading != null) #isLoading: isLoading,
    }),
  );
  @override
  FactionViewerState $make(CopyWithData data) => FactionViewerState(
    persisted: data.get(#persisted, or: $value.persisted),
    allFactions: data.get(#allFactions, or: $value.allFactions),
    filteredFactions: data.get(#filteredFactions, or: $value.filteredFactions),
    searchQuery: data.get(#searchQuery, or: $value.searchQuery),
    isLoading: data.get(#isLoading, or: $value.isLoading),
  );

  @override
  FactionViewerStateCopyWith<$R2, FactionViewerState, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _FactionViewerStateCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

