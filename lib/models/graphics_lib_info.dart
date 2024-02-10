class GraphicsLibInfo {
  MapType mapType;
  String relativeFilePath;

  GraphicsLibInfo(this.mapType, this.relativeFilePath);

  @override
  String toString() {
    return "GraphicsLibInfo(mapType: $mapType, relativeFilePath: $relativeFilePath)";
  }
}

enum MapType { Normal, Material, Surface }
