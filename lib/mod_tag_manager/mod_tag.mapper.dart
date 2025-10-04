// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'mod_tag.dart';

class ModTagMapper extends ClassMapperBase<ModTag> {
  ModTagMapper._();

  static ModTagMapper? _instance;
  static ModTagMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ModTagMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'ModTag';

  static String _$id(ModTag v) => v.id;
  static const Field<ModTag, String> _f$id = Field('id', _$id);
  static String _$name(ModTag v) => v.name;
  static const Field<ModTag, String> _f$name = Field('name', _$name);
  static String _$type(ModTag v) => v.type;
  static const Field<ModTag, String> _f$type = Field('type', _$type);
  static ModTagIcon? _$icon(ModTag v) => v.icon;
  static const Field<ModTag, ModTagIcon> _f$icon = Field(
    'icon',
    _$icon,
    opt: true,
  );
  static Color? _$color(ModTag v) => v.color;
  static const Field<ModTag, Color> _f$color = Field(
    'color',
    _$color,
    opt: true,
  );
  static bool _$isUserCreated(ModTag v) => v.isUserCreated;
  static const Field<ModTag, bool> _f$isUserCreated = Field(
    'isUserCreated',
    _$isUserCreated,
  );

  @override
  final MappableFields<ModTag> fields = const {
    #id: _f$id,
    #name: _f$name,
    #type: _f$type,
    #icon: _f$icon,
    #color: _f$color,
    #isUserCreated: _f$isUserCreated,
  };

  static ModTag _instantiate(DecodingData data) {
    return ModTag(
      id: data.dec(_f$id),
      name: data.dec(_f$name),
      type: data.dec(_f$type),
      icon: data.dec(_f$icon),
      color: data.dec(_f$color),
      isUserCreated: data.dec(_f$isUserCreated),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ModTag fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ModTag>(map);
  }

  static ModTag fromJson(String json) {
    return ensureInitialized().decodeJson<ModTag>(json);
  }
}

mixin ModTagMappable {
  String toJson() {
    return ModTagMapper.ensureInitialized().encodeJson<ModTag>(this as ModTag);
  }

  Map<String, dynamic> toMap() {
    return ModTagMapper.ensureInitialized().encodeMap<ModTag>(this as ModTag);
  }

  ModTagCopyWith<ModTag, ModTag, ModTag> get copyWith =>
      _ModTagCopyWithImpl<ModTag, ModTag>(this as ModTag, $identity, $identity);
  @override
  String toString() {
    return ModTagMapper.ensureInitialized().stringifyValue(this as ModTag);
  }

  @override
  bool operator ==(Object other) {
    return ModTagMapper.ensureInitialized().equalsValue(this as ModTag, other);
  }

  @override
  int get hashCode {
    return ModTagMapper.ensureInitialized().hashValue(this as ModTag);
  }
}

extension ModTagValueCopy<$R, $Out> on ObjectCopyWith<$R, ModTag, $Out> {
  ModTagCopyWith<$R, ModTag, $Out> get $asModTag =>
      $base.as((v, t, t2) => _ModTagCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ModTagCopyWith<$R, $In extends ModTag, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    String? id,
    String? name,
    String? type,
    ModTagIcon? icon,
    Color? color,
    bool? isUserCreated,
  });
  ModTagCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ModTagCopyWithImpl<$R, $Out> extends ClassCopyWithBase<$R, ModTag, $Out>
    implements ModTagCopyWith<$R, ModTag, $Out> {
  _ModTagCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ModTag> $mapper = ModTagMapper.ensureInitialized();
  @override
  $R call({
    String? id,
    String? name,
    String? type,
    Object? icon = $none,
    Object? color = $none,
    bool? isUserCreated,
  }) => $apply(
    FieldCopyWithData({
      if (id != null) #id: id,
      if (name != null) #name: name,
      if (type != null) #type: type,
      if (icon != $none) #icon: icon,
      if (color != $none) #color: color,
      if (isUserCreated != null) #isUserCreated: isUserCreated,
    }),
  );
  @override
  ModTag $make(CopyWithData data) => ModTag(
    id: data.get(#id, or: $value.id),
    name: data.get(#name, or: $value.name),
    type: data.get(#type, or: $value.type),
    icon: data.get(#icon, or: $value.icon),
    color: data.get(#color, or: $value.color),
    isUserCreated: data.get(#isUserCreated, or: $value.isUserCreated),
  );

  @override
  ModTagCopyWith<$R2, ModTag, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _ModTagCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

