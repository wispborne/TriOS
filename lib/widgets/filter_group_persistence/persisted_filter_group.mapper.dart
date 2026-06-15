// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'persisted_filter_group.dart';

class PersistedFilterGroupMapper extends ClassMapperBase<PersistedFilterGroup> {
  PersistedFilterGroupMapper._();

  static PersistedFilterGroupMapper? _instance;
  static PersistedFilterGroupMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = PersistedFilterGroupMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'PersistedFilterGroup';

  static int _$schemaVersion(PersistedFilterGroup v) => v.schemaVersion;
  static const Field<PersistedFilterGroup, int> _f$schemaVersion = Field(
    'schemaVersion',
    _$schemaVersion,
    opt: true,
    def: PersistedFilterGroup.currentSchemaVersion,
  );
  static Map<String, Object?> _$selections(PersistedFilterGroup v) =>
      v.selections;
  static const Field<PersistedFilterGroup, Map<String, Object?>> _f$selections =
      Field('selections', _$selections, opt: true, def: const {});

  @override
  final MappableFields<PersistedFilterGroup> fields = const {
    #schemaVersion: _f$schemaVersion,
    #selections: _f$selections,
  };

  static PersistedFilterGroup _instantiate(DecodingData data) {
    return PersistedFilterGroup(
      schemaVersion: data.dec(_f$schemaVersion),
      selections: data.dec(_f$selections),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static PersistedFilterGroup fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<PersistedFilterGroup>(map);
  }

  static PersistedFilterGroup fromJson(String json) {
    return ensureInitialized().decodeJson<PersistedFilterGroup>(json);
  }
}

mixin PersistedFilterGroupMappable {
  String toJson() {
    return PersistedFilterGroupMapper.ensureInitialized()
        .encodeJson<PersistedFilterGroup>(this as PersistedFilterGroup);
  }

  Map<String, dynamic> toMap() {
    return PersistedFilterGroupMapper.ensureInitialized()
        .encodeMap<PersistedFilterGroup>(this as PersistedFilterGroup);
  }

  PersistedFilterGroupCopyWith<
    PersistedFilterGroup,
    PersistedFilterGroup,
    PersistedFilterGroup
  >
  get copyWith =>
      _PersistedFilterGroupCopyWithImpl<
        PersistedFilterGroup,
        PersistedFilterGroup
      >(this as PersistedFilterGroup, $identity, $identity);
  @override
  String toString() {
    return PersistedFilterGroupMapper.ensureInitialized().stringifyValue(
      this as PersistedFilterGroup,
    );
  }

  @override
  bool operator ==(Object other) {
    return PersistedFilterGroupMapper.ensureInitialized().equalsValue(
      this as PersistedFilterGroup,
      other,
    );
  }

  @override
  int get hashCode {
    return PersistedFilterGroupMapper.ensureInitialized().hashValue(
      this as PersistedFilterGroup,
    );
  }
}

extension PersistedFilterGroupValueCopy<$R, $Out>
    on ObjectCopyWith<$R, PersistedFilterGroup, $Out> {
  PersistedFilterGroupCopyWith<$R, PersistedFilterGroup, $Out>
  get $asPersistedFilterGroup => $base.as(
    (v, t, t2) => _PersistedFilterGroupCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class PersistedFilterGroupCopyWith<
  $R,
  $In extends PersistedFilterGroup,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  MapCopyWith<$R, String, Object?, ObjectCopyWith<$R, Object?, Object?>?>
  get selections;
  $R call({int? schemaVersion, Map<String, Object?>? selections});
  PersistedFilterGroupCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _PersistedFilterGroupCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, PersistedFilterGroup, $Out>
    implements PersistedFilterGroupCopyWith<$R, PersistedFilterGroup, $Out> {
  _PersistedFilterGroupCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<PersistedFilterGroup> $mapper =
      PersistedFilterGroupMapper.ensureInitialized();
  @override
  MapCopyWith<$R, String, Object?, ObjectCopyWith<$R, Object?, Object?>?>
  get selections => MapCopyWith(
    $value.selections,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(selections: v),
  );
  @override
  $R call({int? schemaVersion, Map<String, Object?>? selections}) => $apply(
    FieldCopyWithData({
      if (schemaVersion != null) #schemaVersion: schemaVersion,
      if (selections != null) #selections: selections,
    }),
  );
  @override
  PersistedFilterGroup $make(CopyWithData data) => PersistedFilterGroup(
    schemaVersion: data.get(#schemaVersion, or: $value.schemaVersion),
    selections: data.get(#selections, or: $value.selections),
  );

  @override
  PersistedFilterGroupCopyWith<$R2, PersistedFilterGroup, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _PersistedFilterGroupCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

