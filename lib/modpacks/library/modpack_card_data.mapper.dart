// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'modpack_card_data.dart';

class ModpackCardDataMapper extends ClassMapperBase<ModpackCardData> {
  ModpackCardDataMapper._();

  static ModpackCardDataMapper? _instance;
  static ModpackCardDataMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ModpackCardDataMapper._());
      ModpackInstallProgressMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ModpackCardData';

  static String _$packId(ModpackCardData v) => v.packId;
  static const Field<ModpackCardData, String> _f$packId = Field(
    'packId',
    _$packId,
  );
  static String _$name(ModpackCardData v) => v.name;
  static const Field<ModpackCardData, String> _f$name = Field('name', _$name);
  static String? _$author(ModpackCardData v) => v.author;
  static const Field<ModpackCardData, String> _f$author = Field(
    'author',
    _$author,
    opt: true,
  );
  static String? _$description(ModpackCardData v) => v.description;
  static const Field<ModpackCardData, String> _f$description = Field(
    'description',
    _$description,
    opt: true,
  );
  static String? _$gameVersion(ModpackCardData v) => v.gameVersion;
  static const Field<ModpackCardData, String> _f$gameVersion = Field(
    'gameVersion',
    _$gameVersion,
    opt: true,
  );
  static String? _$homepageUrl(ModpackCardData v) => v.homepageUrl;
  static const Field<ModpackCardData, String> _f$homepageUrl = Field(
    'homepageUrl',
    _$homepageUrl,
    opt: true,
  );
  static String? _$updateUrl(ModpackCardData v) => v.updateUrl;
  static const Field<ModpackCardData, String> _f$updateUrl = Field(
    'updateUrl',
    _$updateUrl,
    opt: true,
  );
  static int? _$packVersion(ModpackCardData v) => v.packVersion;
  static const Field<ModpackCardData, int> _f$packVersion = Field(
    'packVersion',
    _$packVersion,
    opt: true,
  );
  static int _$installedCount(ModpackCardData v) => v.installedCount;
  static const Field<ModpackCardData, int> _f$installedCount = Field(
    'installedCount',
    _$installedCount,
    opt: true,
    def: 0,
  );
  static int _$totalCount(ModpackCardData v) => v.totalCount;
  static const Field<ModpackCardData, int> _f$totalCount = Field(
    'totalCount',
    _$totalCount,
    opt: true,
    def: 0,
  );
  static int _$missingCount(ModpackCardData v) => v.missingCount;
  static const Field<ModpackCardData, int> _f$missingCount = Field(
    'missingCount',
    _$missingCount,
    opt: true,
    def: 0,
  );
  static bool _$isDraftOnly(ModpackCardData v) => v.isDraftOnly;
  static const Field<ModpackCardData, bool> _f$isDraftOnly = Field(
    'isDraftOnly',
    _$isDraftOnly,
    opt: true,
    def: false,
  );
  static bool _$hasUnsavedChanges(ModpackCardData v) => v.hasUnsavedChanges;
  static const Field<ModpackCardData, bool> _f$hasUnsavedChanges = Field(
    'hasUnsavedChanges',
    _$hasUnsavedChanges,
    opt: true,
    def: false,
  );
  static int? _$onlineVersionAvailable(ModpackCardData v) =>
      v.onlineVersionAvailable;
  static const Field<ModpackCardData, int> _f$onlineVersionAvailable = Field(
    'onlineVersionAvailable',
    _$onlineVersionAvailable,
    opt: true,
  );
  static bool _$hasFailures(ModpackCardData v) => v.hasFailures;
  static const Field<ModpackCardData, bool> _f$hasFailures = Field(
    'hasFailures',
    _$hasFailures,
    opt: true,
    def: false,
  );
  static bool _$needsSources(ModpackCardData v) => v.needsSources;
  static const Field<ModpackCardData, bool> _f$needsSources = Field(
    'needsSources',
    _$needsSources,
    opt: true,
    def: false,
  );
  static ModpackInstallProgress? _$installProgress(ModpackCardData v) =>
      v.installProgress;
  static const Field<ModpackCardData, ModpackInstallProgress>
  _f$installProgress = Field('installProgress', _$installProgress, opt: true);

  @override
  final MappableFields<ModpackCardData> fields = const {
    #packId: _f$packId,
    #name: _f$name,
    #author: _f$author,
    #description: _f$description,
    #gameVersion: _f$gameVersion,
    #homepageUrl: _f$homepageUrl,
    #updateUrl: _f$updateUrl,
    #packVersion: _f$packVersion,
    #installedCount: _f$installedCount,
    #totalCount: _f$totalCount,
    #missingCount: _f$missingCount,
    #isDraftOnly: _f$isDraftOnly,
    #hasUnsavedChanges: _f$hasUnsavedChanges,
    #onlineVersionAvailable: _f$onlineVersionAvailable,
    #hasFailures: _f$hasFailures,
    #needsSources: _f$needsSources,
    #installProgress: _f$installProgress,
  };

  static ModpackCardData _instantiate(DecodingData data) {
    return ModpackCardData(
      packId: data.dec(_f$packId),
      name: data.dec(_f$name),
      author: data.dec(_f$author),
      description: data.dec(_f$description),
      gameVersion: data.dec(_f$gameVersion),
      homepageUrl: data.dec(_f$homepageUrl),
      updateUrl: data.dec(_f$updateUrl),
      packVersion: data.dec(_f$packVersion),
      installedCount: data.dec(_f$installedCount),
      totalCount: data.dec(_f$totalCount),
      missingCount: data.dec(_f$missingCount),
      isDraftOnly: data.dec(_f$isDraftOnly),
      hasUnsavedChanges: data.dec(_f$hasUnsavedChanges),
      onlineVersionAvailable: data.dec(_f$onlineVersionAvailable),
      hasFailures: data.dec(_f$hasFailures),
      needsSources: data.dec(_f$needsSources),
      installProgress: data.dec(_f$installProgress),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ModpackCardData fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ModpackCardData>(map);
  }

  static ModpackCardData fromJson(String json) {
    return ensureInitialized().decodeJson<ModpackCardData>(json);
  }
}

