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

  @override
  final MappableFields<ForumDataBundle> fields = const {
    #updatedAt: _f$updatedAt,
    #index: _f$index,
  };

  static ForumDataBundle _instantiate(DecodingData data) {
    return ForumDataBundle(
      updatedAt: data.dec(_f$updatedAt),
      index: data.dec(_f$index),
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
  $R call({DateTime? updatedAt, List<ForumModIndex>? index});
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
  $R call({DateTime? updatedAt, List<ForumModIndex>? index}) => $apply(
    FieldCopyWithData({
      if (updatedAt != null) #updatedAt: updatedAt,
      if (index != null) #index: index,
    }),
  );
  @override
  ForumDataBundle $make(CopyWithData data) => ForumDataBundle(
    updatedAt: data.get(#updatedAt, or: $value.updatedAt),
    index: data.get(#index, or: $value.index),
  );

  @override
  ForumDataBundleCopyWith<$R2, ForumDataBundle, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ForumDataBundleCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

