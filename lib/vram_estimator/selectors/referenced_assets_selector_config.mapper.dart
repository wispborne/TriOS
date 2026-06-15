// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'referenced_assets_selector_config.dart';

class ReferencedAssetsSelectorConfigMapper
    extends ClassMapperBase<ReferencedAssetsSelectorConfig> {
  ReferencedAssetsSelectorConfigMapper._();

  static ReferencedAssetsSelectorConfigMapper? _instance;
  static ReferencedAssetsSelectorConfigMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(
        _instance = ReferencedAssetsSelectorConfigMapper._(),
      );
    }
    return _instance!;
  }

  @override
  final String id = 'ReferencedAssetsSelectorConfig';

  static Set<String> _$enabledParserIds(ReferencedAssetsSelectorConfig v) =>
      v.enabledParserIds;
  static const Field<ReferencedAssetsSelectorConfig, Set<String>>
  _f$enabledParserIds = Field('enabledParserIds', _$enabledParserIds);
  static bool _$suppressUnreferenced(ReferencedAssetsSelectorConfig v) =>
      v.suppressUnreferenced;
  static const Field<ReferencedAssetsSelectorConfig, bool>
  _f$suppressUnreferenced = Field(
    'suppressUnreferenced',
    _$suppressUnreferenced,
    opt: true,
    def: false,
  );

  @override
  final MappableFields<ReferencedAssetsSelectorConfig> fields = const {
    #enabledParserIds: _f$enabledParserIds,
    #suppressUnreferenced: _f$suppressUnreferenced,
  };

  static ReferencedAssetsSelectorConfig _instantiate(DecodingData data) {
    return ReferencedAssetsSelectorConfig(
      enabledParserIds: data.dec(_f$enabledParserIds),
      suppressUnreferenced: data.dec(_f$suppressUnreferenced),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ReferencedAssetsSelectorConfig fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ReferencedAssetsSelectorConfig>(map);
  }

  static ReferencedAssetsSelectorConfig fromJson(String json) {
    return ensureInitialized().decodeJson<ReferencedAssetsSelectorConfig>(json);
  }
}

mixin ReferencedAssetsSelectorConfigMappable {
  String toJson() {
    return ReferencedAssetsSelectorConfigMapper.ensureInitialized()
        .encodeJson<ReferencedAssetsSelectorConfig>(
          this as ReferencedAssetsSelectorConfig,
        );
  }

  Map<String, dynamic> toMap() {
    return ReferencedAssetsSelectorConfigMapper.ensureInitialized()
        .encodeMap<ReferencedAssetsSelectorConfig>(
          this as ReferencedAssetsSelectorConfig,
        );
  }

  ReferencedAssetsSelectorConfigCopyWith<
    ReferencedAssetsSelectorConfig,
    ReferencedAssetsSelectorConfig,
    ReferencedAssetsSelectorConfig
  >
  get copyWith =>
      _ReferencedAssetsSelectorConfigCopyWithImpl<
        ReferencedAssetsSelectorConfig,
        ReferencedAssetsSelectorConfig
      >(this as ReferencedAssetsSelectorConfig, $identity, $identity);
  @override
  String toString() {
    return ReferencedAssetsSelectorConfigMapper.ensureInitialized()
        .stringifyValue(this as ReferencedAssetsSelectorConfig);
  }

  @override
  bool operator ==(Object other) {
    return ReferencedAssetsSelectorConfigMapper.ensureInitialized().equalsValue(
      this as ReferencedAssetsSelectorConfig,
      other,
    );
  }

  @override
  int get hashCode {
    return ReferencedAssetsSelectorConfigMapper.ensureInitialized().hashValue(
      this as ReferencedAssetsSelectorConfig,
    );
  }
}

extension ReferencedAssetsSelectorConfigValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ReferencedAssetsSelectorConfig, $Out> {
  ReferencedAssetsSelectorConfigCopyWith<
    $R,
    ReferencedAssetsSelectorConfig,
    $Out
  >
  get $asReferencedAssetsSelectorConfig => $base.as(
    (v, t, t2) =>
        _ReferencedAssetsSelectorConfigCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class ReferencedAssetsSelectorConfigCopyWith<
  $R,
  $In extends ReferencedAssetsSelectorConfig,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({Set<String>? enabledParserIds, bool? suppressUnreferenced});
  ReferencedAssetsSelectorConfigCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _ReferencedAssetsSelectorConfigCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ReferencedAssetsSelectorConfig, $Out>
    implements
        ReferencedAssetsSelectorConfigCopyWith<
          $R,
          ReferencedAssetsSelectorConfig,
          $Out
        > {
  _ReferencedAssetsSelectorConfigCopyWithImpl(
    super.value,
    super.then,
    super.then2,
  );

  @override
  late final ClassMapperBase<ReferencedAssetsSelectorConfig> $mapper =
      ReferencedAssetsSelectorConfigMapper.ensureInitialized();
  @override
  $R call({Set<String>? enabledParserIds, bool? suppressUnreferenced}) =>
      $apply(
        FieldCopyWithData({
          if (enabledParserIds != null) #enabledParserIds: enabledParserIds,
          if (suppressUnreferenced != null)
            #suppressUnreferenced: suppressUnreferenced,
        }),
      );
  @override
  ReferencedAssetsSelectorConfig $make(CopyWithData data) =>
      ReferencedAssetsSelectorConfig(
        enabledParserIds: data.get(
          #enabledParserIds,
          or: $value.enabledParserIds,
        ),
        suppressUnreferenced: data.get(
          #suppressUnreferenced,
          or: $value.suppressUnreferenced,
        ),
      );

  @override
  ReferencedAssetsSelectorConfigCopyWith<
    $R2,
    ReferencedAssetsSelectorConfig,
    $Out2
  >
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _ReferencedAssetsSelectorConfigCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

