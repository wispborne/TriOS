class GraphicsLibConfig {
// @SerializedName("enableShaders")
  bool areAnyEffectsEnabled;

// @SerializedName("enableNormal")
  bool areGfxLibNormalMapsEnabled;

// @SerializedName("loadMaterial")
  bool areGfxLibMaterialMapsEnabled;

// @SerializedName("loadSurface")
  bool areGfxLibSurfaceMapsEnabled;

  GraphicsLibConfig(
      {required this.areAnyEffectsEnabled,
      required this.areGfxLibNormalMapsEnabled,
      required this.areGfxLibMaterialMapsEnabled,
      required this.areGfxLibSurfaceMapsEnabled});

  static final Disabled = GraphicsLibConfig(
      areAnyEffectsEnabled: false,
      areGfxLibNormalMapsEnabled: false,
      areGfxLibMaterialMapsEnabled: false,
      areGfxLibSurfaceMapsEnabled: false);
}
