import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

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
import 'package:trios/shipViewer/filter_widget.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/utils/search.dart';
import 'package:trios/widgets/moving_tooltip.dart';

part 'portraits_page_controller.mapper.dart';

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
@MappableClass()
class FilterPaneState with FilterPaneStateMappable {
  final bool showOnlyWithMetadata;
  final bool showOnlyReplaced;
  final bool showOnlyEnabledMods;
  final bool showFilters;
  final String searchQuery;

  const FilterPaneState({
    this.showOnlyWithMetadata = true,
    this.showOnlyReplaced = false,
    this.showOnlyEnabledMods = false,
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

  /// Grid filter categories for main pane.
  final List<GridFilter<PortraitFilterItem>> mainFilterCategories;

  /// Grid filter categories for left pane.
  final List<GridFilter<PortraitFilterItem>> leftFilterCategories;

  /// Grid filter categories for right pane.
  final List<GridFilter<PortraitFilterItem>> rightFilterCategories;

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
    this.mainFilterCategories = const [],
    this.leftFilterCategories = const [],
    this.rightFilterCategories = const [],
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

  /// Get the filter categories for the specified pane.
  List<GridFilter<PortraitFilterItem>> getFilterCategories(FilterPane pane) {
    return switch (pane) {
      FilterPane.main => mainFilterCategories,
      FilterPane.left => leftFilterCategories,
      FilterPane.right => rightFilterCategories,
    };
  }
}

/// Controller for the portraits page using Notifier.
class PortraitsPageController extends Notifier<PortraitsPageState> {
  @override
  PortraitsPageState build() {
    // Initialize filter categories for each pane
    final mainFilterCategories = _createFilterCategories();
    final leftFilterCategories = _createFilterCategories();
    final rightFilterCategories = _createFilterCategories();

    // Watch portrait data
    final portraitsAsync = ref.watch(AppState.portraits);
    final metadataAsync = ref.watch(AppState.portraitMetadata);
    final replacementsAsync = ref.watch(AppState.portraitReplacementsManager);
    final isLoadingPortraits =
        ref.watch(AppState.portraits.notifier).isLoadingPortraits;

    final allPortraits = portraitsAsync.value ?? {};
    final metadata = metadataAsync.value ?? {};

    // Hydrate replacements
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

    // Preserve existing state if available
    final existingState = stateOrNull;

    return (existingState ?? const PortraitsPageState()).copyWith(
      mainFilterCategories: mainFilterCategories,
      leftFilterCategories: leftFilterCategories,
      rightFilterCategories: rightFilterCategories,
      allPortraits: allPortraits,
      metadata: metadata,
      replacements: replacements,
      isLoading: isLoadingPortraits,
    );
  }

  List<GridFilter<PortraitFilterItem>> _createFilterCategories() {
    return [
      GridFilter<PortraitFilterItem>(
        name: 'Mod',
        valueGetter: (item) => item.modName,
      ),
      GridFilter<PortraitFilterItem>(
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

  /// Toggle the "Confirmed Portraits" filter for a specific pane.
  void toggleShowOnlyWithMetadata(FilterPane pane) {
    state = _updatePaneState(
      pane,
      (paneState) =>
          paneState.copyWith(showOnlyWithMetadata: !paneState.showOnlyWithMetadata),
    );
  }

  /// Toggle the "Only Your Changes" filter for a specific pane.
  void toggleShowOnlyReplaced(FilterPane pane) {
    state = _updatePaneState(
      pane,
      (paneState) =>
          paneState.copyWith(showOnlyReplaced: !paneState.showOnlyReplaced),
    );
  }

  /// Toggle the "Only Enabled Mods" filter for a specific pane.
  void toggleShowOnlyEnabledMods(FilterPane pane) {
    state = _updatePaneState(
      pane,
      (paneState) =>
          paneState.copyWith(showOnlyEnabledMods: !paneState.showOnlyEnabledMods),
    );
  }

  /// Toggle filters visibility for a specific pane.
  void toggleShowFilters(FilterPane pane) {
    state = _updatePaneState(
      pane,
      (paneState) => paneState.copyWith(showFilters: !paneState.showFilters),
    );
  }

  /// Set show filters visibility for a specific pane.
  void setShowFilters(FilterPane pane, bool value) {
    state = _updatePaneState(
      pane,
      (paneState) => paneState.copyWith(showFilters: value),
    );
  }

  /// Set the "Confirmed Portraits" filter value for a specific pane.
  void setShowOnlyWithMetadata(FilterPane pane, bool value) {
    state = _updatePaneState(
      pane,
      (paneState) => paneState.copyWith(showOnlyWithMetadata: value),
    );
  }

  /// Set the "Only Your Changes" filter value for a specific pane.
  void setShowOnlyReplaced(FilterPane pane, bool value) {
    state = _updatePaneState(
      pane,
      (paneState) => paneState.copyWith(showOnlyReplaced: value),
    );
  }

  /// Set the "Only Enabled Mods" filter value for a specific pane.
  void setShowOnlyEnabledMods(FilterPane pane, bool value) {
    state = _updatePaneState(
      pane,
      (paneState) => paneState.copyWith(showOnlyEnabledMods: value),
    );
  }

  /// Clear all filters for a specific pane.
  void clearAllFilters(FilterPane pane) {
    final filterCategories = state.getFilterCategories(pane);
    for (final filter in filterCategories) {
      filter.filterStates.clear();
    }

    // Trigger state update
    state = state.copyWith();
  }

  /// Update filter states for a specific filter.
  void updateFilterStates(
    GridFilter<PortraitFilterItem> filter,
    Map<String, bool?> states,
  ) {
    filter.filterStates.clear();
    filter.filterStates.addAll(states);

    // Trigger state update
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

  /// Get filtered and sorted images for a specific pane.
  List<({Portrait image, ModVariant? variant})> getFilteredImages(
    FilterPane pane,
    List<Mod> allMods,
  ) {
    final paneState = state.getPaneState(pane);
    final filterCategories = state.getFilterCategories(pane);

    // Convert all portraits to list format
    List<({Portrait image, ModVariant? variant})> images = state.allPortraits
        .entries
        .expand(
          (element) => element.value.map((e) => (variant: element.key, image: e)),
        )
        .toList();

    // Sort images
    images = _sortModsAndImages(images, r'graphics\\.*portraits\\');

    // Apply "Only Enabled Mods" filter
    if (paneState.showOnlyEnabledMods) {
      images = _filterToOnlyEnabledMods(images, allMods);
    }

    // Apply "Confirmed Portraits" filter
    if (paneState.showOnlyWithMetadata) {
      images = images.where((item) {
        final meta = state.metadata.getMetadataFor(item.image.relativePath);
        return meta.hasMetadata;
      }).toList();
    }

    // Apply grid filters
    images = _applyGridFilters(images, filterCategories);

    // Apply "Only Your Changes" filter
    if (paneState.showOnlyReplaced) {
      images = _filterToOnlyReplacedImages(images);
    }

    // Apply search filter
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
  List<PortraitFilterItem> getFilterItems() {
    return getAllImages().map((item) {
      final meta = state.metadata.getMetadataFor(item.image.relativePath);
      return PortraitFilterItem(
        portrait: item.image,
        variant: item.variant,
        metadata: meta.hasMetadata ? meta : null,
      );
    }).toList();
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

  List<({Portrait image, ModVariant? variant})> _filterToOnlyEnabledMods(
    List<({Portrait image, ModVariant? variant})> images,
    List<Mod> allMods,
  ) {
    return images
        .where(
          (element) =>
              element.variant == null ||
              element.variant?.mod(allMods)?.hasEnabledVariant == true,
        )
        .toList();
  }

  List<({Portrait image, ModVariant? variant})> _filterToOnlyReplacedImages(
    List<({Portrait image, ModVariant? variant})> images,
  ) {
    return images
        .where((element) => state.replacements.containsKey(element.image.hash))
        .toList();
  }

  List<({Portrait image, ModVariant? variant})> _applyGridFilters(
    List<({Portrait image, ModVariant? variant})> images,
    List<GridFilter<PortraitFilterItem>> filterCategories,
  ) {
    // Convert to filter items for processing
    var items = images.map((item) {
      final portraitMetadata =
          state.metadata.getMetadataFor(item.image.relativePath);
      return PortraitFilterItem(
        portrait: item.image,
        variant: item.variant,
        metadata: portraitMetadata.hasMetadata ? portraitMetadata : null,
      );
    }).toList();

    // Apply each filter category
    for (final filter in filterCategories) {
      if (filter.hasActiveFilters) {
        items = items.where((item) {
          final value = filter.valueGetter(item);
          final filterState = filter.filterStates[value];

          if (filterState == false) return false; // Explicitly excluded

          final hasIncludedValues = filter.filterStates.values.contains(true);
          if (hasIncludedValues) {
            return filterState == true; // Must be explicitly included
          }

          return true; // Only exclusions, allow anything not excluded
        }).toList();
      }
    }

    // Convert back to the original format
    return items
        .map((item) => (image: item.portrait, variant: item.variant))
        .toList();
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
