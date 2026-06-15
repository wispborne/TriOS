// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'forum_mod_details.dart';

class ForumModDetailsMapper extends ClassMapperBase<ForumModDetails> {
  ForumModDetailsMapper._();

  static ForumModDetailsMapper? _instance;
  static ForumModDetailsMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ForumModDetailsMapper._());
      ForumLinkMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ForumModDetails';

  static int _$topicId(ForumModDetails v) => v.topicId;
  static const Field<ForumModDetails, int> _f$topicId = Field(
    'topicId',
    _$topicId,
  );
  static String _$title(ForumModDetails v) => v.title;
  static const Field<ForumModDetails, String> _f$title = Field(
    'title',
    _$title,
  );
  static String? _$category(ForumModDetails v) => v.category;
  static const Field<ForumModDetails, String> _f$category = Field(
    'category',
    _$category,
    opt: true,
  );
  static String? _$gameVersion(ForumModDetails v) => v.gameVersion;
  static const Field<ForumModDetails, String> _f$gameVersion = Field(
    'gameVersion',
    _$gameVersion,
    opt: true,
  );
  static String _$author(ForumModDetails v) => v.author;
  static const Field<ForumModDetails, String> _f$author = Field(
    'author',
    _$author,
  );
  static String? _$authorTitle(ForumModDetails v) => v.authorTitle;
  static const Field<ForumModDetails, String> _f$authorTitle = Field(
    'authorTitle',
    _$authorTitle,
    opt: true,
  );
  static int? _$authorPostCount(ForumModDetails v) => v.authorPostCount;
  static const Field<ForumModDetails, int> _f$authorPostCount = Field(
    'authorPostCount',
    _$authorPostCount,
    opt: true,
  );
  static String? _$authorAvatarPath(ForumModDetails v) => v.authorAvatarPath;
  static const Field<ForumModDetails, String> _f$authorAvatarPath = Field(
    'authorAvatarPath',
    _$authorAvatarPath,
    opt: true,
  );
  static DateTime? _$postDate(ForumModDetails v) => v.postDate;
  static const Field<ForumModDetails, DateTime> _f$postDate = Field(
    'postDate',
    _$postDate,
    opt: true,
    hook: ForumDateHook(),
  );
  static DateTime? _$lastEditDate(ForumModDetails v) => v.lastEditDate;
  static const Field<ForumModDetails, DateTime> _f$lastEditDate = Field(
    'lastEditDate',
    _$lastEditDate,
    opt: true,
    hook: ForumDateHook(),
  );
  static String _$contentHtml(ForumModDetails v) => v.contentHtml;
  static const Field<ForumModDetails, String> _f$contentHtml = Field(
    'contentHtml',
    _$contentHtml,
  );
  static List<String>? _$images(ForumModDetails v) => v.images;
  static const Field<ForumModDetails, List<String>> _f$images = Field(
    'images',
    _$images,
    opt: true,
  );
  static List<ForumLink>? _$links(ForumModDetails v) => v.links;
  static const Field<ForumModDetails, List<ForumLink>> _f$links = Field(
    'links',
    _$links,
    opt: true,
  );
  static DateTime? _$scrapedAt(ForumModDetails v) => v.scrapedAt;
  static const Field<ForumModDetails, DateTime> _f$scrapedAt = Field(
    'scrapedAt',
    _$scrapedAt,
    opt: true,
  );
  static bool _$isPlaceholderDetail(ForumModDetails v) => v.isPlaceholderDetail;
  static const Field<ForumModDetails, bool> _f$isPlaceholderDetail = Field(
    'isPlaceholderDetail',
    _$isPlaceholderDetail,
  );

  @override
  final MappableFields<ForumModDetails> fields = const {
    #topicId: _f$topicId,
    #title: _f$title,
    #category: _f$category,
    #gameVersion: _f$gameVersion,
    #author: _f$author,
    #authorTitle: _f$authorTitle,
    #authorPostCount: _f$authorPostCount,
    #authorAvatarPath: _f$authorAvatarPath,
    #postDate: _f$postDate,
    #lastEditDate: _f$lastEditDate,
    #contentHtml: _f$contentHtml,
    #images: _f$images,
    #links: _f$links,
    #scrapedAt: _f$scrapedAt,
    #isPlaceholderDetail: _f$isPlaceholderDetail,
  };

  static ForumModDetails _instantiate(DecodingData data) {
    return ForumModDetails(
      topicId: data.dec(_f$topicId),
      title: data.dec(_f$title),
      category: data.dec(_f$category),
      gameVersion: data.dec(_f$gameVersion),
      author: data.dec(_f$author),
      authorTitle: data.dec(_f$authorTitle),
      authorPostCount: data.dec(_f$authorPostCount),
      authorAvatarPath: data.dec(_f$authorAvatarPath),
      postDate: data.dec(_f$postDate),
      lastEditDate: data.dec(_f$lastEditDate),
      contentHtml: data.dec(_f$contentHtml),
      images: data.dec(_f$images),
      links: data.dec(_f$links),
      scrapedAt: data.dec(_f$scrapedAt),
      isPlaceholderDetail: data.dec(_f$isPlaceholderDetail),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ForumModDetails fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ForumModDetails>(map);
  }

  static ForumModDetails fromJson(String json) {
    return ensureInitialized().decodeJson<ForumModDetails>(json);
  }
}

