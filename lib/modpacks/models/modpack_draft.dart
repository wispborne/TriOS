import 'package:dart_mappable/dart_mappable.dart';
import 'package:trios/modpacks/models/modpack_definition.dart';
import 'package:trios/modpacks/modpack_format.dart';

part 'modpack_draft.mapper.dart';

/// What is wrong with one part of a draft.
@MappableEnum()
enum ModpackDraftProblem {
  packNameMissing,
  packNameTooLong,
  homepageUrlInvalid,
  updateUrlInvalid,
  noItems,
  tooManyItems,
  itemModIdMissing,
  itemUrlMissing,
  itemUrlInvalid,
  itemSourceTypeMissing,
  itemStatusInvalid,
  itemNoteTooLong,
  duplicateModId,
}

/// One problem found in a draft, and where it is.
@MappableClass()
class ModpackDraftIssue with ModpackDraftIssueMappable {
  final ModpackDraftProblem problem;

  /// Which item the problem is in, or null when it is a pack-level problem.
  final int? itemIndex;

  const ModpackDraftIssue(this.problem, {this.itemIndex});
}

/// One item while it is still being edited. Any field may be missing, so a
/// half-finished item can still be autosaved.
@MappableClass()
class ModpackDraftItem with ModpackDraftItemMappable {
  final String? modId;
  final String? url;
  final ModpackItemSourceType? sourceType;
  final String? name;
  final String? version;
  final String? status;
  final String? note;
  final ModpackCatalogClues? catalog;
  final Map<String, dynamic> unknownFields;

  const ModpackDraftItem({
    this.modId,
    this.url,
    this.sourceType,
    this.name,
    this.version,
    this.status,
    this.note,
    this.catalog,
    this.unknownFields = const {},
  });

  ModpackDraftItem.fromItem(ModpackItem item)
    : modId = item.modId,
      url = item.url,
      sourceType = item.sourceType,
      name = item.name,
      version = item.version,
      status = item.status,
      note = item.note,
      catalog = item.catalog,
      unknownFields = item.unknownFields;

  /// The name to show while editing, falling back to the mod ID.
  String get displayName {
    final trimmedName = name?.trim();
    if (trimmedName != null && trimmedName.isNotEmpty) return trimmedName;
    return modId?.trim() ?? '';
  }

  /// Whether this item has everything a shared pack needs.
  bool get isComplete =>
      (modId?.trim().isNotEmpty ?? false) &&
      sourceType != null &&
      (url != null && isSafeModpackUrl(url!));
}

/// An autosaved working copy of one modpack.
///
/// A draft may be empty or invalid. It is kept separately from the pack's
/// saved definition, so leaving the editor never changes what the library
/// holds. Only the modpack store creates and commits drafts.
@MappableClass()
class ModpackDraft with ModpackDraftMappable {
  /// The pack ID this draft belongs to. Allocated when the draft is created,
  /// so a pack that has never been saved still has a stable identity.
  final String id;

  final String name;
  final String? author;
  final String? description;
  final String? gameVersion;
  final String? homepageUrl;
  final String? updateUrl;
  final List<ModpackDraftItem> items;

  /// Fields from a newer TriOS, carried through editing untouched.
  final Map<String, dynamic> unknownFields;

  final DateTime? updatedAt;

  const ModpackDraft({
    required this.id,
    this.name = '',
    this.author,
    this.description,
    this.gameVersion,
    this.homepageUrl,
    this.updateUrl,
    this.items = const [],
    this.unknownFields = const {},
    this.updatedAt,
  });

  /// Starts a draft from a saved definition, so editing a saved pack begins
  /// with exactly what was saved.
  ModpackDraft.fromDefinition(ModpackDefinition definition, {this.updatedAt})
    : id = definition.id,
      name = definition.name,
      author = definition.author,
      description = definition.description,
      gameVersion = definition.gameVersion,
      homepageUrl = definition.homepageUrl,
      updateUrl = definition.updateUrl,
      items = definition.items.map(ModpackDraftItem.fromItem).toList(),
      unknownFields = definition.unknownFields;

