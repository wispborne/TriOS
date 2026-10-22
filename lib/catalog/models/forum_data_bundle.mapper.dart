// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'forum_data_bundle.dart';

class ForumDataBundleMapper extends ClassMapperBase<ForumDataBundle> {
  ForumDataBundleMapper._();

  static ForumDataBundleMapper? _instance;
  static ForumDataBundleMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ForumDataBundleMapper._());
      ForumModIndexMapper.ensureInitialized();
      DiscordThreadAnswerMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ForumDataBundle';

  static DateTime _$updatedAt(ForumDataBundle v) => v.updatedAt;
  static const Field<ForumDataBundle, DateTime> _f$updatedAt = Field(
    'updatedAt',
    _$updatedAt,
  );
  static List<ForumModIndex> _$index(ForumDataBundle v) => v.index;
  static const Field<ForumDataBundle, List<ForumModIndex>> _f$index = Field(
    'index',
    _$index,
  );
  static List<DiscordThreadAnswer> _$discordThreads(ForumDataBundle v) =>
      v.discordThreads;
  static const Field<ForumDataBundle, List<DiscordThreadAnswer>>
  _f$discordThreads = Field(
    'discordThreads',
    _$discordThreads,
    opt: true,
    def: const [],
  );

  @override
  final MappableFields<ForumDataBundle> fields = const {
    #updatedAt: _f$updatedAt,
    #index: _f$index,
    #discordThreads: _f$discordThreads,
  };

  static ForumDataBundle _instantiate(DecodingData data) {
    return ForumDataBundle(
      updatedAt: data.dec(_f$updatedAt),
      index: data.dec(_f$index),
      discordThreads: data.dec(_f$discordThreads),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ForumDataBundle fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ForumDataBundle>(map);
  }

  static ForumDataBundle fromJson(String json) {
    return ensureInitialized().decodeJson<ForumDataBundle>(json);
  }
}

mixin ForumDataBundleMappable {
  String toJson() {
    return ForumDataBundleMapper.ensureInitialized()
        .encodeJson<ForumDataBundle>(this as ForumDataBundle);
  }

  Map<String, dynamic> toMap() {
    return ForumDataBundleMapper.ensureInitialized().encodeMap<ForumDataBundle>(
      this as ForumDataBundle,
    );
  }

  ForumDataBundleCopyWith<ForumDataBundle, ForumDataBundle, ForumDataBundle>
  get copyWith =>
      _ForumDataBundleCopyWithImpl<ForumDataBundle, ForumDataBundle>(
        this as ForumDataBundle,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return ForumDataBundleMapper.ensureInitialized().stringifyValue(
      this as ForumDataBundle,
    );
  }

  @override
  bool operator ==(Object other) {
    return ForumDataBundleMapper.ensureInitialized().equalsValue(
      this as ForumDataBundle,
      other,
    );
  }

  @override
  int get hashCode {
    return ForumDataBundleMapper.ensureInitialized().hashValue(
      this as ForumDataBundle,
    );
  }
}

