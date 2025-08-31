import 'package:dart_mappable/dart_mappable.dart';
import 'package:uuid/uuid.dart';

part 'mod_tag.mapper.dart';

@MappableClass()
class ModTag with ModTagMappable {
  const ModTag({required this.id, required this.name, required this.isUserCreated});

  final String id;
  final String name;
  final bool isUserCreated;

  factory ModTag.create({required String name, required bool isUserCreated}) {
    return ModTag(id: const Uuid().v7(), name: name, isUserCreated: isUserCreated);
  }
}
