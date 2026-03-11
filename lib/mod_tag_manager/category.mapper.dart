// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'category.dart';

class CategoryIconMapper extends ClassMapperBase<CategoryIcon> {
  CategoryIconMapper._();

  static CategoryIconMapper? _instance;
  static CategoryIconMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = CategoryIconMapper._());
      MaterialCategoryIconMapper.ensureInitialized();
      SvgCategoryIconMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'CategoryIcon';

  @override
  final MappableFields<CategoryIcon> fields = const {};

  static CategoryIcon _instantiate(DecodingData data) {
    throw MapperException.missingSubclass(
      'CategoryIcon',
      'type',
      '${data.value['type']}',
    );
  }

  @override
  final Function instantiate = _instantiate;

  static CategoryIcon fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<CategoryIcon>(map);
  }

  static CategoryIcon fromJson(String json) {
    return ensureInitialized().decodeJson<CategoryIcon>(json);
  }
}

mixin CategoryIconMappable {
  String toJson();
  Map<String, dynamic> toMap();
  CategoryIconCopyWith<CategoryIcon, CategoryIcon, CategoryIcon> get copyWith;
}

abstract class CategoryIconCopyWith<$R, $In extends CategoryIcon, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call();
  CategoryIconCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class MaterialCategoryIconMapper
    extends SubClassMapperBase<MaterialCategoryIcon> {
  MaterialCategoryIconMapper._();

  static MaterialCategoryIconMapper? _instance;
  static MaterialCategoryIconMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = MaterialCategoryIconMapper._());
      CategoryIconMapper.ensureInitialized().addSubMapper(_instance!);
    }
    return _instance!;
  }

  @override
  final String id = 'MaterialCategoryIcon';

  static int _$codePoint(MaterialCategoryIcon v) => v.codePoint;
  static const Field<MaterialCategoryIcon, int> _f$codePoint = Field(
    'codePoint',
    _$codePoint,
  );

  @override
  final MappableFields<MaterialCategoryIcon> fields = const {
    #codePoint: _f$codePoint,
  };

  @override
  final String discriminatorKey = 'type';
  @override
  final dynamic discriminatorValue = 'material';
  @override
  late final ClassMapperBase superMapper =
      CategoryIconMapper.ensureInitialized();

  static MaterialCategoryIcon _instantiate(DecodingData data) {
    return MaterialCategoryIcon(data.dec(_f$codePoint));
  }

  @override
  final Function instantiate = _instantiate;

  static MaterialCategoryIcon fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<MaterialCategoryIcon>(map);
  }

  static MaterialCategoryIcon fromJson(String json) {
    return ensureInitialized().decodeJson<MaterialCategoryIcon>(json);
  }
}

mixin MaterialCategoryIconMappable {
  String toJson() {
    return MaterialCategoryIconMapper.ensureInitialized()
        .encodeJson<MaterialCategoryIcon>(this as MaterialCategoryIcon);
  }

  Map<String, dynamic> toMap() {
    return MaterialCategoryIconMapper.ensureInitialized()
        .encodeMap<MaterialCategoryIcon>(this as MaterialCategoryIcon);
  }

  MaterialCategoryIconCopyWith<
    MaterialCategoryIcon,
    MaterialCategoryIcon,
    MaterialCategoryIcon
  >
  get copyWith =>
      _MaterialCategoryIconCopyWithImpl<
        MaterialCategoryIcon,
        MaterialCategoryIcon
      >(this as MaterialCategoryIcon, $identity, $identity);
  @override
  String toString() {
    return MaterialCategoryIconMapper.ensureInitialized().stringifyValue(
      this as MaterialCategoryIcon,
    );
  }

  @override
  bool operator ==(Object other) {
    return MaterialCategoryIconMapper.ensureInitialized().equalsValue(
      this as MaterialCategoryIcon,
      other,
    );
  }

  @override
  int get hashCode {
    return MaterialCategoryIconMapper.ensureInitialized().hashValue(
      this as MaterialCategoryIcon,
    );
  }
}

