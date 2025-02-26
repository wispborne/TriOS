// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'enabled_mods.dart';

class EnabledModsMapper extends ClassMapperBase<EnabledMods> {
  EnabledModsMapper._();

  static EnabledModsMapper? _instance;
  static EnabledModsMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = EnabledModsMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'EnabledMods';

  static Set<String> _$enabledMods(EnabledMods v) => v.enabledMods;
  static const Field<EnabledMods, Set<String>> _f$enabledMods = Field(
    'enabledMods',
    _$enabledMods,
  );

  @override
  final MappableFields<EnabledMods> fields = const {
    #enabledMods: _f$enabledMods,
  };

  static EnabledMods _instantiate(DecodingData data) {
    return EnabledMods(data.dec(_f$enabledMods));
  }

  @override
  final Function instantiate = _instantiate;

  static EnabledMods fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<EnabledMods>(map);
  }

  static EnabledMods fromJson(String json) {
    return ensureInitialized().decodeJson<EnabledMods>(json);
  }
}

mixin EnabledModsMappable {
  String toJson() {
    return EnabledModsMapper.ensureInitialized().encodeJson<EnabledMods>(
      this as EnabledMods,
    );
  }

  Map<String, dynamic> toMap() {
    return EnabledModsMapper.ensureInitialized().encodeMap<EnabledMods>(
      this as EnabledMods,
    );
  }

  EnabledModsCopyWith<EnabledMods, EnabledMods, EnabledMods> get copyWith =>
      _EnabledModsCopyWithImpl(this as EnabledMods, $identity, $identity);
  @override
  String toString() {
    return EnabledModsMapper.ensureInitialized().stringifyValue(
      this as EnabledMods,
    );
  }

  @override
  bool operator ==(Object other) {
    return EnabledModsMapper.ensureInitialized().equalsValue(
      this as EnabledMods,
      other,
    );
  }

  @override
  int get hashCode {
    return EnabledModsMapper.ensureInitialized().hashValue(this as EnabledMods);
  }
}

extension EnabledModsValueCopy<$R, $Out>
    on ObjectCopyWith<$R, EnabledMods, $Out> {
  EnabledModsCopyWith<$R, EnabledMods, $Out> get $asEnabledMods =>
      $base.as((v, t, t2) => _EnabledModsCopyWithImpl(v, t, t2));
}

abstract class EnabledModsCopyWith<$R, $In extends EnabledMods, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({Set<String>? enabledMods});
  EnabledModsCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _EnabledModsCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, EnabledMods, $Out>
    implements EnabledModsCopyWith<$R, EnabledMods, $Out> {
  _EnabledModsCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<EnabledMods> $mapper =
      EnabledModsMapper.ensureInitialized();
  @override
  $R call({Set<String>? enabledMods}) => $apply(
    FieldCopyWithData({if (enabledMods != null) #enabledMods: enabledMods}),
  );
  @override
  EnabledMods $make(CopyWithData data) =>
      EnabledMods(data.get(#enabledMods, or: $value.enabledMods));

  @override
  EnabledModsCopyWith<$R2, EnabledMods, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _EnabledModsCopyWithImpl($value, $cast, t);
}