mixin ModpackCardDataMappable {
  String toJson() {
    return ModpackCardDataMapper.ensureInitialized()
        .encodeJson<ModpackCardData>(this as ModpackCardData);
  }

  Map<String, dynamic> toMap() {
    return ModpackCardDataMapper.ensureInitialized().encodeMap<ModpackCardData>(
      this as ModpackCardData,
    );
  }

  ModpackCardDataCopyWith<ModpackCardData, ModpackCardData, ModpackCardData>
  get copyWith =>
      _ModpackCardDataCopyWithImpl<ModpackCardData, ModpackCardData>(
        this as ModpackCardData,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return ModpackCardDataMapper.ensureInitialized().stringifyValue(
      this as ModpackCardData,
    );
  }

  @override
  bool operator ==(Object other) {
    return ModpackCardDataMapper.ensureInitialized().equalsValue(
      this as ModpackCardData,
      other,
    );
  }

  @override
  int get hashCode {
    return ModpackCardDataMapper.ensureInitialized().hashValue(
      this as ModpackCardData,
    );
  }
}

extension ModpackCardDataValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ModpackCardData, $Out> {
  ModpackCardDataCopyWith<$R, ModpackCardData, $Out> get $asModpackCardData =>
      $base.as((v, t, t2) => _ModpackCardDataCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ModpackCardDataCopyWith<$R, $In extends ModpackCardData, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ModpackInstallProgressCopyWith<
    $R,
    ModpackInstallProgress,
    ModpackInstallProgress
  >?
  get installProgress;
  $R call({
    String? packId,
    String? name,
    String? author,
    String? description,
    String? gameVersion,
    String? homepageUrl,
    String? updateUrl,
    int? packVersion,
    int? installedCount,
    int? totalCount,
    int? missingCount,
    bool? isDraftOnly,
    bool? hasUnsavedChanges,
    int? onlineVersionAvailable,
    bool? hasFailures,
    bool? needsSources,
    ModpackInstallProgress? installProgress,
  });
  ModpackCardDataCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _ModpackCardDataCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ModpackCardData, $Out>
    implements ModpackCardDataCopyWith<$R, ModpackCardData, $Out> {
  _ModpackCardDataCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ModpackCardData> $mapper =
      ModpackCardDataMapper.ensureInitialized();
  @override
  ModpackInstallProgressCopyWith<
    $R,
    ModpackInstallProgress,
    ModpackInstallProgress
  >?
  get installProgress =>
      $value.installProgress?.copyWith.$chain((v) => call(installProgress: v));
  @override
  $R call({
    String? packId,
    String? name,
    Object? author = $none,
    Object? description = $none,
    Object? gameVersion = $none,
    Object? homepageUrl = $none,
    Object? updateUrl = $none,
    Object? packVersion = $none,
    int? installedCount,
    int? totalCount,
    int? missingCount,
    bool? isDraftOnly,
    bool? hasUnsavedChanges,
    Object? onlineVersionAvailable = $none,
    bool? hasFailures,
    bool? needsSources,
    Object? installProgress = $none,
  }) => $apply(
    FieldCopyWithData({
      if (packId != null) #packId: packId,
      if (name != null) #name: name,
      if (author != $none) #author: author,
      if (description != $none) #description: description,
      if (gameVersion != $none) #gameVersion: gameVersion,
      if (homepageUrl != $none) #homepageUrl: homepageUrl,
      if (updateUrl != $none) #updateUrl: updateUrl,
      if (packVersion != $none) #packVersion: packVersion,
      if (installedCount != null) #installedCount: installedCount,
      if (totalCount != null) #totalCount: totalCount,
      if (missingCount != null) #missingCount: missingCount,
      if (isDraftOnly != null) #isDraftOnly: isDraftOnly,
      if (hasUnsavedChanges != null) #hasUnsavedChanges: hasUnsavedChanges,
      if (onlineVersionAvailable != $none)
        #onlineVersionAvailable: onlineVersionAvailable,
      if (hasFailures != null) #hasFailures: hasFailures,
      if (needsSources != null) #needsSources: needsSources,
      if (installProgress != $none) #installProgress: installProgress,
    }),
  );
  @override
  ModpackCardData $make(CopyWithData data) => ModpackCardData(
    packId: data.get(#packId, or: $value.packId),
    name: data.get(#name, or: $value.name),
    author: data.get(#author, or: $value.author),
    description: data.get(#description, or: $value.description),
    gameVersion: data.get(#gameVersion, or: $value.gameVersion),
    homepageUrl: data.get(#homepageUrl, or: $value.homepageUrl),
    updateUrl: data.get(#updateUrl, or: $value.updateUrl),
    packVersion: data.get(#packVersion, or: $value.packVersion),
    installedCount: data.get(#installedCount, or: $value.installedCount),
    totalCount: data.get(#totalCount, or: $value.totalCount),
    missingCount: data.get(#missingCount, or: $value.missingCount),
    isDraftOnly: data.get(#isDraftOnly, or: $value.isDraftOnly),
    hasUnsavedChanges: data.get(
      #hasUnsavedChanges,
      or: $value.hasUnsavedChanges,
    ),
    onlineVersionAvailable: data.get(
      #onlineVersionAvailable,
      or: $value.onlineVersionAvailable,
    ),
    hasFailures: data.get(#hasFailures, or: $value.hasFailures),
    needsSources: data.get(#needsSources, or: $value.needsSources),
    installProgress: data.get(#installProgress, or: $value.installProgress),
  );

  @override
  ModpackCardDataCopyWith<$R2, ModpackCardData, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ModpackCardDataCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

