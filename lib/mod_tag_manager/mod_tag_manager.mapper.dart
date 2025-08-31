// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'mod_tag_manager.dart';

class ModTagStoreMapper extends ClassMapperBase<ModTagStore> {
  ModTagStoreMapper._();

  static ModTagStoreMapper? _instance;
  static ModTagStoreMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ModTagStoreMapper._());
      ModTagMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ModTagStore';

  static List<ModTag> _$masterTags(ModTagStore v) => v.masterTags;
  static const Field<ModTagStore, List<ModTag>> _f$masterTags =
      Field('masterTags', _$masterTags);
  static Map<String, Set<String>> _$tagsByModId(ModTagStore v) => v.tagsByModId;
  static const Field<ModTagStore, Map<String, Set<String>>> _f$tagsByModId =
      Field('tagsByModId', _$tagsByModId);

  @override
  final MappableFields<ModTagStore> fields = const {
    #masterTags: _f$masterTags,
    #tagsByModId: _f$tagsByModId,
  };

  static ModTagStore _instantiate(DecodingData data) {
    return ModTagStore(
        masterTags: data.dec(_f$masterTags),
        tagsByModId: data.dec(_f$tagsByModId));
  }

  @override
  final Function instantiate = _instantiate;

  static ModTagStore fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ModTagStore>(map);
  }

  static ModTagStore fromJson(String json) {
    return ensureInitialized().decodeJson<ModTagStore>(json);
  }
}

mixin ModTagStoreMappable {
  String toJson() {
    return ModTagStoreMapper.ensureInitialized()
        .encodeJson<ModTagStore>(this as ModTagStore);
  }

  Map<String, dynamic> toMap() {
    return ModTagStoreMapper.ensureInitialized()
        .encodeMap<ModTagStore>(this as ModTagStore);
  }

  ModTagStoreCopyWith<ModTagStore, ModTagStore, ModTagStore> get copyWith =>
      _ModTagStoreCopyWithImpl<ModTagStore, ModTagStore>(
          this as ModTagStore, $identity, $identity);
  @override
  String toString() {
    return ModTagStoreMapper.ensureInitialized()
        .stringifyValue(this as ModTagStore);
  }

  @override
  bool operator ==(Object other) {
    return ModTagStoreMapper.ensureInitialized()
        .equalsValue(this as ModTagStore, other);
  }

  @override
  int get hashCode {
    return ModTagStoreMapper.ensureInitialized().hashValue(this as ModTagStore);
  }
}

extension ModTagStoreValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ModTagStore, $Out> {
  ModTagStoreCopyWith<$R, ModTagStore, $Out> get $asModTagStore =>
      $base.as((v, t, t2) => _ModTagStoreCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ModTagStoreCopyWith<$R, $In extends ModTagStore, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, ModTag, ModTagCopyWith<$R, ModTag, ModTag>> get masterTags;
  MapCopyWith<$R, String, Set<String>,
      ObjectCopyWith<$R, Set<String>, Set<String>>> get tagsByModId;
  $R call({List<ModTag>? masterTags, Map<String, Set<String>>? tagsByModId});
  ModTagStoreCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ModTagStoreCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ModTagStore, $Out>
    implements ModTagStoreCopyWith<$R, ModTagStore, $Out> {
  _ModTagStoreCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ModTagStore> $mapper =
      ModTagStoreMapper.ensureInitialized();
  @override
  ListCopyWith<$R, ModTag, ModTagCopyWith<$R, ModTag, ModTag>> get masterTags =>
      ListCopyWith($value.masterTags, (v, t) => v.copyWith.$chain(t),
          (v) => call(masterTags: v));
  @override
  MapCopyWith<$R, String, Set<String>,
          ObjectCopyWith<$R, Set<String>, Set<String>>>
      get tagsByModId => MapCopyWith(
          $value.tagsByModId,
          (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(tagsByModId: v));
  @override
  $R call({List<ModTag>? masterTags, Map<String, Set<String>>? tagsByModId}) =>
      $apply(FieldCopyWithData({
        if (masterTags != null) #masterTags: masterTags,
        if (tagsByModId != null) #tagsByModId: tagsByModId
      }));
  @override
  ModTagStore $make(CopyWithData data) => ModTagStore(
      masterTags: data.get(#masterTags, or: $value.masterTags),
      tagsByModId: data.get(#tagsByModId, or: $value.tagsByModId));

  @override
  ModTagStoreCopyWith<$R2, ModTagStore, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _ModTagStoreCopyWithImpl<$R2, $Out2>($value, $cast, t);
}
