// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'wisp_grid.dart';

class WispGridRowMapper extends ClassMapperBase<WispGridRow> {
  WispGridRowMapper._();

  static WispGridRowMapper? _instance;
  static WispGridRowMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = WispGridRowMapper._());
      WispGridModRowMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'WispGridRow';
  @override
  Function get typeFactory => <T>(f) => f<WispGridRow<T>>();

  static dynamic _$item(WispGridRow v) => v.item;
  static dynamic _arg$item<T>(f) => f<T>();
  static const Field<WispGridRow, dynamic> _f$item =
      Field('item', _$item, arg: _arg$item);

  @override
  final MappableFields<WispGridRow> fields = const {
    #item: _f$item,
  };

  static WispGridRow<T> _instantiate<T>(DecodingData data) {
    return WispGridRow(data.dec(_f$item));
  }

  @override
  final Function instantiate = _instantiate;

  static WispGridRow<T> fromMap<T>(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<WispGridRow<T>>(map);
  }

  static WispGridRow<T> fromJson<T>(String json) {
    return ensureInitialized().decodeJson<WispGridRow<T>>(json);
  }
}

mixin WispGridRowMappable<T> {
  String toJson() {
    return WispGridRowMapper.ensureInitialized()
        .encodeJson<WispGridRow<T>>(this as WispGridRow<T>);
  }

  Map<String, dynamic> toMap() {
    return WispGridRowMapper.ensureInitialized()
        .encodeMap<WispGridRow<T>>(this as WispGridRow<T>);
  }

  WispGridRowCopyWith<WispGridRow<T>, WispGridRow<T>, WispGridRow<T>, T>
      get copyWith => _WispGridRowCopyWithImpl(
          this as WispGridRow<T>, $identity, $identity);
  @override
  String toString() {
    return WispGridRowMapper.ensureInitialized()
        .stringifyValue(this as WispGridRow<T>);
  }

  @override
  bool operator ==(Object other) {
    return WispGridRowMapper.ensureInitialized()
        .equalsValue(this as WispGridRow<T>, other);
  }

  @override
  int get hashCode {
    return WispGridRowMapper.ensureInitialized()
        .hashValue(this as WispGridRow<T>);
  }
}

extension WispGridRowValueCopy<$R, $Out, T>
    on ObjectCopyWith<$R, WispGridRow<T>, $Out> {
  WispGridRowCopyWith<$R, WispGridRow<T>, $Out, T> get $asWispGridRow =>
      $base.as((v, t, t2) => _WispGridRowCopyWithImpl(v, t, t2));
}

abstract class WispGridRowCopyWith<$R, $In extends WispGridRow<T>, $Out, T>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({T? item});
  WispGridRowCopyWith<$R2, $In, $Out2, T> $chain<$R2, $Out2>(
      Then<$Out2, $R2> t);
}

class _WispGridRowCopyWithImpl<$R, $Out, T>
    extends ClassCopyWithBase<$R, WispGridRow<T>, $Out>
    implements WispGridRowCopyWith<$R, WispGridRow<T>, $Out, T> {
  _WispGridRowCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<WispGridRow> $mapper =
      WispGridRowMapper.ensureInitialized();
  @override
  $R call({T? item}) =>
      $apply(FieldCopyWithData({if (item != null) #item: item}));
  @override
  WispGridRow<T> $make(CopyWithData data) =>
      WispGridRow(data.get(#item, or: $value.item));

  @override
  WispGridRowCopyWith<$R2, WispGridRow<T>, $Out2, T> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _WispGridRowCopyWithImpl($value, $cast, t);
}

class WispGridModRowMapper extends ClassMapperBase<WispGridModRow> {
  WispGridModRowMapper._();

  static WispGridModRowMapper? _instance;
  static WispGridModRowMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = WispGridModRowMapper._());
      WispGridRowMapper.ensureInitialized();
      ModMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'WispGridModRow';

  static Mod _$item(WispGridModRow v) => v.item;
  static const Field<WispGridModRow, Mod> _f$item =
      Field('item', _$item, key: 'mod');

  @override
  final MappableFields<WispGridModRow> fields = const {
    #item: _f$item,
  };

  static WispGridModRow _instantiate(DecodingData data) {
    return WispGridModRow(data.dec(_f$item));
  }

  @override
  final Function instantiate = _instantiate;

  static WispGridModRow fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<WispGridModRow>(map);
  }

  static WispGridModRow fromJson(String json) {
    return ensureInitialized().decodeJson<WispGridModRow>(json);
  }
}

mixin WispGridModRowMappable {
  String toJson() {
    return WispGridModRowMapper.ensureInitialized()
        .encodeJson<WispGridModRow>(this as WispGridModRow);
  }

  Map<String, dynamic> toMap() {
    return WispGridModRowMapper.ensureInitialized()
        .encodeMap<WispGridModRow>(this as WispGridModRow);
  }

  WispGridModRowCopyWith<WispGridModRow, WispGridModRow, WispGridModRow>
      get copyWith => _WispGridModRowCopyWithImpl(
          this as WispGridModRow, $identity, $identity);
  @override
  String toString() {
    return WispGridModRowMapper.ensureInitialized()
        .stringifyValue(this as WispGridModRow);
  }

  @override
  bool operator ==(Object other) {
    return WispGridModRowMapper.ensureInitialized()
        .equalsValue(this as WispGridModRow, other);
  }

  @override
  int get hashCode {
    return WispGridModRowMapper.ensureInitialized()
        .hashValue(this as WispGridModRow);
  }
}

extension WispGridModRowValueCopy<$R, $Out>
    on ObjectCopyWith<$R, WispGridModRow, $Out> {
  WispGridModRowCopyWith<$R, WispGridModRow, $Out> get $asWispGridModRow =>
      $base.as((v, t, t2) => _WispGridModRowCopyWithImpl(v, t, t2));
}

abstract class WispGridModRowCopyWith<$R, $In extends WispGridModRow, $Out>
    implements WispGridRowCopyWith<$R, $In, $Out, Mod> {
  @override
  ModCopyWith<$R, Mod, Mod> get item;
  @override
  $R call({Mod? item});
  WispGridModRowCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
      Then<$Out2, $R2> t);
}

class _WispGridModRowCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, WispGridModRow, $Out>
    implements WispGridModRowCopyWith<$R, WispGridModRow, $Out> {
  _WispGridModRowCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<WispGridModRow> $mapper =
      WispGridModRowMapper.ensureInitialized();
  @override
  ModCopyWith<$R, Mod, Mod> get item =>
      ($value.item as Mod).copyWith.$chain((v) => call(item: v));
  @override
  $R call({Mod? item}) =>
      $apply(FieldCopyWithData({if (item != null) #item: item}));
  @override
  WispGridModRow $make(CopyWithData data) =>
      WispGridModRow(data.get(#item, or: $value.item));

  @override
  WispGridModRowCopyWith<$R2, WispGridModRow, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _WispGridModRowCopyWithImpl($value, $cast, t);
}
