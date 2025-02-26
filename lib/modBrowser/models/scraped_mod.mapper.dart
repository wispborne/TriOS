// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'scraped_mod.dart';

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
      case 'Index':
        return ModSource.Index;
      case 'ModdingSubforum':
        return ModSource.ModdingSubforum;
      case 'Discord':
        return ModSource.Discord;
      case 'NexusMods':
        return ModSource.NexusMods;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(ModSource self) {
    switch (self) {
      case ModSource.Index:
        return 'Index';
      case ModSource.ModdingSubforum:
        return 'ModdingSubforum';
      case ModSource.Discord:
        return 'Discord';
      case ModSource.NexusMods:
        return 'NexusMods';
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
      case 'Forum':
        return ModUrlType.Forum;
      case 'Discord':
        return ModUrlType.Discord;
      case 'NexusMods':
        return ModUrlType.NexusMods;
      case 'DirectDownload':
        return ModUrlType.DirectDownload;
      case 'DownloadPage':
        return ModUrlType.DownloadPage;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(ModUrlType self) {
    switch (self) {
      case ModUrlType.Forum:
        return 'Forum';
      case ModUrlType.Discord:
        return 'Discord';
      case ModUrlType.NexusMods:
        return 'NexusMods';
      case ModUrlType.DirectDownload:
        return 'DirectDownload';
      case ModUrlType.DownloadPage:
        return 'DownloadPage';
    }
  }
}

extension ModUrlTypeMapperExtension on ModUrlType {
  String toValue() {
    ModUrlTypeMapper.ensureInitialized();
    return MapperContainer.globals.toValue<ModUrlType>(this) as String;
  }
}

class ScrapedModsRepoMapper extends ClassMapperBase<ScrapedModsRepo> {
  ScrapedModsRepoMapper._();

  static ScrapedModsRepoMapper? _instance;
  static ScrapedModsRepoMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ScrapedModsRepoMapper._());
      ScrapedModMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ScrapedModsRepo';

  static List<ScrapedMod> _$items(ScrapedModsRepo v) => v.items;
  static const Field<ScrapedModsRepo, List<ScrapedMod>> _f$items = Field(
    'items',
    _$items,
  );
  static String _$lastUpdated(ScrapedModsRepo v) => v.lastUpdated;
  static const Field<ScrapedModsRepo, String> _f$lastUpdated = Field(
    'lastUpdated',
    _$lastUpdated,
  );

  @override
  final MappableFields<ScrapedModsRepo> fields = const {
    #items: _f$items,
    #lastUpdated: _f$lastUpdated,
  };

  static ScrapedModsRepo _instantiate(DecodingData data) {
    return ScrapedModsRepo(
      items: data.dec(_f$items),
      lastUpdated: data.dec(_f$lastUpdated),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ScrapedModsRepo fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ScrapedModsRepo>(map);
  }

  static ScrapedModsRepo fromJson(String json) {
    return ensureInitialized().decodeJson<ScrapedModsRepo>(json);
  }
}

mixin ScrapedModsRepoMappable {
  String toJson() {
    return ScrapedModsRepoMapper.ensureInitialized()
        .encodeJson<ScrapedModsRepo>(this as ScrapedModsRepo);
  }

  Map<String, dynamic> toMap() {
    return ScrapedModsRepoMapper.ensureInitialized().encodeMap<ScrapedModsRepo>(
      this as ScrapedModsRepo,
    );
  }

  ScrapedModsRepoCopyWith<ScrapedModsRepo, ScrapedModsRepo, ScrapedModsRepo>
  get copyWith => _ScrapedModsRepoCopyWithImpl(
    this as ScrapedModsRepo,
    $identity,
    $identity,
  );
  @override
  String toString() {
    return ScrapedModsRepoMapper.ensureInitialized().stringifyValue(
      this as ScrapedModsRepo,
    );
  }

  @override
  bool operator ==(Object other) {
    return ScrapedModsRepoMapper.ensureInitialized().equalsValue(
      this as ScrapedModsRepo,
      other,
    );
  }

  @override
  int get hashCode {
    return ScrapedModsRepoMapper.ensureInitialized().hashValue(
      this as ScrapedModsRepo,
    );
  }
}

extension ScrapedModsRepoValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ScrapedModsRepo, $Out> {
  ScrapedModsRepoCopyWith<$R, ScrapedModsRepo, $Out> get $asScrapedModsRepo =>
      $base.as((v, t, t2) => _ScrapedModsRepoCopyWithImpl(v, t, t2));
}

abstract class ScrapedModsRepoCopyWith<$R, $In extends ScrapedModsRepo, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, ScrapedMod, ScrapedModCopyWith<$R, ScrapedMod, ScrapedMod>>
  get items;
  $R call({List<ScrapedMod>? items, String? lastUpdated});
  ScrapedModsRepoCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _ScrapedModsRepoCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ScrapedModsRepo, $Out>
    implements ScrapedModsRepoCopyWith<$R, ScrapedModsRepo, $Out> {
  _ScrapedModsRepoCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ScrapedModsRepo> $mapper =
      ScrapedModsRepoMapper.ensureInitialized();
  @override
  ListCopyWith<$R, ScrapedMod, ScrapedModCopyWith<$R, ScrapedMod, ScrapedMod>>
  get items => ListCopyWith(
    $value.items,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(items: v),
  );
  @override
  $R call({List<ScrapedMod>? items, String? lastUpdated}) => $apply(
    FieldCopyWithData({
      if (items != null) #items: items,
      if (lastUpdated != null) #lastUpdated: lastUpdated,
    }),
  );
  @override
  ScrapedModsRepo $make(CopyWithData data) => ScrapedModsRepo(
    items: data.get(#items, or: $value.items),
    lastUpdated: data.get(#lastUpdated, or: $value.lastUpdated),
  );

  @override
  ScrapedModsRepoCopyWith<$R2, ScrapedModsRepo, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ScrapedModsRepoCopyWithImpl($value, $cast, t);
}

class ScrapedModMapper extends ClassMapperBase<ScrapedMod> {
  ScrapedModMapper._();

  static ScrapedModMapper? _instance;
  static ScrapedModMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ScrapedModMapper._());
      ModUrlTypeMapper.ensureInitialized();
      ModSourceMapper.ensureInitialized();
      ScrapedModImageMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ScrapedMod';

  static String _$name(ScrapedMod v) => v.name;
  static const Field<ScrapedMod, String> _f$name = Field('name', _$name);
  static String? _$summary(ScrapedMod v) => v.summary;
  static const Field<ScrapedMod, String> _f$summary = Field(
    'summary',
    _$summary,
    opt: true,
  );
  static String? _$description(ScrapedMod v) => v.description;
  static const Field<ScrapedMod, String> _f$description = Field(
    'description',
    _$description,
    opt: true,
  );
  static String? _$modVersion(ScrapedMod v) => v.modVersion;
  static const Field<ScrapedMod, String> _f$modVersion = Field(
    'modVersion',
    _$modVersion,
    opt: true,
  );
  static String? _$gameVersionReq(ScrapedMod v) => v.gameVersionReq;
  static const Field<ScrapedMod, String> _f$gameVersionReq = Field(
    'gameVersionReq',
    _$gameVersionReq,
    opt: true,
  );
  static List<String>? _$authorsList(ScrapedMod v) => v.authorsList;
  static const Field<ScrapedMod, List<String>> _f$authorsList = Field(
    'authorsList',
    _$authorsList,
    opt: true,
  );
  static Map<ModUrlType, String>? _$urls(ScrapedMod v) => v.urls;
  static const Field<ScrapedMod, Map<ModUrlType, String>> _f$urls = Field(
    'urls',
    _$urls,
    opt: true,
  );
  static List<ModSource>? _$sources(ScrapedMod v) => v.sources;
  static const Field<ScrapedMod, List<ModSource>> _f$sources = Field(
    'sources',
    _$sources,
    opt: true,
  );
  static List<String>? _$categories(ScrapedMod v) => v.categories;
  static const Field<ScrapedMod, List<String>> _f$categories = Field(
    'categories',
    _$categories,
    opt: true,
  );
  static Map<String, ScrapedModImage>? _$images(ScrapedMod v) => v.images;
  static const Field<ScrapedMod, Map<String, ScrapedModImage>> _f$images =
      Field('images', _$images, opt: true);
  static DateTime? _$dateTimeCreated(ScrapedMod v) => v.dateTimeCreated;
  static const Field<ScrapedMod, DateTime> _f$dateTimeCreated = Field(
    'dateTimeCreated',
    _$dateTimeCreated,
    opt: true,
  );
  static DateTime? _$dateTimeEdited(ScrapedMod v) => v.dateTimeEdited;
  static const Field<ScrapedMod, DateTime> _f$dateTimeEdited = Field(
    'dateTimeEdited',
    _$dateTimeEdited,
    opt: true,
  );

  @override
  final MappableFields<ScrapedMod> fields = const {
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
  };

  static ScrapedMod _instantiate(DecodingData data) {
    return ScrapedMod(
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
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ScrapedMod fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ScrapedMod>(map);
  }

  static ScrapedMod fromJson(String json) {
    return ensureInitialized().decodeJson<ScrapedMod>(json);
  }
}

mixin ScrapedModMappable {
  String toJson() {
    return ScrapedModMapper.ensureInitialized().encodeJson<ScrapedMod>(
      this as ScrapedMod,
    );
  }

  Map<String, dynamic> toMap() {
    return ScrapedModMapper.ensureInitialized().encodeMap<ScrapedMod>(
      this as ScrapedMod,
    );
  }

  ScrapedModCopyWith<ScrapedMod, ScrapedMod, ScrapedMod> get copyWith =>
      _ScrapedModCopyWithImpl(this as ScrapedMod, $identity, $identity);
  @override
  String toString() {
    return ScrapedModMapper.ensureInitialized().stringifyValue(
      this as ScrapedMod,
    );
  }

  @override
  bool operator ==(Object other) {
    return ScrapedModMapper.ensureInitialized().equalsValue(
      this as ScrapedMod,
      other,
    );
  }

  @override
  int get hashCode {
    return ScrapedModMapper.ensureInitialized().hashValue(this as ScrapedMod);
  }
}

extension ScrapedModValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ScrapedMod, $Out> {
  ScrapedModCopyWith<$R, ScrapedMod, $Out> get $asScrapedMod =>
      $base.as((v, t, t2) => _ScrapedModCopyWithImpl(v, t, t2));
}

abstract class ScrapedModCopyWith<$R, $In extends ScrapedMod, $Out>
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
    ScrapedModImage,
    ScrapedModImageCopyWith<$R, ScrapedModImage, ScrapedModImage>
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
    Map<String, ScrapedModImage>? images,
    DateTime? dateTimeCreated,
    DateTime? dateTimeEdited,
  });
  ScrapedModCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ScrapedModCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ScrapedMod, $Out>
    implements ScrapedModCopyWith<$R, ScrapedMod, $Out> {
  _ScrapedModCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ScrapedMod> $mapper =
      ScrapedModMapper.ensureInitialized();
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>?
  get authorsList =>
      $value.authorsList != null
          ? ListCopyWith(
            $value.authorsList!,
            (v, t) => ObjectCopyWith(v, $identity, t),
            (v) => call(authorsList: v),
          )
          : null;
  @override
  MapCopyWith<$R, ModUrlType, String, ObjectCopyWith<$R, String, String>>?
  get urls =>
      $value.urls != null
          ? MapCopyWith(
            $value.urls!,
            (v, t) => ObjectCopyWith(v, $identity, t),
            (v) => call(urls: v),
          )
          : null;
  @override
  ListCopyWith<$R, ModSource, ObjectCopyWith<$R, ModSource, ModSource>>?
  get sources =>
      $value.sources != null
          ? ListCopyWith(
            $value.sources!,
            (v, t) => ObjectCopyWith(v, $identity, t),
            (v) => call(sources: v),
          )
          : null;
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>?
  get categories =>
      $value.categories != null
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
    ScrapedModImage,
    ScrapedModImageCopyWith<$R, ScrapedModImage, ScrapedModImage>
  >?
  get images =>
      $value.images != null
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
    }),
  );
  @override
  ScrapedMod $make(CopyWithData data) => ScrapedMod(
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
  );

  @override
  ScrapedModCopyWith<$R2, ScrapedMod, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ScrapedModCopyWithImpl($value, $cast, t);
}

