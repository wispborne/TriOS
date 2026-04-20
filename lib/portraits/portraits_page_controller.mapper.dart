// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'portraits_page_controller.dart';

class PortraitsModeMapper extends EnumMapper<PortraitsMode> {
  PortraitsModeMapper._();

  static PortraitsModeMapper? _instance;
  static PortraitsModeMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = PortraitsModeMapper._());
    }
    return _instance!;
  }

  static PortraitsMode fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  PortraitsMode decode(dynamic value) {
    switch (value) {
      case r'viewer':
        return PortraitsMode.viewer;
      case r'replacer':
        return PortraitsMode.replacer;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(PortraitsMode self) {
    switch (self) {
      case PortraitsMode.viewer:
        return r'viewer';
      case PortraitsMode.replacer:
        return r'replacer';
    }
  }
}

extension PortraitsModeMapperExtension on PortraitsMode {
  String toValue() {
    PortraitsModeMapper.ensureInitialized();
    return MapperContainer.globals.toValue<PortraitsMode>(this) as String;
  }
}

class FilterPaneMapper extends EnumMapper<FilterPane> {
  FilterPaneMapper._();

  static FilterPaneMapper? _instance;
  static FilterPaneMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = FilterPaneMapper._());
    }
    return _instance!;
  }

  static FilterPane fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  FilterPane decode(dynamic value) {
    switch (value) {
      case r'main':
        return FilterPane.main;
      case r'left':
        return FilterPane.left;
      case r'right':
        return FilterPane.right;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(FilterPane self) {
    switch (self) {
      case FilterPane.main:
        return r'main';
      case FilterPane.left:
        return r'left';
      case FilterPane.right:
        return r'right';
    }
  }
}

extension FilterPaneMapperExtension on FilterPane {
  String toValue() {
    FilterPaneMapper.ensureInitialized();
    return MapperContainer.globals.toValue<FilterPane>(this) as String;
  }
}

class PortraitsPageStatePersistedMapper
    extends ClassMapperBase<PortraitsPageStatePersisted> {
  PortraitsPageStatePersistedMapper._();

  static PortraitsPageStatePersistedMapper? _instance;
  static PortraitsPageStatePersistedMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(
        _instance = PortraitsPageStatePersistedMapper._(),
      );
    }
    return _instance!;
  }

  @override
  final String id = 'PortraitsPageStatePersisted';

  static bool _$mainShowFilters(PortraitsPageStatePersisted v) =>
      v.mainShowFilters;
  static const Field<PortraitsPageStatePersisted, bool> _f$mainShowFilters =
      Field('mainShowFilters', _$mainShowFilters, opt: true, def: true);

  @override
  final MappableFields<PortraitsPageStatePersisted> fields = const {
    #mainShowFilters: _f$mainShowFilters,
  };

  static PortraitsPageStatePersisted _instantiate(DecodingData data) {
    return PortraitsPageStatePersisted(
      mainShowFilters: data.dec(_f$mainShowFilters),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static PortraitsPageStatePersisted fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<PortraitsPageStatePersisted>(map);
  }

  static PortraitsPageStatePersisted fromJson(String json) {
    return ensureInitialized().decodeJson<PortraitsPageStatePersisted>(json);
  }
}

mixin PortraitsPageStatePersistedMappable {
  String toJson() {
    return PortraitsPageStatePersistedMapper.ensureInitialized()
        .encodeJson<PortraitsPageStatePersisted>(
          this as PortraitsPageStatePersisted,
        );
  }

  Map<String, dynamic> toMap() {
    return PortraitsPageStatePersistedMapper.ensureInitialized()
        .encodeMap<PortraitsPageStatePersisted>(
          this as PortraitsPageStatePersisted,
        );
  }

  PortraitsPageStatePersistedCopyWith<
    PortraitsPageStatePersisted,
    PortraitsPageStatePersisted,
    PortraitsPageStatePersisted
  >
  get copyWith =>
      _PortraitsPageStatePersistedCopyWithImpl<
        PortraitsPageStatePersisted,
        PortraitsPageStatePersisted
      >(this as PortraitsPageStatePersisted, $identity, $identity);
  @override
  String toString() {
    return PortraitsPageStatePersistedMapper.ensureInitialized().stringifyValue(
      this as PortraitsPageStatePersisted,
    );
  }

  @override
  bool operator ==(Object other) {
    return PortraitsPageStatePersistedMapper.ensureInitialized().equalsValue(
      this as PortraitsPageStatePersisted,
      other,
    );
  }

  @override
  int get hashCode {
    return PortraitsPageStatePersistedMapper.ensureInitialized().hashValue(
      this as PortraitsPageStatePersisted,
    );
  }
}

