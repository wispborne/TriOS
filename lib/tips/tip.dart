import 'dart:io';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/utils/dart_mappable_utils.dart';

part 'tip.mapper.dart';

@MappableClass(hook: TipHooks())
class Tip with TipMappable {
  final String? freq;
  final String? tip;
  final String? originalFreq;

  const Tip({this.freq, this.tip, this.originalFreq});

  @override
  int get hashCode => tip?.hashCode ?? 0;

  @override
  bool operator ==(Object other) {
    if (other is Tip) {
      return tip == other.tip;
    }
    return false;
  }
}

@MappableClass()
class Tips with TipsMappable {
  final List<Tip>? tips;

  const Tips({this.tips});
}

@MappableClass()
class ModTip with ModTipMappable {
  final Tip tipObj;
  final List<ModVariant> variants;
  @MappableField(hook: FileHook())
  final File tipFile;

  const ModTip({
    required this.tipObj,
    required this.variants,
    required this.tipFile,
  });

  @override
  int get hashCode =>
      tipObj.hashCode ^ (variants.firstOrNull?.modInfo.id.hashCode ?? 0);

  @override
  bool operator ==(Object other) {
    if (other is ModTip) {
      return tipObj == other.tipObj && tipFile.path == other.tipFile.path;
    }
    return false;
  }
}

class TipHooks extends MappingHook {
  const TipHooks();

  @override
  dynamic beforeDecode(dynamic value) {
    // If the JSON item is just a string => short format (freq = "1", tip = string)
    if (value is String) {
      return {'freq': '1', 'tip': value};
    }

    // If it's a map => e.g. {"freq":0.75,"tip":"some text"} or missing freq
    if (value is Map) {
      final rawFreq = value['freq'];
      final freqStr = rawFreq == null ? '1' : rawFreq.toString();
      final tipStr = value['tip']?.toString();
      return {'freq': freqStr, 'tip': tipStr};
    }

    // Otherwise pass through
    return value;
  }
}