  /// Everything wrong with this draft right now, in reading order.
  List<ModpackDraftIssue> get issues {
    final found = <ModpackDraftIssue>[];

    if (name.trim().isEmpty) {
      found.add(const ModpackDraftIssue(ModpackDraftProblem.packNameMissing));
    } else if (name.trim().length > ModpackLimits.maxNameLength) {
      found.add(const ModpackDraftIssue(ModpackDraftProblem.packNameTooLong));
    }
    if (homepageUrl != null && !isSafeModpackUrl(homepageUrl!)) {
      found.add(
        const ModpackDraftIssue(ModpackDraftProblem.homepageUrlInvalid),
      );
    }
    if (updateUrl != null && !isSafeModpackUrl(updateUrl!)) {
      found.add(const ModpackDraftIssue(ModpackDraftProblem.updateUrlInvalid));
    }
    if (items.isEmpty) {
      found.add(const ModpackDraftIssue(ModpackDraftProblem.noItems));
    }
    if (items.length > ModpackLimits.maxItems) {
      found.add(const ModpackDraftIssue(ModpackDraftProblem.tooManyItems));
    }

    final seenModIds = <String>{};
    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      final modId = item.modId?.trim() ?? '';
      if (modId.isEmpty) {
        found.add(
          ModpackDraftIssue(
            ModpackDraftProblem.itemModIdMissing,
            itemIndex: index,
          ),
        );
      } else if (!seenModIds.add(modId)) {
        found.add(
          ModpackDraftIssue(
            ModpackDraftProblem.duplicateModId,
            itemIndex: index,
          ),
        );
      }

      final url = item.url?.trim() ?? '';
      if (url.isEmpty) {
        found.add(
          ModpackDraftIssue(
            ModpackDraftProblem.itemUrlMissing,
            itemIndex: index,
          ),
        );
      } else if (!isSafeModpackUrl(url)) {
        found.add(
          ModpackDraftIssue(
            ModpackDraftProblem.itemUrlInvalid,
            itemIndex: index,
          ),
        );
      }

      if (item.sourceType == null) {
        found.add(
          ModpackDraftIssue(
            ModpackDraftProblem.itemSourceTypeMissing,
            itemIndex: index,
          ),
        );
      }

      final status = item.status?.trim();
      if (status != null &&
          (status.length > ModpackLimits.maxStatusLength ||
              status.contains('\n') ||
              status.contains('\r'))) {
        found.add(
          ModpackDraftIssue(
            ModpackDraftProblem.itemStatusInvalid,
            itemIndex: index,
          ),
        );
      }

      if ((item.note?.length ?? 0) > ModpackLimits.maxNoteLength) {
        found.add(
          ModpackDraftIssue(
            ModpackDraftProblem.itemNoteTooLong,
            itemIndex: index,
          ),
        );
      }
    }

    return found;
  }

  /// Whether the store can commit this draft to the library.
  bool get isCommittable => issues.isEmpty;

  /// Whether the person has typed anything worth keeping.
  bool get isEmpty =>
      name.trim().isEmpty &&
      items.isEmpty &&
      (author?.trim().isEmpty ?? true) &&
      (description?.trim().isEmpty ?? true) &&
      (homepageUrl?.trim().isEmpty ?? true) &&
      (updateUrl?.trim().isEmpty ?? true);

  /// The items that still need work before the pack can be shared.
  List<int> get incompleteItemIndices => [
    for (var index = 0; index < items.length; index++)
      if (!items[index].isComplete) index,
  ];

  /// Builds the shared definition this draft describes, at [version].
  ///
  /// Throws [StateError] when the draft is not committable. Callers should
  /// check [isCommittable] first; the store always does.
  ModpackDefinition toDefinition({required int version}) {
    if (!isCommittable) {
      throw StateError(
        'This modpack draft is not finished: ${issues.length} '
        'problems remain.',
      );
    }
    return ModpackDefinition(
      id: id,
      name: name.trim(),
      version: version,
      author: _cleaned(author),
      description: _cleaned(description),
      gameVersion: _cleaned(gameVersion),
      homepageUrl: _cleaned(homepageUrl),
      updateUrl: _cleaned(updateUrl),
      items: [
        for (final item in items)
          ModpackItem(
            modId: item.modId!.trim(),
            url: item.url!.trim(),
            sourceType: item.sourceType!,
            name: _cleaned(item.name),
            version: _cleaned(item.version),
            status: ModpackItemStatuses.normalize(item.status),
            note: item.note?.isEmpty == true ? null : item.note,
            catalog: item.catalog?.isEmpty == true ? null : item.catalog,
            unknownFields: item.unknownFields,
          ),
      ],
      unknownFields: unknownFields,
    );
  }

  static String? _cleaned(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
