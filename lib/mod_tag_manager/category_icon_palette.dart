import 'package:flutter/material.dart';
import 'package:trios/mod_tag_manager/category.dart';

/// Curated SVG icons suitable as category markers.
const List<SvgCategoryIcon> categorySvgIcons = [
  SvgCategoryIcon('assets/images/icon-death-star.svg'),
  SvgCategoryIcon('assets/images/icon-onslaught.svg'),
  SvgCategoryIcon('assets/images/icon-space-invaders.svg'),
  SvgCategoryIcon('assets/images/icon-admin-shield.svg'),
  SvgCategoryIcon('assets/images/icon-admin-shield-half.svg'),
  SvgCategoryIcon('assets/images/icon-bookshelf.svg'),
  SvgCategoryIcon('assets/images/icon-toolbox.svg'),
  SvgCategoryIcon('assets/images/icon-archive.svg'),
  SvgCategoryIcon('assets/images/icon-utility-mod.svg'),
  SvgCategoryIcon('assets/images/icon-experimental.svg'),
  SvgCategoryIcon('assets/images/icon-test-radioactive.svg'),
  SvgCategoryIcon('assets/images/icon-dice.svg'),
  SvgCategoryIcon('assets/images/icon-target.svg'),
  SvgCategoryIcon('assets/images/icon-spider-web.svg'),
  SvgCategoryIcon('assets/images/icon-traffic-cone.svg'),
  SvgCategoryIcon('assets/images/icon-bullhorn-variant.svg'),
  SvgCategoryIcon('assets/images/icon-incognito-circle.svg'),
  SvgCategoryIcon('assets/images/icon-podium-gold.svg'),
  SvgCategoryIcon('assets/images/icon-broom.svg'),
  SvgCategoryIcon('assets/images/icon-repair.svg'),
  SvgCategoryIcon('assets/images/icon-tips.svg'),
  SvgCategoryIcon('assets/images/icon-ice-cream.svg'),
  SvgCategoryIcon('assets/images/icon-power.svg'),
  SvgCategoryIcon('assets/images/icon-weight.svg'),
  SvgCategoryIcon('assets/images/icon-settings.svg'),
  SvgCategoryIcon('assets/images/icon-tag.svg'),
  SvgCategoryIcon('assets/images/icon-image.svg'),
  SvgCategoryIcon('assets/images/icon-view-carousel.svg'),
  SvgCategoryIcon('assets/images/icon-debug.svg'),
  SvgCategoryIcon('assets/images/icon-account-box-outline.svg'),
];

/// Curated Material Design icons suitable as category markers.
final List<MaterialCategoryIcon> categoryMaterialIcons = [
  MaterialCategoryIcon(Icons.star.codePoint),
  MaterialCategoryIcon(Icons.shield.codePoint),
  MaterialCategoryIcon(Icons.build.codePoint),
  MaterialCategoryIcon(Icons.palette.codePoint),
  MaterialCategoryIcon(Icons.electric_bolt.codePoint),
  MaterialCategoryIcon(Icons.rocket_launch.codePoint),
  MaterialCategoryIcon(Icons.science.codePoint),
  MaterialCategoryIcon(Icons.favorite.codePoint),
  MaterialCategoryIcon(Icons.category.codePoint),
  MaterialCategoryIcon(Icons.extension.codePoint),
  MaterialCategoryIcon(Icons.auto_awesome.codePoint),
  MaterialCategoryIcon(Icons.military_tech.codePoint),
];

/// All available category icons, SVG first then Material.
List<CategoryIcon> get allCategoryIcons => [
  ...categorySvgIcons,
  ...categoryMaterialIcons,
];