mixin ForumModDetailsMappable {
  String toJson() {
    return ForumModDetailsMapper.ensureInitialized()
        .encodeJson<ForumModDetails>(this as ForumModDetails);
  }

  Map<String, dynamic> toMap() {
    return ForumModDetailsMapper.ensureInitialized().encodeMap<ForumModDetails>(
      this as ForumModDetails,
    );
  }

  ForumModDetailsCopyWith<ForumModDetails, ForumModDetails, ForumModDetails>
  get copyWith =>
      _ForumModDetailsCopyWithImpl<ForumModDetails, ForumModDetails>(
        this as ForumModDetails,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return ForumModDetailsMapper.ensureInitialized().stringifyValue(
      this as ForumModDetails,
    );
  }

  @override
  bool operator ==(Object other) {
    return ForumModDetailsMapper.ensureInitialized().equalsValue(
      this as ForumModDetails,
      other,
    );
  }

  @override
  int get hashCode {
    return ForumModDetailsMapper.ensureInitialized().hashValue(
      this as ForumModDetails,
    );
  }
}

extension ForumModDetailsValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ForumModDetails, $Out> {
  ForumModDetailsCopyWith<$R, ForumModDetails, $Out> get $asForumModDetails =>
      $base.as((v, t, t2) => _ForumModDetailsCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ForumModDetailsCopyWith<$R, $In extends ForumModDetails, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>? get images;
  ListCopyWith<$R, ForumLink, ForumLinkCopyWith<$R, ForumLink, ForumLink>>?
  get links;
  $R call({
    int? topicId,
    String? title,
    String? category,
    String? gameVersion,
    String? author,
    String? authorTitle,
    int? authorPostCount,
    String? authorAvatarPath,
    DateTime? postDate,
    DateTime? lastEditDate,
    String? contentHtml,
    List<String>? images,
    List<ForumLink>? links,
    DateTime? scrapedAt,
    bool? isPlaceholderDetail,
  });
  ForumModDetailsCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _ForumModDetailsCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ForumModDetails, $Out>
    implements ForumModDetailsCopyWith<$R, ForumModDetails, $Out> {
  _ForumModDetailsCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ForumModDetails> $mapper =
      ForumModDetailsMapper.ensureInitialized();
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>? get images =>
      $value.images != null
      ? ListCopyWith(
          $value.images!,
          (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(images: v),
        )
      : null;
  @override
  ListCopyWith<$R, ForumLink, ForumLinkCopyWith<$R, ForumLink, ForumLink>>?
  get links => $value.links != null
      ? ListCopyWith(
          $value.links!,
          (v, t) => v.copyWith.$chain(t),
          (v) => call(links: v),
        )
      : null;
  @override
  $R call({
    int? topicId,
    String? title,
    Object? category = $none,
    Object? gameVersion = $none,
    String? author,
    Object? authorTitle = $none,
    Object? authorPostCount = $none,
    Object? authorAvatarPath = $none,
    Object? postDate = $none,
    Object? lastEditDate = $none,
    String? contentHtml,
    Object? images = $none,
    Object? links = $none,
    Object? scrapedAt = $none,
    bool? isPlaceholderDetail,
  }) => $apply(
    FieldCopyWithData({
      if (topicId != null) #topicId: topicId,
      if (title != null) #title: title,
      if (category != $none) #category: category,
      if (gameVersion != $none) #gameVersion: gameVersion,
      if (author != null) #author: author,
      if (authorTitle != $none) #authorTitle: authorTitle,
      if (authorPostCount != $none) #authorPostCount: authorPostCount,
      if (authorAvatarPath != $none) #authorAvatarPath: authorAvatarPath,
      if (postDate != $none) #postDate: postDate,
      if (lastEditDate != $none) #lastEditDate: lastEditDate,
      if (contentHtml != null) #contentHtml: contentHtml,
      if (images != $none) #images: images,
      if (links != $none) #links: links,
      if (scrapedAt != $none) #scrapedAt: scrapedAt,
      if (isPlaceholderDetail != null)
        #isPlaceholderDetail: isPlaceholderDetail,
    }),
  );
  @override
  ForumModDetails $make(CopyWithData data) => ForumModDetails(
    topicId: data.get(#topicId, or: $value.topicId),
    title: data.get(#title, or: $value.title),
    category: data.get(#category, or: $value.category),
    gameVersion: data.get(#gameVersion, or: $value.gameVersion),
    author: data.get(#author, or: $value.author),
    authorTitle: data.get(#authorTitle, or: $value.authorTitle),
    authorPostCount: data.get(#authorPostCount, or: $value.authorPostCount),
    authorAvatarPath: data.get(#authorAvatarPath, or: $value.authorAvatarPath),
    postDate: data.get(#postDate, or: $value.postDate),
    lastEditDate: data.get(#lastEditDate, or: $value.lastEditDate),
    contentHtml: data.get(#contentHtml, or: $value.contentHtml),
    images: data.get(#images, or: $value.images),
    links: data.get(#links, or: $value.links),
    scrapedAt: data.get(#scrapedAt, or: $value.scrapedAt),
    isPlaceholderDetail: data.get(
      #isPlaceholderDetail,
      or: $value.isPlaceholderDetail,
    ),
  );

  @override
  ForumModDetailsCopyWith<$R2, ForumModDetails, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ForumModDetailsCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

