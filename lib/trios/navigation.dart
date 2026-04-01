import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/material.dart';
import 'package:trios/widgets/svg_image_icon.dart';

part 'navigation.mapper.dart';

@MappableEnum(defaultValue: TriOSTools.dashboard)
enum TriOSTools {
  dashboard,
  modManager,
  modProfiles,
  vramEstimator,
  chipper,
  portraits,
  weapons,
  ships,
  hullmods,
  settings,
  catalog,
  tips,
}

enum NavGroup { core, viewers, bottom }

extension TriOSToolsUI on TriOSTools {
  String get label => switch (this) {
    TriOSTools.dashboard => 'Dash',
    TriOSTools.modManager => 'Mods',
    TriOSTools.modProfiles => 'Profiles',
    TriOSTools.catalog => 'Catalog',
    TriOSTools.chipper => 'Logs',
    TriOSTools.vramEstimator => 'VRAM Estimator',
    TriOSTools.ships => 'Ships',
    TriOSTools.weapons => 'Weapons',
    TriOSTools.hullmods => 'Hullmods',
    TriOSTools.portraits => 'Portraits',
    TriOSTools.tips => 'Tips',
    TriOSTools.settings => 'Settings',
  };

  String get tooltip => switch (this) {
    TriOSTools.dashboard => 'Dashboard',
    TriOSTools.modManager => 'Mod Manager',
    TriOSTools.modProfiles => 'Mod Profiles',
    TriOSTools.catalog => 'Browse online mods',
    TriOSTools.chipper => 'Log Viewer',
    TriOSTools.vramEstimator => 'VRAM Estimator',
    TriOSTools.ships => 'Ship Viewer',
    TriOSTools.weapons => 'Weapon Viewer',
    TriOSTools.hullmods => 'Hullmod Viewer',
    TriOSTools.portraits => 'Portrait Viewer & Replacer',
    TriOSTools.tips => 'Tips Manager',
    TriOSTools.settings => 'Settings',
  };

  Widget icon({double size = 24, Color? color}) => switch (this) {
    TriOSTools.dashboard => Icon(Icons.dashboard, size: size, color: color),
    TriOSTools.modManager => Transform.rotate(
      angle: 0.7,
      child: SvgImageIcon(
        "assets/images/icon-onslaught.svg",
        height: size,
        width: size,
        color: color,
      ),
    ),
    TriOSTools.modProfiles => SvgImageIcon(
      "assets/images/icon-view-carousel.svg",
      height: size,
      width: size,
      color: color,
    ),
    TriOSTools.catalog => Icon(Icons.cloud_download, size: size, color: color),
    TriOSTools.chipper => ImageIcon(
      AssetImage("assets/images/chipper/icon.png"),
      size: size - 2,
      color: color,
    ),
    TriOSTools.vramEstimator => SvgImageIcon(
      "assets/images/icon-weight.svg",
      color: color,
    ),
    TriOSTools.ships => SvgImageIcon(
      "assets/images/icon-onslaught.svg",
      height: size,
      width: size,
      color: color,
    ),
    TriOSTools.weapons => SvgImageIcon(
      "assets/images/icon-target.svg",
      color: color,
    ),
    TriOSTools.hullmods => SvgImageIcon(
      "assets/images/icon-hullmod.svg",
      height: size,
      width: size,
      color: color,
    ),
    TriOSTools.portraits => SvgImageIcon(
      "assets/images/icon-account-box-outline.svg",
      color: color,
    ),
    TriOSTools.tips => Icon(Icons.lightbulb, size: size, color: color),
    TriOSTools.settings => Icon(Icons.settings, size: size, color: color),
  };

  NavGroup get group => switch (this) {
    TriOSTools.dashboard ||
    TriOSTools.modManager ||
    TriOSTools.modProfiles ||
    TriOSTools.catalog ||
    TriOSTools.chipper => NavGroup.core,
    TriOSTools.vramEstimator ||
    TriOSTools.ships ||
    TriOSTools.weapons ||
    TriOSTools.hullmods ||
    TriOSTools.portraits ||
    TriOSTools.tips => NavGroup.viewers,
    TriOSTools.settings => NavGroup.bottom,
  };
}
