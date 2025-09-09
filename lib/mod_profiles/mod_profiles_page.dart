import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:trios/chipper/utils.dart';
import 'package:trios/mod_manager/audit_page.dart';
import 'package:trios/mod_profiles/models/shared_mod_list.dart';
import 'package:trios/mod_profiles/save_reader.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/thirdparty/dartx/string.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/svg_image_icon.dart';
import 'package:uuid/uuid.dart';

import 'mod_profile_card.dart';
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
                        maxCrossAxisExtent: 680,
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
