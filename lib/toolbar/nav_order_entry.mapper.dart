// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'nav_order_entry.dart';

class NavOrderEntryMapper extends ClassMapperBase<NavOrderEntry> {
  NavOrderEntryMapper._();

  static NavOrderEntryMapper? _instance;
  static NavOrderEntryMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = NavOrderEntryMapper._());
      NavToolEntryMapper.ensureInitialized();
      NavDividerEntryMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'NavOrderEntry';

  @override
  final MappableFields<NavOrderEntry> fields = const {};

  static NavOrderEntry _instantiate(DecodingData data) {
    throw MapperException.missingSubclass(
      'NavOrderEntry',
      'type',
      '${data.value['type']}',
    );
  }

  @override
  final Function instantiate = _instantiate;

  static NavOrderEntry fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<NavOrderEntry>(map);
  }

  static NavOrderEntry fromJson(String json) {
    return ensureInitialized().decodeJson<NavOrderEntry>(json);
  }
}

mixin NavOrderEntryMappable {
  String toJson();
  Map<String, dynamic> toMap();
  NavOrderEntryCopyWith<NavOrderEntry, NavOrderEntry, NavOrderEntry>
  get copyWith;
}

abstract class NavOrderEntryCopyWith<$R, $In extends NavOrderEntry, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call();
  NavOrderEntryCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class NavToolEntryMapper extends SubClassMapperBase<NavToolEntry> {
  NavToolEntryMapper._();

  static NavToolEntryMapper? _instance;
  static NavToolEntryMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = NavToolEntryMapper._());
      NavOrderEntryMapper.ensureInitialized().addSubMapper(_instance!);
      TriOSToolsMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'NavToolEntry';

  static TriOSTools _$tool(NavToolEntry v) => v.tool;
  static const Field<NavToolEntry, TriOSTools> _f$tool = Field('tool', _$tool);

  @override
  final MappableFields<NavToolEntry> fields = const {#tool: _f$tool};

  @override
  final String discriminatorKey = 'type';
  @override
  final dynamic discriminatorValue = 'tool';
  @override
  late final ClassMapperBase superMapper =
      NavOrderEntryMapper.ensureInitialized();

  static NavToolEntry _instantiate(DecodingData data) {
    return NavToolEntry(data.dec(_f$tool));
  }

  @override
  final Function instantiate = _instantiate;

  static NavToolEntry fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<NavToolEntry>(map);
  }

  static NavToolEntry fromJson(String json) {
    return ensureInitialized().decodeJson<NavToolEntry>(json);
  }
}

mixin NavToolEntryMappable {
  String toJson() {
    return NavToolEntryMapper.ensureInitialized().encodeJson<NavToolEntry>(
      this as NavToolEntry,
    );
  }

  Map<String, dynamic> toMap() {
    return NavToolEntryMapper.ensureInitialized().encodeMap<NavToolEntry>(
      this as NavToolEntry,
    );
  }

  NavToolEntryCopyWith<NavToolEntry, NavToolEntry, NavToolEntry> get copyWith =>
      _NavToolEntryCopyWithImpl<NavToolEntry, NavToolEntry>(
        this as NavToolEntry,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return NavToolEntryMapper.ensureInitialized().stringifyValue(
      this as NavToolEntry,
    );
  }

  @override
  bool operator ==(Object other) {
    return NavToolEntryMapper.ensureInitialized().equalsValue(
      this as NavToolEntry,
      other,
    );
  }

  @override
  int get hashCode {
    return NavToolEntryMapper.ensureInitialized().hashValue(
      this as NavToolEntry,
    );
  }
}

