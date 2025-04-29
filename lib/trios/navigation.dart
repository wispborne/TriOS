import 'package:dart_mappable/dart_mappable.dart';

part 'navigation.mapper.dart';

@MappableEnum(defaultValue: TriOSTools.dashboard)
enum TriOSTools {
  dashboard,
  modManager,
  modProfiles,
  vramEstimator,
  chipper,
  jreManager,
  portraits,
  weapons,
  ships,
  settings,
  catalog,
  tips,
}
