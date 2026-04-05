// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'mod_record_source.dart';

class ModRecordSourceMapper extends ClassMapperBase<ModRecordSource> {
  ModRecordSourceMapper._();

  static ModRecordSourceMapper? _instance;
  static ModRecordSourceMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ModRecordSourceMapper._());
      InstalledSourceMapper.ensureInitialized();
      VersionCheckerSourceMapper.ensureInitialized();
      CatalogSourceMapper.ensureInitialized();
      DownloadHistorySourceMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ModRecordSource';

  static DateTime? _$lastSeen(ModRecordSource v) => v.lastSeen;
  static const Field<ModRecordSource, DateTime> _f$lastSeen = Field(
    'lastSeen',
    _$lastSeen,
    opt: true,
  );

  @override
  final MappableFields<ModRecordSource> fields = const {#lastSeen: _f$lastSeen};

  static ModRecordSource _instantiate(DecodingData data) {
    throw MapperException.missingSubclass(
      'ModRecordSource',
      'sourceType',
      '${data.value['sourceType']}',
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ModRecordSource fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ModRecordSource>(map);
  }

  static ModRecordSource fromJson(String json) {
    return ensureInitialized().decodeJson<ModRecordSource>(json);
  }
}

mixin ModRecordSourceMappable {
  String toJson();
  Map<String, dynamic> toMap();
  ModRecordSourceCopyWith<ModRecordSource, ModRecordSource, ModRecordSource>
  get copyWith;
}

abstract class ModRecordSourceCopyWith<$R, $In extends ModRecordSource, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({DateTime? lastSeen});
  ModRecordSourceCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class InstalledSourceMapper extends SubClassMapperBase<InstalledSource> {
  InstalledSourceMapper._();

  static InstalledSourceMapper? _instance;
  static InstalledSourceMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = InstalledSourceMapper._());
      ModRecordSourceMapper.ensureInitialized().addSubMapper(_instance!);
    }
    return _instance!;
  }

  @override
  final String id = 'InstalledSource';

  static String? _$installPath(InstalledSource v) => v.installPath;
  static const Field<InstalledSource, String> _f$installPath = Field(
    'installPath',
    _$installPath,
    opt: true,
  );
  static String? _$version(InstalledSource v) => v.version;
  static const Field<InstalledSource, String> _f$version = Field(
    'version',
    _$version,
    opt: true,
  );
  static DateTime? _$lastSeen(InstalledSource v) => v.lastSeen;
  static const Field<InstalledSource, DateTime> _f$lastSeen = Field(
    'lastSeen',
    _$lastSeen,
    opt: true,
  );

  @override
  final MappableFields<InstalledSource> fields = const {
    #installPath: _f$installPath,
    #version: _f$version,
    #lastSeen: _f$lastSeen,
  };

  @override
  final String discriminatorKey = 'sourceType';
  @override
  final dynamic discriminatorValue = 'installed';
  @override
  late final ClassMapperBase superMapper =
      ModRecordSourceMapper.ensureInitialized();

  static InstalledSource _instantiate(DecodingData data) {
    return InstalledSource(
      installPath: data.dec(_f$installPath),
      version: data.dec(_f$version),
      lastSeen: data.dec(_f$lastSeen),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static InstalledSource fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<InstalledSource>(map);
  }

  static InstalledSource fromJson(String json) {
    return ensureInitialized().decodeJson<InstalledSource>(json);
  }
}

mixin InstalledSourceMappable {
  String toJson() {
    return InstalledSourceMapper.ensureInitialized()
        .encodeJson<InstalledSource>(this as InstalledSource);
  }

  Map<String, dynamic> toMap() {
    return InstalledSourceMapper.ensureInitialized().encodeMap<InstalledSource>(
      this as InstalledSource,
    );
  }

  InstalledSourceCopyWith<InstalledSource, InstalledSource, InstalledSource>
  get copyWith =>
      _InstalledSourceCopyWithImpl<InstalledSource, InstalledSource>(
        this as InstalledSource,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return InstalledSourceMapper.ensureInitialized().stringifyValue(
      this as InstalledSource,
    );
  }

  @override
  bool operator ==(Object other) {
    return InstalledSourceMapper.ensureInitialized().equalsValue(
      this as InstalledSource,
      other,
    );
  }

  @override
  int get hashCode {
    return InstalledSourceMapper.ensureInitialized().hashValue(
      this as InstalledSource,
    );
  }
}

