import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/utils/generic_settings_manager.dart';
import 'package:trios/utils/generic_settings_notifier.dart';

import 'category.dart';
import 'category_auto_color.dart';
import 'category_store.dart';
import 'mod_category_assignment.dart';

final categoryManagerProvider =
    AsyncNotifierProvider<CategoryManagerNotifier, CategoryStore>(
      CategoryManagerNotifier.new,
    );

class CategorySettingsManager
    extends GenericAsyncSettingsManager<CategoryStore> {
  @override
  String get fileName => 'trios_categories-v1.json';

  @override
  CategoryStore Function(Map<String, dynamic> map) get fromMap =>
      (json) => CategoryStoreMapper.fromMap(json);

  @override
  Map<String, dynamic> Function(CategoryStore) get toMap =>
      (state) => state.toMap();

  @override
  FileFormat get fileFormat => FileFormat.json;
}

class CategoryManagerNotifier
    extends GenericSettingsAsyncNotifier<CategoryStore> {
  @override
  GenericAsyncSettingsManager<CategoryStore> createSettingsManager() =>
      CategorySettingsManager();

  @override
  CategoryStore createDefaultState() =>
      CategoryStore(categories: defaultCategories, modAssignments: const {});

  @override
  Future<CategoryStore> build() async {
    final loaded = await super.build();
    final reconciled = _reconcileDefaultCategories(loaded);
    if (reconciled != loaded) {
      state = AsyncData(reconciled);
      settingsManager.scheduleWrite(reconciled);
    }
    return reconciled;
  }

  /// Syncs stored default categories with code-defined [defaultCategories].
  /// - Replaces unmodified defaults with the code version.
  /// - Adds new defaults that don't exist in the store.
  /// - Removes stored defaults that are no longer in code (if unmodified).
  CategoryStore _reconcileDefaultCategories(CategoryStore store) {
    final defaultIds = {for (final d in defaultCategories) d.id};
    final storedById = {for (final c in store.categories) c.id: c};

    final reconciled = <Category>[];
    var changed = false;

    // Keep user-created categories and user-modified defaults as-is.
    // Replace unmodified defaults with code version.
    // Remove stale defaults (no longer in code and not user-modified).
    for (final stored in store.categories) {
      if (stored.isUserCreated) {
        reconciled.add(stored);
      } else if (stored.isUserModified) {
        // User touched this default — keep their version even if removed from code.
        reconciled.add(stored);
      } else if (defaultIds.contains(stored.id)) {
        // Unmodified default still in code — replace with code version.
        final codeVersion =
            defaultCategories.firstWhere((d) => d.id == stored.id);
        if (stored != codeVersion) changed = true;
        reconciled.add(codeVersion);
      } else {
        // Unmodified default removed from code — drop it.
        changed = true;
      }
    }

    // Add any new defaults not yet in the store.
    for (final def in defaultCategories) {
      if (!storedById.containsKey(def.id)) {
        reconciled.add(def);
        changed = true;
      }
    }

    if (!changed) return store;
    return store.copyWith(categories: reconciled);
  }

  // --- Query methods ---

  /// All defined categories, sorted by sortOrder.
  List<Category> getAllCategories() {
    final store = state.value;
    if (store == null) return [];
    return store.categories.sortedBy<num>((c) => c.sortOrder);
  }

  /// Get all category assignments for a mod.
  List<ModCategoryAssignment> getAssignmentsForMod(String modId) {
    return state.value?.modAssignments[modId] ?? [];
  }

  /// Get the primary category for a mod (or null).
  Category? getPrimaryCategory(String modId) {
    final assignments = getAssignmentsForMod(modId);
    final primary = assignments.firstWhereOrNull((a) => a.isPrimary);
    if (primary == null && assignments.isNotEmpty) {
      // Fallback: treat first assignment as primary.
      return _findCategory(assignments.first.categoryId);
    }
    return primary != null ? _findCategory(primary.categoryId) : null;
  }

  /// Get all Category objects assigned to a mod.
  List<Category> getCategoriesForMod(String modId) {
    final assignments = getAssignmentsForMod(modId);
    return assignments
        .map((a) => _findCategory(a.categoryId))
        .whereType<Category>()
        .toList();
  }

  // --- Mutation methods ---

  /// Add a category to a mod.
  /// If [isPrimary] and the mod already has a primary, demote the old one.
  void addCategoryToMod(
    String modId,
    String categoryId, {
    bool isPrimary = false,
    CategoryAssignmentSource source = CategoryAssignmentSource.user,
  }) {
    updateState((current) {
      final assignments = List<ModCategoryAssignment>.from(
        current.modAssignments[modId] ?? [],
      );

      // Don't add duplicates.
      if (assignments.any((a) => a.categoryId == categoryId)) return current;

      // If this is primary, demote any existing primary.
      if (isPrimary) {
        for (var i = 0; i < assignments.length; i++) {
          if (assignments[i].isPrimary) {
            assignments[i] = assignments[i].copyWith(isPrimary: false);
          }
        }
      }

      // If no categories yet, make this primary regardless.
      final shouldBePrimary = isPrimary || assignments.isEmpty;

      assignments.add(
        ModCategoryAssignment(
          categoryId: categoryId,
          isPrimary: shouldBePrimary,
          source: source,
        ),
      );

      final newAssignments = Map<String, List<ModCategoryAssignment>>.from(
        current.modAssignments,
      );
      newAssignments[modId] = assignments;
      return current.copyWith(modAssignments: newAssignments);
    });
  }

  /// Remove a category from a mod.
  /// If it was primary, promote the next one or leave the mod uncategorized.
  void removeCategoryFromMod(String modId, String categoryId) {
    updateState((current) {
      final assignments = List<ModCategoryAssignment>.from(
        current.modAssignments[modId] ?? [],
      );

      final removed = assignments.firstWhereOrNull(
        (a) => a.categoryId == categoryId,
      );
      assignments.removeWhere((a) => a.categoryId == categoryId);

      // If removed was primary, promote the first remaining.
      if (removed?.isPrimary == true && assignments.isNotEmpty) {
        assignments[0] = assignments[0].copyWith(isPrimary: true);
      }

      final newAssignments = Map<String, List<ModCategoryAssignment>>.from(
        current.modAssignments,
      );
      if (assignments.isEmpty) {
        newAssignments.remove(modId);
      } else {
        newAssignments[modId] = assignments;
      }
      return current.copyWith(modAssignments: newAssignments);
    });
  }

  /// Set which category is primary for a mod.
  void setPrimaryCategory(String modId, String categoryId) {
    updateState((current) {
      final assignments = List<ModCategoryAssignment>.from(
        current.modAssignments[modId] ?? [],
      );

      if (!assignments.any((a) => a.categoryId == categoryId)) return current;

      for (var i = 0; i < assignments.length; i++) {
        assignments[i] = assignments[i].copyWith(
          isPrimary: assignments[i].categoryId == categoryId,
        );
      }

      final newAssignments = Map<String, List<ModCategoryAssignment>>.from(
        current.modAssignments,
      );
      newAssignments[modId] = assignments;
      return current.copyWith(modAssignments: newAssignments);
    });
  }

  /// Create a new category definition.
  /// If [color] is null and autoColorNewCategories is enabled, auto-assigns one.
  Category createCategory(String name, {Color? color, CategoryIcon? icon}) {
    final store = state.value ?? createDefaultState();
    final autoColor =
        color ??
        (store.autoColorNewCategories ? pickAutoColor(store.categories) : null);
    final maxSortOrder =
        store.categories.map((c) => c.sortOrder).maxOrNull ?? -1;
    final category = Category.create(
      name: name,
      isUserCreated: true,
      color: autoColor,
      sortOrder: maxSortOrder + 1,
    );

    updateState(
      (current) =>
          current.copyWith(categories: [...current.categories, category]),
    );

    return category;
  }

  /// Update a category definition.
  void updateCategory(
    String categoryId, {
    String? name,
    Color? color,
    bool clearColor = false,
    CategoryIcon? icon,
    int? sortOrder,
  }) {
    updateState((current) {
      final categories = current.categories.map((c) {
        if (c.id != categoryId) return c;
        return c.copyWith(
          name: name ?? c.name,
          color: clearColor ? null : (color ?? c.color),
          icon: icon ?? c.icon,
          sortOrder: sortOrder ?? c.sortOrder,
          isUserModified: !c.isUserCreated ? true : c.isUserModified,
        );
      }).toList();
      return current.copyWith(categories: categories);
    });
  }

  /// Delete a category definition and remove all its assignments.
  void deleteCategory(String categoryId) {
    updateState((current) {
      final categories = current.categories
          .where((c) => c.id != categoryId)
          .toList();

      final newAssignments = Map<String, List<ModCategoryAssignment>>.from(
        current.modAssignments,
      );
      for (final entry in newAssignments.entries.toList()) {
        final wasPrimary = entry.value.any(
          (a) => a.categoryId == categoryId && a.isPrimary,
        );
        final filtered = entry.value
            .where((a) => a.categoryId != categoryId)
            .toList();
        // If the deleted category was primary, promote the first remaining.
        if (wasPrimary && filtered.isNotEmpty) {
          filtered[0] = filtered[0].copyWith(isPrimary: true);
        }
        if (filtered.isEmpty) {
          newAssignments.remove(entry.key);
        } else {
          newAssignments[entry.key] = filtered;
        }
      }

      return current.copyWith(
        categories: categories,
        modAssignments: newAssignments,
      );
    });
  }

  /// Set auto-color preference.
  void setAutoColorNewCategories(bool value) {
    updateState((current) => current.copyWith(autoColorNewCategories: value));
  }

  // --- Helpers ---

  Category? _findCategory(String categoryId) {
    return state.value?.categories.firstWhereOrNull((c) => c.id == categoryId);
  }

  // --- Default categories ---

  static const List<Category> defaultCategories = [
    Category(
      id: 'cat-total-conversion',
      name: 'Total Conversion',
      isUserCreated: false,
      sortOrder: 0,
      color: const Color(0xFF9C27B0),
      icon: SvgCategoryIcon("assets/images/icon-death-star.svg"),
    ),
    Category(
      id: 'cat-faction',
      name: 'Faction',
      isUserCreated: false,
      sortOrder: 1,
      color: const Color(0xFF2196F3),
      // icon: MaterialCategoryIcon(0xe366),
    ),
    Category(
      id: 'cat-utility',
      name: 'Utility',
      isUserCreated: false,
      sortOrder: 2,
      color: const Color(0xFF4CAF50),
    ),
    Category(
      id: 'cat-ship-weapon-pack',
      name: 'Ship/Weapon Pack',
      isUserCreated: false,
      sortOrder: 3,
      color: const Color(0xFFFF9800),
    ),
    Category(
      id: 'cat-graphics',
      name: 'Graphics',
      isUserCreated: false,
      sortOrder: 4,
      color: const Color(0xFFE91E63),
    ),
    Category(
      id: 'cat-qol',
      name: 'Quality of Life',
      isUserCreated: false,
      sortOrder: 5,
      color: const Color(0xFF009688),
    ),
    Category(
      id: 'cat-library',
      name: 'Library/API',
      isUserCreated: false,
      sortOrder: 6,
      color: const Color(0xFF607D8B),
    ),
  ];
}
