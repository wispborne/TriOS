import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/material.dart';
import 'package:trios/utils/dart_mappable_utils.dart';
import 'package:trios/widgets/svg_image_icon.dart';
import 'package:uuid/uuid.dart';

part 'category.mapper.dart';

@MappableClass(discriminatorKey: 'type')
sealed class CategoryIcon with CategoryIconMappable {
  const CategoryIcon();

  Widget toWidget({double? size, Color? color}) => switch (this) {
    MaterialCategoryIcon(:final codePoint) => Icon(
      IconData(codePoint, fontFamily: 'MaterialIcons'),
      size: size,
      color: color,
    ),
    SvgCategoryIcon(:final assetPath) => SvgImageIcon(
      assetPath,
      width: size,
      height: size,
      color: color,
    ),
  };
}

@MappableClass(discriminatorValue: 'material')
class MaterialCategoryIcon extends CategoryIcon
    with MaterialCategoryIconMappable {
  final int codePoint;

  const MaterialCategoryIcon(this.codePoint);

  IconData get iconData => IconData(codePoint);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaterialCategoryIcon && codePoint == other.codePoint;

  @override
  int get hashCode => codePoint.hashCode;
}

@MappableClass(discriminatorValue: 'svg')
class SvgCategoryIcon extends CategoryIcon with SvgCategoryIconMappable {
  final String assetPath;

  const SvgCategoryIcon(this.assetPath);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SvgCategoryIcon && assetPath == other.assetPath;

  @override
  int get hashCode => assetPath.hashCode;
}

@MappableClass()
class Category with CategoryMappable {
  const Category({
    required this.id,
    required this.name,
    this.icon,
    this.color,
    required this.isUserCreated,
    this.isUserModified = false,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final CategoryIcon? icon;
  @MappableField(hook: ColorHook())
  final Color? color;
  final bool isUserCreated;

  /// Whether the user has modified this default category.
  /// Only meaningful when [isUserCreated] is false.
  final bool isUserModified;
  final int sortOrder;

  factory Category.create({
    required String name,
    required bool isUserCreated,
    Color? color,
    int sortOrder = 0,
  }) {
    return Category(
      id: const Uuid().v7(),
      name: name,
      isUserCreated: isUserCreated,
      color: color,
      sortOrder: sortOrder,
    );
  }
}
