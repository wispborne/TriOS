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
      case 'texture':
        return ImageType.texture;
      case 'background':
        return ImageType.background;
      case 'unused':
        return ImageType.unused;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(ImageType self) {
    switch (self) {
      case ImageType.texture:
        return 'texture';
      case ImageType.background:
        return 'background';
      case ImageType.unused:
        return 'unused';
    }
  }
}

extension ImageTypeMapperExtension on ImageType {
  String toValue() {
    ImageTypeMapper.ensureInitialized();
    return MapperContainer.globals.toValue<ImageType>(this) as String;
  }
}

class ModMapper extends ClassMapperBase<Mod> {
  ModMapper._();

  static ModMapper? _instance;
  static ModMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ModMapper._());
      VramCheckerModMapper.ensureInitialized();
      ModImageMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'Mod';

  static VramCheckerMod _$info(Mod v) => v.info;
  static const Field<Mod, VramCheckerMod> _f$info = Field('info', _$info);
  static bool _$isEnabled(Mod v) => v.isEnabled;
  static const Field<Mod, bool> _f$isEnabled = Field('isEnabled', _$isEnabled);
  static List<ModImage> _$images(Mod v) => v.images;
  static const Field<Mod, List<ModImage>> _f$images = Field('images', _$images);
  static int _$maxPossibleBytesForMod(Mod v) => v.maxPossibleBytesForMod;
  static const Field<Mod, int> _f$maxPossibleBytesForMod = Field(
      'maxPossibleBytesForMod', _$maxPossibleBytesForMod,
      mode: FieldMode.member);

  @override
  final MappableFields<Mod> fields = const {
    #info: _f$info,
    #isEnabled: _f$isEnabled,
    #images: _f$images,
    #maxPossibleBytesForMod: _f$maxPossibleBytesForMod,
  };

  static Mod _instantiate(DecodingData data) {
    return Mod(data.dec(_f$info), data.dec(_f$isEnabled), data.dec(_f$images));
  }

  @override
  final Function instantiate = _instantiate;

  static Mod fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<Mod>(map);
  }

  static Mod fromJson(String json) {
    return ensureInitialized().decodeJson<Mod>(json);
  }
}

mixin ModMappable {
  String toJson() {
    return ModMapper.ensureInitialized().encodeJson<Mod>(this as Mod);
  }

  Map<String, dynamic> toMap() {
    return ModMapper.ensureInitialized().encodeMap<Mod>(this as Mod);
  }

  ModCopyWith<Mod, Mod, Mod> get copyWith =>
      _ModCopyWithImpl(this as Mod, $identity, $identity);
  @override
  String toString() {
    return ModMapper.ensureInitialized().stringifyValue(this as Mod);
  }

  @override
  bool operator ==(Object other) {
    return ModMapper.ensureInitialized().equalsValue(this as Mod, other);
  }

  @override
  int get hashCode {
    return ModMapper.ensureInitialized().hashValue(this as Mod);
  }
}

extension ModValueCopy<$R, $Out> on ObjectCopyWith<$R, Mod, $Out> {
  ModCopyWith<$R, Mod, $Out> get $asMod =>
      $base.as((v, t, t2) => _ModCopyWithImpl(v, t, t2));
}

