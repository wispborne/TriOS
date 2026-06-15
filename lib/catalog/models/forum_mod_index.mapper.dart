// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'forum_mod_index.dart';

class ForumModIndexMapper extends ClassMapperBase<ForumModIndex> {
  ForumModIndexMapper._();

  static ForumModIndexMapper? _instance;
  static ForumModIndexMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ForumModIndexMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'ForumModIndex';

  static int _$topicId(ForumModIndex v) => v.topicId;
  static const Field<ForumModIndex, int> _f$topicId = Field(
    'topicId',
    _$topicId,
  );
  static String _$title(ForumModIndex v) => v.title;
  static const Field<ForumModIndex, String> _f$title = Field('title', _$title);
  static String? _$category(ForumModIndex v) => v.category;
  static const Field<ForumModIndex, String> _f$category = Field(
    'category',
    _$category,
    opt: true,
  );
  static bool _$inModIndex(ForumModIndex v) => v.inModIndex;
  static const Field<ForumModIndex, bool> _f$inModIndex = Field(
    'inModIndex',
    _$inModIndex,
  );
  static bool _$isArchivedModIndex(ForumModIndex v) => v.isArchivedModIndex;
  static const Field<ForumModIndex, bool> _f$isArchivedModIndex = Field(
    'isArchivedModIndex',
    _$isArchivedModIndex,
  );
  static String? _$gameVersion(ForumModIndex v) => v.gameVersion;
  static const Field<ForumModIndex, String> _f$gameVersion = Field(
    'gameVersion',
    _$gameVersion,
    opt: true,
  );
  static String _$author(ForumModIndex v) => v.author;
  static const Field<ForumModIndex, String> _f$author = Field(
    'author',
    _$author,
  );
  static int _$replies(ForumModIndex v) => v.replies;
  static const Field<ForumModIndex, int> _f$replies = Field(
    'replies',
    _$replies,
  );
  static int _$views(ForumModIndex v) => v.views;
  static const Field<ForumModIndex, int> _f$views = Field('views', _$views);
  static DateTime? _$createdDate(ForumModIndex v) => v.createdDate;
  static const Field<ForumModIndex, DateTime> _f$createdDate = Field(
    'createdDate',
    _$createdDate,
    opt: true,
    hook: ForumDateHook(),
  );
  static DateTime? _$lastPostDate(ForumModIndex v) => v.lastPostDate;
  static const Field<ForumModIndex, DateTime> _f$lastPostDate = Field(
    'lastPostDate',
    _$lastPostDate,
    opt: true,
    hook: ForumDateHook(),
  );
  static String? _$lastPostBy(ForumModIndex v) => v.lastPostBy;
  static const Field<ForumModIndex, String> _f$lastPostBy = Field(
    'lastPostBy',
    _$lastPostBy,
    opt: true,
  );
  static String _$topicUrl(ForumModIndex v) => v.topicUrl;
  static const Field<ForumModIndex, String> _f$topicUrl = Field(
    'topicUrl',
    _$topicUrl,
  );
  static String? _$thumbnailPath(ForumModIndex v) => v.thumbnailPath;
  static const Field<ForumModIndex, String> _f$thumbnailPath = Field(
    'thumbnailPath',
    _$thumbnailPath,
    opt: true,
  );
  static DateTime? _$scrapedAt(ForumModIndex v) => v.scrapedAt;
  static const Field<ForumModIndex, DateTime> _f$scrapedAt = Field(
    'scrapedAt',
    _$scrapedAt,
    opt: true,
  );
  static bool _$isWip(ForumModIndex v) => v.isWip;
  static const Field<ForumModIndex, bool> _f$isWip = Field('isWip', _$isWip);
  static int? _$sourceBoard(ForumModIndex v) => v.sourceBoard;
  static const Field<ForumModIndex, int> _f$sourceBoard = Field(
    'sourceBoard',
    _$sourceBoard,
    opt: true,
  );

  @override
  final MappableFields<ForumModIndex> fields = const {
    #topicId: _f$topicId,
    #title: _f$title,
    #category: _f$category,
    #inModIndex: _f$inModIndex,
    #isArchivedModIndex: _f$isArchivedModIndex,
    #gameVersion: _f$gameVersion,
    #author: _f$author,
    #replies: _f$replies,
    #views: _f$views,
    #createdDate: _f$createdDate,
    #lastPostDate: _f$lastPostDate,
    #lastPostBy: _f$lastPostBy,
    #topicUrl: _f$topicUrl,
    #thumbnailPath: _f$thumbnailPath,
    #scrapedAt: _f$scrapedAt,
    #isWip: _f$isWip,
    #sourceBoard: _f$sourceBoard,
  };

