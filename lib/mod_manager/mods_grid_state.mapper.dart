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
      SmolColumnMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ModsGridState';

  static bool _$isGroupEnabledExpanded(ModsGridState v) =>
      v.isGroupEnabledExpanded;
  static const Field<ModsGridState, bool> _f$isGroupEnabledExpanded = Field(
      'isGroupEnabledExpanded', _$isGroupEnabledExpanded,
      opt: true, def: true);
  static bool _$isGroupDisabledExpanded(ModsGridState v) =>
      v.isGroupDisabledExpanded;
  static const Field<ModsGridState, bool> _f$isGroupDisabledExpanded = Field(
      'isGroupDisabledExpanded', _$isGroupDisabledExpanded,
      opt: true, def: true);
  static SmolColumn? _$sortedColumn(ModsGridState v) => v.sortedColumn;
  static const Field<ModsGridState, SmolColumn> _f$sortedColumn =
      Field('sortedColumn', _$sortedColumn, opt: true);
  static bool? _$sortAscending(ModsGridState v) => v.sortAscending;
  static const Field<ModsGridState, bool> _f$sortAscending =
      Field('sortAscending', _$sortAscending, opt: true);
  static List<SmolColumn>? _$columnOrder(ModsGridState v) => v.columnOrder;
  static const Field<ModsGridState, List<SmolColumn>> _f$columnOrder =
      Field('columnOrder', _$columnOrder, opt: true);

  @override
  final MappableFields<ModsGridState> fields = const {
    #isGroupEnabledExpanded: _f$isGroupEnabledExpanded,
    #isGroupDisabledExpanded: _f$isGroupDisabledExpanded,
    #sortedColumn: _f$sortedColumn,
    #sortAscending: _f$sortAscending,
    #columnOrder: _f$columnOrder,
  };

  static ModsGridState _instantiate(DecodingData data) {
    return ModsGridState(
        isGroupEnabledExpanded: data.dec(_f$isGroupEnabledExpanded),
        isGroupDisabledExpanded: data.dec(_f$isGroupDisabledExpanded),
        sortedColumn: data.dec(_f$sortedColumn),
        sortAscending: data.dec(_f$sortAscending),
        columnOrder: data.dec(_f$columnOrder));
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
  ListCopyWith<$R, SmolColumn, ObjectCopyWith<$R, SmolColumn, SmolColumn>>?
      get columnOrder;
  $R call(
      {bool? isGroupEnabledExpanded,
      bool? isGroupDisabledExpanded,
      SmolColumn? sortedColumn,
      bool? sortAscending,
      List<SmolColumn>? columnOrder});
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
  ListCopyWith<$R, SmolColumn, ObjectCopyWith<$R, SmolColumn, SmolColumn>>?
      get columnOrder => $value.columnOrder != null
          ? ListCopyWith(
              $value.columnOrder!,
              (v, t) => ObjectCopyWith(v, $identity, t),
              (v) => call(columnOrder: v))
          : null;
  @override
  $R call(
          {bool? isGroupEnabledExpanded,
          bool? isGroupDisabledExpanded,
          Object? sortedColumn = $none,
          Object? sortAscending = $none,
          Object? columnOrder = $none}) =>
      $apply(FieldCopyWithData({
        if (isGroupEnabledExpanded != null)
          #isGroupEnabledExpanded: isGroupEnabledExpanded,
        if (isGroupDisabledExpanded != null)
          #isGroupDisabledExpanded: isGroupDisabledExpanded,
        if (sortedColumn != $none) #sortedColumn: sortedColumn,
        if (sortAscending != $none) #sortAscending: sortAscending,
        if (columnOrder != $none) #columnOrder: columnOrder
      }));
  @override
  ModsGridState $make(CopyWithData data) => ModsGridState(
      isGroupEnabledExpanded:
          data.get(#isGroupEnabledExpanded, or: $value.isGroupEnabledExpanded),
      isGroupDisabledExpanded: data.get(#isGroupDisabledExpanded,
          or: $value.isGroupDisabledExpanded),
      sortedColumn: data.get(#sortedColumn, or: $value.sortedColumn),
      sortAscending: data.get(#sortAscending, or: $value.sortAscending),
      columnOrder: data.get(#columnOrder, or: $value.columnOrder));

  @override
  ModsGridStateCopyWith<$R2, ModsGridState, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _ModsGridStateCopyWithImpl($value, $cast, t);
}
