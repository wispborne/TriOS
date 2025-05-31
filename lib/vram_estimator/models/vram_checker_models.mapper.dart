// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'vram_checker_models.dart';

class ImageTypeMapper extends EnumMapper<ImageType> {
  ImageTypeMapper._();

  static ImageTypeMapper? _instance;
  static ImageTypeMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ImageTypeMapper._());
    }
    return _instance!;
  }

  static ImageType fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  ImageType decode(dynamic value) {
    switch (value) {
      case r'texture':
        return ImageType.texture;
      case r'background':
        return ImageType.background;
      case r'unused':
        return ImageType.unused;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(ImageType self) {
    switch (self) {
      case ImageType.texture:
        return r'texture';
      case ImageType.background:
        return r'background';
      case ImageType.unused:
        return r'unused';
    }
  }
}

extension ImageTypeMapperExtension on ImageType {
  String toValue() {
    ImageTypeMapper.ensureInitialized();
    return MapperContainer.globals.toValue<ImageType>(this) as String;
  }
}

class VramCheckerModMapper extends ClassMapperBase<VramCheckerMod> {
  VramCheckerModMapper._();

  static VramCheckerModMapper? _instance;
  static VramCheckerModMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = VramCheckerModMapper._());
      ModInfoMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'VramCheckerMod';

  static ModInfo _$modInfo(VramCheckerMod v) => v.modInfo;
  static const Field<VramCheckerMod, ModInfo> _f$modInfo =
      Field('modInfo', _$modInfo);
  static String _$modFolder(VramCheckerMod v) => v.modFolder;
  static const Field<VramCheckerMod, String> _f$modFolder =
      Field('modFolder', _$modFolder);

  @override
  final MappableFields<VramCheckerMod> fields = const {
    #modInfo: _f$modInfo,
    #modFolder: _f$modFolder,
  };

  static VramCheckerMod _instantiate(DecodingData data) {
    return VramCheckerMod(data.dec(_f$modInfo), data.dec(_f$modFolder));
  }

  @override
  final Function instantiate = _instantiate;

  static VramCheckerMod fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<VramCheckerMod>(map);
  }

  static VramCheckerMod fromJson(String json) {
    return ensureInitialized().decodeJson<VramCheckerMod>(json);
  }
}

mixin VramCheckerModMappable {
  String toJson() {
    return VramCheckerModMapper.ensureInitialized()
        .encodeJson<VramCheckerMod>(this as VramCheckerMod);
  }

  Map<String, dynamic> toMap() {
    return VramCheckerModMapper.ensureInitialized()
        .encodeMap<VramCheckerMod>(this as VramCheckerMod);
  }

  VramCheckerModCopyWith<VramCheckerMod, VramCheckerMod, VramCheckerMod>
      get copyWith =>
          _VramCheckerModCopyWithImpl<VramCheckerMod, VramCheckerMod>(
              this as VramCheckerMod, $identity, $identity);
  @override
  String toString() {
    return VramCheckerModMapper.ensureInitialized()
        .stringifyValue(this as VramCheckerMod);
  }

  @override
  bool operator ==(Object other) {
    return VramCheckerModMapper.ensureInitialized()
        .equalsValue(this as VramCheckerMod, other);
  }

  @override
  int get hashCode {
    return VramCheckerModMapper.ensureInitialized()
        .hashValue(this as VramCheckerMod);
  }
}

extension VramCheckerModValueCopy<$R, $Out>
    on ObjectCopyWith<$R, VramCheckerMod, $Out> {
  VramCheckerModCopyWith<$R, VramCheckerMod, $Out> get $asVramCheckerMod =>
      $base.as((v, t, t2) => _VramCheckerModCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class VramCheckerModCopyWith<$R, $In extends VramCheckerMod, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ModInfoCopyWith<$R, ModInfo, ModInfo> get modInfo;
  $R call({ModInfo? modInfo, String? modFolder});
  VramCheckerModCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
      Then<$Out2, $R2> t);
}

