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
      case 'updateStatus':
        return ModGridHeader.updateStatus;
      case 'vramImpact':
        return ModGridHeader.vramImpact;
      case 'gameVersion':
        return ModGridHeader.gameVersion;
      case 'firstSeen':
        return ModGridHeader.firstSeen;
      case 'lastEnabled':
        return ModGridHeader.lastEnabled;
      default:
        return ModGridHeader.values[4];
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
      case ModGridHeader.updateStatus:
        return 'updateStatus';
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
      case 'updateStatus':
        return ModGridSortField.updateStatus;
      case 'vramImpact':
        return ModGridSortField.vramImpact;
      case 'gameVersion':
        return ModGridSortField.gameVersion;
      case 'firstSeen':
        return ModGridSortField.firstSeen;
      case 'lastEnabled':
        return ModGridSortField.lastEnabled;
      default:
        return ModGridSortField.values[2];
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
      case ModGridSortField.updateStatus:
        return 'updateStatus';
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

class WeaponGridHeaderMapper extends EnumMapper<WeaponGridHeader> {
  WeaponGridHeaderMapper._();

  static WeaponGridHeaderMapper? _instance;
  static WeaponGridHeaderMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = WeaponGridHeaderMapper._());
    }
    return _instance!;
  }

  static WeaponGridHeader fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  WeaponGridHeader decode(dynamic value) {
    switch (value) {
      case 'weaponType':
        return WeaponGridHeader.weaponType;
      case 'size':
        return WeaponGridHeader.size;
      case 'techManufacturer':
        return WeaponGridHeader.techManufacturer;
      case 'primaryRoleStr':
        return WeaponGridHeader.primaryRoleStr;
      case 'tier':
        return WeaponGridHeader.tier;
      case 'damagePerShot':
        return WeaponGridHeader.damagePerShot;
      case 'baseValue':
        return WeaponGridHeader.baseValue;
      case 'range':
        return WeaponGridHeader.range;
      case 'damagePerSecond':
        return WeaponGridHeader.damagePerSecond;
      case 'emp':
        return WeaponGridHeader.emp;
      case 'impact':
        return WeaponGridHeader.impact;
      case 'turnRate':
        return WeaponGridHeader.turnRate;
      case 'ops':
        return WeaponGridHeader.ops;
      case 'ammo':
        return WeaponGridHeader.ammo;
      case 'ammoPerSec':
        return WeaponGridHeader.ammoPerSec;
      case 'reloadSize':
        return WeaponGridHeader.reloadSize;
      case 'energyPerShot':
        return WeaponGridHeader.energyPerShot;
      case 'energyPerSecond':
        return WeaponGridHeader.energyPerSecond;
      case 'chargeup':
        return WeaponGridHeader.chargeup;
      case 'chargedown':
        return WeaponGridHeader.chargedown;
      case 'burstSize':
        return WeaponGridHeader.burstSize;
      case 'burstDelay':
        return WeaponGridHeader.burstDelay;
      case 'minSpread':
        return WeaponGridHeader.minSpread;
      case 'maxSpread':
        return WeaponGridHeader.maxSpread;
      case 'spreadPerShot':
        return WeaponGridHeader.spreadPerShot;
      case 'spreadDecayPerSec':
        return WeaponGridHeader.spreadDecayPerSec;
      case 'beamSpeed':
        return WeaponGridHeader.beamSpeed;
      case 'projSpeed':
        return WeaponGridHeader.projSpeed;
      case 'launchSpeed':
        return WeaponGridHeader.launchSpeed;
      case 'flightTime':
        return WeaponGridHeader.flightTime;
      case 'projHitpoints':
        return WeaponGridHeader.projHitpoints;
      case 'autofireAccBonus':
        return WeaponGridHeader.autofireAccBonus;
      case 'extraArcForAI':
        return WeaponGridHeader.extraArcForAI;
      case 'hints':
        return WeaponGridHeader.hints;
      case 'tags':
        return WeaponGridHeader.tags;
      case 'groupTag':
        return WeaponGridHeader.groupTag;
      case 'speedStr':
        return WeaponGridHeader.speedStr;
      case 'trackingStr':
        return WeaponGridHeader.trackingStr;
      case 'turnRateStr':
        return WeaponGridHeader.turnRateStr;
      case 'accuracyStr':
        return WeaponGridHeader.accuracyStr;
      case 'specClass':
        return WeaponGridHeader.specClass;
      default:
        return WeaponGridHeader.values[0];
    }
  }

  @override
  dynamic encode(WeaponGridHeader self) {
    switch (self) {
      case WeaponGridHeader.weaponType:
        return 'weaponType';
      case WeaponGridHeader.size:
        return 'size';
      case WeaponGridHeader.techManufacturer:
        return 'techManufacturer';
      case WeaponGridHeader.primaryRoleStr:
        return 'primaryRoleStr';
      case WeaponGridHeader.tier:
        return 'tier';
      case WeaponGridHeader.damagePerShot:
        return 'damagePerShot';
      case WeaponGridHeader.baseValue:
        return 'baseValue';
      case WeaponGridHeader.range:
        return 'range';
      case WeaponGridHeader.damagePerSecond:
        return 'damagePerSecond';
      case WeaponGridHeader.emp:
        return 'emp';
      case WeaponGridHeader.impact:
        return 'impact';
      case WeaponGridHeader.turnRate:
        return 'turnRate';
      case WeaponGridHeader.ops:
        return 'ops';
      case WeaponGridHeader.ammo:
        return 'ammo';
      case WeaponGridHeader.ammoPerSec:
        return 'ammoPerSec';
      case WeaponGridHeader.reloadSize:
        return 'reloadSize';
      case WeaponGridHeader.energyPerShot:
        return 'energyPerShot';
      case WeaponGridHeader.energyPerSecond:
        return 'energyPerSecond';
      case WeaponGridHeader.chargeup:
        return 'chargeup';
      case WeaponGridHeader.chargedown:
        return 'chargedown';
      case WeaponGridHeader.burstSize:
        return 'burstSize';
      case WeaponGridHeader.burstDelay:
        return 'burstDelay';
      case WeaponGridHeader.minSpread:
        return 'minSpread';
      case WeaponGridHeader.maxSpread:
        return 'maxSpread';
      case WeaponGridHeader.spreadPerShot:
        return 'spreadPerShot';
      case WeaponGridHeader.spreadDecayPerSec:
        return 'spreadDecayPerSec';
      case WeaponGridHeader.beamSpeed:
        return 'beamSpeed';
      case WeaponGridHeader.projSpeed:
        return 'projSpeed';
      case WeaponGridHeader.launchSpeed:
        return 'launchSpeed';
      case WeaponGridHeader.flightTime:
        return 'flightTime';
      case WeaponGridHeader.projHitpoints:
        return 'projHitpoints';
      case WeaponGridHeader.autofireAccBonus:
        return 'autofireAccBonus';
      case WeaponGridHeader.extraArcForAI:
        return 'extraArcForAI';
      case WeaponGridHeader.hints:
        return 'hints';
      case WeaponGridHeader.tags:
        return 'tags';
      case WeaponGridHeader.groupTag:
        return 'groupTag';
      case WeaponGridHeader.speedStr:
        return 'speedStr';
      case WeaponGridHeader.trackingStr:
        return 'trackingStr';
      case WeaponGridHeader.turnRateStr:
        return 'turnRateStr';
      case WeaponGridHeader.accuracyStr:
        return 'accuracyStr';
      case WeaponGridHeader.specClass:
        return 'specClass';
    }
  }
}

