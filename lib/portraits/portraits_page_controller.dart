import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:trios/widgets/snackbar.dart';

import 'package:collection/collection.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:trios/models/mod.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/portraits/portrait_metadata.dart';
import 'package:trios/portraits/portrait_metadata_manager.dart';
import 'package:trios/portraits/portrait_model.dart';
import 'package:trios/portraits/portrait_replacements_manager.dart';
import 'package:trios/portraits/portrait_scanner.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/utils/search.dart';
import 'package:trios/widgets/filter_engine/filter_engine.dart';
import 'package:trios/widgets/filter_group_persistence/filter_group_persistence_provider.dart';
import 'package:trios/widgets/moving_tooltip.dart';

part 'portraits_page_controller.mapper.dart';

/// Stable page identifier for persistence keying (main pane only — the left
/// and right replacer panes are transient and intentionally not persisted).
const String kPortraitsPageId = 'portraits';

/// Subset of portraits page state that's persisted across app sessions.
/// Only fields shared by the primary view (main pane) are here; replacer
/// panes are intentionally transient.
@MappableClass()
class PortraitsPageStatePersisted with PortraitsPageStatePersistedMappable {
  final bool mainShowFilters;

  const PortraitsPageStatePersisted({this.mainShowFilters = true});
}

/// Mode for the portraits page.
@MappableEnum()
enum PortraitsMode { viewer, replacer }

/// Identifies which filter pane to use.
@MappableEnum()
enum FilterPane { main, left, right }

/// Helper class to hold portrait info for filtering.
class PortraitFilterItem {
  final Portrait portrait;
  final ModVariant? variant;
  final PortraitMetadata? metadata;

  PortraitFilterItem({
    required this.portrait,
    required this.variant,
    this.metadata,
  });

  String get modName => variant?.modInfo.nameOrId ?? 'Vanilla';

  String get genderString => metadata?.gender?.toString() ?? 'Unknown';
}

/// State for a single filter pane (main, left, or right).
///
/// Filter-adjacent booleans (`showOnlyWithMetadata`, `showOnlyReplaced`,
/// `showOnlyEnabledMods`) have moved into each scope's `general` composite
/// group. Only non-filter UI state remains here.
@MappableClass()
class FilterPaneState with FilterPaneStateMappable {
  final bool showFilters;
  final String searchQuery;

  const FilterPaneState({
    this.showFilters = true,
    this.searchQuery = '',
  });
}

/// State class for the portraits page controller.
@MappableClass()
class PortraitsPageState with PortraitsPageStateMappable {
  final PortraitsMode mode;
  final double portraitSize;

  /// Filter state for main/viewer pane.
  final FilterPaneState mainPaneState;

  /// Filter state for left pane (Replacer mode).
  final FilterPaneState leftPaneState;

  /// Filter state for right pane (Replacer mode).
  final FilterPaneState rightPaneState;

  /// All portraits mapped by variant.
  final Map<ModVariant?, List<Portrait>> allPortraits;

  /// Portrait metadata map.
  final Map<String, PortraitMetadata> metadata;

  /// Portrait replacements (original hash -> replacement portrait).
  final Map<String, Portrait> replacements;

  /// Whether portraits are currently loading.
  final bool isLoading;

  static const double portraitSizeMin = 64;
  static const double portraitSizeMax = 192;
  static const double portraitSizeStep = 8;

  bool get inReplaceMode => mode == PortraitsMode.replacer;

  const PortraitsPageState({
    this.mode = PortraitsMode.viewer,
    this.portraitSize = 128,
    this.mainPaneState = const FilterPaneState(),
    this.leftPaneState = const FilterPaneState(),
    this.rightPaneState = const FilterPaneState(),
    this.allPortraits = const {},
    this.metadata = const {},
    this.replacements = const {},
    this.isLoading = false,
  });

  /// Get the filter pane state for the specified pane.
  FilterPaneState getPaneState(FilterPane pane) {
    return switch (pane) {
      FilterPane.main => mainPaneState,
      FilterPane.left => leftPaneState,
      FilterPane.right => rightPaneState,
    };
  }
}

/// Controller for the portraits page using Notifier.
class PortraitsPageController extends Notifier<PortraitsPageState> {
  static final _mainScope = const FilterScope(kPortraitsPageId, scopeId: 'main');
  static final _leftScope = const FilterScope(kPortraitsPageId, scopeId: 'left');
  static final _rightScope =
      const FilterScope(kPortraitsPageId, scopeId: 'right');