class _VramCheckerModCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, VramCheckerMod, $Out>
    implements VramCheckerModCopyWith<$R, VramCheckerMod, $Out> {
  _VramCheckerModCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<VramCheckerMod> $mapper =
      VramCheckerModMapper.ensureInitialized();
  @override
  ModInfoCopyWith<$R, ModInfo, ModInfo> get modInfo =>
      $value.modInfo.copyWith.$chain((v) => call(modInfo: v));
  @override
  $R call({ModInfo? modInfo, String? modFolder}) => $apply(FieldCopyWithData({
        if (modInfo != null) #modInfo: modInfo,
        if (modFolder != null) #modFolder: modFolder
      }));
  @override
  VramCheckerMod $make(CopyWithData data) => VramCheckerMod(
      data.get(#modInfo, or: $value.modInfo),
      data.get(#modFolder, or: $value.modFolder));

  @override
  VramCheckerModCopyWith<$R2, VramCheckerMod, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _VramCheckerModCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class VramModMapper extends ClassMapperBase<VramMod> {
  VramModMapper._();

  static VramModMapper? _instance;
  static VramModMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = VramModMapper._());
      VramCheckerModMapper.ensureInitialized();
      GraphicsLibInfoMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'VramMod';

  static VramCheckerMod _$info(VramMod v) => v.info;
  static const Field<VramMod, VramCheckerMod> _f$info = Field('info', _$info);
  static bool _$isEnabled(VramMod v) => v.isEnabled;
  static const Field<VramMod, bool> _f$isEnabled =
      Field('isEnabled', _$isEnabled);
  static ModImageTable _$images(VramMod v) => v.images;
  static const Field<VramMod, ModImageTable> _f$images =
      Field('images', _$images, hook: ModImageTableHook());
  static List<GraphicsLibInfo>? _$graphicsLibEntries(VramMod v) =>
      v.graphicsLibEntries;
  static const Field<VramMod, List<GraphicsLibInfo>> _f$graphicsLibEntries =
      Field('graphicsLibEntries', _$graphicsLibEntries);
  static int _$maxPossibleBytesForMod(VramMod v) => v.maxPossibleBytesForMod;
  static const Field<VramMod, int> _f$maxPossibleBytesForMod = Field(
      'maxPossibleBytesForMod', _$maxPossibleBytesForMod,
      mode: FieldMode.member);

  @override
  final MappableFields<VramMod> fields = const {
    #info: _f$info,
    #isEnabled: _f$isEnabled,
    #images: _f$images,
    #graphicsLibEntries: _f$graphicsLibEntries,
    #maxPossibleBytesForMod: _f$maxPossibleBytesForMod,
  };

  static VramMod _instantiate(DecodingData data) {
    return VramMod(data.dec(_f$info), data.dec(_f$isEnabled),
        data.dec(_f$images), data.dec(_f$graphicsLibEntries));
  }

  @override
  final Function instantiate = _instantiate;

  static VramMod fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<VramMod>(map);
  }

  static VramMod fromJson(String json) {
    return ensureInitialized().decodeJson<VramMod>(json);
  }
}

mixin VramModMappable {
  String toJson() {
    return VramModMapper.ensureInitialized()
        .encodeJson<VramMod>(this as VramMod);
  }

  Map<String, dynamic> toMap() {
    return VramModMapper.ensureInitialized()
        .encodeMap<VramMod>(this as VramMod);
  }

  VramModCopyWith<VramMod, VramMod, VramMod> get copyWith =>
      _VramModCopyWithImpl<VramMod, VramMod>(
          this as VramMod, $identity, $identity);
  @override
  String toString() {
    return VramModMapper.ensureInitialized().stringifyValue(this as VramMod);
  }

  @override
  bool operator ==(Object other) {
    return VramModMapper.ensureInitialized()
        .equalsValue(this as VramMod, other);
  }

  @override
  int get hashCode {
    return VramModMapper.ensureInitialized().hashValue(this as VramMod);
  }
}

extension VramModValueCopy<$R, $Out> on ObjectCopyWith<$R, VramMod, $Out> {
  VramModCopyWith<$R, VramMod, $Out> get $asVramMod =>
      $base.as((v, t, t2) => _VramModCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class VramModCopyWith<$R, $In extends VramMod, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  VramCheckerModCopyWith<$R, VramCheckerMod, VramCheckerMod> get info;
  ListCopyWith<$R, GraphicsLibInfo,
          GraphicsLibInfoCopyWith<$R, GraphicsLibInfo, GraphicsLibInfo>>?
      get graphicsLibEntries;
  $R call(
      {VramCheckerMod? info,
      bool? isEnabled,
      ModImageTable? images,
      List<GraphicsLibInfo>? graphicsLibEntries});
  VramModCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _VramModCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, VramMod, $Out>
    implements VramModCopyWith<$R, VramMod, $Out> {
  _VramModCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<VramMod> $mapper =
      VramModMapper.ensureInitialized();
  @override
  VramCheckerModCopyWith<$R, VramCheckerMod, VramCheckerMod> get info =>
      $value.info.copyWith.$chain((v) => call(info: v));
  @override
  ListCopyWith<$R, GraphicsLibInfo,
          GraphicsLibInfoCopyWith<$R, GraphicsLibInfo, GraphicsLibInfo>>?
      get graphicsLibEntries => $value.graphicsLibEntries != null
          ? ListCopyWith(
              $value.graphicsLibEntries!,
              (v, t) => v.copyWith.$chain(t),
              (v) => call(graphicsLibEntries: v))
          : null;
  @override
  $R call(
          {VramCheckerMod? info,
          bool? isEnabled,
          ModImageTable? images,
          Object? graphicsLibEntries = $none}) =>
      $apply(FieldCopyWithData({
        if (info != null) #info: info,
        if (isEnabled != null) #isEnabled: isEnabled,
        if (images != null) #images: images,
        if (graphicsLibEntries != $none) #graphicsLibEntries: graphicsLibEntries
      }));
  @override
  VramMod $make(CopyWithData data) => VramMod(
      data.get(#info, or: $value.info),
      data.get(#isEnabled, or: $value.isEnabled),
      data.get(#images, or: $value.images),
      data.get(#graphicsLibEntries, or: $value.graphicsLibEntries));

  @override
  VramModCopyWith<$R2, VramMod, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _VramModCopyWithImpl<$R2, $Out2>($value, $cast, t);
}