  static ForumModIndex _instantiate(DecodingData data) {
    return ForumModIndex(
      topicId: data.dec(_f$topicId),
      title: data.dec(_f$title),
      category: data.dec(_f$category),
      inModIndex: data.dec(_f$inModIndex),
      isArchivedModIndex: data.dec(_f$isArchivedModIndex),
      gameVersion: data.dec(_f$gameVersion),
      author: data.dec(_f$author),
      replies: data.dec(_f$replies),
      views: data.dec(_f$views),
      createdDate: data.dec(_f$createdDate),
      lastPostDate: data.dec(_f$lastPostDate),
      lastPostBy: data.dec(_f$lastPostBy),
      topicUrl: data.dec(_f$topicUrl),
      thumbnailPath: data.dec(_f$thumbnailPath),
      scrapedAt: data.dec(_f$scrapedAt),
      isWip: data.dec(_f$isWip),
      sourceBoard: data.dec(_f$sourceBoard),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ForumModIndex fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ForumModIndex>(map);
  }

  static ForumModIndex fromJson(String json) {
    return ensureInitialized().decodeJson<ForumModIndex>(json);
  }
}

mixin ForumModIndexMappable {
  String toJson() {
    return ForumModIndexMapper.ensureInitialized().encodeJson<ForumModIndex>(
      this as ForumModIndex,
    );
  }

  Map<String, dynamic> toMap() {
    return ForumModIndexMapper.ensureInitialized().encodeMap<ForumModIndex>(
      this as ForumModIndex,
    );
  }

  ForumModIndexCopyWith<ForumModIndex, ForumModIndex, ForumModIndex>
  get copyWith => _ForumModIndexCopyWithImpl<ForumModIndex, ForumModIndex>(
    this as ForumModIndex,
    $identity,
    $identity,
  );
  @override
  String toString() {
    return ForumModIndexMapper.ensureInitialized().stringifyValue(
      this as ForumModIndex,
    );
  }

  @override
  bool operator ==(Object other) {
    return ForumModIndexMapper.ensureInitialized().equalsValue(
      this as ForumModIndex,
      other,
    );
  }

  @override
  int get hashCode {
    return ForumModIndexMapper.ensureInitialized().hashValue(
      this as ForumModIndex,
    );
  }
}

extension ForumModIndexValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ForumModIndex, $Out> {
  ForumModIndexCopyWith<$R, ForumModIndex, $Out> get $asForumModIndex =>
      $base.as((v, t, t2) => _ForumModIndexCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ForumModIndexCopyWith<$R, $In extends ForumModIndex, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    int? topicId,
    String? title,
    String? category,
    bool? inModIndex,
    bool? isArchivedModIndex,
    String? gameVersion,
    String? author,
    int? replies,
    int? views,
    DateTime? createdDate,
    DateTime? lastPostDate,
    String? lastPostBy,
    String? topicUrl,
    String? thumbnailPath,
    DateTime? scrapedAt,
    bool? isWip,
    int? sourceBoard,
  });
  ForumModIndexCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ForumModIndexCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ForumModIndex, $Out>
    implements ForumModIndexCopyWith<$R, ForumModIndex, $Out> {
  _ForumModIndexCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ForumModIndex> $mapper =
      ForumModIndexMapper.ensureInitialized();
  @override
  $R call({
    int? topicId,
    String? title,
    Object? category = $none,
    bool? inModIndex,
    bool? isArchivedModIndex,
    Object? gameVersion = $none,
    String? author,
    int? replies,
    int? views,
    Object? createdDate = $none,
    Object? lastPostDate = $none,
    Object? lastPostBy = $none,
    String? topicUrl,
    Object? thumbnailPath = $none,
    Object? scrapedAt = $none,
    bool? isWip,
    Object? sourceBoard = $none,
  }) => $apply(
    FieldCopyWithData({
      if (topicId != null) #topicId: topicId,
      if (title != null) #title: title,
      if (category != $none) #category: category,
      if (inModIndex != null) #inModIndex: inModIndex,
      if (isArchivedModIndex != null) #isArchivedModIndex: isArchivedModIndex,
      if (gameVersion != $none) #gameVersion: gameVersion,
      if (author != null) #author: author,
      if (replies != null) #replies: replies,
      if (views != null) #views: views,
      if (createdDate != $none) #createdDate: createdDate,
      if (lastPostDate != $none) #lastPostDate: lastPostDate,
      if (lastPostBy != $none) #lastPostBy: lastPostBy,
      if (topicUrl != null) #topicUrl: topicUrl,
      if (thumbnailPath != $none) #thumbnailPath: thumbnailPath,
      if (scrapedAt != $none) #scrapedAt: scrapedAt,
      if (isWip != null) #isWip: isWip,
      if (sourceBoard != $none) #sourceBoard: sourceBoard,
    }),
  );
  @override
  ForumModIndex $make(CopyWithData data) => ForumModIndex(
    topicId: data.get(#topicId, or: $value.topicId),
    title: data.get(#title, or: $value.title),
    category: data.get(#category, or: $value.category),
    inModIndex: data.get(#inModIndex, or: $value.inModIndex),
    isArchivedModIndex: data.get(
      #isArchivedModIndex,
      or: $value.isArchivedModIndex,
    ),
    gameVersion: data.get(#gameVersion, or: $value.gameVersion),
    author: data.get(#author, or: $value.author),
    replies: data.get(#replies, or: $value.replies),
    views: data.get(#views, or: $value.views),
    createdDate: data.get(#createdDate, or: $value.createdDate),
    lastPostDate: data.get(#lastPostDate, or: $value.lastPostDate),
    lastPostBy: data.get(#lastPostBy, or: $value.lastPostBy),
    topicUrl: data.get(#topicUrl, or: $value.topicUrl),
    thumbnailPath: data.get(#thumbnailPath, or: $value.thumbnailPath),
    scrapedAt: data.get(#scrapedAt, or: $value.scrapedAt),
    isWip: data.get(#isWip, or: $value.isWip),
    sourceBoard: data.get(#sourceBoard, or: $value.sourceBoard),
  );

  @override
  ForumModIndexCopyWith<$R2, ForumModIndex, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ForumModIndexCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