extension NavToolEntryValueCopy<$R, $Out>
    on ObjectCopyWith<$R, NavToolEntry, $Out> {
  NavToolEntryCopyWith<$R, NavToolEntry, $Out> get $asNavToolEntry =>
      $base.as((v, t, t2) => _NavToolEntryCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class NavToolEntryCopyWith<$R, $In extends NavToolEntry, $Out>
    implements NavOrderEntryCopyWith<$R, $In, $Out> {
  @override
  $R call({TriOSTools? tool});
  NavToolEntryCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _NavToolEntryCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, NavToolEntry, $Out>
    implements NavToolEntryCopyWith<$R, NavToolEntry, $Out> {
  _NavToolEntryCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<NavToolEntry> $mapper =
      NavToolEntryMapper.ensureInitialized();
  @override
  $R call({TriOSTools? tool}) =>
      $apply(FieldCopyWithData({if (tool != null) #tool: tool}));
  @override
  NavToolEntry $make(CopyWithData data) =>
      NavToolEntry(data.get(#tool, or: $value.tool));

  @override
  NavToolEntryCopyWith<$R2, NavToolEntry, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _NavToolEntryCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class NavDividerEntryMapper extends SubClassMapperBase<NavDividerEntry> {
  NavDividerEntryMapper._();

  static NavDividerEntryMapper? _instance;
  static NavDividerEntryMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = NavDividerEntryMapper._());
      NavOrderEntryMapper.ensureInitialized().addSubMapper(_instance!);
    }
    return _instance!;
  }

  @override
  final String id = 'NavDividerEntry';

  @override
  final MappableFields<NavDividerEntry> fields = const {};

  @override
  final String discriminatorKey = 'type';
  @override
  final dynamic discriminatorValue = 'divider';
  @override
  late final ClassMapperBase superMapper =
      NavOrderEntryMapper.ensureInitialized();

  static NavDividerEntry _instantiate(DecodingData data) {
    return NavDividerEntry();
  }

  @override
  final Function instantiate = _instantiate;

  static NavDividerEntry fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<NavDividerEntry>(map);
  }

  static NavDividerEntry fromJson(String json) {
    return ensureInitialized().decodeJson<NavDividerEntry>(json);
  }
}

mixin NavDividerEntryMappable {
  String toJson() {
    return NavDividerEntryMapper.ensureInitialized()
        .encodeJson<NavDividerEntry>(this as NavDividerEntry);
  }

  Map<String, dynamic> toMap() {
    return NavDividerEntryMapper.ensureInitialized().encodeMap<NavDividerEntry>(
      this as NavDividerEntry,
    );
  }

  NavDividerEntryCopyWith<NavDividerEntry, NavDividerEntry, NavDividerEntry>
  get copyWith =>
      _NavDividerEntryCopyWithImpl<NavDividerEntry, NavDividerEntry>(
        this as NavDividerEntry,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return NavDividerEntryMapper.ensureInitialized().stringifyValue(
      this as NavDividerEntry,
    );
  }

  @override
  bool operator ==(Object other) {
    return NavDividerEntryMapper.ensureInitialized().equalsValue(
      this as NavDividerEntry,
      other,
    );
  }

  @override
  int get hashCode {
    return NavDividerEntryMapper.ensureInitialized().hashValue(
      this as NavDividerEntry,
    );
  }
}

extension NavDividerEntryValueCopy<$R, $Out>
    on ObjectCopyWith<$R, NavDividerEntry, $Out> {
  NavDividerEntryCopyWith<$R, NavDividerEntry, $Out> get $asNavDividerEntry =>
      $base.as((v, t, t2) => _NavDividerEntryCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class NavDividerEntryCopyWith<$R, $In extends NavDividerEntry, $Out>
    implements NavOrderEntryCopyWith<$R, $In, $Out> {
  @override
  $R call();
  NavDividerEntryCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _NavDividerEntryCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, NavDividerEntry, $Out>
    implements NavDividerEntryCopyWith<$R, NavDividerEntry, $Out> {
  _NavDividerEntryCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<NavDividerEntry> $mapper =
      NavDividerEntryMapper.ensureInitialized();
  @override
  $R call() => $apply(FieldCopyWithData({}));
  @override
  NavDividerEntry $make(CopyWithData data) => NavDividerEntry();

  @override
  NavDividerEntryCopyWith<$R2, NavDividerEntry, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _NavDividerEntryCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

