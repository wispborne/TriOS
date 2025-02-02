import 'package:dart_mappable/dart_mappable.dart';
import 'package:trios/models/mod_variant.dart';

part 'tip.mapper.dart';

@MappableClass()
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
