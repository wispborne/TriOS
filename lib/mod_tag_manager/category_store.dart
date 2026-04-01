import 'package:dart_mappable/dart_mappable.dart';

import 'category.dart';
import 'mod_category_assignment.dart';

part 'category_store.mapper.dart';

@MappableClass()
class CategoryStore with CategoryStoreMappable {
  const CategoryStore({
    this.categories = const [],
    this.modAssignments = const {},
  });

  /// All defined categories.
  final List<Category> categories;

  /// Map of modId -> list of category assignments for that mod.
  final Map<String, List<ModCategoryAssignment>> modAssignments;
}
