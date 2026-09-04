// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'modpacks_page_controller.dart';

class ModpackSortFieldMapper extends EnumMapper<ModpackSortField> {
  ModpackSortFieldMapper._();

  static ModpackSortFieldMapper? _instance;
  static ModpackSortFieldMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ModpackSortFieldMapper._());
    }
    return _instance!;
  }

  static ModpackSortField fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  ModpackSortField decode(dynamic value) {
    switch (value) {
      case r'name':
        return ModpackSortField.name;
      case r'author':
        return ModpackSortField.author;
      case r'packVersion':
        return ModpackSortField.packVersion;
      case r'gameVersion':
        return ModpackSortField.gameVersion;
      case r'installedCount':
        return ModpackSortField.installedCount;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(ModpackSortField self) {
    switch (self) {
      case ModpackSortField.name:
        return r'name';
      case ModpackSortField.author:
        return r'author';
      case ModpackSortField.packVersion:
        return r'packVersion';
      case ModpackSortField.gameVersion:
        return r'gameVersion';
      case ModpackSortField.installedCount:
        return r'installedCount';
    }
  }
}

extension ModpackSortFieldMapperExtension on ModpackSortField {
  String toValue() {
    ModpackSortFieldMapper.ensureInitialized();
    return MapperContainer.globals.toValue<ModpackSortField>(this) as String;
  }
}

class ModpacksPageStatePersistedMapper
    extends ClassMapperBase<ModpacksPageStatePersisted> {
  ModpacksPageStatePersistedMapper._();

  static ModpacksPageStatePersistedMapper? _instance;
  static ModpacksPageStatePersistedMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(
        _instance = ModpacksPageStatePersistedMapper._(),
      );
      ModpackSortFieldMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ModpacksPageStatePersisted';

  static ModpackSortField _$sortField(ModpacksPageStatePersisted v) =>
      v.sortField;
  static const Field<ModpacksPageStatePersisted, ModpackSortField>
  _f$sortField = Field(
    'sortField',
    _$sortField,
    opt: true,
    def: ModpackSortField.name,
  );
  static bool _$sortAscending(ModpacksPageStatePersisted v) => v.sortAscending;
  static const Field<ModpacksPageStatePersisted, bool> _f$sortAscending = Field(
    'sortAscending',
    _$sortAscending,
    opt: true,
    def: true,
  );
  static bool _$showFilters(ModpacksPageStatePersisted v) => v.showFilters;
  static const Field<ModpacksPageStatePersisted, bool> _f$showFilters = Field(
    'showFilters',
    _$showFilters,
    opt: true,
    def: false,
  );

  @override
  final MappableFields<ModpacksPageStatePersisted> fields = const {
    #sortField: _f$sortField,
    #sortAscending: _f$sortAscending,
    #showFilters: _f$showFilters,
  };

  static ModpacksPageStatePersisted _instantiate(DecodingData data) {
    return ModpacksPageStatePersisted(
      sortField: data.dec(_f$sortField),
      sortAscending: data.dec(_f$sortAscending),
      showFilters: data.dec(_f$showFilters),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ModpacksPageStatePersisted fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ModpacksPageStatePersisted>(map);
  }

  static ModpacksPageStatePersisted fromJson(String json) {
    return ensureInitialized().decodeJson<ModpacksPageStatePersisted>(json);
  }
}

mixin ModpacksPageStatePersistedMappable {
  String toJson() {
    return ModpacksPageStatePersistedMapper.ensureInitialized()
        .encodeJson<ModpacksPageStatePersisted>(
          this as ModpacksPageStatePersisted,
        );
  }

  Map<String, dynamic> toMap() {
    return ModpacksPageStatePersistedMapper.ensureInitialized()
        .encodeMap<ModpacksPageStatePersisted>(
          this as ModpacksPageStatePersisted,
        );
  }

  ModpacksPageStatePersistedCopyWith<
    ModpacksPageStatePersisted,
    ModpacksPageStatePersisted,
    ModpacksPageStatePersisted
  >
  get copyWith =>
      _ModpacksPageStatePersistedCopyWithImpl<
        ModpacksPageStatePersisted,
        ModpacksPageStatePersisted
      >(this as ModpacksPageStatePersisted, $identity, $identity);
  @override
  String toString() {
    return ModpacksPageStatePersistedMapper.ensureInitialized().stringifyValue(
      this as ModpacksPageStatePersisted,
    );
  }

  @override
  bool operator ==(Object other) {
    return ModpacksPageStatePersistedMapper.ensureInitialized().equalsValue(
      this as ModpacksPageStatePersisted,
      other,
    );
  }

  @override
  int get hashCode {
    return ModpacksPageStatePersistedMapper.ensureInitialized().hashValue(
      this as ModpacksPageStatePersisted,
    );
  }
}

extension ModpacksPageStatePersistedValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ModpacksPageStatePersisted, $Out> {
  ModpacksPageStatePersistedCopyWith<$R, ModpacksPageStatePersisted, $Out>
  get $asModpacksPageStatePersisted => $base.as(
    (v, t, t2) => _ModpacksPageStatePersistedCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class ModpacksPageStatePersistedCopyWith<
  $R,
  $In extends ModpacksPageStatePersisted,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    ModpackSortField? sortField,
    bool? sortAscending,
    bool? showFilters,
  });
  ModpacksPageStatePersistedCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _ModpacksPageStatePersistedCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ModpacksPageStatePersisted, $Out>
    implements
        ModpacksPageStatePersistedCopyWith<
          $R,
          ModpacksPageStatePersisted,
          $Out
        > {
  _ModpacksPageStatePersistedCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ModpacksPageStatePersisted> $mapper =
      ModpacksPageStatePersistedMapper.ensureInitialized();
  @override
  $R call({
    ModpackSortField? sortField,
    bool? sortAscending,
    bool? showFilters,
  }) => $apply(
    FieldCopyWithData({
      if (sortField != null) #sortField: sortField,
      if (sortAscending != null) #sortAscending: sortAscending,
      if (showFilters != null) #showFilters: showFilters,
    }),
  );
  @override
  ModpacksPageStatePersisted $make(CopyWithData data) =>
      ModpacksPageStatePersisted(
        sortField: data.get(#sortField, or: $value.sortField),
        sortAscending: data.get(#sortAscending, or: $value.sortAscending),
        showFilters: data.get(#showFilters, or: $value.showFilters),
      );

  @override
  ModpacksPageStatePersistedCopyWith<$R2, ModpacksPageStatePersisted, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _ModpacksPageStatePersistedCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class ModpacksPageStateMapper extends ClassMapperBase<ModpacksPageState> {
  ModpacksPageStateMapper._();

  static ModpacksPageStateMapper? _instance;
  static ModpacksPageStateMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ModpacksPageStateMapper._());
      ModpacksPageStatePersistedMapper.ensureInitialized();
      ModpackCardDataMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ModpacksPageState';

  static ModpacksPageStatePersisted _$persisted(ModpacksPageState v) =>
      v.persisted;
  static const Field<ModpacksPageState, ModpacksPageStatePersisted>
  _f$persisted = Field(
    'persisted',
    _$persisted,
    opt: true,
    def: const ModpacksPageStatePersisted(),
  );
  static List<ModpackCardData> _$allCards(ModpacksPageState v) => v.allCards;
  static const Field<ModpacksPageState, List<ModpackCardData>> _f$allCards =
      Field('allCards', _$allCards, opt: true, def: const []);
  static List<ModpackCardData> _$visibleCards(ModpacksPageState v) =>
      v.visibleCards;
  static const Field<ModpacksPageState, List<ModpackCardData>> _f$visibleCards =
      Field('visibleCards', _$visibleCards, opt: true, def: const []);
  static String _$searchQuery(ModpacksPageState v) => v.searchQuery;
  static const Field<ModpacksPageState, String> _f$searchQuery = Field(
    'searchQuery',
    _$searchQuery,
    opt: true,
    def: '',
  );
  static bool _$isLoading(ModpacksPageState v) => v.isLoading;
  static const Field<ModpacksPageState, bool> _f$isLoading = Field(
    'isLoading',
    _$isLoading,
    opt: true,
    def: false,
  );
  static String? _$openPackId(ModpacksPageState v) => v.openPackId;
  static const Field<ModpacksPageState, String> _f$openPackId = Field(
    'openPackId',
    _$openPackId,
    opt: true,
  );
  static bool _$isEditing(ModpacksPageState v) => v.isEditing;
  static const Field<ModpacksPageState, bool> _f$isEditing = Field(
    'isEditing',
    _$isEditing,
    opt: true,
    def: false,
  );

  @override
  final MappableFields<ModpacksPageState> fields = const {
    #persisted: _f$persisted,
    #allCards: _f$allCards,
    #visibleCards: _f$visibleCards,
    #searchQuery: _f$searchQuery,
    #isLoading: _f$isLoading,
    #openPackId: _f$openPackId,
    #isEditing: _f$isEditing,
  };

  static ModpacksPageState _instantiate(DecodingData data) {
    return ModpacksPageState(
      persisted: data.dec(_f$persisted),
      allCards: data.dec(_f$allCards),
      visibleCards: data.dec(_f$visibleCards),
      searchQuery: data.dec(_f$searchQuery),
      isLoading: data.dec(_f$isLoading),
      openPackId: data.dec(_f$openPackId),
      isEditing: data.dec(_f$isEditing),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ModpacksPageState fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ModpacksPageState>(map);
  }

  static ModpacksPageState fromJson(String json) {
    return ensureInitialized().decodeJson<ModpacksPageState>(json);
  }
}

mixin ModpacksPageStateMappable {
  String toJson() {
    return ModpacksPageStateMapper.ensureInitialized()
        .encodeJson<ModpacksPageState>(this as ModpacksPageState);
  }

  Map<String, dynamic> toMap() {
    return ModpacksPageStateMapper.ensureInitialized()
        .encodeMap<ModpacksPageState>(this as ModpacksPageState);
  }

  ModpacksPageStateCopyWith<
    ModpacksPageState,
    ModpacksPageState,
    ModpacksPageState
  >
  get copyWith =>
      _ModpacksPageStateCopyWithImpl<ModpacksPageState, ModpacksPageState>(
        this as ModpacksPageState,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return ModpacksPageStateMapper.ensureInitialized().stringifyValue(
      this as ModpacksPageState,
    );
  }

  @override
  bool operator ==(Object other) {
    return ModpacksPageStateMapper.ensureInitialized().equalsValue(
      this as ModpacksPageState,
      other,
    );
  }

  @override
  int get hashCode {
    return ModpacksPageStateMapper.ensureInitialized().hashValue(
      this as ModpacksPageState,
    );
  }
}

extension ModpacksPageStateValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ModpacksPageState, $Out> {
  ModpacksPageStateCopyWith<$R, ModpacksPageState, $Out>
  get $asModpacksPageState => $base.as(
    (v, t, t2) => _ModpacksPageStateCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class ModpacksPageStateCopyWith<
  $R,
  $In extends ModpacksPageState,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  ModpacksPageStatePersistedCopyWith<
    $R,
    ModpacksPageStatePersisted,
    ModpacksPageStatePersisted
  >
  get persisted;
  ListCopyWith<
    $R,
    ModpackCardData,
    ModpackCardDataCopyWith<$R, ModpackCardData, ModpackCardData>
  >
  get allCards;
  ListCopyWith<
    $R,
    ModpackCardData,
    ModpackCardDataCopyWith<$R, ModpackCardData, ModpackCardData>
  >
  get visibleCards;
  $R call({
    ModpacksPageStatePersisted? persisted,
    List<ModpackCardData>? allCards,
    List<ModpackCardData>? visibleCards,
    String? searchQuery,
    bool? isLoading,
    String? openPackId,
    bool? isEditing,
  });
  ModpacksPageStateCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _ModpacksPageStateCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ModpacksPageState, $Out>
    implements ModpacksPageStateCopyWith<$R, ModpacksPageState, $Out> {
  _ModpacksPageStateCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ModpacksPageState> $mapper =
      ModpacksPageStateMapper.ensureInitialized();
  @override
  ModpacksPageStatePersistedCopyWith<
    $R,
    ModpacksPageStatePersisted,
    ModpacksPageStatePersisted
  >
  get persisted => $value.persisted.copyWith.$chain((v) => call(persisted: v));
  @override
  ListCopyWith<
    $R,
    ModpackCardData,
    ModpackCardDataCopyWith<$R, ModpackCardData, ModpackCardData>
  >
  get allCards => ListCopyWith(
    $value.allCards,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(allCards: v),
  );
  @override
  ListCopyWith<
    $R,
    ModpackCardData,
    ModpackCardDataCopyWith<$R, ModpackCardData, ModpackCardData>
  >
  get visibleCards => ListCopyWith(
    $value.visibleCards,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(visibleCards: v),
  );
  @override
  $R call({
    ModpacksPageStatePersisted? persisted,
    List<ModpackCardData>? allCards,
    List<ModpackCardData>? visibleCards,
    String? searchQuery,
    bool? isLoading,
    Object? openPackId = $none,
    bool? isEditing,
  }) => $apply(
    FieldCopyWithData({
      if (persisted != null) #persisted: persisted,
      if (allCards != null) #allCards: allCards,
      if (visibleCards != null) #visibleCards: visibleCards,
      if (searchQuery != null) #searchQuery: searchQuery,
      if (isLoading != null) #isLoading: isLoading,
      if (openPackId != $none) #openPackId: openPackId,
      if (isEditing != null) #isEditing: isEditing,
    }),
  );
  @override
  ModpacksPageState $make(CopyWithData data) => ModpacksPageState(
    persisted: data.get(#persisted, or: $value.persisted),
    allCards: data.get(#allCards, or: $value.allCards),
    visibleCards: data.get(#visibleCards, or: $value.visibleCards),
    searchQuery: data.get(#searchQuery, or: $value.searchQuery),
    isLoading: data.get(#isLoading, or: $value.isLoading),
    openPackId: data.get(#openPackId, or: $value.openPackId),
    isEditing: data.get(#isEditing, or: $value.isEditing),
  );

  @override
  ModpacksPageStateCopyWith<$R2, ModpacksPageState, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ModpacksPageStateCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

