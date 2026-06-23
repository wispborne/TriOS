// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'sector_map_controller.dart';

class SectorMapModeMapper extends EnumMapper<SectorMapMode> {
  SectorMapModeMapper._();

  static SectorMapModeMapper? _instance;
  static SectorMapModeMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = SectorMapModeMapper._());
    }
    return _instance!;
  }

  static SectorMapMode fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  SectorMapMode decode(dynamic value) {
    switch (value) {
      case r'finder':
        return SectorMapMode.finder;
      case r'atlas':
        return SectorMapMode.atlas;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(SectorMapMode self) {
    switch (self) {
      case SectorMapMode.finder:
        return r'finder';
      case SectorMapMode.atlas:
        return r'atlas';
    }
  }
}

extension SectorMapModeMapperExtension on SectorMapMode {
  String toValue() {
    SectorMapModeMapper.ensureInitialized();
    return MapperContainer.globals.toValue<SectorMapMode>(this) as String;
  }
}

class SectorMapPageStatePersistedMapper
    extends ClassMapperBase<SectorMapPageStatePersisted> {
  SectorMapPageStatePersistedMapper._();

  static SectorMapPageStatePersistedMapper? _instance;
  static SectorMapPageStatePersistedMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(
        _instance = SectorMapPageStatePersistedMapper._(),
      );
      SectorMapModeMapper.ensureInitialized();
      FinderCriteriaMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'SectorMapPageStatePersisted';

  static SectorMapMode _$mode(SectorMapPageStatePersisted v) => v.mode;
  static const Field<SectorMapPageStatePersisted, SectorMapMode> _f$mode =
      Field('mode', _$mode, opt: true, def: SectorMapMode.finder);
  static FinderCriteria _$criteria(SectorMapPageStatePersisted v) => v.criteria;
  static const Field<SectorMapPageStatePersisted, FinderCriteria> _f$criteria =
      Field('criteria', _$criteria, opt: true, def: const FinderCriteria());

  @override
  final MappableFields<SectorMapPageStatePersisted> fields = const {
    #mode: _f$mode,
    #criteria: _f$criteria,
  };

  static SectorMapPageStatePersisted _instantiate(DecodingData data) {
    return SectorMapPageStatePersisted(
      mode: data.dec(_f$mode),
      criteria: data.dec(_f$criteria),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static SectorMapPageStatePersisted fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<SectorMapPageStatePersisted>(map);
  }

  static SectorMapPageStatePersisted fromJson(String json) {
    return ensureInitialized().decodeJson<SectorMapPageStatePersisted>(json);
  }
}

mixin SectorMapPageStatePersistedMappable {
  String toJson() {
    return SectorMapPageStatePersistedMapper.ensureInitialized()
        .encodeJson<SectorMapPageStatePersisted>(
          this as SectorMapPageStatePersisted,
        );
  }

  Map<String, dynamic> toMap() {
    return SectorMapPageStatePersistedMapper.ensureInitialized()
        .encodeMap<SectorMapPageStatePersisted>(
          this as SectorMapPageStatePersisted,
        );
  }

  SectorMapPageStatePersistedCopyWith<
    SectorMapPageStatePersisted,
    SectorMapPageStatePersisted,
    SectorMapPageStatePersisted
  >
  get copyWith =>
      _SectorMapPageStatePersistedCopyWithImpl<
        SectorMapPageStatePersisted,
        SectorMapPageStatePersisted
      >(this as SectorMapPageStatePersisted, $identity, $identity);
  @override
  String toString() {
    return SectorMapPageStatePersistedMapper.ensureInitialized().stringifyValue(
      this as SectorMapPageStatePersisted,
    );
  }

  @override
  bool operator ==(Object other) {
    return SectorMapPageStatePersistedMapper.ensureInitialized().equalsValue(
      this as SectorMapPageStatePersisted,
      other,
    );
  }

  @override
  int get hashCode {
    return SectorMapPageStatePersistedMapper.ensureInitialized().hashValue(
      this as SectorMapPageStatePersisted,
    );
  }
}

extension SectorMapPageStatePersistedValueCopy<$R, $Out>
    on ObjectCopyWith<$R, SectorMapPageStatePersisted, $Out> {
  SectorMapPageStatePersistedCopyWith<$R, SectorMapPageStatePersisted, $Out>
  get $asSectorMapPageStatePersisted => $base.as(
    (v, t, t2) => _SectorMapPageStatePersistedCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class SectorMapPageStatePersistedCopyWith<
  $R,
  $In extends SectorMapPageStatePersisted,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  FinderCriteriaCopyWith<$R, FinderCriteria, FinderCriteria> get criteria;
  $R call({SectorMapMode? mode, FinderCriteria? criteria});
  SectorMapPageStatePersistedCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _SectorMapPageStatePersistedCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, SectorMapPageStatePersisted, $Out>
    implements
        SectorMapPageStatePersistedCopyWith<
          $R,
          SectorMapPageStatePersisted,
          $Out
        > {
  _SectorMapPageStatePersistedCopyWithImpl(
    super.value,
    super.then,
    super.then2,
  );

  @override
  late final ClassMapperBase<SectorMapPageStatePersisted> $mapper =
      SectorMapPageStatePersistedMapper.ensureInitialized();
  @override
  FinderCriteriaCopyWith<$R, FinderCriteria, FinderCriteria> get criteria =>
      $value.criteria.copyWith.$chain((v) => call(criteria: v));
  @override
  $R call({SectorMapMode? mode, FinderCriteria? criteria}) => $apply(
    FieldCopyWithData({
      if (mode != null) #mode: mode,
      if (criteria != null) #criteria: criteria,
    }),
  );
  @override
  SectorMapPageStatePersisted $make(CopyWithData data) =>
      SectorMapPageStatePersisted(
        mode: data.get(#mode, or: $value.mode),
        criteria: data.get(#criteria, or: $value.criteria),
      );

  @override
  SectorMapPageStatePersistedCopyWith<$R2, SectorMapPageStatePersisted, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _SectorMapPageStatePersistedCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

