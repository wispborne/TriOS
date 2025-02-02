import 'package:dart_mappable/dart_mappable.dart';
import 'package:trios/models/mod_variant.dart';

part 'tip.mapper.dart';

@MappableClass(hook: TipHooks())
class Tip with TipMappable {
  final String? freq;
  final String? tip;

  const Tip({this.freq, this.tip});
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

  const ModTip({required this.tipObj, required this.variants});
}

class TipHooks extends MappingHook {
  const TipHooks();

  @override
  dynamic beforeDecode(dynamic value) {
    // If the JSON item is just a string => short format (freq = "1", tip = string)
    if (value is String) {
      return {
        'freq': '1',
        'tip': value,
      };
    }

    // If it's a map => e.g. {"freq":0.75,"tip":"some text"} or missing freq
    if (value is Map) {
      final rawFreq = value['freq'];
      final freqStr = rawFreq == null ? '1' : rawFreq.toString();
      final tipStr = value['tip']?.toString();
      return {
        'freq': freqStr,
        'tip': tipStr,
      };
    }

    // Otherwise pass through
    return value;
  }
}
