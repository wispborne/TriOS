import 'dart:ui';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:uuid/uuid.dart';

part 'mod_tag.mapper.dart';

@MappableClass()
class ModTag with ModTagMappable {
  const ModTag({
    required this.id,
    required this.name,
    required this.type,
    this.icon,
    this.color,
    required this.isUserCreated,
  });

  final String id;
  final String name;
  final String type;
  final ModTagIcon? icon;
  final Color? color;
  final bool isUserCreated;

  factory ModTag.create({
    required String name,
    required String type,
    required bool isUserCreated,
  }) {
    return ModTag(
      id: const Uuid().v7(),
      name: name,
      type: type,
      isUserCreated: isUserCreated,
    );
  }
}

enum ModTagIcon { regular, bug }
