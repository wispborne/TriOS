// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'tips_page_controller.dart';

class TipsGroupingMapper extends EnumMapper<TipsGrouping> {
  TipsGroupingMapper._();

  static TipsGroupingMapper? _instance;
  static TipsGroupingMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = TipsGroupingMapper._());
    }
    return _instance!;
  }

  static TipsGrouping fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  TipsGrouping decode(dynamic value) {
    switch (value) {
      case r'none':
        return TipsGrouping.none;
      case r'mod':
        return TipsGrouping.mod;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(TipsGrouping self) {
    switch (self) {
      case TipsGrouping.none:
        return r'none';
      case TipsGrouping.mod:
        return r'mod';
    }
  }
}

extension TipsGroupingMapperExtension on TipsGrouping {
  String toValue() {
    TipsGroupingMapper.ensureInitialized();
    return MapperContainer.globals.toValue<TipsGrouping>(this) as String;
  }
}

class TipsPageStatePersistedMapper
    extends ClassMapperBase<TipsPageStatePersisted> {
  TipsPageStatePersistedMapper._();

  static TipsPageStatePersistedMapper? _instance;
  static TipsPageStatePersistedMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = TipsPageStatePersistedMapper._());
      TipsGroupingMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'TipsPageStatePersisted';

  static bool _$onlyEnabledMods(TipsPageStatePersisted v) => v.onlyEnabledMods;
  static const Field<TipsPageStatePersisted, bool> _f$onlyEnabledMods = Field(
    'onlyEnabledMods',
    _$onlyEnabledMods,
    opt: true,
    def: false,
  );
  static bool _$showHidden(TipsPageStatePersisted v) => v.showHidden;
  static const Field<TipsPageStatePersisted, bool> _f$showHidden = Field(
    'showHidden',
    _$showHidden,
    opt: true,
    def: false,
  );
  static TipsGrouping _$grouping(TipsPageStatePersisted v) => v.grouping;
  static const Field<TipsPageStatePersisted, TipsGrouping> _f$grouping = Field(
    'grouping',
    _$grouping,
    opt: true,
    def: TipsGrouping.none,
  );

  @override
  final MappableFields<TipsPageStatePersisted> fields = const {
    #onlyEnabledMods: _f$onlyEnabledMods,
    #showHidden: _f$showHidden,
    #grouping: _f$grouping,
  };

  static TipsPageStatePersisted _instantiate(DecodingData data) {
    return TipsPageStatePersisted(
      onlyEnabledMods: data.dec(_f$onlyEnabledMods),
      showHidden: data.dec(_f$showHidden),
      grouping: data.dec(_f$grouping),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static TipsPageStatePersisted fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<TipsPageStatePersisted>(map);
  }

  static TipsPageStatePersisted fromJson(String json) {
    return ensureInitialized().decodeJson<TipsPageStatePersisted>(json);
  }
}

mixin TipsPageStatePersistedMappable {
  String toJson() {
    return TipsPageStatePersistedMapper.ensureInitialized()
        .encodeJson<TipsPageStatePersisted>(this as TipsPageStatePersisted);
  }

  Map<String, dynamic> toMap() {
    return TipsPageStatePersistedMapper.ensureInitialized()
        .encodeMap<TipsPageStatePersisted>(this as TipsPageStatePersisted);
  }

  TipsPageStatePersistedCopyWith<
    TipsPageStatePersisted,
    TipsPageStatePersisted,
    TipsPageStatePersisted
  >
  get copyWith =>
      _TipsPageStatePersistedCopyWithImpl<
        TipsPageStatePersisted,
        TipsPageStatePersisted
      >(this as TipsPageStatePersisted, $identity, $identity);
  @override
  String toString() {
    return TipsPageStatePersistedMapper.ensureInitialized().stringifyValue(
      this as TipsPageStatePersisted,
    );
  }

  @override
  bool operator ==(Object other) {
    return TipsPageStatePersistedMapper.ensureInitialized().equalsValue(
      this as TipsPageStatePersisted,
      other,
    );
  }

  @override
  int get hashCode {
    return TipsPageStatePersistedMapper.ensureInitialized().hashValue(
      this as TipsPageStatePersisted,
    );
  }
}

extension TipsPageStatePersistedValueCopy<$R, $Out>
    on ObjectCopyWith<$R, TipsPageStatePersisted, $Out> {
  TipsPageStatePersistedCopyWith<$R, TipsPageStatePersisted, $Out>
  get $asTipsPageStatePersisted => $base.as(
    (v, t, t2) => _TipsPageStatePersistedCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class TipsPageStatePersistedCopyWith<
  $R,
  $In extends TipsPageStatePersisted,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({bool? onlyEnabledMods, bool? showHidden, TipsGrouping? grouping});
  TipsPageStatePersistedCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _TipsPageStatePersistedCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, TipsPageStatePersisted, $Out>
    implements
        TipsPageStatePersistedCopyWith<$R, TipsPageStatePersisted, $Out> {
  _TipsPageStatePersistedCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<TipsPageStatePersisted> $mapper =
      TipsPageStatePersistedMapper.ensureInitialized();
  @override
  $R call({bool? onlyEnabledMods, bool? showHidden, TipsGrouping? grouping}) =>
      $apply(
        FieldCopyWithData({
          if (onlyEnabledMods != null) #onlyEnabledMods: onlyEnabledMods,
          if (showHidden != null) #showHidden: showHidden,
          if (grouping != null) #grouping: grouping,
        }),
      );
  @override
  TipsPageStatePersisted $make(CopyWithData data) => TipsPageStatePersisted(
    onlyEnabledMods: data.get(#onlyEnabledMods, or: $value.onlyEnabledMods),
    showHidden: data.get(#showHidden, or: $value.showHidden),
    grouping: data.get(#grouping, or: $value.grouping),
  );

  @override
  TipsPageStatePersistedCopyWith<$R2, TipsPageStatePersisted, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _TipsPageStatePersistedCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class TipsPageStateMapper extends ClassMapperBase<TipsPageState> {
  TipsPageStateMapper._();

  static TipsPageStateMapper? _instance;
  static TipsPageStateMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = TipsPageStateMapper._());
      TipsPageStatePersistedMapper.ensureInitialized();
      ModTipMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'TipsPageState';

  static TipsPageStatePersisted _$persisted(TipsPageState v) => v.persisted;
  static const Field<TipsPageState, TipsPageStatePersisted> _f$persisted =
      Field(
        'persisted',
        _$persisted,
        opt: true,
        def: const TipsPageStatePersisted(),
      );
  static List<ModTip> _$allTips(TipsPageState v) => v.allTips;
  static const Field<TipsPageState, List<ModTip>> _f$allTips = Field(
    'allTips',
    _$allTips,
    opt: true,
    def: const [],
  );
  static List<ModTip> _$visibleTips(TipsPageState v) => v.visibleTips;
  static const Field<TipsPageState, List<ModTip>> _f$visibleTips = Field(
    'visibleTips',
    _$visibleTips,
    opt: true,
    def: const [],
  );
  static List<ModTip> _$hiddenTips(TipsPageState v) => v.hiddenTips;
  static const Field<TipsPageState, List<ModTip>> _f$hiddenTips = Field(
    'hiddenTips',
    _$hiddenTips,
    opt: true,
    def: const [],
  );
  static Set<ModTip> _$selectedTips(TipsPageState v) => v.selectedTips;
  static const Field<TipsPageState, Set<ModTip>> _f$selectedTips = Field(
    'selectedTips',
    _$selectedTips,
    opt: true,
    def: const {},
  );
  static String _$searchQuery(TipsPageState v) => v.searchQuery;
  static const Field<TipsPageState, String> _f$searchQuery = Field(
    'searchQuery',
    _$searchQuery,
    opt: true,
    def: '',
  );
  static bool _$isLoading(TipsPageState v) => v.isLoading;
  static const Field<TipsPageState, bool> _f$isLoading = Field(
    'isLoading',
    _$isLoading,
    opt: true,
    def: false,
  );
  static String? _$errorMessage(TipsPageState v) => v.errorMessage;
  static const Field<TipsPageState, String> _f$errorMessage = Field(
    'errorMessage',
    _$errorMessage,
    opt: true,
  );

  @override
  final MappableFields<TipsPageState> fields = const {
    #persisted: _f$persisted,
    #allTips: _f$allTips,
    #visibleTips: _f$visibleTips,
    #hiddenTips: _f$hiddenTips,
    #selectedTips: _f$selectedTips,
    #searchQuery: _f$searchQuery,
    #isLoading: _f$isLoading,
    #errorMessage: _f$errorMessage,
  };

  static TipsPageState _instantiate(DecodingData data) {
    return TipsPageState(
      persisted: data.dec(_f$persisted),
      allTips: data.dec(_f$allTips),
      visibleTips: data.dec(_f$visibleTips),
      hiddenTips: data.dec(_f$hiddenTips),
      selectedTips: data.dec(_f$selectedTips),
      searchQuery: data.dec(_f$searchQuery),
      isLoading: data.dec(_f$isLoading),
      errorMessage: data.dec(_f$errorMessage),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static TipsPageState fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<TipsPageState>(map);
  }

  static TipsPageState fromJson(String json) {
    return ensureInitialized().decodeJson<TipsPageState>(json);
  }
}

mixin TipsPageStateMappable {
  String toJson() {
    return TipsPageStateMapper.ensureInitialized().encodeJson<TipsPageState>(
      this as TipsPageState,
    );
  }

  Map<String, dynamic> toMap() {
    return TipsPageStateMapper.ensureInitialized().encodeMap<TipsPageState>(
      this as TipsPageState,
    );
  }

  TipsPageStateCopyWith<TipsPageState, TipsPageState, TipsPageState>
  get copyWith => _TipsPageStateCopyWithImpl<TipsPageState, TipsPageState>(
    this as TipsPageState,
    $identity,
    $identity,
  );
  @override
  String toString() {
    return TipsPageStateMapper.ensureInitialized().stringifyValue(
      this as TipsPageState,
    );
  }

  @override
  bool operator ==(Object other) {
    return TipsPageStateMapper.ensureInitialized().equalsValue(
      this as TipsPageState,
      other,
    );
  }

  @override
  int get hashCode {
    return TipsPageStateMapper.ensureInitialized().hashValue(
      this as TipsPageState,
    );
  }
}

extension TipsPageStateValueCopy<$R, $Out>
    on ObjectCopyWith<$R, TipsPageState, $Out> {
  TipsPageStateCopyWith<$R, TipsPageState, $Out> get $asTipsPageState =>
      $base.as((v, t, t2) => _TipsPageStateCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class TipsPageStateCopyWith<$R, $In extends TipsPageState, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  TipsPageStatePersistedCopyWith<
    $R,
    TipsPageStatePersisted,
    TipsPageStatePersisted
  >
  get persisted;
  ListCopyWith<$R, ModTip, ModTipCopyWith<$R, ModTip, ModTip>> get allTips;
  ListCopyWith<$R, ModTip, ModTipCopyWith<$R, ModTip, ModTip>> get visibleTips;
  ListCopyWith<$R, ModTip, ModTipCopyWith<$R, ModTip, ModTip>> get hiddenTips;
  $R call({
    TipsPageStatePersisted? persisted,
    List<ModTip>? allTips,
    List<ModTip>? visibleTips,
    List<ModTip>? hiddenTips,
    Set<ModTip>? selectedTips,
    String? searchQuery,
    bool? isLoading,
    String? errorMessage,
  });
  TipsPageStateCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _TipsPageStateCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, TipsPageState, $Out>
    implements TipsPageStateCopyWith<$R, TipsPageState, $Out> {
  _TipsPageStateCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<TipsPageState> $mapper =
      TipsPageStateMapper.ensureInitialized();
  @override
  TipsPageStatePersistedCopyWith<
    $R,
    TipsPageStatePersisted,
    TipsPageStatePersisted
  >
  get persisted => $value.persisted.copyWith.$chain((v) => call(persisted: v));
  @override
  ListCopyWith<$R, ModTip, ModTipCopyWith<$R, ModTip, ModTip>> get allTips =>
      ListCopyWith(
        $value.allTips,
        (v, t) => v.copyWith.$chain(t),
        (v) => call(allTips: v),
      );
  @override
  ListCopyWith<$R, ModTip, ModTipCopyWith<$R, ModTip, ModTip>>
  get visibleTips => ListCopyWith(
    $value.visibleTips,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(visibleTips: v),
  );
  @override
  ListCopyWith<$R, ModTip, ModTipCopyWith<$R, ModTip, ModTip>> get hiddenTips =>
      ListCopyWith(
        $value.hiddenTips,
        (v, t) => v.copyWith.$chain(t),
        (v) => call(hiddenTips: v),
      );
  @override
  $R call({
    TipsPageStatePersisted? persisted,
    List<ModTip>? allTips,
    List<ModTip>? visibleTips,
    List<ModTip>? hiddenTips,
    Set<ModTip>? selectedTips,
    String? searchQuery,
    bool? isLoading,
    Object? errorMessage = $none,
  }) => $apply(
    FieldCopyWithData({
      if (persisted != null) #persisted: persisted,
      if (allTips != null) #allTips: allTips,
      if (visibleTips != null) #visibleTips: visibleTips,
      if (hiddenTips != null) #hiddenTips: hiddenTips,
      if (selectedTips != null) #selectedTips: selectedTips,
      if (searchQuery != null) #searchQuery: searchQuery,
      if (isLoading != null) #isLoading: isLoading,
      if (errorMessage != $none) #errorMessage: errorMessage,
    }),
  );
  @override
  TipsPageState $make(CopyWithData data) => TipsPageState(
    persisted: data.get(#persisted, or: $value.persisted),
    allTips: data.get(#allTips, or: $value.allTips),
    visibleTips: data.get(#visibleTips, or: $value.visibleTips),
    hiddenTips: data.get(#hiddenTips, or: $value.hiddenTips),
    selectedTips: data.get(#selectedTips, or: $value.selectedTips),
    searchQuery: data.get(#searchQuery, or: $value.searchQuery),
    isLoading: data.get(#isLoading, or: $value.isLoading),
    errorMessage: data.get(#errorMessage, or: $value.errorMessage),
  );

  @override
  TipsPageStateCopyWith<$R2, TipsPageState, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _TipsPageStateCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

