// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'wisp_grid_state.dart';

class ModGridHeaderMapper extends EnumMapper<ModGridHeader> {
  ModGridHeaderMapper._();

  static ModGridHeaderMapper? _instance;
  static ModGridHeaderMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ModGridHeaderMapper._());
    }
    return _instance!;
  }

  static ModGridHeader fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  ModGridHeader decode(dynamic value) {
    switch (value) {
      case 'favorites':
        return ModGridHeader.favorites;
      case 'changeVariantButton':
        return ModGridHeader.changeVariantButton;
      case 'icons':
        return ModGridHeader.icons;
      case 'modIcon':
        return ModGridHeader.modIcon;
      case 'name':
        return ModGridHeader.name;
      case 'author':
        return ModGridHeader.author;
      case 'version':
        return ModGridHeader.version;
      case 'vramImpact':
        return ModGridHeader.vramImpact;
      case 'gameVersion':
        return ModGridHeader.gameVersion;
      case 'firstSeen':
        return ModGridHeader.firstSeen;
      case 'lastEnabled':
        return ModGridHeader.lastEnabled;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(ModGridHeader self) {
    switch (self) {
      case ModGridHeader.favorites:
        return 'favorites';
      case ModGridHeader.changeVariantButton:
        return 'changeVariantButton';
      case ModGridHeader.icons:
        return 'icons';
      case ModGridHeader.modIcon:
        return 'modIcon';
      case ModGridHeader.name:
        return 'name';
      case ModGridHeader.author:
        return 'author';
      case ModGridHeader.version:
        return 'version';
      case ModGridHeader.vramImpact:
        return 'vramImpact';
      case ModGridHeader.gameVersion:
        return 'gameVersion';
      case ModGridHeader.firstSeen:
        return 'firstSeen';
      case ModGridHeader.lastEnabled:
        return 'lastEnabled';
    }
  }
}

extension ModGridHeaderMapperExtension on ModGridHeader {
  String toValue() {
    ModGridHeaderMapper.ensureInitialized();
    return MapperContainer.globals.toValue<ModGridHeader>(this) as String;
  }
}

class ModGridGroupEnumMapper extends EnumMapper<ModGridGroupEnum> {
  ModGridGroupEnumMapper._();

  static ModGridGroupEnumMapper? _instance;
  static ModGridGroupEnumMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ModGridGroupEnumMapper._());
    }
    return _instance!;
  }

  static ModGridGroupEnum fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  ModGridGroupEnum decode(dynamic value) {
    switch (value) {
      case 'enabledState':
        return ModGridGroupEnum.enabledState;
      case 'author':
        return ModGridGroupEnum.author;
      case 'modType':
        return ModGridGroupEnum.modType;
      case 'gameVersion':
        return ModGridGroupEnum.gameVersion;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(ModGridGroupEnum self) {
    switch (self) {
      case ModGridGroupEnum.enabledState:
        return 'enabledState';
      case ModGridGroupEnum.author:
        return 'author';
      case ModGridGroupEnum.modType:
        return 'modType';
      case ModGridGroupEnum.gameVersion:
        return 'gameVersion';
    }
  }
}

extension ModGridGroupEnumMapperExtension on ModGridGroupEnum {
  String toValue() {
    ModGridGroupEnumMapper.ensureInitialized();
    return MapperContainer.globals.toValue<ModGridGroupEnum>(this) as String;
  }
}

class ModGridSortFieldMapper extends EnumMapper<ModGridSortField> {
  ModGridSortFieldMapper._();

  static ModGridSortFieldMapper? _instance;
  static ModGridSortFieldMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ModGridSortFieldMapper._());
    }
    return _instance!;
  }

  static ModGridSortField fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  ModGridSortField decode(dynamic value) {
    switch (value) {
      case 'enabledState':
        return ModGridSortField.enabledState;
      case 'icons':
        return ModGridSortField.icons;
      case 'name':
        return ModGridSortField.name;
      case 'author':
        return ModGridSortField.author;
      case 'version':
        return ModGridSortField.version;
      case 'vramImpact':
        return ModGridSortField.vramImpact;
      case 'gameVersion':
        return ModGridSortField.gameVersion;
      case 'firstSeen':
        return ModGridSortField.firstSeen;
      case 'lastEnabled':
        return ModGridSortField.lastEnabled;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(ModGridSortField self) {
    switch (self) {
      case ModGridSortField.enabledState:
        return 'enabledState';
      case ModGridSortField.icons:
        return 'icons';
      case ModGridSortField.name:
        return 'name';
      case ModGridSortField.author:
        return 'author';
      case ModGridSortField.version:
        return 'version';
      case ModGridSortField.vramImpact:
        return 'vramImpact';
      case ModGridSortField.gameVersion:
        return 'gameVersion';
      case ModGridSortField.firstSeen:
        return 'firstSeen';
      case ModGridSortField.lastEnabled:
        return 'lastEnabled';
    }
  }
}

extension ModGridSortFieldMapperExtension on ModGridSortField {
  String toValue() {
    ModGridSortFieldMapper.ensureInitialized();
    return MapperContainer.globals.toValue<ModGridSortField>(this) as String;
  }
}

class WispGridStateMapper extends ClassMapperBase<WispGridState> {
  WispGridStateMapper._();

  static WispGridStateMapper? _instance;
  static WispGridStateMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = WispGridStateMapper._());
      ModGridSortFieldMapper.ensureInitialized();
      ModGridHeaderMapper.ensureInitialized();
      ModGridColumnSettingMapper.ensureInitialized();
      GroupingSettingMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'WispGridState';

  static ModGridSortField? _$sortField(WispGridState v) => v.sortField;
  static const Field<WispGridState, ModGridSortField> _f$sortField =
      Field('sortField', _$sortField, opt: true, def: ModGridSortField.name);
  static bool _$isSortDescending(WispGridState v) => v.isSortDescending;
  static const Field<WispGridState, bool> _f$isSortDescending =
      Field('isSortDescending', _$isSortDescending, opt: true, def: false);
  static Map<ModGridHeader, ModGridColumnSetting> _$columnSettings(
          WispGridState v) =>
      v.columnSettings;
  static const Field<WispGridState, Map<ModGridHeader, ModGridColumnSetting>>
      _f$columnSettings =
      Field('columnSettings', _$columnSettings, opt: true, def: const {
    ModGridHeader.favorites: ModGridColumnSetting(position: 0, width: 50),
    ModGridHeader.changeVariantButton:
        ModGridColumnSetting(position: 1, width: 130),
    ModGridHeader.icons: ModGridColumnSetting(position: 2, width: 25),
    ModGridHeader.modIcon: ModGridColumnSetting(position: 3, width: 32),
    ModGridHeader.name: ModGridColumnSetting(position: 4, width: 200),
    ModGridHeader.author: ModGridColumnSetting(position: 5, width: 200),
    ModGridHeader.version: ModGridColumnSetting(position: 6, width: 100),
    ModGridHeader.vramImpact: ModGridColumnSetting(position: 7, width: 110),
    ModGridHeader.gameVersion: ModGridColumnSetting(position: 8, width: 100),
    ModGridHeader.firstSeen: ModGridColumnSetting(position: 9, width: 100),
    ModGridHeader.lastEnabled: ModGridColumnSetting(position: 10, width: 100)
  });
  static GroupingSetting _$groupingSetting(WispGridState v) =>
      v.groupingSetting;
  static const Field<WispGridState, GroupingSetting> _f$groupingSetting = Field(
      'groupingSetting', _$groupingSetting,
      opt: true,
      def: const GroupingSetting(grouping: ModGridGroupEnum.enabledState));

  @override
  final MappableFields<WispGridState> fields = const {
    #sortField: _f$sortField,
    #isSortDescending: _f$isSortDescending,
    #columnSettings: _f$columnSettings,
    #groupingSetting: _f$groupingSetting,
  };

  static WispGridState _instantiate(DecodingData data) {
    return WispGridState(
        sortField: data.dec(_f$sortField),
        isSortDescending: data.dec(_f$isSortDescending),
        columnSettings: data.dec(_f$columnSettings),
        groupingSetting: data.dec(_f$groupingSetting));
  }

  @override
  final Function instantiate = _instantiate;

  static WispGridState fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<WispGridState>(map);
  }

  static WispGridState fromJson(String json) {
    return ensureInitialized().decodeJson<WispGridState>(json);
  }
}