  late final FilterScopeController<PortraitFilterItem> _mainFilters;
  late final FilterScopeController<PortraitFilterItem> _leftFilters;
  late final FilterScopeController<PortraitFilterItem> _rightFilters;

  FilterScope scopeFor(FilterPane pane) => switch (pane) {
    FilterPane.main => _mainScope,
    FilterPane.left => _leftScope,
    FilterPane.right => _rightScope,
  };

  FilterScopeController<PortraitFilterItem> filtersFor(FilterPane pane) =>
      switch (pane) {
        FilterPane.main => _mainFilters,
        FilterPane.left => _leftFilters,
        FilterPane.right => _rightFilters,
      };

  List<FilterGroup<PortraitFilterItem>> filterGroupsFor(FilterPane pane) =>
      filtersFor(pane).groups;

  int activeFilterCountFor(FilterPane pane) => filtersFor(pane).activeCount;

  CompositeFilterGroup<PortraitFilterItem> _generalFor(FilterPane pane) =>
      filtersFor(pane).findGroup('general')
          as CompositeFilterGroup<PortraitFilterItem>;

  BoolField<PortraitFilterItem> _fieldFor(FilterPane pane, String id) =>
      _generalFor(pane).fieldById(id) as BoolField<PortraitFilterItem>;

  bool showOnlyWithMetadata(FilterPane pane) =>
      _fieldFor(pane, 'showOnlyWithMetadata').value;

  bool showOnlyReplaced(FilterPane pane) =>
      _fieldFor(pane, 'showOnlyReplaced').value;

  bool showOnlyEnabledMods(FilterPane pane) =>
      _fieldFor(pane, 'showOnlyEnabledMods').value;

  @override
  PortraitsPageState build() {
    final existingState = stateOrNull;
    if (existingState == null) {
      _mainFilters = _buildFilters(_mainScope, persistenceEnabled: true);
      _leftFilters = _buildFilters(_leftScope, persistenceEnabled: false);
      _rightFilters = _buildFilters(_rightScope, persistenceEnabled: false);
      final persistence = ref.read(filterGroupPersistenceProvider);
      _mainFilters.loadPersisted(persistence);
    }

    final portraitsAsync = ref.watch(AppState.portraits);
    final metadataAsync = ref.watch(AppState.portraitMetadata);
    final replacementsAsync = ref.watch(AppState.portraitReplacementsManager);
    final isLoadingPortraits =
        ref.watch(AppState.portraits.notifier).isLoadingPortraits;

    final allPortraits = portraitsAsync.value ?? {};
    final metadata = metadataAsync.value ?? {};

    final loadedReplacements = replacementsAsync.value ?? {};
    final replacements = loadedReplacements
        .hydrateToPortraitMap(
          allPortraits.convertToPortraitMap(),
          logWarnings: !isLoadingPortraits,
        )
        .entries
        .where((element) => element.value != null)
        .toMap()
        .cast<String, Portrait>();

    if (_mainFilters.hasPendingChipSelections) {
      _mainFilters.applyPendingChipMerge(
        _buildFilterItems(allPortraits, metadata),
      );
    }

    final savedPersisted = ref.read(appSettings).portraitsPageState;
    final mainPaneState = existingState?.mainPaneState ??
        FilterPaneState(showFilters: savedPersisted?.mainShowFilters ?? true);

    return (existingState ?? const PortraitsPageState()).copyWith(
      mainPaneState: mainPaneState,
      allPortraits: allPortraits,
      metadata: metadata,
      replacements: replacements,
      isLoading: isLoadingPortraits,
    );
  }

