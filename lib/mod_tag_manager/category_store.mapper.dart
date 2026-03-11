// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'category_store.dart';

class CategoryStoreMapper extends ClassMapperBase<CategoryStore> {
  CategoryStoreMapper._();

  static CategoryStoreMapper? _instance;
  static CategoryStoreMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = CategoryStoreMapper._());
      CategoryMapper.ensureInitialized();
      ModCategoryAssignmentMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'CategoryStore';

  static List<Category> _$categories(CategoryStore v) => v.categories;
  static const Field<CategoryStore, List<Category>> _f$categories = Field(
    'categories',
    _$categories,
    opt: true,
    def: const [],
  );
  static Map<String, List<ModCategoryAssignment>> _$modAssignments(
    CategoryStore v,
  ) => v.modAssignments;
  static const Field<CategoryStore, Map<String, List<ModCategoryAssignment>>>
  _f$modAssignments = Field(
    'modAssignments',
    _$modAssignments,
    opt: true,
    def: const {},
  );
  static bool _$autoColorNewCategories(CategoryStore v) =>
      v.autoColorNewCategories;
  static const Field<CategoryStore, bool> _f$autoColorNewCategories = Field(
    'autoColorNewCategories',
    _$autoColorNewCategories,
    opt: true,
    def: true,
  );

  @override
  final MappableFields<CategoryStore> fields = const {
    #categories: _f$categories,
    #modAssignments: _f$modAssignments,
    #autoColorNewCategories: _f$autoColorNewCategories,
  };

  static CategoryStore _instantiate(DecodingData data) {
    return CategoryStore(
      categories: data.dec(_f$categories),
      modAssignments: data.dec(_f$modAssignments),
      autoColorNewCategories: data.dec(_f$autoColorNewCategories),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static CategoryStore fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<CategoryStore>(map);
  }

  static CategoryStore fromJson(String json) {
    return ensureInitialized().decodeJson<CategoryStore>(json);
  }
}

mixin CategoryStoreMappable {
  String toJson() {
    return CategoryStoreMapper.ensureInitialized().encodeJson<CategoryStore>(
      this as CategoryStore,
    );
  }

  Map<String, dynamic> toMap() {
    return CategoryStoreMapper.ensureInitialized().encodeMap<CategoryStore>(
      this as CategoryStore,
    );
  }

  CategoryStoreCopyWith<CategoryStore, CategoryStore, CategoryStore>
  get copyWith => _CategoryStoreCopyWithImpl<CategoryStore, CategoryStore>(
    this as CategoryStore,
    $identity,
    $identity,
  );
  @override
  String toString() {
    return CategoryStoreMapper.ensureInitialized().stringifyValue(
      this as CategoryStore,
    );
  }

  @override
  bool operator ==(Object other) {
    return CategoryStoreMapper.ensureInitialized().equalsValue(
      this as CategoryStore,
      other,
    );
  }

  @override
  int get hashCode {
    return CategoryStoreMapper.ensureInitialized().hashValue(
      this as CategoryStore,
    );
  }
}

extension CategoryStoreValueCopy<$R, $Out>
    on ObjectCopyWith<$R, CategoryStore, $Out> {
  CategoryStoreCopyWith<$R, CategoryStore, $Out> get $asCategoryStore =>
      $base.as((v, t, t2) => _CategoryStoreCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class CategoryStoreCopyWith<$R, $In extends CategoryStore, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, Category, CategoryCopyWith<$R, Category, Category>>
  get categories;
  MapCopyWith<
    $R,
    String,
    List<ModCategoryAssignment>,
    ObjectCopyWith<$R, List<ModCategoryAssignment>, List<ModCategoryAssignment>>
  >
  get modAssignments;
  $R call({
    List<Category>? categories,
    Map<String, List<ModCategoryAssignment>>? modAssignments,
    bool? autoColorNewCategories,
  });
  CategoryStoreCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _CategoryStoreCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, CategoryStore, $Out>
    implements CategoryStoreCopyWith<$R, CategoryStore, $Out> {
  _CategoryStoreCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<CategoryStore> $mapper =
      CategoryStoreMapper.ensureInitialized();
  @override
  ListCopyWith<$R, Category, CategoryCopyWith<$R, Category, Category>>
  get categories => ListCopyWith(
    $value.categories,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(categories: v),
  );
  @override
  MapCopyWith<
    $R,
    String,
    List<ModCategoryAssignment>,
    ObjectCopyWith<$R, List<ModCategoryAssignment>, List<ModCategoryAssignment>>
  >
  get modAssignments => MapCopyWith(
    $value.modAssignments,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(modAssignments: v),
  );
  @override
  $R call({
    List<Category>? categories,
    Map<String, List<ModCategoryAssignment>>? modAssignments,
    bool? autoColorNewCategories,
  }) => $apply(
    FieldCopyWithData({
      if (categories != null) #categories: categories,
      if (modAssignments != null) #modAssignments: modAssignments,
      if (autoColorNewCategories != null)
        #autoColorNewCategories: autoColorNewCategories,
    }),
  );
  @override
  CategoryStore $make(CopyWithData data) => CategoryStore(
    categories: data.get(#categories, or: $value.categories),
    modAssignments: data.get(#modAssignments, or: $value.modAssignments),
    autoColorNewCategories: data.get(
      #autoColorNewCategories,
      or: $value.autoColorNewCategories,
    ),
  );

  @override
  CategoryStoreCopyWith<$R2, CategoryStore, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _CategoryStoreCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

