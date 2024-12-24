// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'mod_metadata.dart';

class ModsMetadataMapper extends ClassMapperBase<ModsMetadata> {
  ModsMetadataMapper._();

  static ModsMetadataMapper? _instance;
  static ModsMetadataMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ModsMetadataMapper._());
      ModMetadataMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ModsMetadata';

  static Map<String, ModMetadata> _$baseMetadata(ModsMetadata v) =>
      v.baseMetadata;
  static const Field<ModsMetadata, Map<String, ModMetadata>> _f$baseMetadata =
      Field('baseMetadata', _$baseMetadata);
  static Map<String, ModMetadata> _$userMetadata(ModsMetadata v) =>
      v.userMetadata;
  static const Field<ModsMetadata, Map<String, ModMetadata>> _f$userMetadata =
      Field('userMetadata', _$userMetadata);

  @override
  final MappableFields<ModsMetadata> fields = const {
    #baseMetadata: _f$baseMetadata,
    #userMetadata: _f$userMetadata,
  };

  static ModsMetadata _instantiate(DecodingData data) {
    return ModsMetadata(
        baseMetadata: data.dec(_f$baseMetadata),
        userMetadata: data.dec(_f$userMetadata));
  }

  @override
  final Function instantiate = _instantiate;

  static ModsMetadata fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ModsMetadata>(map);
  }

  static ModsMetadata fromJson(String json) {
    return ensureInitialized().decodeJson<ModsMetadata>(json);
  }
}

mixin ModsMetadataMappable {
  String toJson() {
    return ModsMetadataMapper.ensureInitialized()
        .encodeJson<ModsMetadata>(this as ModsMetadata);
  }

  Map<String, dynamic> toMap() {
    return ModsMetadataMapper.ensureInitialized()
        .encodeMap<ModsMetadata>(this as ModsMetadata);
  }

  ModsMetadataCopyWith<ModsMetadata, ModsMetadata, ModsMetadata> get copyWith =>
      _ModsMetadataCopyWithImpl(this as ModsMetadata, $identity, $identity);
  @override
  String toString() {
    return ModsMetadataMapper.ensureInitialized()
        .stringifyValue(this as ModsMetadata);
  }

  @override
  bool operator ==(Object other) {
    return ModsMetadataMapper.ensureInitialized()
        .equalsValue(this as ModsMetadata, other);
  }

  @override
  int get hashCode {
    return ModsMetadataMapper.ensureInitialized()
        .hashValue(this as ModsMetadata);
  }
}

extension ModsMetadataValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ModsMetadata, $Out> {
  ModsMetadataCopyWith<$R, ModsMetadata, $Out> get $asModsMetadata =>
      $base.as((v, t, t2) => _ModsMetadataCopyWithImpl(v, t, t2));
}