extension ForumDataBundleValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ForumDataBundle, $Out> {
  ForumDataBundleCopyWith<$R, ForumDataBundle, $Out> get $asForumDataBundle =>
      $base.as((v, t, t2) => _ForumDataBundleCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ForumDataBundleCopyWith<$R, $In extends ForumDataBundle, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<
    $R,
    ForumModIndex,
    ForumModIndexCopyWith<$R, ForumModIndex, ForumModIndex>
  >
  get index;
  ListCopyWith<
    $R,
    DiscordThreadAnswer,
    DiscordThreadAnswerCopyWith<$R, DiscordThreadAnswer, DiscordThreadAnswer>
  >
  get discordThreads;
  $R call({
    DateTime? updatedAt,
    List<ForumModIndex>? index,
    List<DiscordThreadAnswer>? discordThreads,
  });
  ForumDataBundleCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _ForumDataBundleCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ForumDataBundle, $Out>
    implements ForumDataBundleCopyWith<$R, ForumDataBundle, $Out> {
  _ForumDataBundleCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ForumDataBundle> $mapper =
      ForumDataBundleMapper.ensureInitialized();
  @override
  ListCopyWith<
    $R,
    ForumModIndex,
    ForumModIndexCopyWith<$R, ForumModIndex, ForumModIndex>
  >
  get index => ListCopyWith(
    $value.index,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(index: v),
  );
  @override
  ListCopyWith<
    $R,
    DiscordThreadAnswer,
    DiscordThreadAnswerCopyWith<$R, DiscordThreadAnswer, DiscordThreadAnswer>
  >
  get discordThreads => ListCopyWith(
    $value.discordThreads,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(discordThreads: v),
  );
  @override
  $R call({
    DateTime? updatedAt,
    List<ForumModIndex>? index,
    List<DiscordThreadAnswer>? discordThreads,
  }) => $apply(
    FieldCopyWithData({
      if (updatedAt != null) #updatedAt: updatedAt,
      if (index != null) #index: index,
      if (discordThreads != null) #discordThreads: discordThreads,
    }),
  );
  @override
  ForumDataBundle $make(CopyWithData data) => ForumDataBundle(
    updatedAt: data.get(#updatedAt, or: $value.updatedAt),
    index: data.get(#index, or: $value.index),
    discordThreads: data.get(#discordThreads, or: $value.discordThreads),
  );

  @override
  ForumDataBundleCopyWith<$R2, ForumDataBundle, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ForumDataBundleCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class DiscordThreadAnswerMapper extends ClassMapperBase<DiscordThreadAnswer> {
  DiscordThreadAnswerMapper._();

  static DiscordThreadAnswerMapper? _instance;
  static DiscordThreadAnswerMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = DiscordThreadAnswerMapper._());
      ForumLlmModMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'DiscordThreadAnswer';

  static String _$threadId(DiscordThreadAnswer v) => v.threadId;
  static const Field<DiscordThreadAnswer, String> _f$threadId = Field(
    'threadId',
    _$threadId,
  );
  static String _$url(DiscordThreadAnswer v) => v.url;
  static const Field<DiscordThreadAnswer, String> _f$url = Field('url', _$url);
  static String _$name(DiscordThreadAnswer v) => v.name;
  static const Field<DiscordThreadAnswer, String> _f$name = Field(
    'name',
    _$name,
  );
  static List<ForumLlmMod> _$mods(DiscordThreadAnswer v) => v.mods;
  static const Field<DiscordThreadAnswer, List<ForumLlmMod>> _f$mods = Field(
    'mods',
    _$mods,
    opt: true,
    def: const [],
  );

  @override
  final MappableFields<DiscordThreadAnswer> fields = const {
    #threadId: _f$threadId,
    #url: _f$url,
    #name: _f$name,
    #mods: _f$mods,
  };

  static DiscordThreadAnswer _instantiate(DecodingData data) {
    return DiscordThreadAnswer(
      threadId: data.dec(_f$threadId),
      url: data.dec(_f$url),
      name: data.dec(_f$name),
      mods: data.dec(_f$mods),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static DiscordThreadAnswer fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<DiscordThreadAnswer>(map);
  }

  static DiscordThreadAnswer fromJson(String json) {
    return ensureInitialized().decodeJson<DiscordThreadAnswer>(json);
  }
}

mixin DiscordThreadAnswerMappable {
  String toJson() {
    return DiscordThreadAnswerMapper.ensureInitialized()
        .encodeJson<DiscordThreadAnswer>(this as DiscordThreadAnswer);
  }

  Map<String, dynamic> toMap() {
    return DiscordThreadAnswerMapper.ensureInitialized()
        .encodeMap<DiscordThreadAnswer>(this as DiscordThreadAnswer);
  }

  DiscordThreadAnswerCopyWith<
    DiscordThreadAnswer,
    DiscordThreadAnswer,
    DiscordThreadAnswer
  >
  get copyWith =>
      _DiscordThreadAnswerCopyWithImpl<
        DiscordThreadAnswer,
        DiscordThreadAnswer
      >(this as DiscordThreadAnswer, $identity, $identity);
  @override
  String toString() {
    return DiscordThreadAnswerMapper.ensureInitialized().stringifyValue(
      this as DiscordThreadAnswer,
    );
  }

  @override
  bool operator ==(Object other) {
    return DiscordThreadAnswerMapper.ensureInitialized().equalsValue(
      this as DiscordThreadAnswer,
      other,
    );
  }

  @override
  int get hashCode {
    return DiscordThreadAnswerMapper.ensureInitialized().hashValue(
      this as DiscordThreadAnswer,
    );
  }
}

extension DiscordThreadAnswerValueCopy<$R, $Out>
    on ObjectCopyWith<$R, DiscordThreadAnswer, $Out> {
  DiscordThreadAnswerCopyWith<$R, DiscordThreadAnswer, $Out>
  get $asDiscordThreadAnswer => $base.as(
    (v, t, t2) => _DiscordThreadAnswerCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class DiscordThreadAnswerCopyWith<
  $R,
  $In extends DiscordThreadAnswer,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<
    $R,
    ForumLlmMod,
    ForumLlmModCopyWith<$R, ForumLlmMod, ForumLlmMod>
  >
  get mods;
  $R call({
    String? threadId,
    String? url,
    String? name,
    List<ForumLlmMod>? mods,
  });
  DiscordThreadAnswerCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _DiscordThreadAnswerCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, DiscordThreadAnswer, $Out>
    implements DiscordThreadAnswerCopyWith<$R, DiscordThreadAnswer, $Out> {
  _DiscordThreadAnswerCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<DiscordThreadAnswer> $mapper =
      DiscordThreadAnswerMapper.ensureInitialized();
  @override
  ListCopyWith<
    $R,
    ForumLlmMod,
    ForumLlmModCopyWith<$R, ForumLlmMod, ForumLlmMod>
  >
  get mods => ListCopyWith(
    $value.mods,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(mods: v),
  );
  @override
  $R call({
    String? threadId,
    String? url,
    String? name,
    List<ForumLlmMod>? mods,
  }) => $apply(
    FieldCopyWithData({
      if (threadId != null) #threadId: threadId,
      if (url != null) #url: url,
      if (name != null) #name: name,
      if (mods != null) #mods: mods,
    }),
  );
  @override
  DiscordThreadAnswer $make(CopyWithData data) => DiscordThreadAnswer(
    threadId: data.get(#threadId, or: $value.threadId),
    url: data.get(#url, or: $value.url),
    name: data.get(#name, or: $value.name),
    mods: data.get(#mods, or: $value.mods),
  );

  @override
  DiscordThreadAnswerCopyWith<$R2, DiscordThreadAnswer, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _DiscordThreadAnswerCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

