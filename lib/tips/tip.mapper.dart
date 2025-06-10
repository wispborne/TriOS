// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'tip.dart';

class TipMapper extends ClassMapperBase<Tip> {
  TipMapper._();

  static TipMapper? _instance;
  static TipMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = TipMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'Tip';

  static String? _$freq(Tip v) => v.freq;
  static const Field<Tip, String> _f$freq = Field('freq', _$freq, opt: true);
  static String? _$tip(Tip v) => v.tip;
  static const Field<Tip, String> _f$tip = Field('tip', _$tip, opt: true);
  static String? _$originalFreq(Tip v) => v.originalFreq;
  static const Field<Tip, String> _f$originalFreq =
      Field('originalFreq', _$originalFreq, opt: true);

  @override
  final MappableFields<Tip> fields = const {
    #freq: _f$freq,
    #tip: _f$tip,
    #originalFreq: _f$originalFreq,
  };

  @override
  final MappingHook hook = const TipHooks();
  static Tip _instantiate(DecodingData data) {
    return Tip(
        freq: data.dec(_f$freq),
        tip: data.dec(_f$tip),
        originalFreq: data.dec(_f$originalFreq));
  }

  @override
  final Function instantiate = _instantiate;

  static Tip fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<Tip>(map);
  }

  static Tip fromJson(String json) {
    return ensureInitialized().decodeJson<Tip>(json);
  }
}

mixin TipMappable {
  String toJson() {
    return TipMapper.ensureInitialized().encodeJson<Tip>(this as Tip);
  }

  Map<String, dynamic> toMap() {
    return TipMapper.ensureInitialized().encodeMap<Tip>(this as Tip);
  }

  TipCopyWith<Tip, Tip, Tip> get copyWith =>
      _TipCopyWithImpl<Tip, Tip>(this as Tip, $identity, $identity);
  @override
  String toString() {
    return TipMapper.ensureInitialized().stringifyValue(this as Tip);
  }

  @override
  bool operator ==(Object other) {
    return TipMapper.ensureInitialized().equalsValue(this as Tip, other);
  }

  @override
  int get hashCode {
    return TipMapper.ensureInitialized().hashValue(this as Tip);
  }
}

