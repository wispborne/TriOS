import 'package:dart_mappable/dart_mappable.dart';
import 'package:trios/vram_estimator/models/graphics_lib_lunaconfig.dart';

part 'graphics_lib_config.mapper.dart';

@MappableClass()
class GraphicsLibConfig with GraphicsLibConfigMappable {
  @MappableField(key: 'enableShaders')
  final bool areAnyEffectsEnabled;

  @MappableField(key: 'enableNormal')
  final bool areGfxLibNormalMapsEnabled;

  @MappableField(key: 'loadMaterial')
  final bool areGfxLibMaterialMapsEnabled;

  @MappableField(key: 'loadSurface')
  final bool areGfxLibSurfaceMapsEnabled;

  @MappableField(key: 'autoGenNormals')
  final bool autoGenNormals;

  @MappableField(key: 'preloadAllMaps')
  final bool preloadAllMaps;

  const GraphicsLibConfig({
    required this.areAnyEffectsEnabled,
    required this.areGfxLibNormalMapsEnabled,
    required this.areGfxLibMaterialMapsEnabled,
    required this.areGfxLibSurfaceMapsEnabled,
    required this.autoGenNormals,
    required this.preloadAllMaps,
  });

  static const disabled = GraphicsLibConfig(
    areAnyEffectsEnabled: false,
    areGfxLibNormalMapsEnabled: false,
    areGfxLibMaterialMapsEnabled: false,
    areGfxLibSurfaceMapsEnabled: false,
    autoGenNormals: false,
    preloadAllMaps: false
  );
}
