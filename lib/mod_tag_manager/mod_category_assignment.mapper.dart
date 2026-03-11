// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'mod_category_assignment.dart';

class CategoryAssignmentSourceMapper
    extends EnumMapper<CategoryAssignmentSource> {
  CategoryAssignmentSourceMapper._();

  static CategoryAssignmentSourceMapper? _instance;
  static CategoryAssignmentSourceMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(
        _instance = CategoryAssignmentSourceMapper._(),
      );
    }
    return _instance!;
  }

  static CategoryAssignmentSource fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  CategoryAssignmentSource decode(dynamic value) {
    switch (value) {
      case r'user':
        return CategoryAssignmentSource.user;
      case r'automatic':
        return CategoryAssignmentSource.automatic;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(CategoryAssignmentSource self) {
    switch (self) {
      case CategoryAssignmentSource.user:
        return r'user';
      case CategoryAssignmentSource.automatic:
        return r'automatic';
    }
  }
}

extension CategoryAssignmentSourceMapperExtension on CategoryAssignmentSource {
  String toValue() {
    CategoryAssignmentSourceMapper.ensureInitialized();
    return MapperContainer.globals.toValue<CategoryAssignmentSource>(this)
        as String;
  }
}

class ModCategoryAssignmentMapper
    extends ClassMapperBase<ModCategoryAssignment> {
  ModCategoryAssignmentMapper._();

  static ModCategoryAssignmentMapper? _instance;
  static ModCategoryAssignmentMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ModCategoryAssignmentMapper._());
      CategoryAssignmentSourceMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ModCategoryAssignment';

  static String _$categoryId(ModCategoryAssignment v) => v.categoryId;
  static const Field<ModCategoryAssignment, String> _f$categoryId = Field(
    'categoryId',
    _$categoryId,
  );
  static bool _$isPrimary(ModCategoryAssignment v) => v.isPrimary;
  static const Field<ModCategoryAssignment, bool> _f$isPrimary = Field(
    'isPrimary',
    _$isPrimary,
    opt: true,
    def: false,
  );
  static CategoryAssignmentSource _$source(ModCategoryAssignment v) => v.source;
  static const Field<ModCategoryAssignment, CategoryAssignmentSource>
  _f$source = Field(
    'source',
    _$source,
    opt: true,
    def: CategoryAssignmentSource.user,
  );

  @override
  final MappableFields<ModCategoryAssignment> fields = const {
    #categoryId: _f$categoryId,
    #isPrimary: _f$isPrimary,
    #source: _f$source,
  };

  static ModCategoryAssignment _instantiate(DecodingData data) {
    return ModCategoryAssignment(
      categoryId: data.dec(_f$categoryId),
      isPrimary: data.dec(_f$isPrimary),
      source: data.dec(_f$source),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ModCategoryAssignment fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ModCategoryAssignment>(map);
  }

  static ModCategoryAssignment fromJson(String json) {
    return ensureInitialized().decodeJson<ModCategoryAssignment>(json);
  }
}

mixin ModCategoryAssignmentMappable {
  String toJson() {
    return ModCategoryAssignmentMapper.ensureInitialized()
        .encodeJson<ModCategoryAssignment>(this as ModCategoryAssignment);
  }

  Map<String, dynamic> toMap() {
    return ModCategoryAssignmentMapper.ensureInitialized()
        .encodeMap<ModCategoryAssignment>(this as ModCategoryAssignment);
  }

  ModCategoryAssignmentCopyWith<
    ModCategoryAssignment,
    ModCategoryAssignment,
    ModCategoryAssignment
  >
  get copyWith =>
      _ModCategoryAssignmentCopyWithImpl<
        ModCategoryAssignment,
        ModCategoryAssignment
      >(this as ModCategoryAssignment, $identity, $identity);
  @override
  String toString() {
    return ModCategoryAssignmentMapper.ensureInitialized().stringifyValue(
      this as ModCategoryAssignment,
    );
  }

  @override
  bool operator ==(Object other) {
    return ModCategoryAssignmentMapper.ensureInitialized().equalsValue(
      this as ModCategoryAssignment,
      other,
    );
  }

  @override
  int get hashCode {
    return ModCategoryAssignmentMapper.ensureInitialized().hashValue(
      this as ModCategoryAssignment,
    );
  }
}

extension ModCategoryAssignmentValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ModCategoryAssignment, $Out> {
  ModCategoryAssignmentCopyWith<$R, ModCategoryAssignment, $Out>
  get $asModCategoryAssignment => $base.as(
    (v, t, t2) => _ModCategoryAssignmentCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class ModCategoryAssignmentCopyWith<
  $R,
  $In extends ModCategoryAssignment,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    String? categoryId,
    bool? isPrimary,
    CategoryAssignmentSource? source,
  });
  ModCategoryAssignmentCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _ModCategoryAssignmentCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ModCategoryAssignment, $Out>
    implements ModCategoryAssignmentCopyWith<$R, ModCategoryAssignment, $Out> {
  _ModCategoryAssignmentCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ModCategoryAssignment> $mapper =
      ModCategoryAssignmentMapper.ensureInitialized();
  @override
  $R call({
    String? categoryId,
    bool? isPrimary,
    CategoryAssignmentSource? source,
  }) => $apply(
    FieldCopyWithData({
      if (categoryId != null) #categoryId: categoryId,
      if (isPrimary != null) #isPrimary: isPrimary,
      if (source != null) #source: source,
    }),
  );
  @override
  ModCategoryAssignment $make(CopyWithData data) => ModCategoryAssignment(
    categoryId: data.get(#categoryId, or: $value.categoryId),
    isPrimary: data.get(#isPrimary, or: $value.isPrimary),
    source: data.get(#source, or: $value.source),
  );

  @override
  ModCategoryAssignmentCopyWith<$R2, ModCategoryAssignment, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _ModCategoryAssignmentCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

