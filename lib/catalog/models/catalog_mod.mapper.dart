// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'catalog_mod.dart';

class ModSourceMapper extends EnumMapper<ModSource> {
  ModSourceMapper._();

  static ModSourceMapper? _instance;
  static ModSourceMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ModSourceMapper._());
    }
    return _instance!;
  }

  static ModSource fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  ModSource decode(dynamic value) {
    switch (value) {
      case r'Index':
        return ModSource.Index;
      case r'ModdingSubforum':
        return ModSource.ModdingSubforum;
      case r'Discord':
        return ModSource.Discord;
      case r'NexusMods':
        return ModSource.NexusMods;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(ModSource self) {
    switch (self) {
      case ModSource.Index:
        return r'Index';
      case ModSource.ModdingSubforum:
        return r'ModdingSubforum';
      case ModSource.Discord:
        return r'Discord';
      case ModSource.NexusMods:
        return r'NexusMods';
    }
  }
}

extension ModSourceMapperExtension on ModSource {
  String toValue() {
    ModSourceMapper.ensureInitialized();
    return MapperContainer.globals.toValue<ModSource>(this) as String;
  }
}

class ModUrlTypeMapper extends EnumMapper<ModUrlType> {
  ModUrlTypeMapper._();

  static ModUrlTypeMapper? _instance;
  static ModUrlTypeMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ModUrlTypeMapper._());
    }
    return _instance!;
  }

  static ModUrlType fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  ModUrlType decode(dynamic value) {
    switch (value) {
      case r'Forum':
        return ModUrlType.Forum;
      case r'Discord':
        return ModUrlType.Discord;
      case r'NexusMods':
        return ModUrlType.NexusMods;
      case r'DirectDownload':
        return ModUrlType.DirectDownload;
      case r'DownloadPage':
        return ModUrlType.DownloadPage;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(ModUrlType self) {
    switch (self) {
      case ModUrlType.Forum:
        return r'Forum';
      case ModUrlType.Discord:
        return r'Discord';
      case ModUrlType.NexusMods:
        return r'NexusMods';
      case ModUrlType.DirectDownload:
        return r'DirectDownload';
      case ModUrlType.DownloadPage:
        return r'DownloadPage';
    }
  }
}

extension ModUrlTypeMapperExtension on ModUrlType {
  String toValue() {
    ModUrlTypeMapper.ensureInitialized();
    return MapperContainer.globals.toValue<ModUrlType>(this) as String;
  }
}

class CatalogModsRepoMapper extends ClassMapperBase<CatalogModsRepo> {
  CatalogModsRepoMapper._();

  static CatalogModsRepoMapper? _instance;
  static CatalogModsRepoMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = CatalogModsRepoMapper._());
      CatalogModMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'CatalogModsRepo';

  static List<CatalogMod> _$items(CatalogModsRepo v) => v.items;
  static const Field<CatalogModsRepo, List<CatalogMod>> _f$items = Field(
    'items',
    _$items,
  );
  static String _$lastUpdated(CatalogModsRepo v) => v.lastUpdated;
  static const Field<CatalogModsRepo, String> _f$lastUpdated = Field(
    'lastUpdated',
    _$lastUpdated,
  );

  @override
  final MappableFields<CatalogModsRepo> fields = const {
    #items: _f$items,
    #lastUpdated: _f$lastUpdated,
  };

  static CatalogModsRepo _instantiate(DecodingData data) {
    return CatalogModsRepo(
      items: data.dec(_f$items),
      lastUpdated: data.dec(_f$lastUpdated),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static CatalogModsRepo fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<CatalogModsRepo>(map);
  }

  static CatalogModsRepo fromJson(String json) {
    return ensureInitialized().decodeJson<CatalogModsRepo>(json);
  }
}

mixin CatalogModsRepoMappable {
  String toJson() {
    return CatalogModsRepoMapper.ensureInitialized()
        .encodeJson<CatalogModsRepo>(this as CatalogModsRepo);
  }

  Map<String, dynamic> toMap() {
    return CatalogModsRepoMapper.ensureInitialized().encodeMap<CatalogModsRepo>(
      this as CatalogModsRepo,
    );
  }

  CatalogModsRepoCopyWith<CatalogModsRepo, CatalogModsRepo, CatalogModsRepo>
  get copyWith =>
      _CatalogModsRepoCopyWithImpl<CatalogModsRepo, CatalogModsRepo>(
        this as CatalogModsRepo,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return CatalogModsRepoMapper.ensureInitialized().stringifyValue(
      this as CatalogModsRepo,
    );
  }

  @override
  bool operator ==(Object other) {
    return CatalogModsRepoMapper.ensureInitialized().equalsValue(
      this as CatalogModsRepo,
      other,
    );
  }

  @override
  int get hashCode {
    return CatalogModsRepoMapper.ensureInitialized().hashValue(
      this as CatalogModsRepo,
    );
  }
}

extension CatalogModsRepoValueCopy<$R, $Out>
    on ObjectCopyWith<$R, CatalogModsRepo, $Out> {
  CatalogModsRepoCopyWith<$R, CatalogModsRepo, $Out> get $asCatalogModsRepo =>
      $base.as((v, t, t2) => _CatalogModsRepoCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class CatalogModsRepoCopyWith<$R, $In extends CatalogModsRepo, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, CatalogMod, CatalogModCopyWith<$R, CatalogMod, CatalogMod>>
  get items;
  $R call({List<CatalogMod>? items, String? lastUpdated});
  CatalogModsRepoCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _CatalogModsRepoCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, CatalogModsRepo, $Out>
    implements CatalogModsRepoCopyWith<$R, CatalogModsRepo, $Out> {
  _CatalogModsRepoCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<CatalogModsRepo> $mapper =
      CatalogModsRepoMapper.ensureInitialized();
  @override
  ListCopyWith<$R, CatalogMod, CatalogModCopyWith<$R, CatalogMod, CatalogMod>>
  get items => ListCopyWith(
    $value.items,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(items: v),
  );
  @override
  $R call({List<CatalogMod>? items, String? lastUpdated}) => $apply(
    FieldCopyWithData({
      if (items != null) #items: items,
      if (lastUpdated != null) #lastUpdated: lastUpdated,
    }),
  );
  @override
  CatalogModsRepo $make(CopyWithData data) => CatalogModsRepo(
    items: data.get(#items, or: $value.items),
    lastUpdated: data.get(#lastUpdated, or: $value.lastUpdated),
  );

  @override
  CatalogModsRepoCopyWith<$R2, CatalogModsRepo, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _CatalogModsRepoCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class CatalogModMapper extends ClassMapperBase<CatalogMod> {
  CatalogModMapper._();

  static CatalogModMapper? _instance;
  static CatalogModMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = CatalogModMapper._());
      ModUrlTypeMapper.ensureInitialized();
      ModSourceMapper.ensureInitialized();
      CatalogModImageMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'CatalogMod';

  static String _$name(CatalogMod v) => v.name;
  static const Field<CatalogMod, String> _f$name = Field('name', _$name);
  static String? _$summary(CatalogMod v) => v.summary;
  static const Field<CatalogMod, String> _f$summary = Field(
    'summary',
    _$summary,
    opt: true,
  );
  static String? _$description(CatalogMod v) => v.description;
  static const Field<CatalogMod, String> _f$description = Field(
    'description',
    _$description,
    opt: true,
  );
  static String? _$modVersion(CatalogMod v) => v.modVersion;
  static const Field<CatalogMod, String> _f$modVersion = Field(
    'modVersion',
    _$modVersion,
    opt: true,
  );
  static String? _$gameVersionReq(CatalogMod v) => v.gameVersionReq;
  static const Field<CatalogMod, String> _f$gameVersionReq = Field(
    'gameVersionReq',
    _$gameVersionReq,
    opt: true,
  );
  static List<String>? _$authorsList(CatalogMod v) => v.authorsList;
  static const Field<CatalogMod, List<String>> _f$authorsList = Field(
    'authorsList',
    _$authorsList,
    opt: true,
  );
  static Map<ModUrlType, String>? _$urls(CatalogMod v) => v.urls;
  static const Field<CatalogMod, Map<ModUrlType, String>> _f$urls = Field(
    'urls',
    _$urls,
    opt: true,
  );
  static List<ModSource>? _$sources(CatalogMod v) => v.sources;
  static const Field<CatalogMod, List<ModSource>> _f$sources = Field(
    'sources',
    _$sources,
    opt: true,
  );
  static List<String>? _$categories(CatalogMod v) => v.categories;
  static const Field<CatalogMod, List<String>> _f$categories = Field(
    'categories',
    _$categories,
    opt: true,
  );
  static Map<String, CatalogModImage>? _$images(CatalogMod v) => v.images;
  static const Field<CatalogMod, Map<String, CatalogModImage>> _f$images =
      Field('images', _$images, opt: true);
  static DateTime? _$dateTimeCreated(CatalogMod v) => v.dateTimeCreated;
  static const Field<CatalogMod, DateTime> _f$dateTimeCreated = Field(
    'dateTimeCreated',
    _$dateTimeCreated,
    opt: true,
  );
  static DateTime? _$dateTimeEdited(CatalogMod v) => v.dateTimeEdited;
  static const Field<CatalogMod, DateTime> _f$dateTimeEdited = Field(
    'dateTimeEdited',
    _$dateTimeEdited,
    opt: true,
  );
  static String? _$partOfThreadTitle(CatalogMod v) => v.partOfThreadTitle;
  static const Field<CatalogMod, String> _f$partOfThreadTitle = Field(
    'partOfThreadTitle',
    _$partOfThreadTitle,
    opt: true,
  );

  @override
  final MappableFields<CatalogMod> fields = const {
    #name: _f$name,
    #summary: _f$summary,
    #description: _f$description,
    #modVersion: _f$modVersion,
    #gameVersionReq: _f$gameVersionReq,
    #authorsList: _f$authorsList,
    #urls: _f$urls,
    #sources: _f$sources,
    #categories: _f$categories,
    #images: _f$images,
    #dateTimeCreated: _f$dateTimeCreated,
    #dateTimeEdited: _f$dateTimeEdited,
    #partOfThreadTitle: _f$partOfThreadTitle,
  };

  static CatalogMod _instantiate(DecodingData data) {
    return CatalogMod(
      name: data.dec(_f$name),
      summary: data.dec(_f$summary),
      description: data.dec(_f$description),
      modVersion: data.dec(_f$modVersion),
      gameVersionReq: data.dec(_f$gameVersionReq),
      authorsList: data.dec(_f$authorsList),
      urls: data.dec(_f$urls),
      sources: data.dec(_f$sources),
      categories: data.dec(_f$categories),
      images: data.dec(_f$images),
      dateTimeCreated: data.dec(_f$dateTimeCreated),
      dateTimeEdited: data.dec(_f$dateTimeEdited),
      partOfThreadTitle: data.dec(_f$partOfThreadTitle),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static CatalogMod fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<CatalogMod>(map);
  }

  static CatalogMod fromJson(String json) {
    return ensureInitialized().decodeJson<CatalogMod>(json);
  }
}

mixin CatalogModMappable {
  String toJson() {
    return CatalogModMapper.ensureInitialized().encodeJson<CatalogMod>(
      this as CatalogMod,
    );
  }

  Map<String, dynamic> toMap() {
    return CatalogModMapper.ensureInitialized().encodeMap<CatalogMod>(
      this as CatalogMod,
    );
  }

  CatalogModCopyWith<CatalogMod, CatalogMod, CatalogMod> get copyWith =>
      _CatalogModCopyWithImpl<CatalogMod, CatalogMod>(
        this as CatalogMod,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return CatalogModMapper.ensureInitialized().stringifyValue(
      this as CatalogMod,
    );
  }

  @override
  bool operator ==(Object other) {
    return CatalogModMapper.ensureInitialized().equalsValue(
      this as CatalogMod,
      other,
    );
  }

  @override
  int get hashCode {
    return CatalogModMapper.ensureInitialized().hashValue(this as CatalogMod);
  }
}

extension CatalogModValueCopy<$R, $Out>
    on ObjectCopyWith<$R, CatalogMod, $Out> {
  CatalogModCopyWith<$R, CatalogMod, $Out> get $asCatalogMod =>
      $base.as((v, t, t2) => _CatalogModCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class CatalogModCopyWith<$R, $In extends CatalogMod, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>? get authorsList;
  MapCopyWith<$R, ModUrlType, String, ObjectCopyWith<$R, String, String>>?
  get urls;
  ListCopyWith<$R, ModSource, ObjectCopyWith<$R, ModSource, ModSource>>?
  get sources;
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>? get categories;
  MapCopyWith<
    $R,
    String,
    CatalogModImage,
    CatalogModImageCopyWith<$R, CatalogModImage, CatalogModImage>
  >?
  get images;
  $R call({
    String? name,
    String? summary,
    String? description,
    String? modVersion,
    String? gameVersionReq,
    List<String>? authorsList,
    Map<ModUrlType, String>? urls,
    List<ModSource>? sources,
    List<String>? categories,
    Map<String, CatalogModImage>? images,
    DateTime? dateTimeCreated,
    DateTime? dateTimeEdited,
    String? partOfThreadTitle,
  });
  CatalogModCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _CatalogModCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, CatalogMod, $Out>
    implements CatalogModCopyWith<$R, CatalogMod, $Out> {
  _CatalogModCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<CatalogMod> $mapper =
      CatalogModMapper.ensureInitialized();
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>?
  get authorsList => $value.authorsList != null
      ? ListCopyWith(
          $value.authorsList!,
          (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(authorsList: v),
        )
      : null;
  @override
  MapCopyWith<$R, ModUrlType, String, ObjectCopyWith<$R, String, String>>?
  get urls => $value.urls != null
      ? MapCopyWith(
          $value.urls!,
          (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(urls: v),
        )
      : null;
  @override
  ListCopyWith<$R, ModSource, ObjectCopyWith<$R, ModSource, ModSource>>?
  get sources => $value.sources != null
      ? ListCopyWith(
          $value.sources!,
          (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(sources: v),
        )
      : null;
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
  MapCopyWith<
    $R,
    String,
    CatalogModImage,
    CatalogModImageCopyWith<$R, CatalogModImage, CatalogModImage>
  >?
  get images => $value.images != null
      ? MapCopyWith(
          $value.images!,
          (v, t) => v.copyWith.$chain(t),
          (v) => call(images: v),
        )
      : null;
  @override
  $R call({
    String? name,
    Object? summary = $none,
    Object? description = $none,
    Object? modVersion = $none,
    Object? gameVersionReq = $none,
    Object? authorsList = $none,
    Object? urls = $none,
    Object? sources = $none,
    Object? categories = $none,
    Object? images = $none,
    Object? dateTimeCreated = $none,
    Object? dateTimeEdited = $none,
    Object? partOfThreadTitle = $none,
  }) => $apply(
    FieldCopyWithData({
      if (name != null) #name: name,
      if (summary != $none) #summary: summary,
      if (description != $none) #description: description,
      if (modVersion != $none) #modVersion: modVersion,
      if (gameVersionReq != $none) #gameVersionReq: gameVersionReq,
      if (authorsList != $none) #authorsList: authorsList,
      if (urls != $none) #urls: urls,
      if (sources != $none) #sources: sources,
      if (categories != $none) #categories: categories,
      if (images != $none) #images: images,
      if (dateTimeCreated != $none) #dateTimeCreated: dateTimeCreated,
      if (dateTimeEdited != $none) #dateTimeEdited: dateTimeEdited,
      if (partOfThreadTitle != $none) #partOfThreadTitle: partOfThreadTitle,
    }),
  );
  @override
  CatalogMod $make(CopyWithData data) => CatalogMod(
    name: data.get(#name, or: $value.name),
    summary: data.get(#summary, or: $value.summary),
    description: data.get(#description, or: $value.description),
    modVersion: data.get(#modVersion, or: $value.modVersion),
    gameVersionReq: data.get(#gameVersionReq, or: $value.gameVersionReq),
    authorsList: data.get(#authorsList, or: $value.authorsList),
    urls: data.get(#urls, or: $value.urls),
    sources: data.get(#sources, or: $value.sources),
    categories: data.get(#categories, or: $value.categories),
    images: data.get(#images, or: $value.images),
    dateTimeCreated: data.get(#dateTimeCreated, or: $value.dateTimeCreated),
    dateTimeEdited: data.get(#dateTimeEdited, or: $value.dateTimeEdited),
    partOfThreadTitle: data.get(
      #partOfThreadTitle,
      or: $value.partOfThreadTitle,
    ),
  );

  @override
  CatalogModCopyWith<$R2, CatalogMod, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _CatalogModCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class CatalogModImageMapper extends ClassMapperBase<CatalogModImage> {
  CatalogModImageMapper._();

  static CatalogModImageMapper? _instance;
  static CatalogModImageMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = CatalogModImageMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'CatalogModImage';

  static String _$id(CatalogModImage v) => v.id;
  static const Field<CatalogModImage, String> _f$id = Field('id', _$id);
  static String? _$filename(CatalogModImage v) => v.filename;
  static const Field<CatalogModImage, String> _f$filename = Field(
    'filename',
    _$filename,
    opt: true,
  );
  static String? _$description(CatalogModImage v) => v.description;
  static const Field<CatalogModImage, String> _f$description = Field(
    'description',
    _$description,
    opt: true,
  );
  static String? _$contentType(CatalogModImage v) => v.contentType;
  static const Field<CatalogModImage, String> _f$contentType = Field(
    'contentType',
    _$contentType,
    opt: true,
  );
  static int? _$size(CatalogModImage v) => v.size;
  static const Field<CatalogModImage, int> _f$size = Field(
    'size',
    _$size,
    opt: true,
  );
  static String? _$url(CatalogModImage v) => v.url;
  static const Field<CatalogModImage, String> _f$url = Field(
    'url',
    _$url,
    opt: true,
  );
  static String? _$proxyUrl(CatalogModImage v) => v.proxyUrl;
  static const Field<CatalogModImage, String> _f$proxyUrl = Field(
    'proxyUrl',
    _$proxyUrl,
    opt: true,
  );

  @override
  final MappableFields<CatalogModImage> fields = const {
    #id: _f$id,
    #filename: _f$filename,
    #description: _f$description,
    #contentType: _f$contentType,
    #size: _f$size,
    #url: _f$url,
    #proxyUrl: _f$proxyUrl,
  };

  static CatalogModImage _instantiate(DecodingData data) {
    return CatalogModImage(
      id: data.dec(_f$id),
      filename: data.dec(_f$filename),
      description: data.dec(_f$description),
      contentType: data.dec(_f$contentType),
      size: data.dec(_f$size),
      url: data.dec(_f$url),
      proxyUrl: data.dec(_f$proxyUrl),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static CatalogModImage fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<CatalogModImage>(map);
  }

  static CatalogModImage fromJson(String json) {
    return ensureInitialized().decodeJson<CatalogModImage>(json);
  }
}

mixin CatalogModImageMappable {
  String toJson() {
    return CatalogModImageMapper.ensureInitialized()
        .encodeJson<CatalogModImage>(this as CatalogModImage);
  }

  Map<String, dynamic> toMap() {
    return CatalogModImageMapper.ensureInitialized().encodeMap<CatalogModImage>(
      this as CatalogModImage,
    );
  }

  CatalogModImageCopyWith<CatalogModImage, CatalogModImage, CatalogModImage>
  get copyWith =>
      _CatalogModImageCopyWithImpl<CatalogModImage, CatalogModImage>(
        this as CatalogModImage,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return CatalogModImageMapper.ensureInitialized().stringifyValue(
      this as CatalogModImage,
    );
  }

  @override
  bool operator ==(Object other) {
    return CatalogModImageMapper.ensureInitialized().equalsValue(
      this as CatalogModImage,
      other,
    );
  }

  @override
  int get hashCode {
    return CatalogModImageMapper.ensureInitialized().hashValue(
      this as CatalogModImage,
    );
  }
}

extension CatalogModImageValueCopy<$R, $Out>
    on ObjectCopyWith<$R, CatalogModImage, $Out> {
  CatalogModImageCopyWith<$R, CatalogModImage, $Out> get $asCatalogModImage =>
      $base.as((v, t, t2) => _CatalogModImageCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class CatalogModImageCopyWith<$R, $In extends CatalogModImage, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    String? id,
    String? filename,
    String? description,
    String? contentType,
    int? size,
    String? url,
    String? proxyUrl,
  });
  CatalogModImageCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _CatalogModImageCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, CatalogModImage, $Out>
    implements CatalogModImageCopyWith<$R, CatalogModImage, $Out> {
  _CatalogModImageCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<CatalogModImage> $mapper =
      CatalogModImageMapper.ensureInitialized();
  @override
  $R call({
    String? id,
    Object? filename = $none,
    Object? description = $none,
    Object? contentType = $none,
    Object? size = $none,
    Object? url = $none,
    Object? proxyUrl = $none,
  }) => $apply(
    FieldCopyWithData({
      if (id != null) #id: id,
      if (filename != $none) #filename: filename,
      if (description != $none) #description: description,
      if (contentType != $none) #contentType: contentType,
      if (size != $none) #size: size,
      if (url != $none) #url: url,
      if (proxyUrl != $none) #proxyUrl: proxyUrl,
    }),
  );
  @override
  CatalogModImage $make(CopyWithData data) => CatalogModImage(
    id: data.get(#id, or: $value.id),
    filename: data.get(#filename, or: $value.filename),
    description: data.get(#description, or: $value.description),
    contentType: data.get(#contentType, or: $value.contentType),
    size: data.get(#size, or: $value.size),
    url: data.get(#url, or: $value.url),
    proxyUrl: data.get(#proxyUrl, or: $value.proxyUrl),
  );

  @override
  CatalogModImageCopyWith<$R2, CatalogModImage, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _CatalogModImageCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

