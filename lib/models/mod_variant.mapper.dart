// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'mod_variant.dart';

class ModVariantMapper extends ClassMapperBase<ModVariant> {
  ModVariantMapper._();

  static ModVariantMapper? _instance;
  static ModVariantMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ModVariantMapper._());
      ModInfoMapper.ensureInitialized();
      VersionCheckerInfoMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ModVariant';

  static ModInfo _$modInfo(ModVariant v) => v.modInfo;
  static const Field<ModVariant, ModInfo> _f$modInfo = Field(
    'modInfo',
    _$modInfo,
  );
  static VersionCheckerInfo? _$versionCheckerInfo(ModVariant v) =>
      v.versionCheckerInfo;
  static const Field<ModVariant, VersionCheckerInfo> _f$versionCheckerInfo =
      Field('versionCheckerInfo', _$versionCheckerInfo);
  static Directory _$modFolder(ModVariant v) => v.modFolder;
  static const Field<ModVariant, Directory> _f$modFolder = Field(
    'modFolder',
    _$modFolder,
    hook: DirectoryHook(),
  );
  static bool _$hasNonBrickedModInfo(ModVariant v) => v.hasNonBrickedModInfo;
  static const Field<ModVariant, bool> _f$hasNonBrickedModInfo = Field(
    'hasNonBrickedModInfo',
    _$hasNonBrickedModInfo,
  );
  static Directory _$gameCoreFolder(ModVariant v) => v.gameCoreFolder;
  static const Field<ModVariant, Directory> _f$gameCoreFolder = Field(
    'gameCoreFolder',
    _$gameCoreFolder,
  );

  @override
  final MappableFields<ModVariant> fields = const {
    #modInfo: _f$modInfo,
    #versionCheckerInfo: _f$versionCheckerInfo,
    #modFolder: _f$modFolder,
    #hasNonBrickedModInfo: _f$hasNonBrickedModInfo,
    #gameCoreFolder: _f$gameCoreFolder,
  };

  static ModVariant _instantiate(DecodingData data) {
    return ModVariant(
      modInfo: data.dec(_f$modInfo),
      versionCheckerInfo: data.dec(_f$versionCheckerInfo),
      modFolder: data.dec(_f$modFolder),
      hasNonBrickedModInfo: data.dec(_f$hasNonBrickedModInfo),
      gameCoreFolder: data.dec(_f$gameCoreFolder),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ModVariant fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ModVariant>(map);
  }

  static ModVariant fromJson(String json) {
    return ensureInitialized().decodeJson<ModVariant>(json);
  }
}

mixin ModVariantMappable {
  String toJson() {
    return ModVariantMapper.ensureInitialized().encodeJson<ModVariant>(
      this as ModVariant,
    );
  }

  Map<String, dynamic> toMap() {
    return ModVariantMapper.ensureInitialized().encodeMap<ModVariant>(
      this as ModVariant,
    );
  }

  ModVariantCopyWith<ModVariant, ModVariant, ModVariant> get copyWith =>
      _ModVariantCopyWithImpl<ModVariant, ModVariant>(
        this as ModVariant,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return ModVariantMapper.ensureInitialized().stringifyValue(
      this as ModVariant,
    );
  }

  @override
  bool operator ==(Object other) {
    return ModVariantMapper.ensureInitialized().equalsValue(
      this as ModVariant,
      other,
    );
  }

  @override
  int get hashCode {
    return ModVariantMapper.ensureInitialized().hashValue(this as ModVariant);
  }
}

extension ModVariantValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ModVariant, $Out> {
  ModVariantCopyWith<$R, ModVariant, $Out> get $asModVariant =>
      $base.as((v, t, t2) => _ModVariantCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ModVariantCopyWith<$R, $In extends ModVariant, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ModInfoCopyWith<$R, ModInfo, ModInfo> get modInfo;
  VersionCheckerInfoCopyWith<$R, VersionCheckerInfo, VersionCheckerInfo>?
  get versionCheckerInfo;
  $R call({
    ModInfo? modInfo,
    VersionCheckerInfo? versionCheckerInfo,
    Directory? modFolder,
    bool? hasNonBrickedModInfo,
    Directory? gameCoreFolder,
  });
  ModVariantCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ModVariantCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ModVariant, $Out>
    implements ModVariantCopyWith<$R, ModVariant, $Out> {
  _ModVariantCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ModVariant> $mapper =
      ModVariantMapper.ensureInitialized();
  @override
  ModInfoCopyWith<$R, ModInfo, ModInfo> get modInfo =>
      $value.modInfo.copyWith.$chain((v) => call(modInfo: v));
  @override
  VersionCheckerInfoCopyWith<$R, VersionCheckerInfo, VersionCheckerInfo>?
  get versionCheckerInfo => $value.versionCheckerInfo?.copyWith.$chain(
    (v) => call(versionCheckerInfo: v),
  );
  @override
  $R call({
    ModInfo? modInfo,
    Object? versionCheckerInfo = $none,
    Directory? modFolder,
    bool? hasNonBrickedModInfo,
    Directory? gameCoreFolder,
  }) => $apply(
    FieldCopyWithData({
      if (modInfo != null) #modInfo: modInfo,
      if (versionCheckerInfo != $none) #versionCheckerInfo: versionCheckerInfo,
      if (modFolder != null) #modFolder: modFolder,
      if (hasNonBrickedModInfo != null)
        #hasNonBrickedModInfo: hasNonBrickedModInfo,
      if (gameCoreFolder != null) #gameCoreFolder: gameCoreFolder,
    }),
  );
  @override
  ModVariant $make(CopyWithData data) => ModVariant(
    modInfo: data.get(#modInfo, or: $value.modInfo),
    versionCheckerInfo: data.get(
      #versionCheckerInfo,
      or: $value.versionCheckerInfo,
    ),
    modFolder: data.get(#modFolder, or: $value.modFolder),
    hasNonBrickedModInfo: data.get(
      #hasNonBrickedModInfo,
      or: $value.hasNonBrickedModInfo,
    ),
    gameCoreFolder: data.get(#gameCoreFolder, or: $value.gameCoreFolder),
  );

  @override
  ModVariantCopyWith<$R2, ModVariant, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ModVariantCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