class ScrapedModImageMapper extends ClassMapperBase<ScrapedModImage> {
  ScrapedModImageMapper._();

  static ScrapedModImageMapper? _instance;
  static ScrapedModImageMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ScrapedModImageMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'ScrapedModImage';

  static String _$id(ScrapedModImage v) => v.id;
  static const Field<ScrapedModImage, String> _f$id = Field('id', _$id);
  static String? _$filename(ScrapedModImage v) => v.filename;
  static const Field<ScrapedModImage, String> _f$filename = Field(
    'filename',
    _$filename,
    opt: true,
  );
  static String? _$description(ScrapedModImage v) => v.description;
  static const Field<ScrapedModImage, String> _f$description = Field(
    'description',
    _$description,
    opt: true,
  );
  static String? _$contentType(ScrapedModImage v) => v.contentType;
  static const Field<ScrapedModImage, String> _f$contentType = Field(
    'contentType',
    _$contentType,
    opt: true,
  );
  static int? _$size(ScrapedModImage v) => v.size;
  static const Field<ScrapedModImage, int> _f$size = Field(
    'size',
    _$size,
    opt: true,
  );
  static String? _$url(ScrapedModImage v) => v.url;
  static const Field<ScrapedModImage, String> _f$url = Field(
    'url',
    _$url,
    opt: true,
  );
  static String? _$proxyUrl(ScrapedModImage v) => v.proxyUrl;
  static const Field<ScrapedModImage, String> _f$proxyUrl = Field(
    'proxyUrl',
    _$proxyUrl,
    opt: true,
  );