  FilterScopeController<PortraitFilterItem> _buildFilters(
    FilterScope scope, {
    required bool persistenceEnabled,
  }) {
    final groups = <FilterGroup<PortraitFilterItem>>[
      CompositeFilterGroup<PortraitFilterItem>(
        id: 'general',
        name: 'General',
        fields: [
          BoolField<PortraitFilterItem>(
            id: 'showOnlyWithMetadata',
            label: 'Confirmed Portraits',
            defaultValue: true,
            tooltip:
                "Only show images that are confirmed portraits."
                "\n\nPortraits defined in .faction files have genders."
                "\nPortraits from settings.json files do not.",
            predicate: (item) => item.metadata != null,
          ),
          BoolField<PortraitFilterItem>(
            id: 'showOnlyReplaced',
            label: 'Only Your Changes',
            tooltip: 'Only show images that have replacements.',
            // predicate cannot see state.replacements here; applied page-locally.
            predicate: (_) => true,
          ),
          BoolField<PortraitFilterItem>(
            id: 'showOnlyEnabledMods',
            label: 'Only Enabled Mods',
            tooltip: 'Only show images from enabled mods.',
            predicate: (item) {
              final mods = ref.read(AppState.mods);
              return item.variant == null ||
                  item.variant?.mod(mods)?.hasEnabledVariant == true;
            },
          ),
        ],
      ),
      ..._createChipFilterGroups(),
    ];
    return FilterScopeController<PortraitFilterItem>(
      scope: scope,
      groups: groups,
      persistenceEnabled: persistenceEnabled,
    );
  }

  /// Persist the main pane's [showFilters] to app settings. Replacer panes
  /// are intentionally not persisted.
  void _persistMainShowFilters(bool value) {
    ref.read(appSettings.notifier).update((s) {
      final current =
          s.portraitsPageState ?? const PortraitsPageStatePersisted();
      return s.copyWith(
        portraitsPageState: current.copyWith(mainShowFilters: value),
      );
    });
  }

  List<ChipFilterGroup<PortraitFilterItem>> _createChipFilterGroups() {
    return [
      ChipFilterGroup<PortraitFilterItem>(
        id: 'mod',
        name: 'Mod',
        valueGetter: (item) => item.modName,
        sortComparator: (a, b) => a == 'Vanilla'
            ? -1
            : b == 'Vanilla'
            ? 1
            : a.compareTo(b),
      ),
      ChipFilterGroup<PortraitFilterItem>(
        id: 'gender',
        name: 'Gender',
        valueGetter: (item) => item.genderString,
      ),
    ];
  }

  /// Set the portraits mode (viewer or replacer).
  void setMode(PortraitsMode mode) {
    // Copy the main search to the left search if switching to replacer
    if (mode == PortraitsMode.replacer &&
        state.mainPaneState.searchQuery.isNotEmpty) {
      state = state.copyWith(
        mode: mode,
        leftPaneState: state.leftPaneState.copyWith(
          searchQuery: state.mainPaneState.searchQuery,
        ),
      );
    } else {
      state = state.copyWith(mode: mode);
    }
  }

  /// Set portrait size.
  void setPortraitSize(double size) {
    state = state.copyWith(portraitSize: size);
  }

  /// Update the search query for a specific pane.
  void updateSearchQuery(FilterPane pane, String query) {
    state = _updatePaneState(
      pane,
      (paneState) => paneState.copyWith(searchQuery: query),
    );
  }

  void toggleShowOnlyWithMetadata(FilterPane pane) =>
      setShowOnlyWithMetadata(pane, !showOnlyWithMetadata(pane));

  void toggleShowOnlyReplaced(FilterPane pane) =>
      setShowOnlyReplaced(pane, !showOnlyReplaced(pane));

  void toggleShowOnlyEnabledMods(FilterPane pane) =>
      setShowOnlyEnabledMods(pane, !showOnlyEnabledMods(pane));

  /// Toggle filters visibility for a specific pane.
  void toggleShowFilters(FilterPane pane) {
    state = _updatePaneState(
      pane,
      (paneState) => paneState.copyWith(showFilters: !paneState.showFilters),
    );
    if (pane == FilterPane.main) {
      _persistMainShowFilters(state.mainPaneState.showFilters);
    }
  }

  /// Set show filters visibility for a specific pane.
  void setShowFilters(FilterPane pane, bool value) {
    state = _updatePaneState(
      pane,
      (paneState) => paneState.copyWith(showFilters: value),
    );
    if (pane == FilterPane.main) {
      _persistMainShowFilters(value);
    }
  }

  void setShowOnlyWithMetadata(FilterPane pane, bool value) {
    _fieldFor(pane, 'showOnlyWithMetadata').value = value;
    _emitAfterFilterMutation();
    if (pane == FilterPane.main) {
      filtersFor(pane).maybePersist(
        'general',
        ref.read(filterGroupPersistenceProvider),
      );
    }
  }

  void setShowOnlyReplaced(FilterPane pane, bool value) {
    _fieldFor(pane, 'showOnlyReplaced').value = value;
    _emitAfterFilterMutation();
    if (pane == FilterPane.main) {
      filtersFor(pane).maybePersist(
        'general',
        ref.read(filterGroupPersistenceProvider),
      );
    }
  }

