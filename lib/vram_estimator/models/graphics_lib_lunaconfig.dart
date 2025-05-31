import 'package:dart_mappable/dart_mappable.dart';
import 'package:trios/vram_estimator/models/graphics_lib_config.dart';

part 'graphics_lib_lunaconfig.mapper.dart';

@MappableClass()
class GraphicsLibLunaConfig with GraphicsLibLunaConfigMappable {
  final bool aaCompatMode;
  final bool autoGenNormals;
  final bool enableNormal;
  final bool enableShaders;
  final bool loadMaterial;
  final bool loadSurface;
  final bool optimizeNormals;
  final bool preloadAllMaps;

  const GraphicsLibLunaConfig({
    this.aaCompatMode = false,
    this.autoGenNormals = true,
    this.enableNormal = true,
    this.enableShaders = true,
    this.loadMaterial = true,
    this.loadSurface = true,
    this.optimizeNormals = false,
    this.preloadAllMaps = false,
  });

  GraphicsLibConfig toGraphicsLibConfig() {
    return GraphicsLibConfig(
      areAnyEffectsEnabled: enableShaders,
      areGfxLibNormalMapsEnabled: enableNormal,
      areGfxLibMaterialMapsEnabled: loadMaterial,
      areGfxLibSurfaceMapsEnabled: loadSurface,
      autoGenNormals: autoGenNormals,
      preloadAllMaps: preloadAllMaps,
    );
  }
}