  @override
  final MappableFields<ScrapedModImage> fields = const {
    #id: _f$id,
    #filename: _f$filename,
    #description: _f$description,
    #contentType: _f$contentType,
    #size: _f$size,
    #url: _f$url,
    #proxyUrl: _f$proxyUrl,
  };

  static ScrapedModImage _instantiate(DecodingData data) {
    return ScrapedModImage(
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

  static ScrapedModImage fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ScrapedModImage>(map);
  }

  static ScrapedModImage fromJson(String json) {
    return ensureInitialized().decodeJson<ScrapedModImage>(json);
  }
}

mixin ScrapedModImageMappable {
  String toJson() {
    return ScrapedModImageMapper.ensureInitialized()
        .encodeJson<ScrapedModImage>(this as ScrapedModImage);
  }

  Map<String, dynamic> toMap() {
    return ScrapedModImageMapper.ensureInitialized().encodeMap<ScrapedModImage>(
      this as ScrapedModImage,
    );
  }

  ScrapedModImageCopyWith<ScrapedModImage, ScrapedModImage, ScrapedModImage>
  get copyWith => _ScrapedModImageCopyWithImpl(
    this as ScrapedModImage,
    $identity,
    $identity,
  );
  @override
  String toString() {
    return ScrapedModImageMapper.ensureInitialized().stringifyValue(
      this as ScrapedModImage,
    );
  }

  @override
  bool operator ==(Object other) {
    return ScrapedModImageMapper.ensureInitialized().equalsValue(
      this as ScrapedModImage,
      other,
    );
  }

  @override
  int get hashCode {
    return ScrapedModImageMapper.ensureInitialized().hashValue(
      this as ScrapedModImage,
    );
  }
}

extension ScrapedModImageValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ScrapedModImage, $Out> {
  ScrapedModImageCopyWith<$R, ScrapedModImage, $Out> get $asScrapedModImage =>
      $base.as((v, t, t2) => _ScrapedModImageCopyWithImpl(v, t, t2));
}

abstract class ScrapedModImageCopyWith<$R, $In extends ScrapedModImage, $Out>
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
  ScrapedModImageCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _ScrapedModImageCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ScrapedModImage, $Out>
    implements ScrapedModImageCopyWith<$R, ScrapedModImage, $Out> {
  _ScrapedModImageCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ScrapedModImage> $mapper =
      ScrapedModImageMapper.ensureInitialized();
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
  ScrapedModImage $make(CopyWithData data) => ScrapedModImage(
    id: data.get(#id, or: $value.id),
    filename: data.get(#filename, or: $value.filename),
    description: data.get(#description, or: $value.description),
    contentType: data.get(#contentType, or: $value.contentType),
    size: data.get(#size, or: $value.size),
    url: data.get(#url, or: $value.url),
    proxyUrl: data.get(#proxyUrl, or: $value.proxyUrl),
  );

  @override
  ScrapedModImageCopyWith<$R2, ScrapedModImage, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ScrapedModImageCopyWithImpl($value, $cast, t);
}
