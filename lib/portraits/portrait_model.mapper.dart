// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'portrait_model.dart';

class PortraitMapper extends ClassMapperBase<Portrait> {
  PortraitMapper._();

  static PortraitMapper? _instance;
  static PortraitMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = PortraitMapper._());
      ModVariantMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'Portrait';

  static ModVariant? _$modVariant(Portrait v) => v.modVariant;
  static const Field<Portrait, ModVariant> _f$modVariant = Field(
    'modVariant',
    _$modVariant,
    opt: true,
  );
  static File _$imageFile(Portrait v) => v.imageFile;
  static const Field<Portrait, File> _f$imageFile = Field(
    'imageFile',
    _$imageFile,
    hook: FileHook(),
  );
  static String _$relativePath(Portrait v) => v.relativePath;
  static const Field<Portrait, String> _f$relativePath = Field(
    'relativePath',
    _$relativePath,
  );
  static int _$width(Portrait v) => v.width;
  static const Field<Portrait, int> _f$width = Field('width', _$width);
  static int _$height(Portrait v) => v.height;
  static const Field<Portrait, int> _f$height = Field('height', _$height);
  static String _$hash(Portrait v) => v.hash;
  static const Field<Portrait, String> _f$hash = Field('hash', _$hash);

  @override
  final MappableFields<Portrait> fields = const {
    #modVariant: _f$modVariant,
    #imageFile: _f$imageFile,
    #relativePath: _f$relativePath,
    #width: _f$width,
    #height: _f$height,
    #hash: _f$hash,
  };

  static Portrait _instantiate(DecodingData data) {
    return Portrait(
      modVariant: data.dec(_f$modVariant),
      imageFile: data.dec(_f$imageFile),
      relativePath: data.dec(_f$relativePath),
      width: data.dec(_f$width),
      height: data.dec(_f$height),
      hash: data.dec(_f$hash),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static Portrait fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<Portrait>(map);
  }

  static Portrait fromJson(String json) {
    return ensureInitialized().decodeJson<Portrait>(json);
  }
}

mixin PortraitMappable {
  String toJson() {
    return PortraitMapper.ensureInitialized().encodeJson<Portrait>(
      this as Portrait,
    );
  }

  Map<String, dynamic> toMap() {
    return PortraitMapper.ensureInitialized().encodeMap<Portrait>(
      this as Portrait,
    );
  }

  PortraitCopyWith<Portrait, Portrait, Portrait> get copyWith =>
      _PortraitCopyWithImpl<Portrait, Portrait>(
        this as Portrait,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return PortraitMapper.ensureInitialized().stringifyValue(this as Portrait);
  }

  @override
  bool operator ==(Object other) {
    return PortraitMapper.ensureInitialized().equalsValue(
      this as Portrait,
      other,
    );
  }

  @override
  int get hashCode {
    return PortraitMapper.ensureInitialized().hashValue(this as Portrait);
  }
}