extension WeaponGridHeaderMapperExtension on WeaponGridHeader {
  String toValue() {
    WeaponGridHeaderMapper.ensureInitialized();
    return MapperContainer.globals.toValue<WeaponGridHeader>(this) as String;
  }
}

class WispGridColumnMapper extends ClassMapperBase<WispGridColumn> {
  WispGridColumnMapper._();

  static WispGridColumnMapper? _instance;
  static WispGridColumnMapper ensureInitialized() {
    if (_instance == null) {
      MapperBase.addType<WispGridItem>();
      MapperContainer.globals.use(_instance = WispGridColumnMapper._());
      WispGridColumnStateMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'WispGridColumn';
  @override
  Function get typeFactory =>
      <T extends WispGridItem>(f) => f<WispGridColumn<T>>();

  static String _$key(WispGridColumn v) => v.key;
  static const Field<WispGridColumn, String> _f$key = Field('key', _$key);
  static String _$name(WispGridColumn v) => v.name;
  static const Field<WispGridColumn, String> _f$name = Field('name', _$name);
  static bool _$isSortable(WispGridColumn v) => v.isSortable;
  static const Field<WispGridColumn, bool> _f$isSortable =
      Field('isSortable', _$isSortable);
  static Function _$getSortValue(WispGridColumn v) =>
      (v as dynamic).getSortValue as Function;
  static dynamic _arg$getSortValue<T extends WispGridItem>(f) =>
      f<Comparable<dynamic>? Function(T)>();
  static const Field<WispGridColumn, Function> _f$getSortValue =
      Field('getSortValue', _$getSortValue, opt: true, arg: _arg$getSortValue);
  static Function _$headerCellBuilder(WispGridColumn v) =>
      (v as dynamic).headerCellBuilder as Function;
  static dynamic _arg$headerCellBuilder<T extends WispGridItem>(f) =>
      f<Widget Function(HeaderBuilderModifiers)>();
  static const Field<WispGridColumn, Function> _f$headerCellBuilder = Field(
      'headerCellBuilder', _$headerCellBuilder,
      opt: true, arg: _arg$headerCellBuilder);
  static Function _$itemCellBuilder(WispGridColumn v) =>
      (v as dynamic).itemCellBuilder as Function;
  static dynamic _arg$itemCellBuilder<T extends WispGridItem>(f) =>
      f<Widget Function(T, CellBuilderModifiers)>();
  static const Field<WispGridColumn, Function> _f$itemCellBuilder = Field(
      'itemCellBuilder', _$itemCellBuilder,
      opt: true, arg: _arg$itemCellBuilder);
  static WispGridColumnState _$defaultState(WispGridColumn v) => v.defaultState;
  static const Field<WispGridColumn, WispGridColumnState> _f$defaultState =
      Field('defaultState', _$defaultState);

  @override
  final MappableFields<WispGridColumn> fields = const {
    #key: _f$key,
    #name: _f$name,
    #isSortable: _f$isSortable,
    #getSortValue: _f$getSortValue,
    #headerCellBuilder: _f$headerCellBuilder,
    #itemCellBuilder: _f$itemCellBuilder,
    #defaultState: _f$defaultState,
  };

  static WispGridColumn<T> _instantiate<T extends WispGridItem>(
      DecodingData data) {
    return WispGridColumn(
        key: data.dec(_f$key),
        name: data.dec(_f$name),
        isSortable: data.dec(_f$isSortable),
        getSortValue: data.dec(_f$getSortValue),
        headerCellBuilder: data.dec(_f$headerCellBuilder),
        itemCellBuilder: data.dec(_f$itemCellBuilder),
        defaultState: data.dec(_f$defaultState));
  }

  @override
  final Function instantiate = _instantiate;

  static WispGridColumn<T> fromMap<T extends WispGridItem>(
      Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<WispGridColumn<T>>(map);
  }

  static WispGridColumn<T> fromJson<T extends WispGridItem>(String json) {
    return ensureInitialized().decodeJson<WispGridColumn<T>>(json);
  }
}

mixin WispGridColumnMappable<T extends WispGridItem> {
  String toJson() {
    return WispGridColumnMapper.ensureInitialized()
        .encodeJson<WispGridColumn<T>>(this as WispGridColumn<T>);
  }

  Map<String, dynamic> toMap() {
    return WispGridColumnMapper.ensureInitialized()
        .encodeMap<WispGridColumn<T>>(this as WispGridColumn<T>);
  }

  WispGridColumnCopyWith<WispGridColumn<T>, WispGridColumn<T>,
          WispGridColumn<T>, T>
      get copyWith => _WispGridColumnCopyWithImpl(
          this as WispGridColumn<T>, $identity, $identity);
  @override
  String toString() {
    return WispGridColumnMapper.ensureInitialized()
        .stringifyValue(this as WispGridColumn<T>);
  }

  @override
  bool operator ==(Object other) {
    return WispGridColumnMapper.ensureInitialized()
        .equalsValue(this as WispGridColumn<T>, other);
  }

  @override
  int get hashCode {
    return WispGridColumnMapper.ensureInitialized()
        .hashValue(this as WispGridColumn<T>);
  }
}

extension WispGridColumnValueCopy<$R, $Out, T extends WispGridItem>
    on ObjectCopyWith<$R, WispGridColumn<T>, $Out> {
  WispGridColumnCopyWith<$R, WispGridColumn<T>, $Out, T>
      get $asWispGridColumn =>
          $base.as((v, t, t2) => _WispGridColumnCopyWithImpl(v, t, t2));
}

abstract class WispGridColumnCopyWith<$R, $In extends WispGridColumn<T>, $Out,
    T extends WispGridItem> implements ClassCopyWith<$R, $In, $Out> {
  WispGridColumnStateCopyWith<$R, WispGridColumnState, WispGridColumnState>
      get defaultState;
  $R call(
      {String? key,
      String? name,
      bool? isSortable,
      Comparable<dynamic>? Function(T)? getSortValue,
      Widget Function(HeaderBuilderModifiers)? headerCellBuilder,
      Widget Function(T, CellBuilderModifiers)? itemCellBuilder,
      WispGridColumnState? defaultState});
  WispGridColumnCopyWith<$R2, $In, $Out2, T> $chain<$R2, $Out2>(
      Then<$Out2, $R2> t);
}

class _WispGridColumnCopyWithImpl<$R, $Out, T extends WispGridItem>
    extends ClassCopyWithBase<$R, WispGridColumn<T>, $Out>
    implements WispGridColumnCopyWith<$R, WispGridColumn<T>, $Out, T> {
  _WispGridColumnCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<WispGridColumn> $mapper =
      WispGridColumnMapper.ensureInitialized();
  @override
  WispGridColumnStateCopyWith<$R, WispGridColumnState, WispGridColumnState>
      get defaultState =>
          $value.defaultState.copyWith.$chain((v) => call(defaultState: v));
  @override
  $R call(
          {String? key,
          String? name,
          bool? isSortable,
          Object? getSortValue = $none,
          Object? headerCellBuilder = $none,
          Object? itemCellBuilder = $none,
          WispGridColumnState? defaultState}) =>
      $apply(FieldCopyWithData({
        if (key != null) #key: key,
        if (name != null) #name: name,
        if (isSortable != null) #isSortable: isSortable,
        if (getSortValue != $none) #getSortValue: getSortValue,
        if (headerCellBuilder != $none) #headerCellBuilder: headerCellBuilder,
        if (itemCellBuilder != $none) #itemCellBuilder: itemCellBuilder,
        if (defaultState != null) #defaultState: defaultState
      }));
  @override
  WispGridColumn<T> $make(CopyWithData data) => WispGridColumn(
      key: data.get(#key, or: $value.key),
      name: data.get(#name, or: $value.name),
      isSortable: data.get(#isSortable, or: $value.isSortable),
      getSortValue: data.get(#getSortValue, or: $value.getSortValue),
      headerCellBuilder:
          data.get(#headerCellBuilder, or: $value.headerCellBuilder),
      itemCellBuilder: data.get(#itemCellBuilder, or: $value.itemCellBuilder),
      defaultState: data.get(#defaultState, or: $value.defaultState));

  @override
  WispGridColumnCopyWith<$R2, WispGridColumn<T>, $Out2, T> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _WispGridColumnCopyWithImpl($value, $cast, t);
}

class WispGridColumnStateMapper extends ClassMapperBase<WispGridColumnState> {
  WispGridColumnStateMapper._();

  static WispGridColumnStateMapper? _instance;
  static WispGridColumnStateMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = WispGridColumnStateMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'WispGridColumnState';

  static int _$position(WispGridColumnState v) => v.position;
  static const Field<WispGridColumnState, int> _f$position =
      Field('position', _$position);
  static double _$width(WispGridColumnState v) => v.width;
  static const Field<WispGridColumnState, double> _f$width =
      Field('width', _$width);
  static bool _$isVisible(WispGridColumnState v) => v.isVisible;
  static const Field<WispGridColumnState, bool> _f$isVisible =
      Field('isVisible', _$isVisible, opt: true, def: true);

  @override
  final MappableFields<WispGridColumnState> fields = const {
    #position: _f$position,
    #width: _f$width,
    #isVisible: _f$isVisible,
  };

  static WispGridColumnState _instantiate(DecodingData data) {
    return WispGridColumnState(
        position: data.dec(_f$position),
        width: data.dec(_f$width),
        isVisible: data.dec(_f$isVisible));
  }

  @override
  final Function instantiate = _instantiate;

  static WispGridColumnState fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<WispGridColumnState>(map);
  }

  static WispGridColumnState fromJson(String json) {
    return ensureInitialized().decodeJson<WispGridColumnState>(json);
  }
}

mixin WispGridColumnStateMappable {
  String toJson() {
    return WispGridColumnStateMapper.ensureInitialized()
        .encodeJson<WispGridColumnState>(this as WispGridColumnState);
  }

  Map<String, dynamic> toMap() {
    return WispGridColumnStateMapper.ensureInitialized()
        .encodeMap<WispGridColumnState>(this as WispGridColumnState);
  }

  WispGridColumnStateCopyWith<WispGridColumnState, WispGridColumnState,
          WispGridColumnState>
      get copyWith => _WispGridColumnStateCopyWithImpl(
          this as WispGridColumnState, $identity, $identity);
  @override
  String toString() {
    return WispGridColumnStateMapper.ensureInitialized()
        .stringifyValue(this as WispGridColumnState);
  }

  @override
  bool operator ==(Object other) {
    return WispGridColumnStateMapper.ensureInitialized()
        .equalsValue(this as WispGridColumnState, other);
  }

  @override
  int get hashCode {
    return WispGridColumnStateMapper.ensureInitialized()
        .hashValue(this as WispGridColumnState);
  }
}

extension WispGridColumnStateValueCopy<$R, $Out>
    on ObjectCopyWith<$R, WispGridColumnState, $Out> {
  WispGridColumnStateCopyWith<$R, WispGridColumnState, $Out>
      get $asWispGridColumnState =>
          $base.as((v, t, t2) => _WispGridColumnStateCopyWithImpl(v, t, t2));
}

abstract class WispGridColumnStateCopyWith<$R, $In extends WispGridColumnState,
    $Out> implements ClassCopyWith<$R, $In, $Out> {
  $R call({int? position, double? width, bool? isVisible});
  WispGridColumnStateCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
      Then<$Out2, $R2> t);
}

class _WispGridColumnStateCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, WispGridColumnState, $Out>
    implements WispGridColumnStateCopyWith<$R, WispGridColumnState, $Out> {
  _WispGridColumnStateCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<WispGridColumnState> $mapper =
      WispGridColumnStateMapper.ensureInitialized();
  @override
  $R call({int? position, double? width, bool? isVisible}) =>
      $apply(FieldCopyWithData({
        if (position != null) #position: position,
        if (width != null) #width: width,
        if (isVisible != null) #isVisible: isVisible
      }));
  @override
  WispGridColumnState $make(CopyWithData data) => WispGridColumnState(
      position: data.get(#position, or: $value.position),
      width: data.get(#width, or: $value.width),
      isVisible: data.get(#isVisible, or: $value.isVisible));

  @override
  WispGridColumnStateCopyWith<$R2, WispGridColumnState, $Out2>
      $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
          _WispGridColumnStateCopyWithImpl($value, $cast, t);
}

class HeaderBuilderModifiersMapper
    extends ClassMapperBase<HeaderBuilderModifiers> {
  HeaderBuilderModifiersMapper._();

  static HeaderBuilderModifiersMapper? _instance;
  static HeaderBuilderModifiersMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = HeaderBuilderModifiersMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'HeaderBuilderModifiers';

  static bool _$isHovering(HeaderBuilderModifiers v) => v.isHovering;
  static const Field<HeaderBuilderModifiers, bool> _f$isHovering =
      Field('isHovering', _$isHovering);

  @override
  final MappableFields<HeaderBuilderModifiers> fields = const {
    #isHovering: _f$isHovering,
  };

  static HeaderBuilderModifiers _instantiate(DecodingData data) {
    return HeaderBuilderModifiers(isHovering: data.dec(_f$isHovering));
  }

  @override
  final Function instantiate = _instantiate;

  static HeaderBuilderModifiers fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<HeaderBuilderModifiers>(map);
  }

  static HeaderBuilderModifiers fromJson(String json) {
    return ensureInitialized().decodeJson<HeaderBuilderModifiers>(json);
  }
}

mixin HeaderBuilderModifiersMappable {
  String toJson() {
    return HeaderBuilderModifiersMapper.ensureInitialized()
        .encodeJson<HeaderBuilderModifiers>(this as HeaderBuilderModifiers);
  }

  Map<String, dynamic> toMap() {
    return HeaderBuilderModifiersMapper.ensureInitialized()
        .encodeMap<HeaderBuilderModifiers>(this as HeaderBuilderModifiers);
  }

  HeaderBuilderModifiersCopyWith<HeaderBuilderModifiers, HeaderBuilderModifiers,
          HeaderBuilderModifiers>
      get copyWith => _HeaderBuilderModifiersCopyWithImpl(
          this as HeaderBuilderModifiers, $identity, $identity);
  @override
  String toString() {
    return HeaderBuilderModifiersMapper.ensureInitialized()
        .stringifyValue(this as HeaderBuilderModifiers);
  }

  @override
  bool operator ==(Object other) {
    return HeaderBuilderModifiersMapper.ensureInitialized()
        .equalsValue(this as HeaderBuilderModifiers, other);
  }

  @override
  int get hashCode {
    return HeaderBuilderModifiersMapper.ensureInitialized()
        .hashValue(this as HeaderBuilderModifiers);
  }
}

extension HeaderBuilderModifiersValueCopy<$R, $Out>
    on ObjectCopyWith<$R, HeaderBuilderModifiers, $Out> {
  HeaderBuilderModifiersCopyWith<$R, HeaderBuilderModifiers, $Out>
      get $asHeaderBuilderModifiers =>
          $base.as((v, t, t2) => _HeaderBuilderModifiersCopyWithImpl(v, t, t2));
}

abstract class HeaderBuilderModifiersCopyWith<
    $R,
    $In extends HeaderBuilderModifiers,
    $Out> implements ClassCopyWith<$R, $In, $Out> {
  $R call({bool? isHovering});
  HeaderBuilderModifiersCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
      Then<$Out2, $R2> t);
}

class _HeaderBuilderModifiersCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, HeaderBuilderModifiers, $Out>
    implements
        HeaderBuilderModifiersCopyWith<$R, HeaderBuilderModifiers, $Out> {
  _HeaderBuilderModifiersCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<HeaderBuilderModifiers> $mapper =
      HeaderBuilderModifiersMapper.ensureInitialized();
  @override
  $R call({bool? isHovering}) => $apply(
      FieldCopyWithData({if (isHovering != null) #isHovering: isHovering}));
  @override
  HeaderBuilderModifiers $make(CopyWithData data) => HeaderBuilderModifiers(
      isHovering: data.get(#isHovering, or: $value.isHovering));

  @override
  HeaderBuilderModifiersCopyWith<$R2, HeaderBuilderModifiers, $Out2>
      $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
          _HeaderBuilderModifiersCopyWithImpl($value, $cast, t);
}

class CellBuilderModifiersMapper extends ClassMapperBase<CellBuilderModifiers> {
  CellBuilderModifiersMapper._();

  static CellBuilderModifiersMapper? _instance;
  static CellBuilderModifiersMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = CellBuilderModifiersMapper._());
      WispGridColumnStateMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'CellBuilderModifiers';

  static bool _$isHovering(CellBuilderModifiers v) => v.isHovering;
  static const Field<CellBuilderModifiers, bool> _f$isHovering =
      Field('isHovering', _$isHovering);
  static bool _$isRowChecked(CellBuilderModifiers v) => v.isRowChecked;
  static const Field<CellBuilderModifiers, bool> _f$isRowChecked =
      Field('isRowChecked', _$isRowChecked);
  static WispGridColumnState _$columnState(CellBuilderModifiers v) =>
      v.columnState;
  static const Field<CellBuilderModifiers, WispGridColumnState> _f$columnState =
      Field('columnState', _$columnState);

  @override
  final MappableFields<CellBuilderModifiers> fields = const {
    #isHovering: _f$isHovering,
    #isRowChecked: _f$isRowChecked,
    #columnState: _f$columnState,
  };

  static CellBuilderModifiers _instantiate(DecodingData data) {
    return CellBuilderModifiers(
        isHovering: data.dec(_f$isHovering),
        isRowChecked: data.dec(_f$isRowChecked),
        columnState: data.dec(_f$columnState));
  }

  @override
  final Function instantiate = _instantiate;

  static CellBuilderModifiers fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<CellBuilderModifiers>(map);
  }

  static CellBuilderModifiers fromJson(String json) {
    return ensureInitialized().decodeJson<CellBuilderModifiers>(json);
  }
}

mixin CellBuilderModifiersMappable {
  String toJson() {
    return CellBuilderModifiersMapper.ensureInitialized()
        .encodeJson<CellBuilderModifiers>(this as CellBuilderModifiers);
  }

  Map<String, dynamic> toMap() {
    return CellBuilderModifiersMapper.ensureInitialized()
        .encodeMap<CellBuilderModifiers>(this as CellBuilderModifiers);
  }

  CellBuilderModifiersCopyWith<CellBuilderModifiers, CellBuilderModifiers,
          CellBuilderModifiers>
      get copyWith => _CellBuilderModifiersCopyWithImpl(
          this as CellBuilderModifiers, $identity, $identity);
  @override
  String toString() {
    return CellBuilderModifiersMapper.ensureInitialized()
        .stringifyValue(this as CellBuilderModifiers);
  }

  @override
  bool operator ==(Object other) {
    return CellBuilderModifiersMapper.ensureInitialized()
        .equalsValue(this as CellBuilderModifiers, other);
  }

  @override
  int get hashCode {
    return CellBuilderModifiersMapper.ensureInitialized()
        .hashValue(this as CellBuilderModifiers);
  }
}

extension CellBuilderModifiersValueCopy<$R, $Out>
    on ObjectCopyWith<$R, CellBuilderModifiers, $Out> {
  CellBuilderModifiersCopyWith<$R, CellBuilderModifiers, $Out>
      get $asCellBuilderModifiers =>
          $base.as((v, t, t2) => _CellBuilderModifiersCopyWithImpl(v, t, t2));
}

abstract class CellBuilderModifiersCopyWith<
    $R,
    $In extends CellBuilderModifiers,
    $Out> implements ClassCopyWith<$R, $In, $Out> {
  WispGridColumnStateCopyWith<$R, WispGridColumnState, WispGridColumnState>
      get columnState;
  $R call(
      {bool? isHovering, bool? isRowChecked, WispGridColumnState? columnState});
  CellBuilderModifiersCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
      Then<$Out2, $R2> t);
}

class _CellBuilderModifiersCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, CellBuilderModifiers, $Out>
    implements CellBuilderModifiersCopyWith<$R, CellBuilderModifiers, $Out> {
  _CellBuilderModifiersCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<CellBuilderModifiers> $mapper =
      CellBuilderModifiersMapper.ensureInitialized();
  @override
  WispGridColumnStateCopyWith<$R, WispGridColumnState, WispGridColumnState>
      get columnState =>
          $value.columnState.copyWith.$chain((v) => call(columnState: v));
  @override
  $R call(
          {bool? isHovering,
          bool? isRowChecked,
          WispGridColumnState? columnState}) =>
      $apply(FieldCopyWithData({
        if (isHovering != null) #isHovering: isHovering,
        if (isRowChecked != null) #isRowChecked: isRowChecked,
        if (columnState != null) #columnState: columnState
      }));
  @override
  CellBuilderModifiers $make(CopyWithData data) => CellBuilderModifiers(
      isHovering: data.get(#isHovering, or: $value.isHovering),
      isRowChecked: data.get(#isRowChecked, or: $value.isRowChecked),
      columnState: data.get(#columnState, or: $value.columnState));

  @override
  CellBuilderModifiersCopyWith<$R2, CellBuilderModifiers, $Out2>
      $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
          _CellBuilderModifiersCopyWithImpl($value, $cast, t);
}

class RowBuilderModifiersMapper extends ClassMapperBase<RowBuilderModifiers> {
  RowBuilderModifiersMapper._();

  static RowBuilderModifiersMapper? _instance;
  static RowBuilderModifiersMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = RowBuilderModifiersMapper._());
      WispGridColumnMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'RowBuilderModifiers';

  static bool _$isHovering(RowBuilderModifiers v) => v.isHovering;
  static const Field<RowBuilderModifiers, bool> _f$isHovering =
      Field('isHovering', _$isHovering);
  static bool _$isRowChecked(RowBuilderModifiers v) => v.isRowChecked;
  static const Field<RowBuilderModifiers, bool> _f$isRowChecked =
      Field('isRowChecked', _$isRowChecked);
  static List<WispGridColumn<WispGridItem>> _$columns(RowBuilderModifiers v) =>
      v.columns;
  static const Field<RowBuilderModifiers, List<WispGridColumn<WispGridItem>>>
      _f$columns = Field('columns', _$columns);

  @override
  final MappableFields<RowBuilderModifiers> fields = const {
    #isHovering: _f$isHovering,
    #isRowChecked: _f$isRowChecked,
    #columns: _f$columns,
  };

  static RowBuilderModifiers _instantiate(DecodingData data) {
    return RowBuilderModifiers(
        isHovering: data.dec(_f$isHovering),
        isRowChecked: data.dec(_f$isRowChecked),
        columns: data.dec(_f$columns));
  }

  @override
  final Function instantiate = _instantiate;

  static RowBuilderModifiers fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<RowBuilderModifiers>(map);
  }

  static RowBuilderModifiers fromJson(String json) {
    return ensureInitialized().decodeJson<RowBuilderModifiers>(json);
  }
}

mixin RowBuilderModifiersMappable {
  String toJson() {
    return RowBuilderModifiersMapper.ensureInitialized()
        .encodeJson<RowBuilderModifiers>(this as RowBuilderModifiers);
  }

  Map<String, dynamic> toMap() {
    return RowBuilderModifiersMapper.ensureInitialized()
        .encodeMap<RowBuilderModifiers>(this as RowBuilderModifiers);
  }

  RowBuilderModifiersCopyWith<RowBuilderModifiers, RowBuilderModifiers,
          RowBuilderModifiers>
      get copyWith => _RowBuilderModifiersCopyWithImpl(
          this as RowBuilderModifiers, $identity, $identity);
  @override
  String toString() {
    return RowBuilderModifiersMapper.ensureInitialized()
        .stringifyValue(this as RowBuilderModifiers);
  }

  @override
  bool operator ==(Object other) {
    return RowBuilderModifiersMapper.ensureInitialized()
        .equalsValue(this as RowBuilderModifiers, other);
  }

  @override
  int get hashCode {
    return RowBuilderModifiersMapper.ensureInitialized()
        .hashValue(this as RowBuilderModifiers);
  }
}

extension RowBuilderModifiersValueCopy<$R, $Out>
    on ObjectCopyWith<$R, RowBuilderModifiers, $Out> {
  RowBuilderModifiersCopyWith<$R, RowBuilderModifiers, $Out>
      get $asRowBuilderModifiers =>
          $base.as((v, t, t2) => _RowBuilderModifiersCopyWithImpl(v, t, t2));
}

abstract class RowBuilderModifiersCopyWith<$R, $In extends RowBuilderModifiers,
    $Out> implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<
      $R,
      WispGridColumn<WispGridItem>,
      WispGridColumnCopyWith<$R, WispGridColumn<WispGridItem>,
          WispGridColumn<WispGridItem>, WispGridItem>> get columns;
  $R call(
      {bool? isHovering,
      bool? isRowChecked,
      List<WispGridColumn<WispGridItem>>? columns});
  RowBuilderModifiersCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
      Then<$Out2, $R2> t);
}

class _RowBuilderModifiersCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, RowBuilderModifiers, $Out>
    implements RowBuilderModifiersCopyWith<$R, RowBuilderModifiers, $Out> {
  _RowBuilderModifiersCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<RowBuilderModifiers> $mapper =
      RowBuilderModifiersMapper.ensureInitialized();
  @override
  ListCopyWith<
      $R,
      WispGridColumn<WispGridItem>,
      WispGridColumnCopyWith<
          $R,
          WispGridColumn<WispGridItem>,
          WispGridColumn<WispGridItem>,
          WispGridItem>> get columns => ListCopyWith(
      $value.columns, (v, t) => v.copyWith.$chain(t), (v) => call(columns: v));
  @override
  $R call(
          {bool? isHovering,
          bool? isRowChecked,
          List<WispGridColumn<WispGridItem>>? columns}) =>
      $apply(FieldCopyWithData({
        if (isHovering != null) #isHovering: isHovering,
        if (isRowChecked != null) #isRowChecked: isRowChecked,
        if (columns != null) #columns: columns
      }));
  @override
  RowBuilderModifiers $make(CopyWithData data) => RowBuilderModifiers(
      isHovering: data.get(#isHovering, or: $value.isHovering),
      isRowChecked: data.get(#isRowChecked, or: $value.isRowChecked),
      columns: data.get(#columns, or: $value.columns));

  @override
  RowBuilderModifiersCopyWith<$R2, RowBuilderModifiers, $Out2>
      $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
          _RowBuilderModifiersCopyWithImpl($value, $cast, t);
}

class WispGridStateMapper extends ClassMapperBase<WispGridState> {
  WispGridStateMapper._();

  static WispGridStateMapper? _instance;
  static WispGridStateMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = WispGridStateMapper._());
      WispGridColumnStateMapper.ensureInitialized();
      GroupingSettingMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'WispGridState';

  static String? _$sortedColumnKey(WispGridState v) => v.sortedColumnKey;
  static const Field<WispGridState, String> _f$sortedColumnKey =
      Field('sortedColumnKey', _$sortedColumnKey, opt: true);
  static bool _$isSortDescending(WispGridState v) => v.isSortDescending;
  static const Field<WispGridState, bool> _f$isSortDescending =
      Field('isSortDescending', _$isSortDescending, opt: true, def: false);
  static Map<String, WispGridColumnState> _$columnsState(WispGridState v) =>
      v.columnsState;
  static const Field<WispGridState, Map<String, WispGridColumnState>>
      _f$columnsState = Field('columnsState', _$columnsState);
  static GroupingSetting? _$groupingSetting(WispGridState v) =>
      v.groupingSetting;
  static const Field<WispGridState, GroupingSetting> _f$groupingSetting =
      Field('groupingSetting', _$groupingSetting);

  @override
  final MappableFields<WispGridState> fields = const {
    #sortedColumnKey: _f$sortedColumnKey,
    #isSortDescending: _f$isSortDescending,
    #columnsState: _f$columnsState,
    #groupingSetting: _f$groupingSetting,
  };

  static WispGridState _instantiate(DecodingData data) {
    return WispGridState(
        sortedColumnKey: data.dec(_f$sortedColumnKey),
        isSortDescending: data.dec(_f$isSortDescending),
        columnsState: data.dec(_f$columnsState),
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
      String,
      WispGridColumnState,
      WispGridColumnStateCopyWith<$R, WispGridColumnState,
          WispGridColumnState>> get columnsState;
  GroupingSettingCopyWith<$R, GroupingSetting, GroupingSetting>?
      get groupingSetting;
  $R call(
      {String? sortedColumnKey,
      bool? isSortDescending,
      Map<String, WispGridColumnState>? columnsState,
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
      String,
      WispGridColumnState,
      WispGridColumnStateCopyWith<$R, WispGridColumnState,
          WispGridColumnState>> get columnsState => MapCopyWith(
      $value.columnsState,
      (v, t) => v.copyWith.$chain(t),
      (v) => call(columnsState: v));
  @override
  GroupingSettingCopyWith<$R, GroupingSetting, GroupingSetting>?
      get groupingSetting => $value.groupingSetting?.copyWith
          .$chain((v) => call(groupingSetting: v));
  @override
  $R call(
          {Object? sortedColumnKey = $none,
          bool? isSortDescending,
          Map<String, WispGridColumnState>? columnsState,
          Object? groupingSetting = $none}) =>
      $apply(FieldCopyWithData({
        if (sortedColumnKey != $none) #sortedColumnKey: sortedColumnKey,
        if (isSortDescending != null) #isSortDescending: isSortDescending,
        if (columnsState != null) #columnsState: columnsState,
        if (groupingSetting != $none) #groupingSetting: groupingSetting
      }));
  @override
  WispGridState $make(CopyWithData data) => WispGridState(
      sortedColumnKey: data.get(#sortedColumnKey, or: $value.sortedColumnKey),
      isSortDescending:
          data.get(#isSortDescending, or: $value.isSortDescending),
      columnsState: data.get(#columnsState, or: $value.columnsState),
      groupingSetting: data.get(#groupingSetting, or: $value.groupingSetting));

  @override
  WispGridStateCopyWith<$R2, WispGridState, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _WispGridStateCopyWithImpl($value, $cast, t);
}

class GroupingSettingMapper extends ClassMapperBase<GroupingSetting> {
  GroupingSettingMapper._();

  static GroupingSettingMapper? _instance;
  static GroupingSettingMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = GroupingSettingMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'GroupingSetting';

  static String _$currentGroupedByKey(GroupingSetting v) =>
      v.currentGroupedByKey;
  static const Field<GroupingSetting, String> _f$currentGroupedByKey =
      Field('currentGroupedByKey', _$currentGroupedByKey);
  static bool _$isSortDescending(GroupingSetting v) => v.isSortDescending;
  static const Field<GroupingSetting, bool> _f$isSortDescending =
      Field('isSortDescending', _$isSortDescending, opt: true, def: false);

  @override
  final MappableFields<GroupingSetting> fields = const {
    #currentGroupedByKey: _f$currentGroupedByKey,
    #isSortDescending: _f$isSortDescending,
  };

  static GroupingSetting _instantiate(DecodingData data) {
    return GroupingSetting(
        currentGroupedByKey: data.dec(_f$currentGroupedByKey),
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
  $R call({String? currentGroupedByKey, bool? isSortDescending});
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
  $R call({String? currentGroupedByKey, bool? isSortDescending}) =>
      $apply(FieldCopyWithData({
        if (currentGroupedByKey != null)
          #currentGroupedByKey: currentGroupedByKey,
        if (isSortDescending != null) #isSortDescending: isSortDescending
      }));
  @override
  GroupingSetting $make(CopyWithData data) => GroupingSetting(
      currentGroupedByKey:
          data.get(#currentGroupedByKey, or: $value.currentGroupedByKey),
      isSortDescending:
          data.get(#isSortDescending, or: $value.isSortDescending));

  @override
  GroupingSettingCopyWith<$R2, GroupingSetting, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _GroupingSettingCopyWithImpl($value, $cast, t);
}