mixin WispGridStateMappable {
  String toJson() {
    return WispGridStateMapper.ensureInitialized()
        .encodeJson<WispGridState>(this as WispGridState);
  }

  Map<String, dynamic> toMap() {
    return WispGridStateMapper.ensureInitialized()
        .encodeMap<WispGridState>(this as WispGridState);
  }

  WispGridStateCopyWith<WispGridState, WispGridState, WispGridState>
      get copyWith => _WispGridStateCopyWithImpl(
          this as WispGridState, $identity, $identity);
  @override
  String toString() {
    return WispGridStateMapper.ensureInitialized()
        .stringifyValue(this as WispGridState);
  }

  @override
  bool operator ==(Object other) {
    return WispGridStateMapper.ensureInitialized()
        .equalsValue(this as WispGridState, other);
  }

  @override
  int get hashCode {
    return WispGridStateMapper.ensureInitialized()
        .hashValue(this as WispGridState);
  }
}

extension WispGridStateValueCopy<$R, $Out>
    on ObjectCopyWith<$R, WispGridState, $Out> {
  WispGridStateCopyWith<$R, WispGridState, $Out> get $asWispGridState =>
      $base.as((v, t, t2) => _WispGridStateCopyWithImpl(v, t, t2));
}

abstract class WispGridStateCopyWith<$R, $In extends WispGridState, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  MapCopyWith<
      $R,
      ModGridHeader,
      ModGridColumnSetting,
      ModGridColumnSettingCopyWith<$R, ModGridColumnSetting,
          ModGridColumnSetting>> get columnSettings;
  GroupingSettingCopyWith<$R, GroupingSetting, GroupingSetting>
      get groupingSetting;
  $R call(
      {ModGridSortField? sortField,
      bool? isSortDescending,
      Map<ModGridHeader, ModGridColumnSetting>? columnSettings,
      GroupingSetting? groupingSetting});
  WispGridStateCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _WispGridStateCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, WispGridState, $Out>
    implements WispGridStateCopyWith<$R, WispGridState, $Out> {
  _WispGridStateCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<WispGridState> $mapper =
      WispGridStateMapper.ensureInitialized();
  @override
  MapCopyWith<
      $R,
      ModGridHeader,
      ModGridColumnSetting,
      ModGridColumnSettingCopyWith<$R, ModGridColumnSetting,
          ModGridColumnSetting>> get columnSettings => MapCopyWith(
      $value.columnSettings,
      (v, t) => v.copyWith.$chain(t),
      (v) => call(columnSettings: v));
  @override
  GroupingSettingCopyWith<$R, GroupingSetting, GroupingSetting>
      get groupingSetting => $value.groupingSetting.copyWith
          .$chain((v) => call(groupingSetting: v));
  @override
  $R call(
          {Object? sortField = $none,
          bool? isSortDescending,
          Map<ModGridHeader, ModGridColumnSetting>? columnSettings,
          GroupingSetting? groupingSetting}) =>
      $apply(FieldCopyWithData({
        if (sortField != $none) #sortField: sortField,
        if (isSortDescending != null) #isSortDescending: isSortDescending,
        if (columnSettings != null) #columnSettings: columnSettings,
        if (groupingSetting != null) #groupingSetting: groupingSetting
      }));
  @override
  WispGridState $make(CopyWithData data) => WispGridState(
      sortField: data.get(#sortField, or: $value.sortField),
      isSortDescending:
          data.get(#isSortDescending, or: $value.isSortDescending),
      columnSettings: data.get(#columnSettings, or: $value.columnSettings),
      groupingSetting: data.get(#groupingSetting, or: $value.groupingSetting));

  @override
  WispGridStateCopyWith<$R2, WispGridState, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _WispGridStateCopyWithImpl($value, $cast, t);
}

class ModGridColumnSettingMapper extends ClassMapperBase<ModGridColumnSetting> {
  ModGridColumnSettingMapper._();

  static ModGridColumnSettingMapper? _instance;
  static ModGridColumnSettingMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ModGridColumnSettingMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'ModGridColumnSetting';

  static int _$position(ModGridColumnSetting v) => v.position;
  static const Field<ModGridColumnSetting, int> _f$position =
      Field('position', _$position);
  static double _$width(ModGridColumnSetting v) => v.width;
  static const Field<ModGridColumnSetting, double> _f$width =
      Field('width', _$width);
  static bool _$isVisible(ModGridColumnSetting v) => v.isVisible;
  static const Field<ModGridColumnSetting, bool> _f$isVisible =
      Field('isVisible', _$isVisible, opt: true, def: true);

  @override
  final MappableFields<ModGridColumnSetting> fields = const {
    #position: _f$position,
    #width: _f$width,
    #isVisible: _f$isVisible,
  };

  static ModGridColumnSetting _instantiate(DecodingData data) {
    return ModGridColumnSetting(
        position: data.dec(_f$position),
        width: data.dec(_f$width),
        isVisible: data.dec(_f$isVisible));
  }

  @override
  final Function instantiate = _instantiate;

  static ModGridColumnSetting fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ModGridColumnSetting>(map);
  }

  static ModGridColumnSetting fromJson(String json) {
    return ensureInitialized().decodeJson<ModGridColumnSetting>(json);
  }
}

mixin ModGridColumnSettingMappable {
  String toJson() {
    return ModGridColumnSettingMapper.ensureInitialized()
        .encodeJson<ModGridColumnSetting>(this as ModGridColumnSetting);
  }

  Map<String, dynamic> toMap() {
    return ModGridColumnSettingMapper.ensureInitialized()
        .encodeMap<ModGridColumnSetting>(this as ModGridColumnSetting);
  }

  ModGridColumnSettingCopyWith<ModGridColumnSetting, ModGridColumnSetting,
          ModGridColumnSetting>
      get copyWith => _ModGridColumnSettingCopyWithImpl(
          this as ModGridColumnSetting, $identity, $identity);
  @override
  String toString() {
    return ModGridColumnSettingMapper.ensureInitialized()
        .stringifyValue(this as ModGridColumnSetting);
  }

  @override
  bool operator ==(Object other) {
    return ModGridColumnSettingMapper.ensureInitialized()
        .equalsValue(this as ModGridColumnSetting, other);
  }

  @override
  int get hashCode {
    return ModGridColumnSettingMapper.ensureInitialized()
        .hashValue(this as ModGridColumnSetting);
  }
}

extension ModGridColumnSettingValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ModGridColumnSetting, $Out> {
  ModGridColumnSettingCopyWith<$R, ModGridColumnSetting, $Out>
      get $asModGridColumnSetting =>
          $base.as((v, t, t2) => _ModGridColumnSettingCopyWithImpl(v, t, t2));
}

abstract class ModGridColumnSettingCopyWith<
    $R,
    $In extends ModGridColumnSetting,
    $Out> implements ClassCopyWith<$R, $In, $Out> {
  $R call({int? position, double? width, bool? isVisible});
  ModGridColumnSettingCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
      Then<$Out2, $R2> t);
}

class _ModGridColumnSettingCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ModGridColumnSetting, $Out>
    implements ModGridColumnSettingCopyWith<$R, ModGridColumnSetting, $Out> {
  _ModGridColumnSettingCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ModGridColumnSetting> $mapper =
      ModGridColumnSettingMapper.ensureInitialized();
  @override
  $R call({int? position, double? width, bool? isVisible}) =>
      $apply(FieldCopyWithData({
        if (position != null) #position: position,
        if (width != null) #width: width,
        if (isVisible != null) #isVisible: isVisible
      }));
  @override
  ModGridColumnSetting $make(CopyWithData data) => ModGridColumnSetting(
      position: data.get(#position, or: $value.position),
      width: data.get(#width, or: $value.width),
      isVisible: data.get(#isVisible, or: $value.isVisible));

  @override
  ModGridColumnSettingCopyWith<$R2, ModGridColumnSetting, $Out2>
      $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
          _ModGridColumnSettingCopyWithImpl($value, $cast, t);
}

class GroupingSettingMapper extends ClassMapperBase<GroupingSetting> {
  GroupingSettingMapper._();

  static GroupingSettingMapper? _instance;
  static GroupingSettingMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = GroupingSettingMapper._());
      ModGridGroupEnumMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'GroupingSetting';

  static ModGridGroupEnum _$grouping(GroupingSetting v) => v.grouping;
  static const Field<GroupingSetting, ModGridGroupEnum> _f$grouping =
      Field('grouping', _$grouping);
  static bool _$isSortDescending(GroupingSetting v) => v.isSortDescending;
  static const Field<GroupingSetting, bool> _f$isSortDescending =
      Field('isSortDescending', _$isSortDescending, opt: true, def: false);

  @override
  final MappableFields<GroupingSetting> fields = const {
    #grouping: _f$grouping,
    #isSortDescending: _f$isSortDescending,
  };

  static GroupingSetting _instantiate(DecodingData data) {
    return GroupingSetting(
        grouping: data.dec(_f$grouping),
        isSortDescending: data.dec(_f$isSortDescending));
  }

  @override
  final Function instantiate = _instantiate;

  static GroupingSetting fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<GroupingSetting>(map);
  }

  static GroupingSetting fromJson(String json) {
    return ensureInitialized().decodeJson<GroupingSetting>(json);
  }
}

mixin GroupingSettingMappable {
  String toJson() {
    return GroupingSettingMapper.ensureInitialized()
        .encodeJson<GroupingSetting>(this as GroupingSetting);
  }

  Map<String, dynamic> toMap() {
    return GroupingSettingMapper.ensureInitialized()
        .encodeMap<GroupingSetting>(this as GroupingSetting);
  }

  GroupingSettingCopyWith<GroupingSetting, GroupingSetting, GroupingSetting>
      get copyWith => _GroupingSettingCopyWithImpl(
          this as GroupingSetting, $identity, $identity);
  @override
  String toString() {
    return GroupingSettingMapper.ensureInitialized()
        .stringifyValue(this as GroupingSetting);
  }

  @override
  bool operator ==(Object other) {
    return GroupingSettingMapper.ensureInitialized()
        .equalsValue(this as GroupingSetting, other);
  }

  @override
  int get hashCode {
    return GroupingSettingMapper.ensureInitialized()
        .hashValue(this as GroupingSetting);
  }
}

extension GroupingSettingValueCopy<$R, $Out>
    on ObjectCopyWith<$R, GroupingSetting, $Out> {
  GroupingSettingCopyWith<$R, GroupingSetting, $Out> get $asGroupingSetting =>
      $base.as((v, t, t2) => _GroupingSettingCopyWithImpl(v, t, t2));
}

abstract class GroupingSettingCopyWith<$R, $In extends GroupingSetting, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({ModGridGroupEnum? grouping, bool? isSortDescending});
  GroupingSettingCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
      Then<$Out2, $R2> t);
}

class _GroupingSettingCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, GroupingSetting, $Out>
    implements GroupingSettingCopyWith<$R, GroupingSetting, $Out> {
  _GroupingSettingCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<GroupingSetting> $mapper =
      GroupingSettingMapper.ensureInitialized();
  @override
  $R call({ModGridGroupEnum? grouping, bool? isSortDescending}) =>
      $apply(FieldCopyWithData({
        if (grouping != null) #grouping: grouping,
        if (isSortDescending != null) #isSortDescending: isSortDescending
      }));
  @override
  GroupingSetting $make(CopyWithData data) => GroupingSetting(
      grouping: data.get(#grouping, or: $value.grouping),
      isSortDescending:
          data.get(#isSortDescending, or: $value.isSortDescending));

  @override
  GroupingSettingCopyWith<$R2, GroupingSetting, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _GroupingSettingCopyWithImpl($value, $cast, t);
}