  void setShowOnlyEnabledMods(FilterPane pane, bool value) {
    _fieldFor(pane, 'showOnlyEnabledMods').value = value;
    _emitAfterFilterMutation();
    if (pane == FilterPane.main) {
      filtersFor(pane).maybePersist(
        'general',
        ref.read(filterGroupPersistenceProvider),
      );
    }
  }

  /// Clear all filters for a specific pane.
  void clearAllFilters(FilterPane pane) {
    filtersFor(pane).clearAll();
    _emitAfterFilterMutation();
  }

  void onGroupChanged(FilterPane pane, String groupId) {
    _emitAfterFilterMutation();
    filtersFor(pane).maybePersist(
      groupId,
      ref.read(filterGroupPersistenceProvider),
    );
  }

  /// Imperatively replace chip selections on a named group.
  /// Used by context-menu navigation (e.g. "show this mod only") on the main pane.
  void setChipSelections(
    FilterPane pane,
    String groupId,
    Map<String, bool?> selections,
  ) {
    filtersFor(pane).setChipSelections(groupId, selections);
    _emitAfterFilterMutation();
  }

  void _emitAfterFilterMutation() {
    state = state.copyWith();
  }

  /// Refresh portraits by triggering a rescan.
  void refreshPortraits() {
    ref.read(AppState.portraitMetadata.notifier).rescan();
    ref.read(AppState.portraits.notifier).rescan();
  }

  /// Opens a file picker for the user to select image files, validates them
  /// against portrait size requirements, prompts for gender selection, and
  /// copies valid images to the Companion Mod's `graphics/portraits/imported` folder.
  ///
  /// Also updates the faction file to register the imported portraits with their genders.
  Future<void> importPortraits(BuildContext context) async {
    try {
      // Pick image files
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: Constants.portraitsSupportedImageFileExtensions,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      // Get companion mod folder
      final allMods = ref.read(AppState.mods);
      final companionMod = allMods.firstWhereOrNull(
        (mod) => mod.id == Constants.companionModId,
      );
      final companionModVariant = companionMod?.findHighestVersion;

      if (companionModVariant == null) {
        if (context.mounted) {
          showSnackBar(
            context: context,
            type: SnackBarType.error,
            content: Text(
              '${Constants.appName} Companion Mod not found. Please install it first from Settings.',
            ),
          );
        }

        return;
      }

      // Validate all files first
      final List<_PendingImport> validFiles = [];
      final List<_ImportResult> failedValidations = [];

      for (final file in result.files) {
        if (file.path == null) {
          failedValidations.add(
            _ImportResult(
              fileName: file.name,
              success: false,
              reason: 'File path not available',
            ),
          );
          continue;
        }

        final sourceFile = File(file.path!);

        // Validate image dimensions
        final validationResult = await _validatePortraitImage(sourceFile);
        if (!validationResult.isValid) {
          failedValidations.add(
            _ImportResult(
              fileName: file.name,
              success: false,
              reason: validationResult.reason,
            ),
          );
          continue;
        }

        validFiles.add(
          _PendingImport(fileName: file.name, sourcePath: file.path!),
        );
      }

      // If no valid files, show error results
      if (validFiles.isEmpty) {
        if (context.mounted) {
          await _showImportResultsDialog(context, failedValidations);
        }
        return;
      }

      // Show gender selection dialog for valid files
      if (!context.mounted) return;
      final genderSelections = await showDialog<List<_PendingImport>?>(
        context: context,
        barrierDismissible: false,
        builder: (context) => _GenderSelectionDialog(
          pendingImports: validFiles,
          failedValidations: failedValidations,
        ),
      );

      // User cancelled
      if (genderSelections == null) return;

      // Create the imported portraits folder
      final importedFolder = Directory(
        p.join(
          companionModVariant.modFolder.path,
          'graphics',
          'portraits',
          'imported',
        ),
      );
      if (!await importedFolder.exists()) {
        await importedFolder.create(recursive: true);
      }

      // Copy files and collect results
      final List<_ImportResult> results = [...failedValidations];
      final List<_ImportedPortrait> importedPortraits = [];

      for (final pending in genderSelections) {
        final sourceFile = File(pending.sourcePath);
        final destinationFile = await _getUniqueDestinationFile(
          importedFolder,
          pending.fileName,
        );

        try {
          await sourceFile.copy(destinationFile.path);
          final relativePath = p
              .relative(
                destinationFile.path,
                from: companionModVariant.modFolder.path,
              )
              .replaceAll('\\', '/');

          results.add(
            _ImportResult(
              fileName: pending.fileName,
              success: true,
              newPath: destinationFile.path,
            ),
          );

          importedPortraits.add(
            _ImportedPortrait(
              relativePath: relativePath,
              gender: pending.gender!,
            ),
          );
        } catch (e) {
          results.add(
            _ImportResult(
              fileName: pending.fileName,
              success: false,
              reason: 'Failed to copy: $e',
            ),
          );
        }
      }

      // Update faction file with imported portraits
      if (importedPortraits.isNotEmpty) {
        await _updateCompanionModFactionFile(
          companionModVariant,
          importedPortraits,
        );
      }

      // Trigger rescan of portraits
      final successCount = results.where((r) => r.success).length;
      if (successCount > 0) {
        refreshPortraits();
      }

      // Show results dialog
      if (context.mounted) {
        await _showImportResultsDialog(context, results);
      }
    } catch (e) {
      Fimber.e('Error importing portraits: $e');
      if (context.mounted) {
        showSnackBar(
          context: context,
          type: SnackBarType.error,
          content: Text('Error importing portraits: $e'),
        );
      }
    }
  }

