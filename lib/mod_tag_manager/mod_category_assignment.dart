import 'package:dart_mappable/dart_mappable.dart';

part 'mod_category_assignment.mapper.dart';

@MappableEnum()
enum CategoryAssignmentSource { user, automatic }

@MappableClass()
class ModCategoryAssignment with ModCategoryAssignmentMappable {
  const ModCategoryAssignment({
    required this.categoryId,
    this.isPrimary = false,
    this.source = CategoryAssignmentSource.user,
  });

  final String categoryId;
  final bool isPrimary;
  final CategoryAssignmentSource source;
}
