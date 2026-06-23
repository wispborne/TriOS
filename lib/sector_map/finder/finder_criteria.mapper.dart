// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'finder_criteria.dart';

class ResourceCriterionMapper extends ClassMapperBase<ResourceCriterion> {
  ResourceCriterionMapper._();

  static ResourceCriterionMapper? _instance;
  static ResourceCriterionMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ResourceCriterionMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'ResourceCriterion';

  static int? _$minTier(ResourceCriterion v) => v.minTier;
  static const Field<ResourceCriterion, int> _f$minTier = Field(
    'minTier',
    _$minTier,
    opt: true,
  );
  static double _$weight(ResourceCriterion v) => v.weight;
  static const Field<ResourceCriterion, double> _f$weight = Field(
    'weight',
    _$weight,
    opt: true,
    def: 0.0,
  );

  @override
  final MappableFields<ResourceCriterion> fields = const {
    #minTier: _f$minTier,
    #weight: _f$weight,
  };

  static ResourceCriterion _instantiate(DecodingData data) {
    return ResourceCriterion(
      minTier: data.dec(_f$minTier),
      weight: data.dec(_f$weight),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ResourceCriterion fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ResourceCriterion>(map);
  }

  static ResourceCriterion fromJson(String json) {
    return ensureInitialized().decodeJson<ResourceCriterion>(json);
  }
}

mixin ResourceCriterionMappable {
  String toJson() {
    return ResourceCriterionMapper.ensureInitialized()
        .encodeJson<ResourceCriterion>(this as ResourceCriterion);
  }

  Map<String, dynamic> toMap() {
    return ResourceCriterionMapper.ensureInitialized()
        .encodeMap<ResourceCriterion>(this as ResourceCriterion);
  }

  ResourceCriterionCopyWith<
    ResourceCriterion,
    ResourceCriterion,
    ResourceCriterion
  >
  get copyWith =>
      _ResourceCriterionCopyWithImpl<ResourceCriterion, ResourceCriterion>(
        this as ResourceCriterion,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return ResourceCriterionMapper.ensureInitialized().stringifyValue(
      this as ResourceCriterion,
    );
  }

  @override
  bool operator ==(Object other) {
    return ResourceCriterionMapper.ensureInitialized().equalsValue(
      this as ResourceCriterion,
      other,
    );
  }

  @override
  int get hashCode {
    return ResourceCriterionMapper.ensureInitialized().hashValue(
      this as ResourceCriterion,
    );
  }
}

extension ResourceCriterionValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ResourceCriterion, $Out> {
  ResourceCriterionCopyWith<$R, ResourceCriterion, $Out>
  get $asResourceCriterion => $base.as(
    (v, t, t2) => _ResourceCriterionCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class ResourceCriterionCopyWith<
  $R,
  $In extends ResourceCriterion,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({int? minTier, double? weight});
  ResourceCriterionCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _ResourceCriterionCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ResourceCriterion, $Out>
    implements ResourceCriterionCopyWith<$R, ResourceCriterion, $Out> {
  _ResourceCriterionCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ResourceCriterion> $mapper =
      ResourceCriterionMapper.ensureInitialized();
  @override
  $R call({Object? minTier = $none, double? weight}) => $apply(
    FieldCopyWithData({
      if (minTier != $none) #minTier: minTier,
      if (weight != null) #weight: weight,
    }),
  );
  @override
  ResourceCriterion $make(CopyWithData data) => ResourceCriterion(
    minTier: data.get(#minTier, or: $value.minTier),
    weight: data.get(#weight, or: $value.weight),
  );

  @override
  ResourceCriterionCopyWith<$R2, ResourceCriterion, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ResourceCriterionCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class FinderCriteriaMapper extends ClassMapperBase<FinderCriteria> {
  FinderCriteriaMapper._();

  static FinderCriteriaMapper? _instance;
  static FinderCriteriaMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = FinderCriteriaMapper._());
      ResourceCriterionMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'FinderCriteria';

  static Map<String, ResourceCriterion> _$resources(FinderCriteria v) =>
      v.resources;
  static const Field<FinderCriteria, Map<String, ResourceCriterion>>
  _f$resources = Field('resources', _$resources, opt: true, def: const {});
  static bool _$mustBeHabitable(FinderCriteria v) => v.mustBeHabitable;
  static const Field<FinderCriteria, bool> _f$mustBeHabitable = Field(
    'mustBeHabitable',
    _$mustBeHabitable,
    opt: true,
    def: false,
  );
  static bool _$mustHaveGasGiant(FinderCriteria v) => v.mustHaveGasGiant;
  static const Field<FinderCriteria, bool> _f$mustHaveGasGiant = Field(
    'mustHaveGasGiant',
    _$mustHaveGasGiant,
    opt: true,
    def: false,
  );
  static bool _$excludeColonized(FinderCriteria v) => v.excludeColonized;
  static const Field<FinderCriteria, bool> _f$excludeColonized = Field(
    'excludeColonized',
    _$excludeColonized,
    opt: true,
    def: false,
  );
  static int _$minStableLocations(FinderCriteria v) => v.minStableLocations;
  static const Field<FinderCriteria, int> _f$minStableLocations = Field(
    'minStableLocations',
    _$minStableLocations,
    opt: true,
    def: 0,
  );
  static Map<String, bool> _$landmarkNearby(FinderCriteria v) =>
      v.landmarkNearby;
  static const Field<FinderCriteria, Map<String, bool>> _f$landmarkNearby =
      Field('landmarkNearby', _$landmarkNearby, opt: true, def: const {});
  static double _$nearbyRangeLy(FinderCriteria v) => v.nearbyRangeLy;
  static const Field<FinderCriteria, double> _f$nearbyRangeLy = Field(
    'nearbyRangeLy',
    _$nearbyRangeLy,
    opt: true,
    def: 10.0,
  );
  static Map<String, bool> _$otherConditionToggles(FinderCriteria v) =>
      v.otherConditionToggles;
  static const Field<FinderCriteria, Map<String, bool>>
  _f$otherConditionToggles = Field(
    'otherConditionToggles',
    _$otherConditionToggles,
    opt: true,
    def: const {},
  );
  static double? _$maxDistanceFromCoreLy(FinderCriteria v) =>
      v.maxDistanceFromCoreLy;
  static const Field<FinderCriteria, double> _f$maxDistanceFromCoreLy = Field(
    'maxDistanceFromCoreLy',
    _$maxDistanceFromCoreLy,
    opt: true,
  );
  static double _$closeToCoreWeight(FinderCriteria v) => v.closeToCoreWeight;
  static const Field<FinderCriteria, double> _f$closeToCoreWeight = Field(
    'closeToCoreWeight',
    _$closeToCoreWeight,
    opt: true,
    def: 0.0,
  );
  static double _$lowHazardWeight(FinderCriteria v) => v.lowHazardWeight;
  static const Field<FinderCriteria, double> _f$lowHazardWeight = Field(
    'lowHazardWeight',
    _$lowHazardWeight,
    opt: true,
    def: 0.0,
  );

  @override
  final MappableFields<FinderCriteria> fields = const {
    #resources: _f$resources,
    #mustBeHabitable: _f$mustBeHabitable,
    #mustHaveGasGiant: _f$mustHaveGasGiant,
    #excludeColonized: _f$excludeColonized,
    #minStableLocations: _f$minStableLocations,
    #landmarkNearby: _f$landmarkNearby,
    #nearbyRangeLy: _f$nearbyRangeLy,
    #otherConditionToggles: _f$otherConditionToggles,
    #maxDistanceFromCoreLy: _f$maxDistanceFromCoreLy,
    #closeToCoreWeight: _f$closeToCoreWeight,
    #lowHazardWeight: _f$lowHazardWeight,
  };

  static FinderCriteria _instantiate(DecodingData data) {
    return FinderCriteria(
      resources: data.dec(_f$resources),
      mustBeHabitable: data.dec(_f$mustBeHabitable),
      mustHaveGasGiant: data.dec(_f$mustHaveGasGiant),
      excludeColonized: data.dec(_f$excludeColonized),
      minStableLocations: data.dec(_f$minStableLocations),
      landmarkNearby: data.dec(_f$landmarkNearby),
      nearbyRangeLy: data.dec(_f$nearbyRangeLy),
      otherConditionToggles: data.dec(_f$otherConditionToggles),
      maxDistanceFromCoreLy: data.dec(_f$maxDistanceFromCoreLy),
      closeToCoreWeight: data.dec(_f$closeToCoreWeight),
      lowHazardWeight: data.dec(_f$lowHazardWeight),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static FinderCriteria fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<FinderCriteria>(map);
  }

  static FinderCriteria fromJson(String json) {
    return ensureInitialized().decodeJson<FinderCriteria>(json);
  }
}

mixin FinderCriteriaMappable {
  String toJson() {
    return FinderCriteriaMapper.ensureInitialized().encodeJson<FinderCriteria>(
      this as FinderCriteria,
    );
  }

  Map<String, dynamic> toMap() {
    return FinderCriteriaMapper.ensureInitialized().encodeMap<FinderCriteria>(
      this as FinderCriteria,
    );
  }

  FinderCriteriaCopyWith<FinderCriteria, FinderCriteria, FinderCriteria>
  get copyWith => _FinderCriteriaCopyWithImpl<FinderCriteria, FinderCriteria>(
    this as FinderCriteria,
    $identity,
    $identity,
  );
  @override
  String toString() {
    return FinderCriteriaMapper.ensureInitialized().stringifyValue(
      this as FinderCriteria,
    );
  }

  @override
  bool operator ==(Object other) {
    return FinderCriteriaMapper.ensureInitialized().equalsValue(
      this as FinderCriteria,
      other,
    );
  }

  @override
  int get hashCode {
    return FinderCriteriaMapper.ensureInitialized().hashValue(
      this as FinderCriteria,
    );
  }
}

extension FinderCriteriaValueCopy<$R, $Out>
    on ObjectCopyWith<$R, FinderCriteria, $Out> {
  FinderCriteriaCopyWith<$R, FinderCriteria, $Out> get $asFinderCriteria =>
      $base.as((v, t, t2) => _FinderCriteriaCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class FinderCriteriaCopyWith<$R, $In extends FinderCriteria, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  MapCopyWith<
    $R,
    String,
    ResourceCriterion,
    ResourceCriterionCopyWith<$R, ResourceCriterion, ResourceCriterion>
  >
  get resources;
  MapCopyWith<$R, String, bool, ObjectCopyWith<$R, bool, bool>>
  get landmarkNearby;
  MapCopyWith<$R, String, bool, ObjectCopyWith<$R, bool, bool>>
  get otherConditionToggles;
  $R call({
    Map<String, ResourceCriterion>? resources,
    bool? mustBeHabitable,
    bool? mustHaveGasGiant,
    bool? excludeColonized,
    int? minStableLocations,
    Map<String, bool>? landmarkNearby,
    double? nearbyRangeLy,
    Map<String, bool>? otherConditionToggles,
    double? maxDistanceFromCoreLy,
    double? closeToCoreWeight,
    double? lowHazardWeight,
  });
  FinderCriteriaCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _FinderCriteriaCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, FinderCriteria, $Out>
    implements FinderCriteriaCopyWith<$R, FinderCriteria, $Out> {
  _FinderCriteriaCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<FinderCriteria> $mapper =
      FinderCriteriaMapper.ensureInitialized();
  @override
  MapCopyWith<
    $R,
    String,
    ResourceCriterion,
    ResourceCriterionCopyWith<$R, ResourceCriterion, ResourceCriterion>
  >
  get resources => MapCopyWith(
    $value.resources,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(resources: v),
  );
  @override
  MapCopyWith<$R, String, bool, ObjectCopyWith<$R, bool, bool>>
  get landmarkNearby => MapCopyWith(
    $value.landmarkNearby,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(landmarkNearby: v),
  );
  @override
  MapCopyWith<$R, String, bool, ObjectCopyWith<$R, bool, bool>>
  get otherConditionToggles => MapCopyWith(
    $value.otherConditionToggles,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(otherConditionToggles: v),
  );
  @override
  $R call({
    Map<String, ResourceCriterion>? resources,
    bool? mustBeHabitable,
    bool? mustHaveGasGiant,
    bool? excludeColonized,
    int? minStableLocations,
    Map<String, bool>? landmarkNearby,
    double? nearbyRangeLy,
    Map<String, bool>? otherConditionToggles,
    Object? maxDistanceFromCoreLy = $none,
    double? closeToCoreWeight,
    double? lowHazardWeight,
  }) => $apply(
    FieldCopyWithData({
      if (resources != null) #resources: resources,
      if (mustBeHabitable != null) #mustBeHabitable: mustBeHabitable,
      if (mustHaveGasGiant != null) #mustHaveGasGiant: mustHaveGasGiant,
      if (excludeColonized != null) #excludeColonized: excludeColonized,
      if (minStableLocations != null) #minStableLocations: minStableLocations,
      if (landmarkNearby != null) #landmarkNearby: landmarkNearby,
      if (nearbyRangeLy != null) #nearbyRangeLy: nearbyRangeLy,
      if (otherConditionToggles != null)
        #otherConditionToggles: otherConditionToggles,
      if (maxDistanceFromCoreLy != $none)
        #maxDistanceFromCoreLy: maxDistanceFromCoreLy,
      if (closeToCoreWeight != null) #closeToCoreWeight: closeToCoreWeight,
      if (lowHazardWeight != null) #lowHazardWeight: lowHazardWeight,
    }),
  );
  @override
  FinderCriteria $make(CopyWithData data) => FinderCriteria(
    resources: data.get(#resources, or: $value.resources),
    mustBeHabitable: data.get(#mustBeHabitable, or: $value.mustBeHabitable),
    mustHaveGasGiant: data.get(#mustHaveGasGiant, or: $value.mustHaveGasGiant),
    excludeColonized: data.get(#excludeColonized, or: $value.excludeColonized),
    minStableLocations: data.get(
      #minStableLocations,
      or: $value.minStableLocations,
    ),
    landmarkNearby: data.get(#landmarkNearby, or: $value.landmarkNearby),
    nearbyRangeLy: data.get(#nearbyRangeLy, or: $value.nearbyRangeLy),
    otherConditionToggles: data.get(
      #otherConditionToggles,
      or: $value.otherConditionToggles,
    ),
    maxDistanceFromCoreLy: data.get(
      #maxDistanceFromCoreLy,
      or: $value.maxDistanceFromCoreLy,
    ),
    closeToCoreWeight: data.get(
      #closeToCoreWeight,
      or: $value.closeToCoreWeight,
    ),
    lowHazardWeight: data.get(#lowHazardWeight, or: $value.lowHazardWeight),
  );

  @override
  FinderCriteriaCopyWith<$R2, FinderCriteria, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _FinderCriteriaCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