  /// Get filtered and sorted images for a specific pane. Pipeline order:
  /// `enabled → metadata → chips → replaced → search`.
  List<({Portrait image, ModVariant? variant})> getFilteredImages(
    FilterPane pane,
    List<Mod> allMods,
  ) {
    final paneState = state.getPaneState(pane);
    final filters = filtersFor(pane);

    var items = _buildFilterItems(state.allPortraits, state.metadata);

    // showOnlyReplaced's predicate is a no-op (`_ => true`) because it needs
    // state.replacements, which isn't available to field predicates; applied below.
    items = filters.applyNonChipFilters(items);

    // Apply chip filters.
    items = filters.applyChipFilters(items);

    // Apply `Only Your Changes` — requires state.replacements, so done here.
    if (showOnlyReplaced(pane)) {
      items = items
          .where((item) => state.replacements.containsKey(item.portrait.hash))
          .toList();
    }

    // Convert back to the original ({image, variant}) tuple shape.
    var images = items
        .map<({Portrait image, ModVariant? variant})>(
          (item) => (image: item.portrait, variant: item.variant),
        )
        .toList();

    images = _sortModsAndImages(images, r'graphics\\.*portraits\\');

    if (paneState.searchQuery.isNotEmpty) {
      images = _filterImages(images, paneState.searchQuery);
    }

    return images;
  }

  /// Get all images without filtering (for filter panels).
  List<({Portrait image, ModVariant? variant})> getAllImages() {
    return state.allPortraits.entries
        .expand(
          (element) => element.value.map((e) => (variant: element.key, image: e)),
        )
        .toList();
  }

  /// Get filter items for the filter panel.
  List<PortraitFilterItem> getFilterItems() =>
      _buildFilterItems(state.allPortraits, state.metadata);

  /// Build `PortraitFilterItem`s from a portrait map + metadata map with a
  /// single `getMetadataFor` call per portrait.
  static List<PortraitFilterItem> _buildFilterItems(
    Map<ModVariant?, List<Portrait>> allPortraits,
    Map<String, PortraitMetadata> metadata,
  ) {
    final result = <PortraitFilterItem>[];
    for (final entry in allPortraits.entries) {
      for (final portrait in entry.value) {
        final meta = metadata.getMetadataFor(portrait.relativePath);
        result.add(PortraitFilterItem(
          portrait: portrait,
          variant: entry.key,
          metadata: meta.hasMetadata ? meta : null,
        ));
      }
    }
    return result;
  }

  // Private helper methods

  PortraitsPageState _updatePaneState(
    FilterPane pane,
    FilterPaneState Function(FilterPaneState) updater,
  ) {
    return switch (pane) {
      FilterPane.main => state.copyWith(
          mainPaneState: updater(state.mainPaneState),
        ),
      FilterPane.left => state.copyWith(
          leftPaneState: updater(state.leftPaneState),
        ),
      FilterPane.right => state.copyWith(
          rightPaneState: updater(state.rightPaneState),
        ),
    };
  }

