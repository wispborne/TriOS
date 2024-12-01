// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'mods_grid_state.dart';

class ModsGridStateMapper extends ClassMapperBase<ModsGridState> {
  ModsGridStateMapper._();

  static ModsGridStateMapper? _instance;
  static ModsGridStateMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ModsGridStateMapper._());
      ModsGridColumnStateMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ModsGridState';

  static bool _$isGroupEnabledExpanded(ModsGridState v) =>
      v.isGroupEnabledExpanded;
  static const Field<ModsGridState, bool> _f$isGroupEnabledExpanded = Field(
      'isGroupEnabledExpanded', _$isGroupEnabledExpanded,
      opt: true, def: true, hook: SafeDecodeHook(defaultValue: true));
  static bool _$isGroupDisabledExpanded(ModsGridState v) =>
      v.isGroupDisabledExpanded;
  static const Field<ModsGridState, bool> _f$isGroupDisabledExpanded = Field(
      'isGroupDisabledExpanded', _$isGroupDisabledExpanded,
      opt: true, def: true, hook: SafeDecodeHook(defaultValue: true));
  static ModsGridColumnState? _$sortedColumn(ModsGridState v) => v.sortedColumn;
  static const Field<ModsGridState, ModsGridColumnState> _f$sortedColumn =
      Field('sortedColumn', _$sortedColumn, opt: true, hook: SafeDecodeHook());
  static bool? _$sortAscending(ModsGridState v) => v.sortAscending;
  static const Field<ModsGridState, bool> _f$sortAscending = Field(
      'sortAscending', _$sortAscending,
      opt: true, hook: SafeDecodeHook());
  static List<ModsGridColumnState>? _$columns(ModsGridState v) => v.columns;
  static const Field<ModsGridState, List<ModsGridColumnState>> _f$columns =
      Field('columns', _$columns, opt: true, hook: SafeDecodeHook());

  @override
  final MappableFields<ModsGridState> fields = const {
    #isGroupEnabledExpanded: _f$isGroupEnabledExpanded,
    #isGroupDisabledExpanded: _f$isGroupDisabledExpanded,
    #sortedColumn: _f$sortedColumn,
    #sortAscending: _f$sortAscending,
    #columns: _f$columns,
  };

  static ModsGridState _instantiate(DecodingData data) {
    return ModsGridState(
        isGroupEnabledExpanded: data.dec(_f$isGroupEnabledExpanded),
        isGroupDisabledExpanded: data.dec(_f$isGroupDisabledExpanded),
        sortedColumn: data.dec(_f$sortedColumn),
        sortAscending: data.dec(_f$sortAscending),
        columns: data.dec(_f$columns));
  }

  @override
  final Function instantiate = _instantiate;

  static ModsGridState fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ModsGridState>(map);
  }

  static ModsGridState fromJson(String json) {
    return ensureInitialized().decodeJson<ModsGridState>(json);
  }
}

mixin ModsGridStateMappable {
  String toJson() {
    return ModsGridStateMapper.ensureInitialized()
        .encodeJson<ModsGridState>(this as ModsGridState);
  }

  Map<String, dynamic> toMap() {
    return ModsGridStateMapper.ensureInitialized()
        .encodeMap<ModsGridState>(this as ModsGridState);
  }

  ModsGridStateCopyWith<ModsGridState, ModsGridState, ModsGridState>
      get copyWith => _ModsGridStateCopyWithImpl(
          this as ModsGridState, $identity, $identity);
  @override
  String toString() {
    return ModsGridStateMapper.ensureInitialized()
        .stringifyValue(this as ModsGridState);
  }

  @override
  bool operator ==(Object other) {
    return ModsGridStateMapper.ensureInitialized()
        .equalsValue(this as ModsGridState, other);
  }

  @override
  int get hashCode {
    return ModsGridStateMapper.ensureInitialized()
        .hashValue(this as ModsGridState);
  }
}

extension ModsGridStateValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ModsGridState, $Out> {
  ModsGridStateCopyWith<$R, ModsGridState, $Out> get $asModsGridState =>
      $base.as((v, t, t2) => _ModsGridStateCopyWithImpl(v, t, t2));
}

