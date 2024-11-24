import 'package:dart_mappable/dart_mappable.dart';

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

  const GraphicsLibConfig({
    required this.areAnyEffectsEnabled,
    required this.areGfxLibNormalMapsEnabled,
    required this.areGfxLibMaterialMapsEnabled,
    required this.areGfxLibSurfaceMapsEnabled,
  });

  static const disabled = GraphicsLibConfig(
    areAnyEffectsEnabled: false,
    areGfxLibNormalMapsEnabled: false,
    areGfxLibMaterialMapsEnabled: false,
    areGfxLibSurfaceMapsEnabled: false,
  );
}