  List<({Portrait image, ModVariant? variant})> _sortModsAndImages(
    List<({Portrait image, ModVariant? variant})> modsAndImages,
    String regexPattern,
  ) {
    final regex = RegExp(regexPattern);

    return modsAndImages
      ..sort((a, b) {
        final aMatches = regex.hasMatch(a.image.imageFile.path);
        final bMatches = regex.hasMatch(b.image.imageFile.path);

        if (aMatches && !bMatches) return -1;
        if (!aMatches && bMatches) return 1;

        final variantComparison = a.variant?.modInfo.nameOrId
                .compareTo(b.variant?.modInfo.nameOrId ?? "") ??
            -1;
        if (variantComparison != 0) return variantComparison;

        return a.image.imageFile.path.compareTo(b.image.imageFile.path);
      });
  }

  List<({Portrait image, ModVariant? variant})> _filterImages(
    List<({Portrait image, ModVariant? variant})> images,
    String query,
  ) {
    if (query.isEmpty) return images;

    final lowerQuery = query.toLowerCase();

    return images.where((item) {
      final variant = item.variant;
      final portrait = item.image;

      // Check vanilla
      if (lowerQuery == 'vanilla' && variant == null) return true;

      // Check mod name
      if (searchModVariants([?variant], query).isNotEmpty) return true;

      // Check file path
      if (portrait.imageFile.path.toLowerCase().contains(lowerQuery)) {
        return true;
      }

      // Check portrait metadata (gender, factions, portrait ID)
      final portraitMetadata =
          state.metadata.getMetadataFor(portrait.relativePath);
      if (portraitMetadata.hasMetadata) {
        // Check portrait ID (from settings.json)
        if (portraitMetadata.portraitId?.toLowerCase().contains(lowerQuery) ??
            false) {
          return true;
        }

        // Check gender (male, female)
        if (portraitMetadata.gender
            .toString()
            .toLowerCase()
            .contains(lowerQuery)) {
          return true;
        }

        // Check faction names
        for (final faction in portraitMetadata.factions) {
          if (faction.id.toLowerCase().contains(lowerQuery) ||
              (faction.displayName?.toLowerCase().contains(lowerQuery) ??
                  false)) {
            return true;
          }
        }
      }

      return false;
    }).toList();
  }
}

/// Provider for the portraits page controller.
final portraitsPageControllerProvider =
    NotifierProvider<PortraitsPageController, PortraitsPageState>(() {
  return PortraitsPageController();
});

// =============================================================================
// Portrait Import Helper Functions and Classes
// =============================================================================

/// Updates the companion mod's faction file to include the newly imported portraits.
///
/// Creates the file if it doesn't exist, or appends to existing portrait lists.
Future<void> _updateCompanionModFactionFile(
  ModVariant companionModVariant,
  List<_ImportedPortrait> importedPortraits,
) async {
  final factionDir = Directory(
    p.join(companionModVariant.modFolder.path, 'data', 'world', 'factions'),
  );
  if (!await factionDir.exists()) {
    await factionDir.create(recursive: true);
  }

  final factionFile = File(
    p.join(factionDir.path, 'trios-companion-portraits.faction'),
  );

  Map<String, dynamic> factionData;

  if (await factionFile.exists()) {
    // Parse existing file
    try {
      final content = await factionFile.readAsString();
      factionData = _parseJsonWithComments(content);
    } catch (e) {
      Fimber.w('Failed to parse existing faction file, creating new one: $e');
      factionData = _createEmptyFactionData();
    }
  } else {
    factionData = _createEmptyFactionData();
  }

  // Ensure portraits structure exists
  factionData['portraits'] ??= <String, dynamic>{};
  final portraits = factionData['portraits'] as Map<String, dynamic>;
  portraits['standard_male'] ??= <String>[];
  portraits['standard_female'] ??= <String>[];

  // Add new portraits to appropriate lists
  final maleList = List<String>.from(portraits['standard_male'] as List);
  final femaleList = List<String>.from(portraits['standard_female'] as List);

  for (final portrait in importedPortraits) {
    final path = portrait.relativePath;
    if (portrait.gender == _PortraitGender.male) {
      if (!maleList.contains(path)) {
        maleList.add(path);
      }
    } else {
      if (!femaleList.contains(path)) {
        femaleList.add(path);
      }
    }
  }

  portraits['standard_male'] = maleList;
  portraits['standard_female'] = femaleList;

  // Write the updated faction file
  const encoder = JsonEncoder.withIndent('\t');
  final jsonString = encoder.convert(factionData);
  await factionFile.writeAsString(jsonString);

  Fimber.i('Updated faction file with ${importedPortraits.length} portraits');
}