abstract class ModsGridStateCopyWith<$R, $In extends ModsGridState, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ModsGridColumnStateCopyWith<$R, ModsGridColumnState, ModsGridColumnState>?
      get sortedColumn;
  ListCopyWith<
      $R,
      ModsGridColumnState,
      ModsGridColumnStateCopyWith<$R, ModsGridColumnState,
          ModsGridColumnState>>? get columns;
  $R call(
      {bool? isGroupEnabledExpanded,
      bool? isGroupDisabledExpanded,
      ModsGridColumnState? sortedColumn,
      bool? sortAscending,
      List<ModsGridColumnState>? columns});
  ModsGridStateCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ModsGridStateCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ModsGridState, $Out>
    implements ModsGridStateCopyWith<$R, ModsGridState, $Out> {
  _ModsGridStateCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ModsGridState> $mapper =
      ModsGridStateMapper.ensureInitialized();
  @override
  ModsGridColumnStateCopyWith<$R, ModsGridColumnState, ModsGridColumnState>?
      get sortedColumn =>
          $value.sortedColumn?.copyWith.$chain((v) => call(sortedColumn: v));
  @override
  ListCopyWith<
      $R,
      ModsGridColumnState,
      ModsGridColumnStateCopyWith<$R, ModsGridColumnState,
          ModsGridColumnState>>? get columns => $value.columns != null
      ? ListCopyWith($value.columns!, (v, t) => v.copyWith.$chain(t),
          (v) => call(columns: v))
      : null;
  @override
  $R call(
          {bool? isGroupEnabledExpanded,
          bool? isGroupDisabledExpanded,
          Object? sortedColumn = $none,
          Object? sortAscending = $none,
          Object? columns = $none}) =>
      $apply(FieldCopyWithData({
        if (isGroupEnabledExpanded != null)
          #isGroupEnabledExpanded: isGroupEnabledExpanded,
        if (isGroupDisabledExpanded != null)
          #isGroupDisabledExpanded: isGroupDisabledExpanded,
        if (sortedColumn != $none) #sortedColumn: sortedColumn,
        if (sortAscending != $none) #sortAscending: sortAscending,
        if (columns != $none) #columns: columns
      }));
  @override
  ModsGridState $make(CopyWithData data) => ModsGridState(
      isGroupEnabledExpanded:
          data.get(#isGroupEnabledExpanded, or: $value.isGroupEnabledExpanded),
      isGroupDisabledExpanded: data.get(#isGroupDisabledExpanded,
          or: $value.isGroupDisabledExpanded),
      sortedColumn: data.get(#sortedColumn, or: $value.sortedColumn),
      sortAscending: data.get(#sortAscending, or: $value.sortAscending),
      columns: data.get(#columns, or: $value.columns));

  @override
  ModsGridStateCopyWith<$R2, ModsGridState, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _ModsGridStateCopyWithImpl($value, $cast, t);
}

class ModsGridColumnStateMapper extends ClassMapperBase<ModsGridColumnState> {
  ModsGridColumnStateMapper._();

  static ModsGridColumnStateMapper? _instance;
  static ModsGridColumnStateMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ModsGridColumnStateMapper._());
      SmolColumnMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ModsGridColumnState';

  static SmolColumn _$column(ModsGridColumnState v) => v.column;
  static const Field<ModsGridColumnState, SmolColumn> _f$column =
      Field('column', _$column);
  static bool? _$sortedAscending(ModsGridColumnState v) => v.sortedAscending;
  static const Field<ModsGridColumnState, bool> _f$sortedAscending =
      Field('sortedAscending', _$sortedAscending, opt: true);
  static double? _$width(ModsGridColumnState v) => v.width;
  static const Field<ModsGridColumnState, double> _f$width =
      Field('width', _$width, opt: true);
  static bool _$visible(ModsGridColumnState v) => v.visible;
  static const Field<ModsGridColumnState, bool> _f$visible =
      Field('visible', _$visible, opt: true, def: true);
  static double? _$width2(ModsGridColumnState v) => v.width2;
  static const Field<ModsGridColumnState, double> _f$width2 =
      Field('width2', _$width2, mode: FieldMode.member);

  @override
  final MappableFields<ModsGridColumnState> fields = const {
    #column: _f$column,
    #sortedAscending: _f$sortedAscending,
    #width: _f$width,
    #visible: _f$visible,
    #width2: _f$width2,
  };

  static ModsGridColumnState _instantiate(DecodingData data) {
    return ModsGridColumnState(
        column: data.dec(_f$column),
        sortedAscending: data.dec(_f$sortedAscending),
        width: data.dec(_f$width),
        visible: data.dec(_f$visible));
  }

  @override
  final Function instantiate = _instantiate;

  static ModsGridColumnState fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ModsGridColumnState>(map);
  }

  static ModsGridColumnState fromJson(String json) {
    return ensureInitialized().decodeJson<ModsGridColumnState>(json);
  }
}

mixin ModsGridColumnStateMappable {
  String toJson() {
    return ModsGridColumnStateMapper.ensureInitialized()
        .encodeJson<ModsGridColumnState>(this as ModsGridColumnState);
  }

  Map<String, dynamic> toMap() {
    return ModsGridColumnStateMapper.ensureInitialized()
        .encodeMap<ModsGridColumnState>(this as ModsGridColumnState);
  }

  ModsGridColumnStateCopyWith<ModsGridColumnState, ModsGridColumnState,
          ModsGridColumnState>
      get copyWith => _ModsGridColumnStateCopyWithImpl(
          this as ModsGridColumnState, $identity, $identity);
  @override
  String toString() {
    return ModsGridColumnStateMapper.ensureInitialized()
        .stringifyValue(this as ModsGridColumnState);
  }

  @override
  bool operator ==(Object other) {
    return ModsGridColumnStateMapper.ensureInitialized()
        .equalsValue(this as ModsGridColumnState, other);
  }

  @override
  int get hashCode {
    return ModsGridColumnStateMapper.ensureInitialized()
        .hashValue(this as ModsGridColumnState);
  }
}

extension ModsGridColumnStateValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ModsGridColumnState, $Out> {
  ModsGridColumnStateCopyWith<$R, ModsGridColumnState, $Out>
      get $asModsGridColumnState =>
          $base.as((v, t, t2) => _ModsGridColumnStateCopyWithImpl(v, t, t2));
}

abstract class ModsGridColumnStateCopyWith<$R, $In extends ModsGridColumnState,
    $Out> implements ClassCopyWith<$R, $In, $Out> {
  $R call(
      {SmolColumn? column,
      bool? sortedAscending,
      double? width,
      bool? visible});
  ModsGridColumnStateCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
      Then<$Out2, $R2> t);
}

class _ModsGridColumnStateCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ModsGridColumnState, $Out>
    implements ModsGridColumnStateCopyWith<$R, ModsGridColumnState, $Out> {
  _ModsGridColumnStateCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ModsGridColumnState> $mapper =
      ModsGridColumnStateMapper.ensureInitialized();
  @override
  $R call(
          {SmolColumn? column,
          Object? sortedAscending = $none,
          Object? width = $none,
          bool? visible}) =>
      $apply(FieldCopyWithData({
        if (column != null) #column: column,
        if (sortedAscending != $none) #sortedAscending: sortedAscending,
        if (width != $none) #width: width,
        if (visible != null) #visible: visible
      }));
  @override
  ModsGridColumnState $make(CopyWithData data) => ModsGridColumnState(
      column: data.get(#column, or: $value.column),
      sortedAscending: data.get(#sortedAscending, or: $value.sortedAscending),
      width: data.get(#width, or: $value.width),
      visible: data.get(#visible, or: $value.visible));

  @override
  ModsGridColumnStateCopyWith<$R2, ModsGridColumnState, $Out2>
      $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
          _ModsGridColumnStateCopyWithImpl($value, $cast, t);
}
