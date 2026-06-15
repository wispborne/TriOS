// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'forum_link.dart';

class ForumLinkMapper extends ClassMapperBase<ForumLink> {
  ForumLinkMapper._();

  static ForumLinkMapper? _instance;
  static ForumLinkMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ForumLinkMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'ForumLink';

  static String _$url(ForumLink v) => v.url;
  static const Field<ForumLink, String> _f$url = Field('url', _$url);
  static String _$text(ForumLink v) => v.text;
  static const Field<ForumLink, String> _f$text = Field(
    'text',
    _$text,
    opt: true,
    def: '',
  );
  static bool _$isExternal(ForumLink v) => v.isExternal;
  static const Field<ForumLink, bool> _f$isExternal = Field(
    'isExternal',
    _$isExternal,
    opt: true,
    def: false,
  );
  static bool _$isDownloadable(ForumLink v) => v.isDownloadable;
  static const Field<ForumLink, bool> _f$isDownloadable = Field(
    'isDownloadable',
    _$isDownloadable,
    opt: true,
    def: false,
  );

  @override
  final MappableFields<ForumLink> fields = const {
    #url: _f$url,
    #text: _f$text,
    #isExternal: _f$isExternal,
    #isDownloadable: _f$isDownloadable,
  };

  static ForumLink _instantiate(DecodingData data) {
    return ForumLink(
      url: data.dec(_f$url),
      text: data.dec(_f$text),
      isExternal: data.dec(_f$isExternal),
      isDownloadable: data.dec(_f$isDownloadable),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ForumLink fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ForumLink>(map);
  }

  static ForumLink fromJson(String json) {
    return ensureInitialized().decodeJson<ForumLink>(json);
  }
}

mixin ForumLinkMappable {
  String toJson() {
    return ForumLinkMapper.ensureInitialized().encodeJson<ForumLink>(
      this as ForumLink,
    );
  }

  Map<String, dynamic> toMap() {
    return ForumLinkMapper.ensureInitialized().encodeMap<ForumLink>(
      this as ForumLink,
    );
  }

  ForumLinkCopyWith<ForumLink, ForumLink, ForumLink> get copyWith =>
      _ForumLinkCopyWithImpl<ForumLink, ForumLink>(
        this as ForumLink,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return ForumLinkMapper.ensureInitialized().stringifyValue(
      this as ForumLink,
    );
  }

  @override
  bool operator ==(Object other) {
    return ForumLinkMapper.ensureInitialized().equalsValue(
      this as ForumLink,
      other,
    );
  }

  @override
  int get hashCode {
    return ForumLinkMapper.ensureInitialized().hashValue(this as ForumLink);
  }
}

extension ForumLinkValueCopy<$R, $Out> on ObjectCopyWith<$R, ForumLink, $Out> {
  ForumLinkCopyWith<$R, ForumLink, $Out> get $asForumLink =>
      $base.as((v, t, t2) => _ForumLinkCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ForumLinkCopyWith<$R, $In extends ForumLink, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({String? url, String? text, bool? isExternal, bool? isDownloadable});
  ForumLinkCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ForumLinkCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ForumLink, $Out>
    implements ForumLinkCopyWith<$R, ForumLink, $Out> {
  _ForumLinkCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ForumLink> $mapper =
      ForumLinkMapper.ensureInitialized();
  @override
  $R call({
    String? url,
    String? text,
    bool? isExternal,
    bool? isDownloadable,
  }) => $apply(
    FieldCopyWithData({
      if (url != null) #url: url,
      if (text != null) #text: text,
      if (isExternal != null) #isExternal: isExternal,
      if (isDownloadable != null) #isDownloadable: isDownloadable,
    }),
  );
  @override
  ForumLink $make(CopyWithData data) => ForumLink(
    url: data.get(#url, or: $value.url),
    text: data.get(#text, or: $value.text),
    isExternal: data.get(#isExternal, or: $value.isExternal),
    isDownloadable: data.get(#isDownloadable, or: $value.isDownloadable),
  );

  @override
  ForumLinkCopyWith<$R2, ForumLink, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ForumLinkCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