/// Creates an empty faction data structure for the companion mod.
Map<String, dynamic> _createEmptyFactionData() {
  return {
    'id': 'trios_companion_portraits',
    'portraits': {'standard_male': <String>[], 'standard_female': <String>[]},
  };
}

/// Parses JSON that may contain trailing commas (common in Starsector files).
Map<String, dynamic> _parseJsonWithComments(String content) {
  // Remove trailing commas before ] or }
  var cleaned = content.replaceAllMapped(
    RegExp(r',(\s*[}\]])'),
    (match) => match.group(1)!,
  );
  return jsonDecode(cleaned) as Map<String, dynamic>;
}

/// Validates that an image file meets the portrait size requirements.
///
/// Uses [PortraitScanner.isValidPortraitSize] to check that portraits are
/// square and between [PortraitScanner.minWidth] and [PortraitScanner.maxWidth]
/// pixels in size.
Future<_ValidationResult> _validatePortraitImage(File file) async {
  try {
    final bytes = await file.readAsBytes();
    final (width, height) = await _getImageDimensions(file.path, bytes);

    if (!PortraitScanner.isValidPortraitSize(width, height)) {
      // Provide a descriptive error message
      if (width != height) {
        return _ValidationResult(
          isValid: false,
          reason: 'Image must be square (${width}x$height is not square)',
        );
      } else {
        return _ValidationResult(
          isValid: false,
          reason:
              'Image must be between ${PortraitScanner.minWidth}x${PortraitScanner.minWidth} and ${PortraitScanner.maxWidth}x${PortraitScanner.maxWidth} (got ${width}x$height)',
        );
      }
    }

    return _ValidationResult(isValid: true);
  } catch (e) {
    return _ValidationResult(
      isValid: false,
      reason: 'Failed to read image: $e',
    );
  }
}

/// Returns the width and height of an image from its bytes.
Future<(int, int)> _getImageDimensions(String path, Uint8List bytes) async {
  final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
  final descriptor = await ui.ImageDescriptor.encoded(buffer);
  return (descriptor.width, descriptor.height);
}

/// Returns a unique file path in [folder] for the given [originalName].
///
/// If a file with [originalName] already exists, appends `_1`, `_2`, etc.
/// until a unique name is found.
Future<File> _getUniqueDestinationFile(
  Directory folder,
  String originalName,
) async {
  final extension = p.extension(originalName);
  final baseName = p.basenameWithoutExtension(originalName);

  var destinationFile = File(p.join(folder.path, originalName));
  var counter = 1;

  while (await destinationFile.exists()) {
    final newName = '${baseName}_$counter$extension';
    destinationFile = File(p.join(folder.path, newName));
    counter++;
  }

  return destinationFile;
}

