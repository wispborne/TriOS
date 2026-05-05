import 'dart:io';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/utils/dart_mappable_utils.dart';

part 'hullmod.mapper.dart';

@MappableClass(caseStyle: CaseStyle.lowerCase)
class Hullmod with HullmodMappable implements WispGridItem {
  @override
  String get key => id;

  final String id;
  final String? name;
  final int? tier;
  final double? rarity;
  @MappableField(key: 'tech/manufacturer')
  final String? techManufacturer;
  final String? tags;
  final String? uiTags;
  @MappableField(key: 'base value')
  final double? baseValue;
  final bool? unlocked;
  final bool? hidden;
  final bool? hiddenEverywhere;
  @MappableField(key: 'cost_frigate')
  final int? costFrigate;
  @MappableField(key: 'cost_dest')
  final int? costDest;
  @MappableField(key: 'cost_cruiser')
  final int? costCruiser;
  @MappableField(key: 'cost_capital')
  final int? costCapital;
  final String? script;
  final String? desc;
  @MappableField(key: 'short')
  final String? shortDescription;
  final String? sModDesc;
  final String? sprite;

  @MappableField(hook: SkipSerializationHook())
  late ModVariant? modVariant;
  @MappableField(hook: FileHook())
  File? csvFile;

  Hullmod({
    required this.id,
    this.name,
    this.tier,
    this.rarity,
    this.techManufacturer,
    this.tags,
    this.uiTags,
    this.baseValue,
    this.unlocked,
    this.hidden,
    this.hiddenEverywhere,
    this.costFrigate,
    this.costDest,
    this.costCruiser,
    this.costCapital,
    this.script,
    this.desc,
    this.shortDescription,
    this.sModDesc,
    this.sprite,
  });

  /// Returns the tags as a set of strings, with each tag trimmed and lowercased.
  late Set<String> tagsAsSet =
      tags?.split(',').map((tag) => tag.trim().toLowerCase()).toSet() ?? {};

  /// Returns the uiTags as a set of strings, with each tag trimmed and lowercased.
  late Set<String> uiTagsAsSet =
      uiTags?.split(',').map((tag) => tag.trim().toLowerCase()).toSet() ?? {};
}