extension TipValueCopy<$R, $Out> on ObjectCopyWith<$R, Tip, $Out> {
  TipCopyWith<$R, Tip, $Out> get $asTip =>
      $base.as((v, t, t2) => _TipCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class TipCopyWith<$R, $In extends Tip, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({String? freq, String? tip, String? originalFreq});
  TipCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _TipCopyWithImpl<$R, $Out> extends ClassCopyWithBase<$R, Tip, $Out>
    implements TipCopyWith<$R, Tip, $Out> {
  _TipCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<Tip> $mapper = TipMapper.ensureInitialized();
  @override
  $R call(
          {Object? freq = $none,
          Object? tip = $none,
          Object? originalFreq = $none}) =>
      $apply(FieldCopyWithData({
        if (freq != $none) #freq: freq,
        if (tip != $none) #tip: tip,
        if (originalFreq != $none) #originalFreq: originalFreq
      }));
  @override
  Tip $make(CopyWithData data) => Tip(
      freq: data.get(#freq, or: $value.freq),
      tip: data.get(#tip, or: $value.tip),
      originalFreq: data.get(#originalFreq, or: $value.originalFreq));

  @override
  TipCopyWith<$R2, Tip, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _TipCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class TipsMapper extends ClassMapperBase<Tips> {
  TipsMapper._();

  static TipsMapper? _instance;
  static TipsMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = TipsMapper._());
      TipMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'Tips';

  static List<Tip>? _$tips(Tips v) => v.tips;
  static const Field<Tips, List<Tip>> _f$tips =
      Field('tips', _$tips, opt: true);

  @override
  final MappableFields<Tips> fields = const {
    #tips: _f$tips,
  };

  static Tips _instantiate(DecodingData data) {
    return Tips(tips: data.dec(_f$tips));
  }

  @override
  final Function instantiate = _instantiate;

  static Tips fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<Tips>(map);
  }

  static Tips fromJson(String json) {
    return ensureInitialized().decodeJson<Tips>(json);
  }
}

mixin TipsMappable {
  String toJson() {
    return TipsMapper.ensureInitialized().encodeJson<Tips>(this as Tips);
  }

  Map<String, dynamic> toMap() {
    return TipsMapper.ensureInitialized().encodeMap<Tips>(this as Tips);
  }

  TipsCopyWith<Tips, Tips, Tips> get copyWith =>
      _TipsCopyWithImpl<Tips, Tips>(this as Tips, $identity, $identity);
  @override
  String toString() {
    return TipsMapper.ensureInitialized().stringifyValue(this as Tips);
  }

  @override
  bool operator ==(Object other) {
    return TipsMapper.ensureInitialized().equalsValue(this as Tips, other);
  }

  @override
  int get hashCode {
    return TipsMapper.ensureInitialized().hashValue(this as Tips);
  }
}

extension TipsValueCopy<$R, $Out> on ObjectCopyWith<$R, Tips, $Out> {
  TipsCopyWith<$R, Tips, $Out> get $asTips =>
      $base.as((v, t, t2) => _TipsCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class TipsCopyWith<$R, $In extends Tips, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, Tip, TipCopyWith<$R, Tip, Tip>>? get tips;
  $R call({List<Tip>? tips});
  TipsCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _TipsCopyWithImpl<$R, $Out> extends ClassCopyWithBase<$R, Tips, $Out>
    implements TipsCopyWith<$R, Tips, $Out> {
  _TipsCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<Tips> $mapper = TipsMapper.ensureInitialized();
  @override
  ListCopyWith<$R, Tip, TipCopyWith<$R, Tip, Tip>>? get tips => $value.tips !=
          null
      ? ListCopyWith(
          $value.tips!, (v, t) => v.copyWith.$chain(t), (v) => call(tips: v))
      : null;
  @override
  $R call({Object? tips = $none}) =>
      $apply(FieldCopyWithData({if (tips != $none) #tips: tips}));
  @override
  Tips $make(CopyWithData data) => Tips(tips: data.get(#tips, or: $value.tips));

  @override
  TipsCopyWith<$R2, Tips, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _TipsCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class ModTipMapper extends ClassMapperBase<ModTip> {
  ModTipMapper._();

  static ModTipMapper? _instance;
  static ModTipMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ModTipMapper._());
      TipMapper.ensureInitialized();
      ModVariantMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ModTip';

  static Tip _$tipObj(ModTip v) => v.tipObj;
  static const Field<ModTip, Tip> _f$tipObj = Field('tipObj', _$tipObj);
  static List<ModVariant> _$variants(ModTip v) => v.variants;
  static const Field<ModTip, List<ModVariant>> _f$variants =
      Field('variants', _$variants);
  static File _$tipFile(ModTip v) => v.tipFile;
  static const Field<ModTip, File> _f$tipFile =
      Field('tipFile', _$tipFile, hook: FileHook());

  @override
  final MappableFields<ModTip> fields = const {
    #tipObj: _f$tipObj,
    #variants: _f$variants,
    #tipFile: _f$tipFile,
  };

  static ModTip _instantiate(DecodingData data) {
    return ModTip(
        tipObj: data.dec(_f$tipObj),
        variants: data.dec(_f$variants),
        tipFile: data.dec(_f$tipFile));
  }

  @override
  final Function instantiate = _instantiate;

  static ModTip fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ModTip>(map);
  }

  static ModTip fromJson(String json) {
    return ensureInitialized().decodeJson<ModTip>(json);
  }
}

mixin ModTipMappable {
  String toJson() {
    return ModTipMapper.ensureInitialized().encodeJson<ModTip>(this as ModTip);
  }

  Map<String, dynamic> toMap() {
    return ModTipMapper.ensureInitialized().encodeMap<ModTip>(this as ModTip);
  }

  ModTipCopyWith<ModTip, ModTip, ModTip> get copyWith =>
      _ModTipCopyWithImpl<ModTip, ModTip>(this as ModTip, $identity, $identity);
  @override
  String toString() {
    return ModTipMapper.ensureInitialized().stringifyValue(this as ModTip);
  }

  @override
  bool operator ==(Object other) {
    return ModTipMapper.ensureInitialized().equalsValue(this as ModTip, other);
  }

  @override
  int get hashCode {
    return ModTipMapper.ensureInitialized().hashValue(this as ModTip);
  }
}

extension ModTipValueCopy<$R, $Out> on ObjectCopyWith<$R, ModTip, $Out> {
  ModTipCopyWith<$R, ModTip, $Out> get $asModTip =>
      $base.as((v, t, t2) => _ModTipCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ModTipCopyWith<$R, $In extends ModTip, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  TipCopyWith<$R, Tip, Tip> get tipObj;
  ListCopyWith<$R, ModVariant, ModVariantCopyWith<$R, ModVariant, ModVariant>>
      get variants;
  $R call({Tip? tipObj, List<ModVariant>? variants, File? tipFile});
  ModTipCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ModTipCopyWithImpl<$R, $Out> extends ClassCopyWithBase<$R, ModTip, $Out>
    implements ModTipCopyWith<$R, ModTip, $Out> {
  _ModTipCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ModTip> $mapper = ModTipMapper.ensureInitialized();
  @override
  TipCopyWith<$R, Tip, Tip> get tipObj =>
      $value.tipObj.copyWith.$chain((v) => call(tipObj: v));
  @override
  ListCopyWith<$R, ModVariant, ModVariantCopyWith<$R, ModVariant, ModVariant>>
      get variants => ListCopyWith($value.variants,
          (v, t) => v.copyWith.$chain(t), (v) => call(variants: v));
  @override
  $R call({Tip? tipObj, List<ModVariant>? variants, File? tipFile}) =>
      $apply(FieldCopyWithData({
        if (tipObj != null) #tipObj: tipObj,
        if (variants != null) #variants: variants,
        if (tipFile != null) #tipFile: tipFile
      }));
  @override
  ModTip $make(CopyWithData data) => ModTip(
      tipObj: data.get(#tipObj, or: $value.tipObj),
      variants: data.get(#variants, or: $value.variants),
      tipFile: data.get(#tipFile, or: $value.tipFile));

  @override
  ModTipCopyWith<$R2, ModTip, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _ModTipCopyWithImpl<$R2, $Out2>($value, $cast, t);
}
