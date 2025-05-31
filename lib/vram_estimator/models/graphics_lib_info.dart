import 'package:dart_mappable/dart_mappable.dart';

part 'graphics_lib_info.mapper.dart';

@MappableClass()
class GraphicsLibInfo with GraphicsLibInfoMappable {
  String id;
  MapType mapType;
  String relativeFilePath;

  GraphicsLibInfo(this.id, this.mapType, this.relativeFilePath);

  @override
  String toString() {
    return "GraphicsLibInfo(id: $id,mapType: $mapType, relativeFilePath: $relativeFilePath)";
  }
}

@MappableEnum()
enum MapType { Normal, Material, Surface }
