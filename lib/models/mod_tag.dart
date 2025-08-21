import 'package:dart_mappable/dart_mappable.dart';
import 'package:uuid/uuid.dart';

part 'mod_tag.mapper.dart';

@MappableClass()
class ModTag with ModTagMappable {
  const ModTag({required this.id, required this.name});

  final String id;
  final String name;

  factory ModTag.create(String name) {
    return ModTag(id: const Uuid().v7(), name: name);
  }
}