extension PortraitsPageStatePersistedValueCopy<$R, $Out>
    on ObjectCopyWith<$R, PortraitsPageStatePersisted, $Out> {
  PortraitsPageStatePersistedCopyWith<$R, PortraitsPageStatePersisted, $Out>
  get $asPortraitsPageStatePersisted => $base.as(
    (v, t, t2) => _PortraitsPageStatePersistedCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class PortraitsPageStatePersistedCopyWith<
  $R,
  $In extends PortraitsPageStatePersisted,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({bool? mainShowFilters});
  PortraitsPageStatePersistedCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _PortraitsPageStatePersistedCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, PortraitsPageStatePersisted, $Out>
    implements
        PortraitsPageStatePersistedCopyWith<
          $R,
          PortraitsPageStatePersisted,
          $Out
        > {
  _PortraitsPageStatePersistedCopyWithImpl(
    super.value,
    super.then,
    super.then2,
  );

  @override
  late final ClassMapperBase<PortraitsPageStatePersisted> $mapper =
      PortraitsPageStatePersistedMapper.ensureInitialized();
  @override
  $R call({bool? mainShowFilters}) => $apply(
    FieldCopyWithData({
      if (mainShowFilters != null) #mainShowFilters: mainShowFilters,
    }),
  );
  @override
  PortraitsPageStatePersisted $make(CopyWithData data) =>
      PortraitsPageStatePersisted(
        mainShowFilters: data.get(#mainShowFilters, or: $value.mainShowFilters),
      );

  @override
  PortraitsPageStatePersistedCopyWith<$R2, PortraitsPageStatePersisted, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _PortraitsPageStatePersistedCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class FilterPaneStateMapper extends ClassMapperBase<FilterPaneState> {
  FilterPaneStateMapper._();

  static FilterPaneStateMapper? _instance;
  static FilterPaneStateMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = FilterPaneStateMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'FilterPaneState';

  static bool _$showFilters(FilterPaneState v) => v.showFilters;
  static const Field<FilterPaneState, bool> _f$showFilters = Field(
    'showFilters',
    _$showFilters,
    opt: true,
    def: true,
  );
  static String _$searchQuery(FilterPaneState v) => v.searchQuery;
  static const Field<FilterPaneState, String> _f$searchQuery = Field(
    'searchQuery',
    _$searchQuery,
    opt: true,
    def: '',
  );

  @override
  final MappableFields<FilterPaneState> fields = const {
    #showFilters: _f$showFilters,
    #searchQuery: _f$searchQuery,
  };

  static FilterPaneState _instantiate(DecodingData data) {
    return FilterPaneState(
      showFilters: data.dec(_f$showFilters),
      searchQuery: data.dec(_f$searchQuery),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static FilterPaneState fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<FilterPaneState>(map);
  }

  static FilterPaneState fromJson(String json) {
    return ensureInitialized().decodeJson<FilterPaneState>(json);
  }
}

mixin FilterPaneStateMappable {
  String toJson() {
    return FilterPaneStateMapper.ensureInitialized()
        .encodeJson<FilterPaneState>(this as FilterPaneState);
  }

  Map<String, dynamic> toMap() {
    return FilterPaneStateMapper.ensureInitialized().encodeMap<FilterPaneState>(
      this as FilterPaneState,
    );
  }

  FilterPaneStateCopyWith<FilterPaneState, FilterPaneState, FilterPaneState>
  get copyWith =>
      _FilterPaneStateCopyWithImpl<FilterPaneState, FilterPaneState>(
        this as FilterPaneState,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return FilterPaneStateMapper.ensureInitialized().stringifyValue(
      this as FilterPaneState,
    );
  }

  @override
  bool operator ==(Object other) {
    return FilterPaneStateMapper.ensureInitialized().equalsValue(
      this as FilterPaneState,
      other,
    );
  }

  @override
  int get hashCode {
    return FilterPaneStateMapper.ensureInitialized().hashValue(
      this as FilterPaneState,
    );
  }
}

extension FilterPaneStateValueCopy<$R, $Out>
    on ObjectCopyWith<$R, FilterPaneState, $Out> {
  FilterPaneStateCopyWith<$R, FilterPaneState, $Out> get $asFilterPaneState =>
      $base.as((v, t, t2) => _FilterPaneStateCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class FilterPaneStateCopyWith<$R, $In extends FilterPaneState, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({bool? showFilters, String? searchQuery});
  FilterPaneStateCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _FilterPaneStateCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, FilterPaneState, $Out>
    implements FilterPaneStateCopyWith<$R, FilterPaneState, $Out> {
  _FilterPaneStateCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<FilterPaneState> $mapper =
      FilterPaneStateMapper.ensureInitialized();
  @override
  $R call({bool? showFilters, String? searchQuery}) => $apply(
    FieldCopyWithData({
      if (showFilters != null) #showFilters: showFilters,
      if (searchQuery != null) #searchQuery: searchQuery,
    }),
  );
  @override
  FilterPaneState $make(CopyWithData data) => FilterPaneState(
    showFilters: data.get(#showFilters, or: $value.showFilters),
    searchQuery: data.get(#searchQuery, or: $value.searchQuery),
  );

  @override
  FilterPaneStateCopyWith<$R2, FilterPaneState, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _FilterPaneStateCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class PortraitsPageStateMapper extends ClassMapperBase<PortraitsPageState> {
  PortraitsPageStateMapper._();

  static PortraitsPageStateMapper? _instance;
  static PortraitsPageStateMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = PortraitsPageStateMapper._());
      PortraitsModeMapper.ensureInitialized();
      FilterPaneStateMapper.ensureInitialized();
      ModVariantMapper.ensureInitialized();
      PortraitMapper.ensureInitialized();
      PortraitMetadataMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'PortraitsPageState';

  static PortraitsMode _$mode(PortraitsPageState v) => v.mode;
  static const Field<PortraitsPageState, PortraitsMode> _f$mode = Field(
    'mode',
    _$mode,
    opt: true,
    def: PortraitsMode.viewer,
  );
  static double _$portraitSize(PortraitsPageState v) => v.portraitSize;
  static const Field<PortraitsPageState, double> _f$portraitSize = Field(
    'portraitSize',
    _$portraitSize,
    opt: true,
    def: 128,
  );
  static FilterPaneState _$mainPaneState(PortraitsPageState v) =>
      v.mainPaneState;
  static const Field<PortraitsPageState, FilterPaneState> _f$mainPaneState =
      Field(
        'mainPaneState',
        _$mainPaneState,
        opt: true,
        def: const FilterPaneState(),
      );
  static FilterPaneState _$leftPaneState(PortraitsPageState v) =>
      v.leftPaneState;
  static const Field<PortraitsPageState, FilterPaneState> _f$leftPaneState =
      Field(
        'leftPaneState',
        _$leftPaneState,
        opt: true,
        def: const FilterPaneState(),
      );
  static FilterPaneState _$rightPaneState(PortraitsPageState v) =>
      v.rightPaneState;
  static const Field<PortraitsPageState, FilterPaneState> _f$rightPaneState =
      Field(
        'rightPaneState',
        _$rightPaneState,
        opt: true,
        def: const FilterPaneState(),
      );
  static Map<ModVariant?, List<Portrait>> _$allPortraits(
    PortraitsPageState v,
  ) => v.allPortraits;
  static const Field<PortraitsPageState, Map<ModVariant?, List<Portrait>>>
  _f$allPortraits = Field(
    'allPortraits',
    _$allPortraits,
    opt: true,
    def: const {},
  );
  static Map<String, PortraitMetadata> _$metadata(PortraitsPageState v) =>
      v.metadata;
  static const Field<PortraitsPageState, Map<String, PortraitMetadata>>
  _f$metadata = Field('metadata', _$metadata, opt: true, def: const {});
  static Map<String, Portrait> _$replacements(PortraitsPageState v) =>
      v.replacements;
  static const Field<PortraitsPageState, Map<String, Portrait>>
  _f$replacements = Field(
    'replacements',
    _$replacements,
    opt: true,
    def: const {},
  );
  static bool _$isLoading(PortraitsPageState v) => v.isLoading;
  static const Field<PortraitsPageState, bool> _f$isLoading = Field(
    'isLoading',
    _$isLoading,
    opt: true,
    def: false,
  );

  @override
  final MappableFields<PortraitsPageState> fields = const {
    #mode: _f$mode,
    #portraitSize: _f$portraitSize,
    #mainPaneState: _f$mainPaneState,
    #leftPaneState: _f$leftPaneState,
    #rightPaneState: _f$rightPaneState,
    #allPortraits: _f$allPortraits,
    #metadata: _f$metadata,
    #replacements: _f$replacements,
    #isLoading: _f$isLoading,
  };

  static PortraitsPageState _instantiate(DecodingData data) {
    return PortraitsPageState(
      mode: data.dec(_f$mode),
      portraitSize: data.dec(_f$portraitSize),
      mainPaneState: data.dec(_f$mainPaneState),
      leftPaneState: data.dec(_f$leftPaneState),
      rightPaneState: data.dec(_f$rightPaneState),
      allPortraits: data.dec(_f$allPortraits),
      metadata: data.dec(_f$metadata),
      replacements: data.dec(_f$replacements),
      isLoading: data.dec(_f$isLoading),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static PortraitsPageState fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<PortraitsPageState>(map);
  }

  static PortraitsPageState fromJson(String json) {
    return ensureInitialized().decodeJson<PortraitsPageState>(json);
  }
}

mixin PortraitsPageStateMappable {
  String toJson() {
    return PortraitsPageStateMapper.ensureInitialized()
        .encodeJson<PortraitsPageState>(this as PortraitsPageState);
  }

  Map<String, dynamic> toMap() {
    return PortraitsPageStateMapper.ensureInitialized()
        .encodeMap<PortraitsPageState>(this as PortraitsPageState);
  }

  PortraitsPageStateCopyWith<
    PortraitsPageState,
    PortraitsPageState,
    PortraitsPageState
  >
  get copyWith =>
      _PortraitsPageStateCopyWithImpl<PortraitsPageState, PortraitsPageState>(
        this as PortraitsPageState,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return PortraitsPageStateMapper.ensureInitialized().stringifyValue(
      this as PortraitsPageState,
    );
  }

  @override
  bool operator ==(Object other) {
    return PortraitsPageStateMapper.ensureInitialized().equalsValue(
      this as PortraitsPageState,
      other,
    );
  }

  @override
  int get hashCode {
    return PortraitsPageStateMapper.ensureInitialized().hashValue(
      this as PortraitsPageState,
    );
  }
}

extension PortraitsPageStateValueCopy<$R, $Out>
    on ObjectCopyWith<$R, PortraitsPageState, $Out> {
  PortraitsPageStateCopyWith<$R, PortraitsPageState, $Out>
  get $asPortraitsPageState => $base.as(
    (v, t, t2) => _PortraitsPageStateCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class PortraitsPageStateCopyWith<
  $R,
  $In extends PortraitsPageState,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  FilterPaneStateCopyWith<$R, FilterPaneState, FilterPaneState>
  get mainPaneState;
  FilterPaneStateCopyWith<$R, FilterPaneState, FilterPaneState>
  get leftPaneState;
  FilterPaneStateCopyWith<$R, FilterPaneState, FilterPaneState>
  get rightPaneState;
  MapCopyWith<
    $R,
    ModVariant?,
    List<Portrait>,
    ObjectCopyWith<$R, List<Portrait>, List<Portrait>>
  >
  get allPortraits;
  MapCopyWith<
    $R,
    String,
    PortraitMetadata,
    PortraitMetadataCopyWith<$R, PortraitMetadata, PortraitMetadata>
  >
  get metadata;
  MapCopyWith<$R, String, Portrait, PortraitCopyWith<$R, Portrait, Portrait>>
  get replacements;
  $R call({
    PortraitsMode? mode,
    double? portraitSize,
    FilterPaneState? mainPaneState,
    FilterPaneState? leftPaneState,
    FilterPaneState? rightPaneState,
    Map<ModVariant?, List<Portrait>>? allPortraits,
    Map<String, PortraitMetadata>? metadata,
    Map<String, Portrait>? replacements,
    bool? isLoading,
  });
  PortraitsPageStateCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _PortraitsPageStateCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, PortraitsPageState, $Out>
    implements PortraitsPageStateCopyWith<$R, PortraitsPageState, $Out> {
  _PortraitsPageStateCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<PortraitsPageState> $mapper =
      PortraitsPageStateMapper.ensureInitialized();
  @override
  FilterPaneStateCopyWith<$R, FilterPaneState, FilterPaneState>
  get mainPaneState =>
      $value.mainPaneState.copyWith.$chain((v) => call(mainPaneState: v));
  @override
  FilterPaneStateCopyWith<$R, FilterPaneState, FilterPaneState>
  get leftPaneState =>
      $value.leftPaneState.copyWith.$chain((v) => call(leftPaneState: v));
  @override
  FilterPaneStateCopyWith<$R, FilterPaneState, FilterPaneState>
  get rightPaneState =>
      $value.rightPaneState.copyWith.$chain((v) => call(rightPaneState: v));
  @override
  MapCopyWith<
    $R,
    ModVariant?,
    List<Portrait>,
    ObjectCopyWith<$R, List<Portrait>, List<Portrait>>
  >
  get allPortraits => MapCopyWith(
    $value.allPortraits,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(allPortraits: v),
  );
  @override
  MapCopyWith<
    $R,
    String,
    PortraitMetadata,
    PortraitMetadataCopyWith<$R, PortraitMetadata, PortraitMetadata>
  >
  get metadata => MapCopyWith(
    $value.metadata,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(metadata: v),
  );
  @override
  MapCopyWith<$R, String, Portrait, PortraitCopyWith<$R, Portrait, Portrait>>
  get replacements => MapCopyWith(
    $value.replacements,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(replacements: v),
  );
  @override
  $R call({
    PortraitsMode? mode,
    double? portraitSize,
    FilterPaneState? mainPaneState,
    FilterPaneState? leftPaneState,
    FilterPaneState? rightPaneState,
    Map<ModVariant?, List<Portrait>>? allPortraits,
    Map<String, PortraitMetadata>? metadata,
    Map<String, Portrait>? replacements,
    bool? isLoading,
  }) => $apply(
    FieldCopyWithData({
      if (mode != null) #mode: mode,
      if (portraitSize != null) #portraitSize: portraitSize,
      if (mainPaneState != null) #mainPaneState: mainPaneState,
      if (leftPaneState != null) #leftPaneState: leftPaneState,
      if (rightPaneState != null) #rightPaneState: rightPaneState,
      if (allPortraits != null) #allPortraits: allPortraits,
      if (metadata != null) #metadata: metadata,
      if (replacements != null) #replacements: replacements,
      if (isLoading != null) #isLoading: isLoading,
    }),
  );
  @override
  PortraitsPageState $make(CopyWithData data) => PortraitsPageState(
    mode: data.get(#mode, or: $value.mode),
    portraitSize: data.get(#portraitSize, or: $value.portraitSize),
    mainPaneState: data.get(#mainPaneState, or: $value.mainPaneState),
    leftPaneState: data.get(#leftPaneState, or: $value.leftPaneState),
    rightPaneState: data.get(#rightPaneState, or: $value.rightPaneState),
    allPortraits: data.get(#allPortraits, or: $value.allPortraits),
    metadata: data.get(#metadata, or: $value.metadata),
    replacements: data.get(#replacements, or: $value.replacements),
    isLoading: data.get(#isLoading, or: $value.isLoading),
  );

  @override
  PortraitsPageStateCopyWith<$R2, PortraitsPageState, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _PortraitsPageStateCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