extension PortraitValueCopy<$R, $Out> on ObjectCopyWith<$R, Portrait, $Out> {
  PortraitCopyWith<$R, Portrait, $Out> get $asPortrait =>
      $base.as((v, t, t2) => _PortraitCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class PortraitCopyWith<$R, $In extends Portrait, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ModVariantCopyWith<$R, ModVariant, ModVariant>? get modVariant;
  $R call({
    ModVariant? modVariant,
    File? imageFile,
    String? relativePath,
    int? width,
    int? height,
    String? hash,
  });
  PortraitCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _PortraitCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, Portrait, $Out>
    implements PortraitCopyWith<$R, Portrait, $Out> {
  _PortraitCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<Portrait> $mapper =
      PortraitMapper.ensureInitialized();
  @override
  ModVariantCopyWith<$R, ModVariant, ModVariant>? get modVariant =>
      $value.modVariant?.copyWith.$chain((v) => call(modVariant: v));
  @override
  $R call({
    Object? modVariant = $none,
    File? imageFile,
    String? relativePath,
    int? width,
    int? height,
    String? hash,
  }) => $apply(
    FieldCopyWithData({
      if (modVariant != $none) #modVariant: modVariant,
      if (imageFile != null) #imageFile: imageFile,
      if (relativePath != null) #relativePath: relativePath,
      if (width != null) #width: width,
      if (height != null) #height: height,
      if (hash != null) #hash: hash,
    }),
  );
  @override
  Portrait $make(CopyWithData data) => Portrait(
    modVariant: data.get(#modVariant, or: $value.modVariant),
    imageFile: data.get(#imageFile, or: $value.imageFile),
    relativePath: data.get(#relativePath, or: $value.relativePath),
    width: data.get(#width, or: $value.width),
    height: data.get(#height, or: $value.height),
    hash: data.get(#hash, or: $value.hash),
  );

  @override
  PortraitCopyWith<$R2, Portrait, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _PortraitCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class SavedPortraitMapper extends ClassMapperBase<SavedPortrait> {
  SavedPortraitMapper._();

  static SavedPortraitMapper? _instance;
  static SavedPortraitMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = SavedPortraitMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'SavedPortrait';

  static String _$relativePath(SavedPortrait v) => v.relativePath;
  static const Field<SavedPortrait, String> _f$relativePath = Field(
    'relativePath',
    _$relativePath,
  );
  static String _$lastKnownFullPath(SavedPortrait v) => v.lastKnownFullPath;
  static const Field<SavedPortrait, String> _f$lastKnownFullPath = Field(
    'lastKnownFullPath',
    _$lastKnownFullPath,
  );
  static String _$hash(SavedPortrait v) => v.hash;
  static const Field<SavedPortrait, String> _f$hash = Field('hash', _$hash);

  @override
  final MappableFields<SavedPortrait> fields = const {
    #relativePath: _f$relativePath,
    #lastKnownFullPath: _f$lastKnownFullPath,
    #hash: _f$hash,
  };

  static SavedPortrait _instantiate(DecodingData data) {
    return SavedPortrait(
      relativePath: data.dec(_f$relativePath),
      lastKnownFullPath: data.dec(_f$lastKnownFullPath),
      hash: data.dec(_f$hash),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static SavedPortrait fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<SavedPortrait>(map);
  }

  static SavedPortrait fromJson(String json) {
    return ensureInitialized().decodeJson<SavedPortrait>(json);
  }
}

mixin SavedPortraitMappable {
  String toJson() {
    return SavedPortraitMapper.ensureInitialized().encodeJson<SavedPortrait>(
      this as SavedPortrait,
    );
  }

  Map<String, dynamic> toMap() {
    return SavedPortraitMapper.ensureInitialized().encodeMap<SavedPortrait>(
      this as SavedPortrait,
    );
  }

  SavedPortraitCopyWith<SavedPortrait, SavedPortrait, SavedPortrait>
  get copyWith => _SavedPortraitCopyWithImpl<SavedPortrait, SavedPortrait>(
    this as SavedPortrait,
    $identity,
    $identity,
  );
  @override
  String toString() {
    return SavedPortraitMapper.ensureInitialized().stringifyValue(
      this as SavedPortrait,
    );
  }

  @override
  bool operator ==(Object other) {
    return SavedPortraitMapper.ensureInitialized().equalsValue(
      this as SavedPortrait,
      other,
    );
  }

  @override
  int get hashCode {
    return SavedPortraitMapper.ensureInitialized().hashValue(
      this as SavedPortrait,
    );
  }
}

extension SavedPortraitValueCopy<$R, $Out>
    on ObjectCopyWith<$R, SavedPortrait, $Out> {
  SavedPortraitCopyWith<$R, SavedPortrait, $Out> get $asSavedPortrait =>
      $base.as((v, t, t2) => _SavedPortraitCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class SavedPortraitCopyWith<$R, $In extends SavedPortrait, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({String? relativePath, String? lastKnownFullPath, String? hash});
  SavedPortraitCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _SavedPortraitCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, SavedPortrait, $Out>
    implements SavedPortraitCopyWith<$R, SavedPortrait, $Out> {
  _SavedPortraitCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<SavedPortrait> $mapper =
      SavedPortraitMapper.ensureInitialized();
  @override
  $R call({String? relativePath, String? lastKnownFullPath, String? hash}) =>
      $apply(
        FieldCopyWithData({
          if (relativePath != null) #relativePath: relativePath,
          if (lastKnownFullPath != null) #lastKnownFullPath: lastKnownFullPath,
          if (hash != null) #hash: hash,
        }),
      );
  @override
  SavedPortrait $make(CopyWithData data) => SavedPortrait(
    relativePath: data.get(#relativePath, or: $value.relativePath),
    lastKnownFullPath: data.get(
      #lastKnownFullPath,
      or: $value.lastKnownFullPath,
    ),
    hash: data.get(#hash, or: $value.hash),
  );

  @override
  SavedPortraitCopyWith<$R2, SavedPortrait, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _SavedPortraitCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class ReplacedSavedPortraitMapper
    extends ClassMapperBase<ReplacedSavedPortrait> {
  ReplacedSavedPortraitMapper._();

  static ReplacedSavedPortraitMapper? _instance;
  static ReplacedSavedPortraitMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ReplacedSavedPortraitMapper._());
      SavedPortraitMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ReplacedSavedPortrait';

  static SavedPortrait _$original(ReplacedSavedPortrait v) => v.original;
  static const Field<ReplacedSavedPortrait, SavedPortrait> _f$original = Field(
    'original',
    _$original,
  );
  static SavedPortrait _$replacement(ReplacedSavedPortrait v) => v.replacement;
  static const Field<ReplacedSavedPortrait, SavedPortrait> _f$replacement =
      Field('replacement', _$replacement);

  @override
  final MappableFields<ReplacedSavedPortrait> fields = const {
    #original: _f$original,
    #replacement: _f$replacement,
  };

  static ReplacedSavedPortrait _instantiate(DecodingData data) {
    return ReplacedSavedPortrait(
      original: data.dec(_f$original),
      replacement: data.dec(_f$replacement),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ReplacedSavedPortrait fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ReplacedSavedPortrait>(map);
  }

  static ReplacedSavedPortrait fromJson(String json) {
    return ensureInitialized().decodeJson<ReplacedSavedPortrait>(json);
  }
}

mixin ReplacedSavedPortraitMappable {
  String toJson() {
    return ReplacedSavedPortraitMapper.ensureInitialized()
        .encodeJson<ReplacedSavedPortrait>(this as ReplacedSavedPortrait);
  }

  Map<String, dynamic> toMap() {
    return ReplacedSavedPortraitMapper.ensureInitialized()
        .encodeMap<ReplacedSavedPortrait>(this as ReplacedSavedPortrait);
  }

  ReplacedSavedPortraitCopyWith<
    ReplacedSavedPortrait,
    ReplacedSavedPortrait,
    ReplacedSavedPortrait
  >
  get copyWith =>
      _ReplacedSavedPortraitCopyWithImpl<
        ReplacedSavedPortrait,
        ReplacedSavedPortrait
      >(this as ReplacedSavedPortrait, $identity, $identity);
  @override
  String toString() {
    return ReplacedSavedPortraitMapper.ensureInitialized().stringifyValue(
      this as ReplacedSavedPortrait,
    );
  }

  @override
  bool operator ==(Object other) {
    return ReplacedSavedPortraitMapper.ensureInitialized().equalsValue(
      this as ReplacedSavedPortrait,
      other,
    );
  }

  @override
  int get hashCode {
    return ReplacedSavedPortraitMapper.ensureInitialized().hashValue(
      this as ReplacedSavedPortrait,
    );
  }
}

extension ReplacedSavedPortraitValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ReplacedSavedPortrait, $Out> {
  ReplacedSavedPortraitCopyWith<$R, ReplacedSavedPortrait, $Out>
  get $asReplacedSavedPortrait => $base.as(
    (v, t, t2) => _ReplacedSavedPortraitCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class ReplacedSavedPortraitCopyWith<
  $R,
  $In extends ReplacedSavedPortrait,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  SavedPortraitCopyWith<$R, SavedPortrait, SavedPortrait> get original;
  SavedPortraitCopyWith<$R, SavedPortrait, SavedPortrait> get replacement;
  $R call({SavedPortrait? original, SavedPortrait? replacement});
  ReplacedSavedPortraitCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _ReplacedSavedPortraitCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ReplacedSavedPortrait, $Out>
    implements ReplacedSavedPortraitCopyWith<$R, ReplacedSavedPortrait, $Out> {
  _ReplacedSavedPortraitCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ReplacedSavedPortrait> $mapper =
      ReplacedSavedPortraitMapper.ensureInitialized();
  @override
  SavedPortraitCopyWith<$R, SavedPortrait, SavedPortrait> get original =>
      $value.original.copyWith.$chain((v) => call(original: v));
  @override
  SavedPortraitCopyWith<$R, SavedPortrait, SavedPortrait> get replacement =>
      $value.replacement.copyWith.$chain((v) => call(replacement: v));
  @override
  $R call({SavedPortrait? original, SavedPortrait? replacement}) => $apply(
    FieldCopyWithData({
      if (original != null) #original: original,
      if (replacement != null) #replacement: replacement,
    }),
  );
  @override
  ReplacedSavedPortrait $make(CopyWithData data) => ReplacedSavedPortrait(
    original: data.get(#original, or: $value.original),
    replacement: data.get(#replacement, or: $value.replacement),
  );

  @override
  ReplacedSavedPortraitCopyWith<$R2, ReplacedSavedPortrait, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _ReplacedSavedPortraitCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