extension MaterialCategoryIconValueCopy<$R, $Out>
    on ObjectCopyWith<$R, MaterialCategoryIcon, $Out> {
  MaterialCategoryIconCopyWith<$R, MaterialCategoryIcon, $Out>
  get $asMaterialCategoryIcon => $base.as(
    (v, t, t2) => _MaterialCategoryIconCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class MaterialCategoryIconCopyWith<
  $R,
  $In extends MaterialCategoryIcon,
  $Out
>
    implements CategoryIconCopyWith<$R, $In, $Out> {
  @override
  $R call({int? codePoint});
  MaterialCategoryIconCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _MaterialCategoryIconCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, MaterialCategoryIcon, $Out>
    implements MaterialCategoryIconCopyWith<$R, MaterialCategoryIcon, $Out> {
  _MaterialCategoryIconCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<MaterialCategoryIcon> $mapper =
      MaterialCategoryIconMapper.ensureInitialized();
  @override
  $R call({int? codePoint}) =>
      $apply(FieldCopyWithData({if (codePoint != null) #codePoint: codePoint}));
  @override
  MaterialCategoryIcon $make(CopyWithData data) =>
      MaterialCategoryIcon(data.get(#codePoint, or: $value.codePoint));

  @override
  MaterialCategoryIconCopyWith<$R2, MaterialCategoryIcon, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _MaterialCategoryIconCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class SvgCategoryIconMapper extends SubClassMapperBase<SvgCategoryIcon> {
  SvgCategoryIconMapper._();

  static SvgCategoryIconMapper? _instance;
  static SvgCategoryIconMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = SvgCategoryIconMapper._());
      CategoryIconMapper.ensureInitialized().addSubMapper(_instance!);
    }
    return _instance!;
  }

  @override
  final String id = 'SvgCategoryIcon';

  static String _$assetPath(SvgCategoryIcon v) => v.assetPath;
  static const Field<SvgCategoryIcon, String> _f$assetPath = Field(
    'assetPath',
    _$assetPath,
  );

  @override
  final MappableFields<SvgCategoryIcon> fields = const {
    #assetPath: _f$assetPath,
  };

  @override
  final String discriminatorKey = 'type';
  @override
  final dynamic discriminatorValue = 'svg';
  @override
  late final ClassMapperBase superMapper =
      CategoryIconMapper.ensureInitialized();

  static SvgCategoryIcon _instantiate(DecodingData data) {
    return SvgCategoryIcon(data.dec(_f$assetPath));
  }

  @override
  final Function instantiate = _instantiate;

  static SvgCategoryIcon fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<SvgCategoryIcon>(map);
  }

  static SvgCategoryIcon fromJson(String json) {
    return ensureInitialized().decodeJson<SvgCategoryIcon>(json);
  }
}

mixin SvgCategoryIconMappable {
  String toJson() {
    return SvgCategoryIconMapper.ensureInitialized()
        .encodeJson<SvgCategoryIcon>(this as SvgCategoryIcon);
  }

  Map<String, dynamic> toMap() {
    return SvgCategoryIconMapper.ensureInitialized().encodeMap<SvgCategoryIcon>(
      this as SvgCategoryIcon,
    );
  }

  SvgCategoryIconCopyWith<SvgCategoryIcon, SvgCategoryIcon, SvgCategoryIcon>
  get copyWith =>
      _SvgCategoryIconCopyWithImpl<SvgCategoryIcon, SvgCategoryIcon>(
        this as SvgCategoryIcon,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return SvgCategoryIconMapper.ensureInitialized().stringifyValue(
      this as SvgCategoryIcon,
    );
  }

  @override
  bool operator ==(Object other) {
    return SvgCategoryIconMapper.ensureInitialized().equalsValue(
      this as SvgCategoryIcon,
      other,
    );
  }

  @override
  int get hashCode {
    return SvgCategoryIconMapper.ensureInitialized().hashValue(
      this as SvgCategoryIcon,
    );
  }
}

extension SvgCategoryIconValueCopy<$R, $Out>
    on ObjectCopyWith<$R, SvgCategoryIcon, $Out> {
  SvgCategoryIconCopyWith<$R, SvgCategoryIcon, $Out> get $asSvgCategoryIcon =>
      $base.as((v, t, t2) => _SvgCategoryIconCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class SvgCategoryIconCopyWith<$R, $In extends SvgCategoryIcon, $Out>
    implements CategoryIconCopyWith<$R, $In, $Out> {
  @override
  $R call({String? assetPath});
  SvgCategoryIconCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _SvgCategoryIconCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, SvgCategoryIcon, $Out>
    implements SvgCategoryIconCopyWith<$R, SvgCategoryIcon, $Out> {
  _SvgCategoryIconCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<SvgCategoryIcon> $mapper =
      SvgCategoryIconMapper.ensureInitialized();
  @override
  $R call({String? assetPath}) =>
      $apply(FieldCopyWithData({if (assetPath != null) #assetPath: assetPath}));
  @override
  SvgCategoryIcon $make(CopyWithData data) =>
      SvgCategoryIcon(data.get(#assetPath, or: $value.assetPath));

  @override
  SvgCategoryIconCopyWith<$R2, SvgCategoryIcon, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _SvgCategoryIconCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class CategoryMapper extends ClassMapperBase<Category> {
  CategoryMapper._();

  static CategoryMapper? _instance;
  static CategoryMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = CategoryMapper._());
      CategoryIconMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'Category';

  static String _$id(Category v) => v.id;
  static const Field<Category, String> _f$id = Field('id', _$id);
  static String _$name(Category v) => v.name;
  static const Field<Category, String> _f$name = Field('name', _$name);
  static CategoryIcon? _$icon(Category v) => v.icon;
  static const Field<Category, CategoryIcon> _f$icon = Field(
    'icon',
    _$icon,
    opt: true,
  );
  static Color? _$color(Category v) => v.color;
  static const Field<Category, Color> _f$color = Field(
    'color',
    _$color,
    opt: true,
    hook: ColorHook(),
  );
  static bool _$isUserCreated(Category v) => v.isUserCreated;
  static const Field<Category, bool> _f$isUserCreated = Field(
    'isUserCreated',
    _$isUserCreated,
  );
  static bool _$isUserModified(Category v) => v.isUserModified;
  static const Field<Category, bool> _f$isUserModified = Field(
    'isUserModified',
    _$isUserModified,
    opt: true,
    def: false,
  );
  static int _$sortOrder(Category v) => v.sortOrder;
  static const Field<Category, int> _f$sortOrder = Field(
    'sortOrder',
    _$sortOrder,
    opt: true,
    def: 0,
  );

  @override
  final MappableFields<Category> fields = const {
    #id: _f$id,
    #name: _f$name,
    #icon: _f$icon,
    #color: _f$color,
    #isUserCreated: _f$isUserCreated,
    #isUserModified: _f$isUserModified,
    #sortOrder: _f$sortOrder,
  };

  static Category _instantiate(DecodingData data) {
    return Category(
      id: data.dec(_f$id),
      name: data.dec(_f$name),
      icon: data.dec(_f$icon),
      color: data.dec(_f$color),
      isUserCreated: data.dec(_f$isUserCreated),
      isUserModified: data.dec(_f$isUserModified),
      sortOrder: data.dec(_f$sortOrder),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static Category fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<Category>(map);
  }

  static Category fromJson(String json) {
    return ensureInitialized().decodeJson<Category>(json);
  }
}

mixin CategoryMappable {
  String toJson() {
    return CategoryMapper.ensureInitialized().encodeJson<Category>(
      this as Category,
    );
  }

  Map<String, dynamic> toMap() {
    return CategoryMapper.ensureInitialized().encodeMap<Category>(
      this as Category,
    );
  }

  CategoryCopyWith<Category, Category, Category> get copyWith =>
      _CategoryCopyWithImpl<Category, Category>(
        this as Category,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return CategoryMapper.ensureInitialized().stringifyValue(this as Category);
  }

  @override
  bool operator ==(Object other) {
    return CategoryMapper.ensureInitialized().equalsValue(
      this as Category,
      other,
    );
  }

  @override
  int get hashCode {
    return CategoryMapper.ensureInitialized().hashValue(this as Category);
  }
}

extension CategoryValueCopy<$R, $Out> on ObjectCopyWith<$R, Category, $Out> {
  CategoryCopyWith<$R, Category, $Out> get $asCategory =>
      $base.as((v, t, t2) => _CategoryCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class CategoryCopyWith<$R, $In extends Category, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  CategoryIconCopyWith<$R, CategoryIcon, CategoryIcon>? get icon;
  $R call({
    String? id,
    String? name,
    CategoryIcon? icon,
    Color? color,
    bool? isUserCreated,
    bool? isUserModified,
    int? sortOrder,
  });
  CategoryCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _CategoryCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, Category, $Out>
    implements CategoryCopyWith<$R, Category, $Out> {
  _CategoryCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<Category> $mapper =
      CategoryMapper.ensureInitialized();
  @override
  CategoryIconCopyWith<$R, CategoryIcon, CategoryIcon>? get icon =>
      $value.icon?.copyWith.$chain((v) => call(icon: v));
  @override
  $R call({
    String? id,
    String? name,
    Object? icon = $none,
    Object? color = $none,
    bool? isUserCreated,
    bool? isUserModified,
    int? sortOrder,
  }) => $apply(
    FieldCopyWithData({
      if (id != null) #id: id,
      if (name != null) #name: name,
      if (icon != $none) #icon: icon,
      if (color != $none) #color: color,
      if (isUserCreated != null) #isUserCreated: isUserCreated,
      if (isUserModified != null) #isUserModified: isUserModified,
      if (sortOrder != null) #sortOrder: sortOrder,
    }),
  );
  @override
  Category $make(CopyWithData data) => Category(
    id: data.get(#id, or: $value.id),
    name: data.get(#name, or: $value.name),
    icon: data.get(#icon, or: $value.icon),
    color: data.get(#color, or: $value.color),
    isUserCreated: data.get(#isUserCreated, or: $value.isUserCreated),
    isUserModified: data.get(#isUserModified, or: $value.isUserModified),
    sortOrder: data.get(#sortOrder, or: $value.sortOrder),
  );

  @override
  CategoryCopyWith<$R2, Category, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _CategoryCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

