import 'package:dart_mappable/dart_mappable.dart';

part 'persisted_filter_group.mapper.dart';

/// Persistence envelope for a single locked filter group.
///
/// [selections] is a typed map whose values may be:
///   - `bool?` — chip tri-state (`true` include, `false` exclude, `null` unused)
///   - `bool` — composite `BoolField` value
///   - `String` — composite `EnumField` enum `.name`
///
/// The schema is versioned via [schemaVersion]. Entries whose version is not
/// 2 are dropped on load (v1 was unreleased).
@MappableClass()
class PersistedFilterGroup with PersistedFilterGroupMappable {
  static const int currentSchemaVersion = 2;

  final int schemaVersion;
  final Map<String, Object?> selections;

  const PersistedFilterGroup({
    this.schemaVersion = currentSchemaVersion,
    this.selections = const {},
  });
}