extension InstalledSourceValueCopy<$R, $Out>
    on ObjectCopyWith<$R, InstalledSource, $Out> {
  InstalledSourceCopyWith<$R, InstalledSource, $Out> get $asInstalledSource =>
      $base.as((v, t, t2) => _InstalledSourceCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class InstalledSourceCopyWith<$R, $In extends InstalledSource, $Out>
    implements ModRecordSourceCopyWith<$R, $In, $Out> {
  @override
  $R call({String? installPath, String? version, DateTime? lastSeen});
  InstalledSourceCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _InstalledSourceCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, InstalledSource, $Out>
    implements InstalledSourceCopyWith<$R, InstalledSource, $Out> {
  _InstalledSourceCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<InstalledSource> $mapper =
      InstalledSourceMapper.ensureInitialized();
  @override
  $R call({
    Object? installPath = $none,
    Object? version = $none,
    Object? lastSeen = $none,
  }) => $apply(
    FieldCopyWithData({
      if (installPath != $none) #installPath: installPath,
      if (version != $none) #version: version,
      if (lastSeen != $none) #lastSeen: lastSeen,
    }),
  );
  @override
  InstalledSource $make(CopyWithData data) => InstalledSource(
    installPath: data.get(#installPath, or: $value.installPath),
    version: data.get(#version, or: $value.version),
    lastSeen: data.get(#lastSeen, or: $value.lastSeen),
  );

  @override
  InstalledSourceCopyWith<$R2, InstalledSource, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _InstalledSourceCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class VersionCheckerSourceMapper
    extends SubClassMapperBase<VersionCheckerSource> {
  VersionCheckerSourceMapper._();

  static VersionCheckerSourceMapper? _instance;
  static VersionCheckerSourceMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = VersionCheckerSourceMapper._());
      ModRecordSourceMapper.ensureInitialized().addSubMapper(_instance!);
    }
    return _instance!;
  }

  @override
  final String id = 'VersionCheckerSource';

  static String? _$forumThreadId(VersionCheckerSource v) => v.forumThreadId;
  static const Field<VersionCheckerSource, String> _f$forumThreadId = Field(
    'forumThreadId',
    _$forumThreadId,
    opt: true,
  );
  static String? _$nexusModsId(VersionCheckerSource v) => v.nexusModsId;
  static const Field<VersionCheckerSource, String> _f$nexusModsId = Field(
    'nexusModsId',
    _$nexusModsId,
    opt: true,
  );
  static String? _$directDownloadUrl(VersionCheckerSource v) =>
      v.directDownloadUrl;
  static const Field<VersionCheckerSource, String> _f$directDownloadUrl = Field(
    'directDownloadUrl',
    _$directDownloadUrl,
    opt: true,
  );
  static String? _$changelogUrl(VersionCheckerSource v) => v.changelogUrl;
  static const Field<VersionCheckerSource, String> _f$changelogUrl = Field(
    'changelogUrl',
    _$changelogUrl,
    opt: true,
  );
  static String? _$masterVersionFileUrl(VersionCheckerSource v) =>
      v.masterVersionFileUrl;
  static const Field<VersionCheckerSource, String> _f$masterVersionFileUrl =
      Field('masterVersionFileUrl', _$masterVersionFileUrl, opt: true);
  static DateTime? _$lastSeen(VersionCheckerSource v) => v.lastSeen;
  static const Field<VersionCheckerSource, DateTime> _f$lastSeen = Field(
    'lastSeen',
    _$lastSeen,
    opt: true,
  );

  @override
  final MappableFields<VersionCheckerSource> fields = const {
    #forumThreadId: _f$forumThreadId,
    #nexusModsId: _f$nexusModsId,
    #directDownloadUrl: _f$directDownloadUrl,
    #changelogUrl: _f$changelogUrl,
    #masterVersionFileUrl: _f$masterVersionFileUrl,
    #lastSeen: _f$lastSeen,
  };

  @override
  final String discriminatorKey = 'sourceType';
  @override
  final dynamic discriminatorValue = 'versionChecker';
  @override
  late final ClassMapperBase superMapper =
      ModRecordSourceMapper.ensureInitialized();

  static VersionCheckerSource _instantiate(DecodingData data) {
    return VersionCheckerSource(
      forumThreadId: data.dec(_f$forumThreadId),
      nexusModsId: data.dec(_f$nexusModsId),
      directDownloadUrl: data.dec(_f$directDownloadUrl),
      changelogUrl: data.dec(_f$changelogUrl),
      masterVersionFileUrl: data.dec(_f$masterVersionFileUrl),
      lastSeen: data.dec(_f$lastSeen),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static VersionCheckerSource fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<VersionCheckerSource>(map);
  }

  static VersionCheckerSource fromJson(String json) {
    return ensureInitialized().decodeJson<VersionCheckerSource>(json);
  }
}

mixin VersionCheckerSourceMappable {
  String toJson() {
    return VersionCheckerSourceMapper.ensureInitialized()
        .encodeJson<VersionCheckerSource>(this as VersionCheckerSource);
  }

  Map<String, dynamic> toMap() {
    return VersionCheckerSourceMapper.ensureInitialized()
        .encodeMap<VersionCheckerSource>(this as VersionCheckerSource);
  }

  VersionCheckerSourceCopyWith<
    VersionCheckerSource,
    VersionCheckerSource,
    VersionCheckerSource
  >
  get copyWith =>
      _VersionCheckerSourceCopyWithImpl<
        VersionCheckerSource,
        VersionCheckerSource
      >(this as VersionCheckerSource, $identity, $identity);
  @override
  String toString() {
    return VersionCheckerSourceMapper.ensureInitialized().stringifyValue(
      this as VersionCheckerSource,
    );
  }

  @override
  bool operator ==(Object other) {
    return VersionCheckerSourceMapper.ensureInitialized().equalsValue(
      this as VersionCheckerSource,
      other,
    );
  }

  @override
  int get hashCode {
    return VersionCheckerSourceMapper.ensureInitialized().hashValue(
      this as VersionCheckerSource,
    );
  }
}

extension VersionCheckerSourceValueCopy<$R, $Out>
    on ObjectCopyWith<$R, VersionCheckerSource, $Out> {
  VersionCheckerSourceCopyWith<$R, VersionCheckerSource, $Out>
  get $asVersionCheckerSource => $base.as(
    (v, t, t2) => _VersionCheckerSourceCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class VersionCheckerSourceCopyWith<
  $R,
  $In extends VersionCheckerSource,
  $Out
>
    implements ModRecordSourceCopyWith<$R, $In, $Out> {
  @override
  $R call({
    String? forumThreadId,
    String? nexusModsId,
    String? directDownloadUrl,
    String? changelogUrl,
    String? masterVersionFileUrl,
    DateTime? lastSeen,
  });
  VersionCheckerSourceCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _VersionCheckerSourceCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, VersionCheckerSource, $Out>
    implements VersionCheckerSourceCopyWith<$R, VersionCheckerSource, $Out> {
  _VersionCheckerSourceCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<VersionCheckerSource> $mapper =
      VersionCheckerSourceMapper.ensureInitialized();
  @override
  $R call({
    Object? forumThreadId = $none,
    Object? nexusModsId = $none,
    Object? directDownloadUrl = $none,
    Object? changelogUrl = $none,
    Object? masterVersionFileUrl = $none,
    Object? lastSeen = $none,
  }) => $apply(
    FieldCopyWithData({
      if (forumThreadId != $none) #forumThreadId: forumThreadId,
      if (nexusModsId != $none) #nexusModsId: nexusModsId,
      if (directDownloadUrl != $none) #directDownloadUrl: directDownloadUrl,
      if (changelogUrl != $none) #changelogUrl: changelogUrl,
      if (masterVersionFileUrl != $none)
        #masterVersionFileUrl: masterVersionFileUrl,
      if (lastSeen != $none) #lastSeen: lastSeen,
    }),
  );
  @override
  VersionCheckerSource $make(CopyWithData data) => VersionCheckerSource(
    forumThreadId: data.get(#forumThreadId, or: $value.forumThreadId),
    nexusModsId: data.get(#nexusModsId, or: $value.nexusModsId),
    directDownloadUrl: data.get(
      #directDownloadUrl,
      or: $value.directDownloadUrl,
    ),
    changelogUrl: data.get(#changelogUrl, or: $value.changelogUrl),
    masterVersionFileUrl: data.get(
      #masterVersionFileUrl,
      or: $value.masterVersionFileUrl,
    ),
    lastSeen: data.get(#lastSeen, or: $value.lastSeen),
  );

  @override
  VersionCheckerSourceCopyWith<$R2, VersionCheckerSource, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _VersionCheckerSourceCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class CatalogSourceMapper extends SubClassMapperBase<CatalogSource> {
  CatalogSourceMapper._();

  static CatalogSourceMapper? _instance;
  static CatalogSourceMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = CatalogSourceMapper._());
      ModRecordSourceMapper.ensureInitialized().addSubMapper(_instance!);
    }
    return _instance!;
  }

  @override
  final String id = 'CatalogSource';

  static String? _$catalogName(CatalogSource v) => v.catalogName;
  static const Field<CatalogSource, String> _f$catalogName = Field(
    'catalogName',
    _$catalogName,
    opt: true,
  );
  static String? _$forumUrl(CatalogSource v) => v.forumUrl;
  static const Field<CatalogSource, String> _f$forumUrl = Field(
    'forumUrl',
    _$forumUrl,
    opt: true,
  );
  static String? _$nexusUrl(CatalogSource v) => v.nexusUrl;
  static const Field<CatalogSource, String> _f$nexusUrl = Field(
    'nexusUrl',
    _$nexusUrl,
    opt: true,
  );
  static String? _$discordUrl(CatalogSource v) => v.discordUrl;
  static const Field<CatalogSource, String> _f$discordUrl = Field(
    'discordUrl',
    _$discordUrl,
    opt: true,
  );
  static String? _$directDownloadUrl(CatalogSource v) => v.directDownloadUrl;
  static const Field<CatalogSource, String> _f$directDownloadUrl = Field(
    'directDownloadUrl',
    _$directDownloadUrl,
    opt: true,
  );
  static String? _$downloadPageUrl(CatalogSource v) => v.downloadPageUrl;
  static const Field<CatalogSource, String> _f$downloadPageUrl = Field(
    'downloadPageUrl',
    _$downloadPageUrl,
    opt: true,
  );
  static String? _$forumThreadId(CatalogSource v) => v.forumThreadId;
  static const Field<CatalogSource, String> _f$forumThreadId = Field(
    'forumThreadId',
    _$forumThreadId,
    opt: true,
  );
  static String? _$nexusModsId(CatalogSource v) => v.nexusModsId;
  static const Field<CatalogSource, String> _f$nexusModsId = Field(
    'nexusModsId',
    _$nexusModsId,
    opt: true,
  );
  static List<String>? _$categories(CatalogSource v) => v.categories;
  static const Field<CatalogSource, List<String>> _f$categories = Field(
    'categories',
    _$categories,
    opt: true,
  );
  static DateTime? _$lastSeen(CatalogSource v) => v.lastSeen;
  static const Field<CatalogSource, DateTime> _f$lastSeen = Field(
    'lastSeen',
    _$lastSeen,
    opt: true,
  );

  @override
  final MappableFields<CatalogSource> fields = const {
    #catalogName: _f$catalogName,
    #forumUrl: _f$forumUrl,
    #nexusUrl: _f$nexusUrl,
    #discordUrl: _f$discordUrl,
    #directDownloadUrl: _f$directDownloadUrl,
    #downloadPageUrl: _f$downloadPageUrl,
    #forumThreadId: _f$forumThreadId,
    #nexusModsId: _f$nexusModsId,
    #categories: _f$categories,
    #lastSeen: _f$lastSeen,
  };

  @override
  final String discriminatorKey = 'sourceType';
  @override
  final dynamic discriminatorValue = 'catalog';
  @override
  late final ClassMapperBase superMapper =
      ModRecordSourceMapper.ensureInitialized();

  static CatalogSource _instantiate(DecodingData data) {
    return CatalogSource(
      catalogName: data.dec(_f$catalogName),
      forumUrl: data.dec(_f$forumUrl),
      nexusUrl: data.dec(_f$nexusUrl),
      discordUrl: data.dec(_f$discordUrl),
      directDownloadUrl: data.dec(_f$directDownloadUrl),
      downloadPageUrl: data.dec(_f$downloadPageUrl),
      forumThreadId: data.dec(_f$forumThreadId),
      nexusModsId: data.dec(_f$nexusModsId),
      categories: data.dec(_f$categories),
      lastSeen: data.dec(_f$lastSeen),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static CatalogSource fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<CatalogSource>(map);
  }

  static CatalogSource fromJson(String json) {
    return ensureInitialized().decodeJson<CatalogSource>(json);
  }
}

mixin CatalogSourceMappable {
  String toJson() {
    return CatalogSourceMapper.ensureInitialized().encodeJson<CatalogSource>(
      this as CatalogSource,
    );
  }

  Map<String, dynamic> toMap() {
    return CatalogSourceMapper.ensureInitialized().encodeMap<CatalogSource>(
      this as CatalogSource,
    );
  }

  CatalogSourceCopyWith<CatalogSource, CatalogSource, CatalogSource>
  get copyWith => _CatalogSourceCopyWithImpl<CatalogSource, CatalogSource>(
    this as CatalogSource,
    $identity,
    $identity,
  );
  @override
  String toString() {
    return CatalogSourceMapper.ensureInitialized().stringifyValue(
      this as CatalogSource,
    );
  }

  @override
  bool operator ==(Object other) {
    return CatalogSourceMapper.ensureInitialized().equalsValue(
      this as CatalogSource,
      other,
    );
  }

  @override
  int get hashCode {
    return CatalogSourceMapper.ensureInitialized().hashValue(
      this as CatalogSource,
    );
  }
}

extension CatalogSourceValueCopy<$R, $Out>
    on ObjectCopyWith<$R, CatalogSource, $Out> {
  CatalogSourceCopyWith<$R, CatalogSource, $Out> get $asCatalogSource =>
      $base.as((v, t, t2) => _CatalogSourceCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class CatalogSourceCopyWith<$R, $In extends CatalogSource, $Out>
    implements ModRecordSourceCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>? get categories;
  @override
  $R call({
    String? catalogName,
    String? forumUrl,
    String? nexusUrl,
    String? discordUrl,
    String? directDownloadUrl,
    String? downloadPageUrl,
    String? forumThreadId,
    String? nexusModsId,
    List<String>? categories,
    DateTime? lastSeen,
  });
  CatalogSourceCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _CatalogSourceCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, CatalogSource, $Out>
    implements CatalogSourceCopyWith<$R, CatalogSource, $Out> {
  _CatalogSourceCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<CatalogSource> $mapper =
      CatalogSourceMapper.ensureInitialized();
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>?
  get categories => $value.categories != null
      ? ListCopyWith(
          $value.categories!,
          (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(categories: v),
        )
      : null;
  @override
  $R call({
    Object? catalogName = $none,
    Object? forumUrl = $none,
    Object? nexusUrl = $none,
    Object? discordUrl = $none,
    Object? directDownloadUrl = $none,
    Object? downloadPageUrl = $none,
    Object? forumThreadId = $none,
    Object? nexusModsId = $none,
    Object? categories = $none,
    Object? lastSeen = $none,
  }) => $apply(
    FieldCopyWithData({
      if (catalogName != $none) #catalogName: catalogName,
      if (forumUrl != $none) #forumUrl: forumUrl,
      if (nexusUrl != $none) #nexusUrl: nexusUrl,
      if (discordUrl != $none) #discordUrl: discordUrl,
      if (directDownloadUrl != $none) #directDownloadUrl: directDownloadUrl,
      if (downloadPageUrl != $none) #downloadPageUrl: downloadPageUrl,
      if (forumThreadId != $none) #forumThreadId: forumThreadId,
      if (nexusModsId != $none) #nexusModsId: nexusModsId,
      if (categories != $none) #categories: categories,
      if (lastSeen != $none) #lastSeen: lastSeen,
    }),
  );
  @override
  CatalogSource $make(CopyWithData data) => CatalogSource(
    catalogName: data.get(#catalogName, or: $value.catalogName),
    forumUrl: data.get(#forumUrl, or: $value.forumUrl),
    nexusUrl: data.get(#nexusUrl, or: $value.nexusUrl),
    discordUrl: data.get(#discordUrl, or: $value.discordUrl),
    directDownloadUrl: data.get(
      #directDownloadUrl,
      or: $value.directDownloadUrl,
    ),
    downloadPageUrl: data.get(#downloadPageUrl, or: $value.downloadPageUrl),
    forumThreadId: data.get(#forumThreadId, or: $value.forumThreadId),
    nexusModsId: data.get(#nexusModsId, or: $value.nexusModsId),
    categories: data.get(#categories, or: $value.categories),
    lastSeen: data.get(#lastSeen, or: $value.lastSeen),
  );

  @override
  CatalogSourceCopyWith<$R2, CatalogSource, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _CatalogSourceCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class DownloadHistorySourceMapper
    extends SubClassMapperBase<DownloadHistorySource> {
  DownloadHistorySourceMapper._();

  static DownloadHistorySourceMapper? _instance;
  static DownloadHistorySourceMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = DownloadHistorySourceMapper._());
      ModRecordSourceMapper.ensureInitialized().addSubMapper(_instance!);
    }
    return _instance!;
  }

  @override
  final String id = 'DownloadHistorySource';

  static String? _$lastDownloadedFrom(DownloadHistorySource v) =>
      v.lastDownloadedFrom;
  static const Field<DownloadHistorySource, String> _f$lastDownloadedFrom =
      Field('lastDownloadedFrom', _$lastDownloadedFrom, opt: true);
  static DateTime? _$lastDownloadedAt(DownloadHistorySource v) =>
      v.lastDownloadedAt;
  static const Field<DownloadHistorySource, DateTime> _f$lastDownloadedAt =
      Field('lastDownloadedAt', _$lastDownloadedAt, opt: true);
  static DateTime? _$lastSeen(DownloadHistorySource v) => v.lastSeen;
  static const Field<DownloadHistorySource, DateTime> _f$lastSeen = Field(
    'lastSeen',
    _$lastSeen,
    opt: true,
  );

  @override
  final MappableFields<DownloadHistorySource> fields = const {
    #lastDownloadedFrom: _f$lastDownloadedFrom,
    #lastDownloadedAt: _f$lastDownloadedAt,
    #lastSeen: _f$lastSeen,
  };

  @override
  final String discriminatorKey = 'sourceType';
  @override
  final dynamic discriminatorValue = 'downloadHistory';
  @override
  late final ClassMapperBase superMapper =
      ModRecordSourceMapper.ensureInitialized();

  static DownloadHistorySource _instantiate(DecodingData data) {
    return DownloadHistorySource(
      lastDownloadedFrom: data.dec(_f$lastDownloadedFrom),
      lastDownloadedAt: data.dec(_f$lastDownloadedAt),
      lastSeen: data.dec(_f$lastSeen),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static DownloadHistorySource fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<DownloadHistorySource>(map);
  }

  static DownloadHistorySource fromJson(String json) {
    return ensureInitialized().decodeJson<DownloadHistorySource>(json);
  }
}

mixin DownloadHistorySourceMappable {
  String toJson() {
    return DownloadHistorySourceMapper.ensureInitialized()
        .encodeJson<DownloadHistorySource>(this as DownloadHistorySource);
  }

  Map<String, dynamic> toMap() {
    return DownloadHistorySourceMapper.ensureInitialized()
        .encodeMap<DownloadHistorySource>(this as DownloadHistorySource);
  }

  DownloadHistorySourceCopyWith<
    DownloadHistorySource,
    DownloadHistorySource,
    DownloadHistorySource
  >
  get copyWith =>
      _DownloadHistorySourceCopyWithImpl<
        DownloadHistorySource,
        DownloadHistorySource
      >(this as DownloadHistorySource, $identity, $identity);
  @override
  String toString() {
    return DownloadHistorySourceMapper.ensureInitialized().stringifyValue(
      this as DownloadHistorySource,
    );
  }

  @override
  bool operator ==(Object other) {
    return DownloadHistorySourceMapper.ensureInitialized().equalsValue(
      this as DownloadHistorySource,
      other,
    );
  }

  @override
  int get hashCode {
    return DownloadHistorySourceMapper.ensureInitialized().hashValue(
      this as DownloadHistorySource,
    );
  }
}

extension DownloadHistorySourceValueCopy<$R, $Out>
    on ObjectCopyWith<$R, DownloadHistorySource, $Out> {
  DownloadHistorySourceCopyWith<$R, DownloadHistorySource, $Out>
  get $asDownloadHistorySource => $base.as(
    (v, t, t2) => _DownloadHistorySourceCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class DownloadHistorySourceCopyWith<
  $R,
  $In extends DownloadHistorySource,
  $Out
>
    implements ModRecordSourceCopyWith<$R, $In, $Out> {
  @override
  $R call({
    String? lastDownloadedFrom,
    DateTime? lastDownloadedAt,
    DateTime? lastSeen,
  });
  DownloadHistorySourceCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _DownloadHistorySourceCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, DownloadHistorySource, $Out>
    implements DownloadHistorySourceCopyWith<$R, DownloadHistorySource, $Out> {
  _DownloadHistorySourceCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<DownloadHistorySource> $mapper =
      DownloadHistorySourceMapper.ensureInitialized();
  @override
  $R call({
    Object? lastDownloadedFrom = $none,
    Object? lastDownloadedAt = $none,
    Object? lastSeen = $none,
  }) => $apply(
    FieldCopyWithData({
      if (lastDownloadedFrom != $none) #lastDownloadedFrom: lastDownloadedFrom,
      if (lastDownloadedAt != $none) #lastDownloadedAt: lastDownloadedAt,
      if (lastSeen != $none) #lastSeen: lastSeen,
    }),
  );
  @override
  DownloadHistorySource $make(CopyWithData data) => DownloadHistorySource(
    lastDownloadedFrom: data.get(
      #lastDownloadedFrom,
      or: $value.lastDownloadedFrom,
    ),
    lastDownloadedAt: data.get(#lastDownloadedAt, or: $value.lastDownloadedAt),
    lastSeen: data.get(#lastSeen, or: $value.lastSeen),
  );

  @override
  DownloadHistorySourceCopyWith<$R2, DownloadHistorySource, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _DownloadHistorySourceCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