/// Shows a dialog displaying the results of the portrait import operation.
///
/// Lists each file with its success/failure status and relevant details
/// (new path for successes, error reason for failures).
Future<void> _showImportResultsDialog(
  BuildContext context,
  List<_ImportResult> results,
) async {
  final successCount = results.where((r) => r.success).length;
  final failureCount = results.where((r) => !r.success).length;

  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Import Results'),
      content: SizedBox(
        width: 600,
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$successCount imported successfully, $failureCount failed',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final result = results[index];
                  return _ImportResultListItem(result: result);
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

/// Represents the result of attempting to import a single portrait image.
class _ImportResult {
  /// The original file name of the imported file.
  final String fileName;

  /// Whether the import was successful.
  final bool success;

  /// The new path where the file was copied (only set if [success] is true).
  final String? newPath;

  /// The reason for failure (only set if [success] is false).
  final String? reason;

  _ImportResult({
    required this.fileName,
    required this.success,
    this.newPath,
    this.reason,
  });
}

/// Represents the result of validating a portrait image's dimensions.
class _ValidationResult {
  /// Whether the image meets the portrait size requirements.
  final bool isValid;

  /// The reason for validation failure (only set if [isValid] is false).
  final String? reason;

  _ValidationResult({required this.isValid, this.reason});
}

/// Gender options for imported portraits.
enum _PortraitGender { male, female }

/// Represents a file that has been validated but not yet imported.
class _PendingImport {
  final String fileName;
  final String sourcePath;
  _PortraitGender? gender;

  _PendingImport({
    required this.fileName,
    required this.sourcePath,
    this.gender,
  });
}

/// Represents a successfully imported portrait with its gender.
class _ImportedPortrait {
  final String relativePath;
  final _PortraitGender gender;

  _ImportedPortrait({required this.relativePath, required this.gender});
}

/// Dialog for selecting gender for each portrait before import.
class _GenderSelectionDialog extends StatefulWidget {
  final List<_PendingImport> pendingImports;
  final List<_ImportResult> failedValidations;

  const _GenderSelectionDialog({
    required this.pendingImports,
    required this.failedValidations,
  });

  @override
  State<_GenderSelectionDialog> createState() => _GenderSelectionDialogState();
}

class _GenderSelectionDialogState extends State<_GenderSelectionDialog> {
  late List<_PendingImport> _imports;

  @override
  void initState() {
    super.initState();
    // Create a mutable copy
    _imports = widget.pendingImports
        .map(
          (p) => _PendingImport(
            fileName: p.fileName,
            sourcePath: p.sourcePath,
            gender: p.gender,
          ),
        )
        .toList();
  }

  bool get _allGendersSelected => _imports.every((p) => p.gender != null);

  void _setAllGenders(_PortraitGender gender) {
    setState(() {
      for (final import in _imports) {
        import.gender = gender;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final validCount = _imports.length;
    final failedCount = widget.failedValidations.length;

    return AlertDialog(
      title: const Text('Import Portrait(s)'),
      content: SizedBox(
        width: 600,
        height: 500,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$validCount valid portrait${validCount == 1 ? '' : 's'}'
              '${failedCount > 0 ? ', $failedCount failed validation' : ''}',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Select male or female for each portrait.'
              '\nPortraits in .faction files only support male and female.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            if (_imports.length > 1) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _setAllGenders(_PortraitGender.male),
                    icon: const Icon(Icons.male, size: 18),
                    label: Text(
                      'All Male',
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _setAllGenders(_PortraitGender.female),
                    icon: const Icon(Icons.female, size: 18),
                    label: Text(
                      'All Female',
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _imports.length + widget.failedValidations.length,
                itemBuilder: (context, index) {
                  if (index < _imports.length) {
                    final import = _imports[index];
                    return _GenderSelectionListItem(
                      import: import,
                      onGenderChanged: (gender) {
                        setState(() {
                          import.gender = gender;
                        });
                      },
                    );
                  } else {
                    final failedIndex = index - _imports.length;
                    final failed = widget.failedValidations[failedIndex];
                    return _ImportResultListItem(result: failed);
                  }
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed:
              _allGendersSelected ? () => Navigator.of(context).pop(_imports) : null,
          child: const Text('Import'),
        ),
      ],
    );
  }
}

/// List item for selecting gender of a single portrait.
class _GenderSelectionListItem extends StatelessWidget {
  final _PendingImport import;
  final ValueChanged<_PortraitGender?> onGenderChanged;

  const _GenderSelectionListItem({
    required this.import,
    required this.onGenderChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const size = 128.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          spacing: 16,
          children: [
            // Thumbnail preview
            MovingTooltipWidget.framed(
              tooltipWidget: Image.file(File(import.sourcePath)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.file(
                  File(import.sourcePath),
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: size,
                    height: size,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.broken_image,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
            Column(
              spacing: 8,
              children: [
                Text(
                  import.fileName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SegmentedButton<_PortraitGender>(
                  segments: const [
                    ButtonSegment(
                      value: _PortraitGender.male,
                      label: Text('Male'),
                      icon: Icon(Icons.male),
                    ),
                    ButtonSegment(
                      value: _PortraitGender.female,
                      label: Text('Female'),
                      icon: Icon(Icons.female),
                    ),
                  ],
                  selected: import.gender != null ? {import.gender!} : {},
                  onSelectionChanged: (selection) {
                    onGenderChanged(selection.firstOrNull);
                  },
                  emptySelectionAllowed: true,
                  showSelectedIcon: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A list item widget that displays the result of a single portrait import.
class _ImportResultListItem extends StatelessWidget {
  final _ImportResult result;

  const _ImportResultListItem({required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Icon(
              result.success ? Icons.check_circle : Icons.error,
              color: result.success ? Colors.green : theme.colorScheme.error,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.fileName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (result.success && result.newPath != null)
                    SelectableText(
                      result.newPath!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  if (!result.success && result.reason != null)
                    Text(
                      result.reason!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
