// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'portrait_metadata.dart';

class FactionInfoMapper extends ClassMapperBase<FactionInfo> {
  FactionInfoMapper._();

  static FactionInfoMapper? _instance;
  static FactionInfoMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = FactionInfoMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'FactionInfo';

  static String _$id(FactionInfo v) => v.id;
  static const Field<FactionInfo, String> _f$id = Field('id', _$id);
  static String? _$displayName(FactionInfo v) => v.displayName;
  static const Field<FactionInfo, String> _f$displayName = Field(
    'displayName',
    _$displayName,
    opt: true,
  );

  @override
  final MappableFields<FactionInfo> fields = const {
    #id: _f$id,
    #displayName: _f$displayName,
  };

  static FactionInfo _instantiate(DecodingData data) {
    return FactionInfo(
      id: data.dec(_f$id),
      displayName: data.dec(_f$displayName),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static FactionInfo fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<FactionInfo>(map);
  }

  static FactionInfo fromJson(String json) {
    return ensureInitialized().decodeJson<FactionInfo>(json);
  }
}

mixin FactionInfoMappable {
  String toJson() {
    return FactionInfoMapper.ensureInitialized().encodeJson<FactionInfo>(
      this as FactionInfo,
    );
  }

  Map<String, dynamic> toMap() {
    return FactionInfoMapper.ensureInitialized().encodeMap<FactionInfo>(
      this as FactionInfo,
    );
  }

  FactionInfoCopyWith<FactionInfo, FactionInfo, FactionInfo> get copyWith =>
      _FactionInfoCopyWithImpl<FactionInfo, FactionInfo>(
        this as FactionInfo,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return FactionInfoMapper.ensureInitialized().stringifyValue(
      this as FactionInfo,
    );
  }

  @override
  bool operator ==(Object other) {
    return FactionInfoMapper.ensureInitialized().equalsValue(
      this as FactionInfo,
      other,
    );
  }

  @override
  int get hashCode {
    return FactionInfoMapper.ensureInitialized().hashValue(this as FactionInfo);
  }
}

extension FactionInfoValueCopy<$R, $Out>
    on ObjectCopyWith<$R, FactionInfo, $Out> {
  FactionInfoCopyWith<$R, FactionInfo, $Out> get $asFactionInfo =>
      $base.as((v, t, t2) => _FactionInfoCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class FactionInfoCopyWith<$R, $In extends FactionInfo, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({String? id, String? displayName});
  FactionInfoCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _FactionInfoCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, FactionInfo, $Out>
    implements FactionInfoCopyWith<$R, FactionInfo, $Out> {
  _FactionInfoCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<FactionInfo> $mapper =
      FactionInfoMapper.ensureInitialized();
  @override
  $R call({String? id, Object? displayName = $none}) => $apply(
    FieldCopyWithData({
      if (id != null) #id: id,
      if (displayName != $none) #displayName: displayName,
    }),
  );
  @override
  FactionInfo $make(CopyWithData data) => FactionInfo(
    id: data.get(#id, or: $value.id),
    displayName: data.get(#displayName, or: $value.displayName),
  );

  @override
  FactionInfoCopyWith<$R2, FactionInfo, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _FactionInfoCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class PortraitMetadataMapper extends ClassMapperBase<PortraitMetadata> {
  PortraitMetadataMapper._();

  static PortraitMetadataMapper? _instance;
  static PortraitMetadataMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = PortraitMetadataMapper._());
      FactionInfoMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'PortraitMetadata';

  static String _$relativePath(PortraitMetadata v) => v.relativePath;
  static const Field<PortraitMetadata, String> _f$relativePath = Field(
    'relativePath',
    _$relativePath,
  );
  static PortraitGender? _$gender(PortraitMetadata v) => v.gender;
  static const Field<PortraitMetadata, PortraitGender> _f$gender = Field(
    'gender',
    _$gender,
  );
  static Set<FactionInfo> _$factions(PortraitMetadata v) => v.factions;
  static const Field<PortraitMetadata, Set<FactionInfo>> _f$factions = Field(
    'factions',
    _$factions,
  );
  static String? _$portraitId(PortraitMetadata v) => v.portraitId;
  static const Field<PortraitMetadata, String> _f$portraitId = Field(
    'portraitId',
    _$portraitId,
    opt: true,
  );

  @override
  final MappableFields<PortraitMetadata> fields = const {
    #relativePath: _f$relativePath,
    #gender: _f$gender,
    #factions: _f$factions,
    #portraitId: _f$portraitId,
  };

  static PortraitMetadata _instantiate(DecodingData data) {
    return PortraitMetadata(
      relativePath: data.dec(_f$relativePath),
      gender: data.dec(_f$gender),
      factions: data.dec(_f$factions),
      portraitId: data.dec(_f$portraitId),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static PortraitMetadata fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<PortraitMetadata>(map);
  }

  static PortraitMetadata fromJson(String json) {
    return ensureInitialized().decodeJson<PortraitMetadata>(json);
  }
}

mixin PortraitMetadataMappable {
  String toJson() {
    return PortraitMetadataMapper.ensureInitialized()
        .encodeJson<PortraitMetadata>(this as PortraitMetadata);
  }

  Map<String, dynamic> toMap() {
    return PortraitMetadataMapper.ensureInitialized()
        .encodeMap<PortraitMetadata>(this as PortraitMetadata);
  }

  PortraitMetadataCopyWith<PortraitMetadata, PortraitMetadata, PortraitMetadata>
  get copyWith =>
      _PortraitMetadataCopyWithImpl<PortraitMetadata, PortraitMetadata>(
        this as PortraitMetadata,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return PortraitMetadataMapper.ensureInitialized().stringifyValue(
      this as PortraitMetadata,
    );
  }

  @override
  bool operator ==(Object other) {
    return PortraitMetadataMapper.ensureInitialized().equalsValue(
      this as PortraitMetadata,
      other,
    );
  }

  @override
  int get hashCode {
    return PortraitMetadataMapper.ensureInitialized().hashValue(
      this as PortraitMetadata,
    );
  }
}

extension PortraitMetadataValueCopy<$R, $Out>
    on ObjectCopyWith<$R, PortraitMetadata, $Out> {
  PortraitMetadataCopyWith<$R, PortraitMetadata, $Out>
  get $asPortraitMetadata =>
      $base.as((v, t, t2) => _PortraitMetadataCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class PortraitMetadataCopyWith<$R, $In extends PortraitMetadata, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    String? relativePath,
    PortraitGender? gender,
    Set<FactionInfo>? factions,
    String? portraitId,
  });
  PortraitMetadataCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _PortraitMetadataCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, PortraitMetadata, $Out>
    implements PortraitMetadataCopyWith<$R, PortraitMetadata, $Out> {
  _PortraitMetadataCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<PortraitMetadata> $mapper =
      PortraitMetadataMapper.ensureInitialized();
  @override
  $R call({
    String? relativePath,
    Object? gender = $none,
    Set<FactionInfo>? factions,
    Object? portraitId = $none,
  }) => $apply(
    FieldCopyWithData({
      if (relativePath != null) #relativePath: relativePath,
      if (gender != $none) #gender: gender,
      if (factions != null) #factions: factions,
      if (portraitId != $none) #portraitId: portraitId,
    }),
  );
  @override
  PortraitMetadata $make(CopyWithData data) => PortraitMetadata(
    relativePath: data.get(#relativePath, or: $value.relativePath),
    gender: data.get(#gender, or: $value.gender),
    factions: data.get(#factions, or: $value.factions),
    portraitId: data.get(#portraitId, or: $value.portraitId),
  );

  @override
  PortraitMetadataCopyWith<$R2, PortraitMetadata, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _PortraitMetadataCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

