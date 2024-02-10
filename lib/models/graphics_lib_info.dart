class GraphicsLibInfo {
  MapType mapType;
  String relativeFilePath;

  GraphicsLibInfo(this.mapType, this.relativeFilePath);
}

enum MapType { Normal, Material, Surface }
