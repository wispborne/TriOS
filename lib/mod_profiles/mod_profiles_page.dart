import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:trios/chipper/utils.dart';
import 'package:trios/mod_manager/audit_page.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/mod_profiles/models/shared_mod_list.dart';
import 'package:trios/mod_profiles/save_reader.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/thirdparty/dartx/iterable.dart';
import 'package:trios/thirdparty/dartx/string.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/widgets/disable.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/svg_image_icon.dart';
import 'package:uuid/uuid.dart';

import '../models/mod_variant.dart';
import '../models/version.dart';
import '../widgets/trios_expansion_tile.dart';
import 'mod_profiles_manager.dart';
import 'models/mod_profile.dart';

class ModProfilePage extends ConsumerStatefulWidget {
  const ModProfilePage({super.key});

  @override
  ConsumerState<ModProfilePage> createState() => _ModProfilePageState();
}

class _ModProfilePageState extends ConsumerState<ModProfilePage>
    with AutomaticKeepAliveClientMixin<ModProfilePage> {
  @override
  bool get wantKeepAlive => true;

  final actualAxisSpacing = 8;

  // Make a minute change to the height to force a row remeasure when the expansion tile is opened/closed.
  double axisSpacingForHeightHack = 8;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final modProfilesAsync = ref.watch(modProfilesProvider);
    final saveGamesAsync = ref.watch(saveFileProvider);
    const minHeight = 120.0;
    const cardPadding = 8.0;

    return Theme(
      data: Theme.of(context).lowContrastCardTheme(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, right: 4, bottom: 4),
                  child: Row(
                    children: [
                      Text(
                        'Mod Profiles',
                        style: Theme.of(
                          context,
                        ).textTheme.headlineSmall?.copyWith(fontSize: 20),
                      ),
                      IconButton(
                        icon: const Icon(Icons.info),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text("Mod Profiles"),
                                content: const Text(
                                  "Mod profiles are a way to quickly switch between different mods, including specific versions."
                                  "\nWhen one is enabled, any mods you change will update the profile as well."
                                  "\n"
                                  "\n\nYou can also generate profiles from your saves.",
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text("OK"),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: modProfilesAsync.when(
                    data: (modProfilesObj) {
                      final modProfiles = modProfilesObj.modProfiles
                          .sortedByButBetter((profile) => profile.dateModified)
                          .reversed
                          .toList();
                      return AlignedGridView.extent(
                        crossAxisSpacing: axisSpacingForHeightHack,
                        mainAxisSpacing: 10,
                        maxCrossAxisExtent: 560,
                        // crossAxisCount: 2,
                        itemCount: modProfiles.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return ConstrainedBox(
                              constraints: const BoxConstraints(
                                minHeight: minHeight,
                              ),
                              child: Align(
                                alignment: Alignment.topLeft,
                                child: _buildNewProfileCard(),
                              ),
                            );
                          } else {
                            final profile = modProfiles[index - 1];

                            return ModProfileCard(
                              minHeight: minHeight,
                              profile: profile,
                              modProfiles: modProfiles,
                              save: null,
                              saves: null,
                              cardPadding: cardPadding,
                              actualAxisSpacing: actualAxisSpacing,
                              axisSpacingForHeightHack:
                                  axisSpacingForHeightHack,
                            );
                          }
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stackTrace) =>
                        Center(child: Text('Error: $error')),
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(),
          Padding(
            padding: const EdgeInsets.only(left: 0.0),
            child: SizedBox(
              width: 320,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 4,
                      right: 4,
                      bottom: 4,
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Save Games',
                          style: Theme.of(
                            context,
                          ).textTheme.headlineSmall?.copyWith(fontSize: 20),
                        ),
                        const Spacer(),
                        MovingTooltipWidget.text(
                          message: 'Reread from Saves folder',
                          child: IconButton(
                            onPressed: () {
                              ref.invalidate(saveFileProvider);
                            },
                            icon: const Icon(Icons.refresh),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: saveGamesAsync.when(
                      data: (saveGames) {
                        saveGames = saveGames
                            .sortedByButBetter(
                              (save) =>
                                  save.saveDate ??
                                  DateTime.fromMicrosecondsSinceEpoch(0),
                            )
                            .reversed
                            .toList();
                        return AlignedGridView.count(
                          crossAxisSpacing: axisSpacingForHeightHack,
                          mainAxisSpacing: 10,
                          crossAxisCount: 1,
                          itemCount: saveGames.length,
                          itemBuilder: (context, index) {
                            return ModProfileCard(
                              minHeight: minHeight,
                              profile: null,
                              modProfiles: null,
                              save: saveGames[index],
                              saves: saveGames,
                              cardPadding: cardPadding,
                              actualAxisSpacing: actualAxisSpacing,
                              axisSpacingForHeightHack:
                                  axisSpacingForHeightHack,
                            );
                          },
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, stackTrace) =>
                          Center(child: Text('Error: $error')),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 350,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Container(
                // round edges
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    ThemeManager.cornerRadius,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: const AuditPage(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewProfileCard() {
    final newProfileNameController = TextEditingController();
    return Card(
      margin: const EdgeInsets.all(0),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: newProfileNameController,
              decoration: const InputDecoration(labelText: 'Name'),
              onSubmitted: (_) =>
                  _onSubmittedNewProfile(newProfileNameController),
            ),
            const SizedBox(height: 8.0),
            Row(
              children: [
                const Spacer(),
                MovingTooltipWidget.text(
                  message: "Import a shared mod Profile from clipboard",
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final success = await _importModProfileFromClipboard();
                      if (!success) {
                        showAlertDialog(
                          context,
                          title: "Sharing Mod Profiles",
                          widget: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "No valid mod profile was found on your clipboard.",
                              ),
                              const SizedBox(height: 8.0),
                              Row(
                                children: [
                                  const Text(
                                    "1. Export a profile by clicking the",
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: SvgImageIcon(
                                      "assets/images/icon-export-horiz.svg",
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                      width: 24,
                                      height: 24,
                                    ),
                                  ),
                                  const Text("Share button on a Mod Profile."),
                                ],
                              ),
                              const Text(
                                "2. Paste the text to another TriOS user.",
                              ),
                              Row(
                                children: [
                                  const Text("3. They may click"),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: SvgImageIcon(
                                      "assets/images/icon-import-horiz.svg",
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                      width: 24,
                                      height: 24,
                                    ),
                                  ),
                                  const Text(
                                    "Import Profile to use your profile.",
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    icon: SvgImageIcon(
                      "assets/images/icon-import-horiz.svg",
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    label: const Text('Import Profile'),
                  ),
                ),
                const SizedBox(width: 8),
                MovingTooltipWidget.text(
                  message:
                      "Creates a new profile using your current mods."
                      "\nDoes not set it to active.",
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _onSubmittedNewProfile(newProfileNameController);
                    },
                    icon: Icon(
                      Icons.add,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    label: const Text('Create Profile'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _onSubmittedNewProfile(TextEditingController newProfileNameController) {
    if (newProfileNameController.text.isNotEmpty) {
      ref
          .read(modProfilesProvider.notifier)
          .createModProfile(
            newProfileNameController.text,
            enabledModVariants: ref
                .read(AppState.enabledModVariants)
                .map((mod) => ShallowModVariant.fromModVariant(mod))
                .toList(),
          );
      newProfileNameController.clear();
    }
  }

  Future<bool> _importModProfileFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData?.text == null || clipboardData!.text!.isEmpty) {
        Fimber.w('Clipboard is empty');
        return false;
      }

      SharedModList? importedModList;

      if (clipboardData.text.isNullOrBlank) {
        Fimber.w('Clipboard is empty');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Clipboard is empty')));
        return false;
      }

      try {
        importedModList = SharedModListMapper.fromJson(clipboardData.text!);
      } catch (e) {
        Fimber.w('Failed to parse JSON from clipboard: $e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
        return false;
      }

      final originalId = importedModList.id as String?;
      final originalName =
          importedModList.name as String? ?? 'Imported Profile';

      // Check for existing profiles
      final existingProfiles =
          ref.read(modProfilesProvider).valueOrNull?.modProfiles ?? [];
      final existingProfileWithId = existingProfiles.firstWhereOrNull(
        (p) => p.id == originalId,
      );
      final existingProfileWithName = existingProfiles.firstWhereOrNull(
        (p) => p.name == originalName,
      );

      String finalId = originalId ?? const Uuid().v4();
      String finalName = originalName;

      // Handle conflicts
      if (existingProfileWithId != null || existingProfileWithName != null) {
        final existingProfile =
            existingProfileWithId ?? existingProfileWithName!;

        final result = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Profile Already Exists'),
            content: StatefulBuilder(
              builder: (context, stateSetter) {
                // Build a minimal diff of mod name + versions (Existing vs Imported)
                final theme = Theme.of(context);
                final existingById = {
                  for (final v in (existingProfile.enabledModVariants))
                    v.modId: (
                      name: (v.modName ?? v.modId),
                      version: (v.version),
                    ),
                };

                final importedRaw = importedModList?.mods ?? [];

                final importedById = {
                  for (final v in importedRaw)
                    v.modId: (
                      name: (v.modName ?? v.modId),
                      version: v.versionName,
                    ),
                };

                final allIds = <String>{}
                  ..addAll(existingById.keys)
                  ..addAll(importedById.keys);

                final differingIds =
                    allIds.where((id) {
                      final existingV = existingById[id]?.version;
                      final importedV = importedById[id]?.version;
                      // Show only rows where the versions differ or the mod is missing on one side
                      return existingV != importedV;
                    }).toList()..sort((a, b) {
                      final nameA =
                          importedById[a]?.name ?? existingById[a]?.name ?? a;
                      final nameB =
                          importedById[b]?.name ?? existingById[b]?.name ?? b;
                      return nameA.toLowerCase().compareTo(nameB.toLowerCase());
                    });

                return ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 520,
                    maxHeight: 420,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Unable to import profile '$finalName'."),
                      Text(
                        "\nA profile with the same ${existingProfileWithId != null ? "ID (name: '${existingProfile.name}')" : existingProfile.name} already exists.",
                      ),
                      const SizedBox(height: 8),
                      if (differingIds.isEmpty)
                        Text('Both profiles are identical.')
                      else
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: theme.dividerColor.withOpacity(0.4),
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Column(
                            children: [
                              // Header
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Mod',
                                        style: theme.textTheme.labelMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        'Existing',
                                        style: theme.textTheme.labelMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Imported',
                                        style: theme.textTheme.labelMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 1),
                              // Rows
                              SingleChildScrollView(
                                child: Column(
                                  children: differingIds.map((id) {
                                    final existing = existingById[id];
                                    final imported = importedById[id];
                                    final name =
                                        imported?.name ?? existing?.name ?? id;
                                    final existingV =
                                        existing?.version.toString() ?? '—';
                                    final importedV =
                                        imported?.version.toString() ?? '—';
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 6,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              name,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                              style: theme.textTheme.labelLarge,
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              existingV,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                              style: theme.textTheme.labelLarge,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              importedV,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                              style: theme.textTheme.labelLarge,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop('cancel'),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop('rename'),
                child: const Text('Import as Copy'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop('overwrite'),
                child: const Text('Overwrite Existing'),
              ),
            ],
          ),
        );

        switch (result) {
          case 'cancel':
            return true;
          case 'rename':
            // Generate new ID and create unique name
            finalId = const Uuid().v4();
            finalName = _generateUniqueProfileName(
              originalName,
              existingProfiles,
            );
            break;
          case 'overwrite':
            // Keep original ID and name to overwrite
            break;
          default:
            return true; // User dismissed dialog
        }
      }

      final modProfile = ModProfile(
        id: finalId,
        name: finalName,
        description: importedModList.description,
        sortOrder: 0,
        enabledModVariants: importedModList.mods
            .map(
              (mod) => ShallowModVariant(
                modId: mod.modId,
                modName: mod.modName,
                smolVariantId: mod.smolVariantId,
                version: mod.versionName,
              ),
            )
            .toList(),
        dateCreated: importedModList.dateCreated,
        dateModified: importedModList.dateModified,
      );

      // Add or update the profile
      final notifier = ref.read(modProfilesProvider.notifier);
      if (existingProfileWithId != null && finalId == originalId) {
        // Overwrite existing profile
        notifier.updateModProfile(modProfile);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully overwritten profile: ${modProfile.name}',
            ),
          ),
        );
      } else {
        // Add new profile
        notifier.updateState(
          (prevState) => prevState.copyWith(
            modProfiles: [...prevState.modProfiles, modProfile],
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully imported profile: ${modProfile.name}'),
          ),
        );
      }

      return true;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to import profile: ${e.toString()}')),
      );
      return false;
    }
  }

  String _generateUniqueProfileName(
    String baseName,
    List<ModProfile> existingProfiles,
  ) {
    final existingNames = existingProfiles.map((p) => p.name).toSet();

    if (!existingNames.contains(baseName)) {
      return baseName;
    }

    // Try "Base Name (Copy)", "Base Name (Copy 2)", etc.
    String copyName = '$baseName (Copy)';
    if (!existingNames.contains(copyName)) {
      return copyName;
    }

    int counter = 2;
    while (existingNames.contains('$baseName (Copy $counter)')) {
      counter++;
    }

    return '$baseName (Copy $counter)';
  }
}

class ModProfileCard extends ConsumerStatefulWidget {
  final double minHeight;
  final ModProfile? profile;
  final List<ModProfile>? modProfiles;
  final SaveFile? save;
  final List<SaveFile>? saves;
  final double cardPadding;
  final int actualAxisSpacing;
  final double axisSpacingForHeightHack;

  const ModProfileCard({
    super.key,
    required this.minHeight,
    required this.profile,
    required this.modProfiles,
    required this.save,
    required this.saves,
    required this.cardPadding,
    required this.actualAxisSpacing,
    required this.axisSpacingForHeightHack,
  });

  @override
  ConsumerState createState() => _ModProfileCardState();
}

class _ModProfileCardState extends ConsumerState<ModProfileCard> {
  final TextEditingController _nameController = TextEditingController();
  String? _editingProfileId;
  double axisSpacingForHeightHack = 8;
  bool _isPortraitExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardPadding = widget.cardPadding;
    final minHeight = widget.minHeight;

    final isSaveGame = widget.save != null;

    final profile = widget.profile;
    final save = widget.save;
    final isEditing = !isSaveGame && profile?.id == _editingProfileId;
    final activeProfileId = ref.watch(
      appSettings.select((s) => s.activeModProfileId),
    );
    final isActiveProfile =
        activeProfileId != null && profile?.id == activeProfileId;
    final isGameRunning = ref.watch(AppState.isGameRunning).value == true;

    final allMods = ref.read(AppState.mods);
    final modVariants = ref.read(AppState.modVariants).valueOrNull ?? [];
    final currentlyEnabledModVariants = ref.read(AppState.enabledModVariants);
    final changesByModId = ModProfileManagerNotifier.computeModProfileChanges(
      profile ??
          ModProfile.newProfile(
            "",
            save?.mods.map((m) => m.toShallowModVariant()).toList() ?? [],
          ),
      allMods,
      modVariants,
      currentlyEnabledModVariants,
    ).associateBy((m) => m.modId);

    var enabledModVariants =
        profile?.enabledModVariants ??
        save!.mods
            .map(
              (mod) => ShallowModVariant(
                modId: mod.id,
                modName: mod.name,
                version: mod.version,
                smolVariantId: createSmolId(mod.id, mod.version),
              ),
            )
            .toList();

    final modRootFolders = [
      ref.watch(appSettings.select((s) => s.gameCoreDir)),
      ...ref
          .watch(AppState.mods)
          .map((mod) => mod.findFirstEnabledOrHighestVersion?.modFolder),
    ].nonNulls.toList();

    var dateCreated = profile?.dateCreated ?? save?.saveDate;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Card(
        margin: const EdgeInsets.all(0),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isActiveProfile
                  ? theme.colorScheme.primary
                  : Colors.transparent,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(ThemeManager.cornerRadius),
          ),
          child: Stack(
            children: [
              if (!isSaveGame)
                Positioned(
                  right: 0,
                  top: 0,
                  child: isEditing
                      ? IconButton(
                          icon: const Icon(Icons.check),
                          onPressed: () {
                            _onSubmitProfileRename(profile);
                          },
                        )
                      : IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            setState(() {
                              _editingProfileId = profile!.id;
                              _nameController.text = profile.name;
                            });
                          },
                        ),
                ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      left: 0,
                      top: cardPadding,
                      right: cardPadding + 24,
                      bottom: cardPadding,
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 8),
                        if (save?.portraitPath != null)
                          FutureBuilder<File?>(
                            future: Future.sync(() async {
                              final portraitImage = modRootFolders
                                  .map(
                                    (dir) => dir
                                        .resolve(save!.portraitPath!)
                                        .toFile(),
                                  )
                                  .firstWhereOrNull(
                                    (file) => file.existsSync(),
                                  );

                              if (portraitImage == null) return null;

                              final portraitReplacements = ref.read(
                                AppState.portraitReplacementsManager.notifier,
                              );
                              final replacement = await portraitReplacements
                                  .getReplacementByPath(portraitImage);
                              if (replacement != null) {
                                return replacement.lastKnownFullPath.toFile();
                              } else {
                                return portraitImage;
                              }
                            }),
                            builder: (context, portraitImage) {
                              if (portraitImage.data == null) {
                                return const SizedBox.shrink();
                              }

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isPortraitExpanded =
                                        !_isPortraitExpanded; // Toggle between expanded and thumbnail
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: MovingTooltipWidget.text(
                                      message:
                                          portraitImage.data!.nameWithExtension,
                                      child: Image.file(
                                        portraitImage.data!,
                                        width: _isPortraitExpanded ? null : 36,
                                        // Toggle width: full size or thumbnail
                                        height: _isPortraitExpanded
                                            ? null
                                            : 36, // Optional: toggle height as well
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        Expanded(
                          child: Builder(
                            builder: (context) {
                              return isEditing
                                  ? TextField(
                                      controller: _nameController,
                                      decoration: const InputDecoration(
                                        labelText: 'Name',
                                      ),
                                      onSubmitted: (value) {
                                        _onSubmitProfileRename(profile);
                                      },
                                    )
                                  : MovingTooltipWidget.text(
                                      message:
                                          profile?.name ?? save?.characterName,
                                      child: Text(
                                        profile?.name ?? save!.characterName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodyLarge
                                            ?.copyWith(fontSize: 18),
                                      ),
                                    );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: cardPadding),
                    child: DefaultTextStyle.merge(
                      style: theme.textTheme.labelSmall,
                      child: Column(
                        children: [
                          if (save != null)
                            Row(
                              children: [
                                if (save.gameTimestamp != null)
                                  Text(
                                    "Level ${save.characterLevel}",
                                    style: theme.textTheme.labelSmall,
                                  ),
                                Text(
                                  "  •  ",
                                  style: theme.textTheme.labelSmall,
                                ),
                                Text(
                                  Constants.gameDateFormat.format(
                                    DateTime.fromMicrosecondsSinceEpoch(
                                      save.gameTimestamp! * 1000,
                                    ),
                                  ),
                                  style: theme.textTheme.labelSmall,
                                ),
                              ],
                            ),
                          Row(
                            children: [
                              Text('${enabledModVariants.length} mods'),
                              // bullet
                              Text("  •  ", style: theme.textTheme.labelSmall),
                              MovingTooltipWidget.text(
                                message:
                                    'Created: ${Constants.dateTimeFormat.format(dateCreated?.toLocal() ?? DateTime.now())}'
                                    '\nLast modified: ${Constants.dateTimeFormat.format(profile?.dateModified?.toLocal() ?? DateTime.now())}',
                                child: Text(
                                  dateCreated?.toLocal().let(
                                        (d) =>
                                            Constants.dateTimeFormat.format(d),
                                      ) ??
                                      "(date missing)",
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TriOSExpansionTile(
                    tilePadding: EdgeInsets.symmetric(horizontal: cardPadding),
                    title: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Spacer(),
                        if (!isSaveGame)
                          MovingTooltipWidget.text(
                            message: 'Duplicate profile',
                            child: IconButton(
                              icon: const SvgImageIcon(
                                "assets/images/icon-clone.svg",
                              ),
                              onPressed: () {
                                ref
                                    .read(modProfilesProvider.notifier)
                                    .cloneModProfile(profile!);
                              },
                            ),
                          ),
                        MovingTooltipWidget.text(
                          message: 'Copy mod list to clipboard',
                          child: IconButton(
                            icon: const Icon(Icons.content_copy),
                            onPressed: () {
                              _copyModListToClipboard(enabledModVariants);
                            },
                          ),
                        ),
                        MovingTooltipWidget.text(
                          message:
                              'Share mod Profile'
                              '\n(copies data to clipboard)',
                          child: IconButton(
                            icon: SvgImageIcon(
                              "assets/images/icon-export-horiz.svg",
                            ),
                            onPressed: () {
                              copyModListToClipboard(
                                id: profile?.id,
                                name: profile?.name,
                                description: profile?.description,
                                variants: enabledModVariants,
                                dateCreated: profile?.dateCreated,
                                dateModified: profile?.dateModified,
                                context: context,
                              );
                            },
                          ),
                        ),
                        if (!isSaveGame)
                          Disable(
                            isEnabled:
                                widget.modProfiles!.length > 1 &&
                                activeProfileId != profile?.id,
                            child: MovingTooltipWidget.text(
                              message: 'Delete profile',
                              child: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete profile?'),
                                      content: Text(
                                        "Are you sure you want to delete profile '${profile?.name}'?",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                            ref
                                                .read(
                                                  modProfilesProvider.notifier,
                                                )
                                                .removeModProfile(profile!.id);
                                          },
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        // if (kDebugMode)
                        //   Tooltip(
                        //       message: 'Id: ${profile.id}',
                        //       child: const Icon(
                        //           Icons.bug_report)),
                        if (isSaveGame)
                          // Open save folder
                          MovingTooltipWidget.text(
                            message: 'Open save folder',
                            child: IconButton(
                              icon: const SvgImageIcon(
                                "assets/images/icon-folder-open.svg",
                              ),
                              onPressed: () {
                                save!.folder.openInExplorer();
                              },
                            ),
                          ),
                        const SizedBox(width: 8),
                        if (!isSaveGame)
                          Disable(
                            isEnabled: !isGameRunning,
                            child: MovingTooltipWidget.text(
                              message: isGameRunning ? "Game is running" : "",
                              child: OutlinedButton(
                                onPressed: isActiveProfile
                                    ? null
                                    : () {
                                        ref
                                            .read(modProfilesProvider.notifier)
                                            .showActivateDialog(
                                              profile!,
                                              context,
                                            );
                                      },
                                child: Text(
                                  isActiveProfile ? 'Enabled' : 'Enable',
                                ),
                              ),
                            ),
                          ),
                        if (isSaveGame)
                          MovingTooltipWidget.text(
                            message:
                                "Creates a profile based on this save's last-used mods.",
                            child: OutlinedButton(
                              onPressed: () {
                                ref
                                    .read(modProfilesProvider.notifier)
                                    .createModProfile(
                                      save!.characterName,
                                      enabledModVariants: enabledModVariants,
                                    );
                              },
                              child: const Text("Create Profile"),
                            ),
                          ),
                      ],
                    ),
                    // expansionAnimationStyle:
                    //     AnimationStyle.noAnimation,
                    controlAffinity: ListTileControlAffinity.leading,
                    backgroundColor: theme.colorScheme.surfaceContainerLow,
                    collapsedShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        ThemeManager.cornerRadius,
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        ThemeManager.cornerRadius,
                      ),
                    ),
                    dense: true,
                    expansionAnimationStyle: AnimationStyle.noAnimation,
                    onExpansionChanged: (isExpanded) {
                      // This hack is needed to force the expansion tile to rebuild.
                      // Without it, expanding a second tile doesn't remeasure heights and the row stays the wrong height.
                      WidgetsBinding.instance.scheduleFrameCallback((_) {
                        setState(() {
                          // todo this might need to reference the parent widget's actualAxisSpacing
                          axisSpacingForHeightHack =
                              widget.actualAxisSpacing +
                              Random().nextInt(1000) * .000001;
                        });
                      });
                    },
                    childrenPadding: const EdgeInsets.all(8),
                    children: enabledModVariants.map((mod) {
                      final change = changesByModId[mod.modId];
                      final textColor =
                          change?.changeType == ModChangeType.missingMod
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurface;

                      return Row(
                        children: [
                          if (change?.changeType == ModChangeType.missingMod)
                            Padding(
                              padding: const EdgeInsets.only(right: 2),
                              child: MovingTooltipWidget.text(
                                message: 'Search Catalog',
                                child: IconButton.outlined(
                                  icon: Icon(Icons.search),
                                  iconSize: 16,
                                  color: theme.colorScheme.primary,q
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(2),
                                  onPressed: () {},
                                ),
                              ),
                            ),
                          Expanded(
                            child: Text(
                              mod.modName ?? mod.modId,
                              overflow: TextOverflow.fade,
                              maxLines: 1,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: textColor,
                              ),
                            ),
                          ),
                          Text(
                            mod.version?.toString() ?? '???',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: textColor,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onSubmitProfileRename(ModProfile? profile) {
    ref
        .read(modProfilesProvider.notifier)
        .updateModProfile(profile!.copyWith(name: _nameController.text));
    setState(() {
      _editingProfileId = null;
    });
  }

  void _copyModListToClipboard(List<ShallowModVariant> enabledModVariants) {
    final modList = enabledModVariants
        .map(
          (mod) =>
              '${mod.modName ?? mod.modId} - Version: ${mod.version ?? 'Unknown'}',
        )
        .join('\n');
    Clipboard.setData(ClipboardData(text: modList));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mod list copied to clipboard')),
    );
  }

  void _copyModListToClipboardAsJson(
    List<ShallowModVariant> enabledModVariants,
  ) {
    final enabledModVariantsJson = enabledModVariants
        .map(
          (mod) => {
            "modId": mod.modId,
            "modName": mod.modName ?? mod.modId,
            "variantId": mod.smolVariantId,
            "versionName": mod.version?.toString() ?? "Unknown",
          },
        )
        .toList();

    final profile = widget.profile;
    final save = widget.save;
    final jsonOutput = {
      "id": profile?.id ?? save?.id ?? "shared-profile",
      "name": profile?.name ?? save?.characterName ?? "Shared Mod Profile",
      "description":
          profile?.description ??
          save?.toString() ??
          "Shared mod profile from ${Constants.appName}",
      "mods": enabledModVariantsJson,
      "dateCreated": (profile?.dateCreated ?? DateTime.now()).toIso8601String(),
      "dateModified": (profile?.dateModified ?? DateTime.now())
          .toIso8601String(),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(jsonOutput);

    Clipboard.setData(ClipboardData(text: jsonString));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mod Profile copied to clipboard.')),
    );
  }
}