abstract class ModsMetadataCopyWith<$R, $In extends ModsMetadata, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  MapCopyWith<$R, String, ModMetadata,
      ModMetadataCopyWith<$R, ModMetadata, ModMetadata>> get baseMetadata;
  MapCopyWith<$R, String, ModMetadata,
      ModMetadataCopyWith<$R, ModMetadata, ModMetadata>> get userMetadata;
  $R call(
      {Map<String, ModMetadata>? baseMetadata,
      Map<String, ModMetadata>? userMetadata});
  ModsMetadataCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ModsMetadataCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ModsMetadata, $Out>
    implements ModsMetadataCopyWith<$R, ModsMetadata, $Out> {
  _ModsMetadataCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ModsMetadata> $mapper =
      ModsMetadataMapper.ensureInitialized();
  @override
  MapCopyWith<$R, String, ModMetadata,
          ModMetadataCopyWith<$R, ModMetadata, ModMetadata>>
      get baseMetadata => MapCopyWith($value.baseMetadata,
          (v, t) => v.copyWith.$chain(t), (v) => call(baseMetadata: v));
  @override
  MapCopyWith<$R, String, ModMetadata,
          ModMetadataCopyWith<$R, ModMetadata, ModMetadata>>
      get userMetadata => MapCopyWith($value.userMetadata,
          (v, t) => v.copyWith.$chain(t), (v) => call(userMetadata: v));
  @override
  $R call(
          {Map<String, ModMetadata>? baseMetadata,
          Map<String, ModMetadata>? userMetadata}) =>
      $apply(FieldCopyWithData({
        if (baseMetadata != null) #baseMetadata: baseMetadata,
        if (userMetadata != null) #userMetadata: userMetadata
      }));
  @override
  ModsMetadata $make(CopyWithData data) => ModsMetadata(
      baseMetadata: data.get(#baseMetadata, or: $value.baseMetadata),
      userMetadata: data.get(#userMetadata, or: $value.userMetadata));

  @override
  ModsMetadataCopyWith<$R2, ModsMetadata, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _ModsMetadataCopyWithImpl($value, $cast, t);
}

class ModMetadataMapper extends ClassMapperBase<ModMetadata> {
  ModMetadataMapper._();

  static ModMetadataMapper? _instance;
  static ModMetadataMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ModMetadataMapper._());
      ModVariantMetadataMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ModMetadata';

  static Map<String, ModVariantMetadata> _$variantsMetadata(ModMetadata v) =>
      v.variantsMetadata;
  static const Field<ModMetadata, Map<String, ModVariantMetadata>>
      _f$variantsMetadata =
      Field('variantsMetadata', _$variantsMetadata, opt: true, def: const {});
  static int _$firstSeen(ModMetadata v) => v.firstSeen;
  static const Field<ModMetadata, int> _f$firstSeen =
      Field('firstSeen', _$firstSeen);
  static bool _$isFavorited(ModMetadata v) => v.isFavorited;
  static const Field<ModMetadata, bool> _f$isFavorited =
      Field('isFavorited', _$isFavorited, opt: true, def: false);
  static int? _$lastEnabled(ModMetadata v) => v.lastEnabled;
  static const Field<ModMetadata, int> _f$lastEnabled =
      Field('lastEnabled', _$lastEnabled, opt: true);

  @override
  final MappableFields<ModMetadata> fields = const {
    #variantsMetadata: _f$variantsMetadata,
    #firstSeen: _f$firstSeen,
    #isFavorited: _f$isFavorited,
    #lastEnabled: _f$lastEnabled,
  };

  static ModMetadata _instantiate(DecodingData data) {
    return ModMetadata(
        variantsMetadata: data.dec(_f$variantsMetadata),
        firstSeen: data.dec(_f$firstSeen),
        isFavorited: data.dec(_f$isFavorited),
        lastEnabled: data.dec(_f$lastEnabled));
  }

  @override
  final Function instantiate = _instantiate;

  static ModMetadata fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ModMetadata>(map);
  }

  static ModMetadata fromJson(String json) {
    return ensureInitialized().decodeJson<ModMetadata>(json);
  }
}

mixin ModMetadataMappable {
  String toJson() {
    return ModMetadataMapper.ensureInitialized()
        .encodeJson<ModMetadata>(this as ModMetadata);
  }

  Map<String, dynamic> toMap() {
    return ModMetadataMapper.ensureInitialized()
        .encodeMap<ModMetadata>(this as ModMetadata);
  }

  ModMetadataCopyWith<ModMetadata, ModMetadata, ModMetadata> get copyWith =>
      _ModMetadataCopyWithImpl(this as ModMetadata, $identity, $identity);
  @override
  String toString() {
    return ModMetadataMapper.ensureInitialized()
        .stringifyValue(this as ModMetadata);
  }

  @override
  bool operator ==(Object other) {
    return ModMetadataMapper.ensureInitialized()
        .equalsValue(this as ModMetadata, other);
  }

  @override
  int get hashCode {
    return ModMetadataMapper.ensureInitialized().hashValue(this as ModMetadata);
  }
}

extension ModMetadataValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ModMetadata, $Out> {
  ModMetadataCopyWith<$R, ModMetadata, $Out> get $asModMetadata =>
      $base.as((v, t, t2) => _ModMetadataCopyWithImpl(v, t, t2));
}

abstract class ModMetadataCopyWith<$R, $In extends ModMetadata, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  MapCopyWith<
      $R,
      String,
      ModVariantMetadata,
      ModVariantMetadataCopyWith<$R, ModVariantMetadata,
          ModVariantMetadata>> get variantsMetadata;
  $R call(
      {Map<String, ModVariantMetadata>? variantsMetadata,
      int? firstSeen,
      bool? isFavorited,
      int? lastEnabled});
  ModMetadataCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ModMetadataCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ModMetadata, $Out>
    implements ModMetadataCopyWith<$R, ModMetadata, $Out> {
  _ModMetadataCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ModMetadata> $mapper =
      ModMetadataMapper.ensureInitialized();
  @override
  MapCopyWith<
      $R,
      String,
      ModVariantMetadata,
      ModVariantMetadataCopyWith<$R, ModVariantMetadata,
          ModVariantMetadata>> get variantsMetadata => MapCopyWith(
      $value.variantsMetadata,
      (v, t) => v.copyWith.$chain(t),
      (v) => call(variantsMetadata: v));
  @override
  $R call(
          {Map<String, ModVariantMetadata>? variantsMetadata,
          int? firstSeen,
          bool? isFavorited,
          Object? lastEnabled = $none}) =>
      $apply(FieldCopyWithData({
        if (variantsMetadata != null) #variantsMetadata: variantsMetadata,
        if (firstSeen != null) #firstSeen: firstSeen,
        if (isFavorited != null) #isFavorited: isFavorited,
        if (lastEnabled != $none) #lastEnabled: lastEnabled
      }));
  @override
  ModMetadata $make(CopyWithData data) => ModMetadata(
      variantsMetadata:
          data.get(#variantsMetadata, or: $value.variantsMetadata),
      firstSeen: data.get(#firstSeen, or: $value.firstSeen),
      isFavorited: data.get(#isFavorited, or: $value.isFavorited),
      lastEnabled: data.get(#lastEnabled, or: $value.lastEnabled));

  @override
  ModMetadataCopyWith<$R2, ModMetadata, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _ModMetadataCopyWithImpl($value, $cast, t);
}

class ModVariantMetadataMapper extends ClassMapperBase<ModVariantMetadata> {
  ModVariantMetadataMapper._();

  static ModVariantMetadataMapper? _instance;
  static ModVariantMetadataMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ModVariantMetadataMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'ModVariantMetadata';

  static int _$firstSeen(ModVariantMetadata v) => v.firstSeen;
  static const Field<ModVariantMetadata, int> _f$firstSeen =
      Field('firstSeen', _$firstSeen);

  @override
  final MappableFields<ModVariantMetadata> fields = const {
    #firstSeen: _f$firstSeen,
  };

  static ModVariantMetadata _instantiate(DecodingData data) {
    return ModVariantMetadata(firstSeen: data.dec(_f$firstSeen));
  }

  @override
  final Function instantiate = _instantiate;

  static ModVariantMetadata fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ModVariantMetadata>(map);
  }

  static ModVariantMetadata fromJson(String json) {
    return ensureInitialized().decodeJson<ModVariantMetadata>(json);
  }
}

mixin ModVariantMetadataMappable {
  String toJson() {
    return ModVariantMetadataMapper.ensureInitialized()
        .encodeJson<ModVariantMetadata>(this as ModVariantMetadata);
  }

  Map<String, dynamic> toMap() {
    return ModVariantMetadataMapper.ensureInitialized()
        .encodeMap<ModVariantMetadata>(this as ModVariantMetadata);
  }

  ModVariantMetadataCopyWith<ModVariantMetadata, ModVariantMetadata,
          ModVariantMetadata>
      get copyWith => _ModVariantMetadataCopyWithImpl(
          this as ModVariantMetadata, $identity, $identity);
  @override
  String toString() {
    return ModVariantMetadataMapper.ensureInitialized()
        .stringifyValue(this as ModVariantMetadata);
  }

  @override
  bool operator ==(Object other) {
    return ModVariantMetadataMapper.ensureInitialized()
        .equalsValue(this as ModVariantMetadata, other);
  }

  @override
  int get hashCode {
    return ModVariantMetadataMapper.ensureInitialized()
        .hashValue(this as ModVariantMetadata);
  }
}

extension ModVariantMetadataValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ModVariantMetadata, $Out> {
  ModVariantMetadataCopyWith<$R, ModVariantMetadata, $Out>
      get $asModVariantMetadata =>
          $base.as((v, t, t2) => _ModVariantMetadataCopyWithImpl(v, t, t2));
}

abstract class ModVariantMetadataCopyWith<$R, $In extends ModVariantMetadata,
    $Out> implements ClassCopyWith<$R, $In, $Out> {
  $R call({int? firstSeen});
  ModVariantMetadataCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
      Then<$Out2, $R2> t);
}

class _ModVariantMetadataCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ModVariantMetadata, $Out>
    implements ModVariantMetadataCopyWith<$R, ModVariantMetadata, $Out> {
  _ModVariantMetadataCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ModVariantMetadata> $mapper =
      ModVariantMetadataMapper.ensureInitialized();
  @override
  $R call({int? firstSeen}) =>
      $apply(FieldCopyWithData({if (firstSeen != null) #firstSeen: firstSeen}));
  @override
  ModVariantMetadata $make(CopyWithData data) =>
      ModVariantMetadata(firstSeen: data.get(#firstSeen, or: $value.firstSeen));

  @override
  ModVariantMetadataCopyWith<$R2, ModVariantMetadata, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _ModVariantMetadataCopyWithImpl($value, $cast, t);
}