abstract class ModCopyWith<$R, $In extends Mod, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  VramCheckerModCopyWith<$R, VramCheckerMod, VramCheckerMod> get info;
  ListCopyWith<$R, ModImage, ModImageCopyWith<$R, ModImage, ModImage>>
      get images;
  $R call({VramCheckerMod? info, bool? isEnabled, List<ModImage>? images});
  ModCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ModCopyWithImpl<$R, $Out> extends ClassCopyWithBase<$R, Mod, $Out>
    implements ModCopyWith<$R, Mod, $Out> {
  _ModCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<Mod> $mapper = ModMapper.ensureInitialized();
  @override
  VramCheckerModCopyWith<$R, VramCheckerMod, VramCheckerMod> get info =>
      $value.info.copyWith.$chain((v) => call(info: v));
  @override
  ListCopyWith<$R, ModImage, ModImageCopyWith<$R, ModImage, ModImage>>
      get images => ListCopyWith($value.images, (v, t) => v.copyWith.$chain(t),
          (v) => call(images: v));
  @override
  $R call({VramCheckerMod? info, bool? isEnabled, List<ModImage>? images}) =>
      $apply(FieldCopyWithData({
        if (info != null) #info: info,
        if (isEnabled != null) #isEnabled: isEnabled,
        if (images != null) #images: images
      }));
  @override
  Mod $make(CopyWithData data) => Mod(
      data.get(#info, or: $value.info),
      data.get(#isEnabled, or: $value.isEnabled),
      data.get(#images, or: $value.images));

  @override
  ModCopyWith<$R2, Mod, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _ModCopyWithImpl($value, $cast, t);
}

class VramCheckerModMapper extends ClassMapperBase<VramCheckerMod> {
  VramCheckerModMapper._();

  static VramCheckerModMapper? _instance;
  static VramCheckerModMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = VramCheckerModMapper._());
      ModInfoJsonMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'VramCheckerMod';

  static ModInfoJson _$modInfo(VramCheckerMod v) => v.modInfo;
  static const Field<VramCheckerMod, ModInfoJson> _f$modInfo =
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
      get copyWith => _VramCheckerModCopyWithImpl(
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
      $base.as((v, t, t2) => _VramCheckerModCopyWithImpl(v, t, t2));
}

abstract class VramCheckerModCopyWith<$R, $In extends VramCheckerMod, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ModInfoJsonCopyWith<$R, ModInfoJson, ModInfoJson> get modInfo;
  $R call({ModInfoJson? modInfo, String? modFolder});
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
  ModInfoJsonCopyWith<$R, ModInfoJson, ModInfoJson> get modInfo =>
      $value.modInfo.copyWith.$chain((v) => call(modInfo: v));
  @override
  $R call({ModInfoJson? modInfo, String? modFolder}) =>
      $apply(FieldCopyWithData({
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
      _VramCheckerModCopyWithImpl($value, $cast, t);
}

class ModImageMapper extends ClassMapperBase<ModImage> {
  ModImageMapper._();

  static ModImageMapper? _instance;
  static ModImageMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ModImageMapper._());
      ImageTypeMapper.ensureInitialized();
      MapTypeMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ModImage';

  static String _$filePath(ModImage v) => v.filePath;
  static const Field<ModImage, String> _f$filePath =
      Field('filePath', _$filePath);
  static int _$textureHeight(ModImage v) => v.textureHeight;
  static const Field<ModImage, int> _f$textureHeight =
      Field('textureHeight', _$textureHeight);
  static int _$textureWidth(ModImage v) => v.textureWidth;
  static const Field<ModImage, int> _f$textureWidth =
      Field('textureWidth', _$textureWidth);
  static int _$bitsInAllChannelsSum(ModImage v) => v.bitsInAllChannelsSum;
  static const Field<ModImage, int> _f$bitsInAllChannelsSum =
      Field('bitsInAllChannelsSum', _$bitsInAllChannelsSum);
  static ImageType _$imageType(ModImage v) => v.imageType;
  static const Field<ModImage, ImageType> _f$imageType =
      Field('imageType', _$imageType);
  static MapType? _$graphicsLibType(ModImage v) => v.graphicsLibType;
  static const Field<ModImage, MapType> _f$graphicsLibType =
      Field('graphicsLibType', _$graphicsLibType);
  static double _$multiplier(ModImage v) => v.multiplier;
  static const Field<ModImage, double> _f$multiplier =
      Field('multiplier', _$multiplier, mode: FieldMode.member);
  static int _$bytesUsed(ModImage v) => v.bytesUsed;
  static const Field<ModImage, int> _f$bytesUsed =
      Field('bytesUsed', _$bytesUsed, mode: FieldMode.member);

  @override
  final MappableFields<ModImage> fields = const {
    #filePath: _f$filePath,
    #textureHeight: _f$textureHeight,
    #textureWidth: _f$textureWidth,
    #bitsInAllChannelsSum: _f$bitsInAllChannelsSum,
    #imageType: _f$imageType,
    #graphicsLibType: _f$graphicsLibType,
    #multiplier: _f$multiplier,
    #bytesUsed: _f$bytesUsed,
  };

  static ModImage _instantiate(DecodingData data) {
    return ModImage(
        data.dec(_f$filePath),
        data.dec(_f$textureHeight),
        data.dec(_f$textureWidth),
        data.dec(_f$bitsInAllChannelsSum),
        data.dec(_f$imageType),
        data.dec(_f$graphicsLibType));
  }

  @override
  final Function instantiate = _instantiate;

  static ModImage fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ModImage>(map);
  }

  static ModImage fromJson(String json) {
    return ensureInitialized().decodeJson<ModImage>(json);
  }
}

mixin ModImageMappable {
  String toJson() {
    return ModImageMapper.ensureInitialized()
        .encodeJson<ModImage>(this as ModImage);
  }

  Map<String, dynamic> toMap() {
    return ModImageMapper.ensureInitialized()
        .encodeMap<ModImage>(this as ModImage);
  }

  ModImageCopyWith<ModImage, ModImage, ModImage> get copyWith =>
      _ModImageCopyWithImpl(this as ModImage, $identity, $identity);
  @override
  String toString() {
    return ModImageMapper.ensureInitialized().stringifyValue(this as ModImage);
  }

  @override
  bool operator ==(Object other) {
    return ModImageMapper.ensureInitialized()
        .equalsValue(this as ModImage, other);
  }

  @override
  int get hashCode {
    return ModImageMapper.ensureInitialized().hashValue(this as ModImage);
  }
}

extension ModImageValueCopy<$R, $Out> on ObjectCopyWith<$R, ModImage, $Out> {
  ModImageCopyWith<$R, ModImage, $Out> get $asModImage =>
      $base.as((v, t, t2) => _ModImageCopyWithImpl(v, t, t2));
}

abstract class ModImageCopyWith<$R, $In extends ModImage, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call(
      {String? filePath,
      int? textureHeight,
      int? textureWidth,
      int? bitsInAllChannelsSum,
      ImageType? imageType,
      MapType? graphicsLibType});
  ModImageCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ModImageCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ModImage, $Out>
    implements ModImageCopyWith<$R, ModImage, $Out> {
  _ModImageCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ModImage> $mapper =
      ModImageMapper.ensureInitialized();
  @override
  $R call(
          {String? filePath,
          int? textureHeight,
          int? textureWidth,
          int? bitsInAllChannelsSum,
          ImageType? imageType,
          Object? graphicsLibType = $none}) =>
      $apply(FieldCopyWithData({
        if (filePath != null) #filePath: filePath,
        if (textureHeight != null) #textureHeight: textureHeight,
        if (textureWidth != null) #textureWidth: textureWidth,
        if (bitsInAllChannelsSum != null)
          #bitsInAllChannelsSum: bitsInAllChannelsSum,
        if (imageType != null) #imageType: imageType,
        if (graphicsLibType != $none) #graphicsLibType: graphicsLibType
      }));
  @override
  ModImage $make(CopyWithData data) => ModImage(
      data.get(#filePath, or: $value.filePath),
      data.get(#textureHeight, or: $value.textureHeight),
      data.get(#textureWidth, or: $value.textureWidth),
      data.get(#bitsInAllChannelsSum, or: $value.bitsInAllChannelsSum),
      data.get(#imageType, or: $value.imageType),
      data.get(#graphicsLibType, or: $value.graphicsLibType));

  @override
  ModImageCopyWith<$R2, ModImage, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _ModImageCopyWithImpl($value, $cast, t);
}
