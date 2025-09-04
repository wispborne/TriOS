import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:trios/mod_manager/audit_page.dart';
import 'package:trios/mod_profiles/save_reader.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/extensions.dart';
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
                      const Spacer(),
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
                              child: IntrinsicHeight(
                                child: Column(
                                  children: [
                                    _buildNewProfileCard(),
                                    const Spacer(),
                                  ],
                                ),
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
              width: 300,
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
                  message: "Import a mod profile from clipboard JSON",
                  child: OutlinedButton(
                    onPressed: () {
                      _importModProfileFromClipboard();
                    },
                    child: const Text('Import Profile'),
                  ),
                ),
                const SizedBox(width: 8),
                MovingTooltipWidget.text(
                  message:
                      "Creates a new profile using your current mods."
                      "\nDoes not set it to active.",
                  child: OutlinedButton(
                    onPressed: () {
                      _onSubmittedNewProfile(newProfileNameController);
                    },
                    child: const Text('Create Profile'),
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

  Future<void> _importModProfileFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData?.text == null || clipboardData!.text!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Clipboard is empty')),
        );
        return;
      }

      final jsonData = jsonDecode(clipboardData.text!);
      if (jsonData is! Map<String, dynamic>) {
        throw const FormatException('Invalid JSON format');
      }

      // Validate required fields
      if (!jsonData.containsKey('enabledModVariants')) {
        throw const FormatException('Missing enabledModVariants field');
      }

      final originalId = jsonData['id'] as String?;
      final originalName = jsonData['name'] as String? ?? 'Imported Profile';
      
      // Check for existing profiles
      final existingProfiles = ref.read(modProfilesProvider).valueOrNull?.modProfiles ?? [];
      final existingProfileWithId = existingProfiles.firstWhereOrNull((p) => p.id == originalId);
      final existingProfileWithName = existingProfiles.firstWhereOrNull((p) => p.name == originalName);

      String finalId = originalId ?? const Uuid().v4();
      String finalName = originalName;

      // Handle conflicts
      if (existingProfileWithId != null || existingProfileWithName != null) {
        final conflictType = existingProfileWithId != null ? 'ID and name' : 'name';
        final existingProfile = existingProfileWithId ?? existingProfileWithName!;
        
        final result = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Profile Already Exists'),
            content: Text(
              'A profile with the same $conflictType already exists:\n\n'
              '"${existingProfile.name}"\n\n'
              'What would you like to do?'
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
            return;
          case 'rename':
            // Generate new ID and create unique name
            finalId = const Uuid().v4();
            finalName = _generateUniqueProfileName(originalName, existingProfiles);
            break;
          case 'overwrite':
            // Keep original ID and name to overwrite
            break;
          default:
            return; // User dismissed dialog
        }
      }

      // Create ModProfile from JSON
      final profile = ModProfile(
        id: finalId,
        name: finalName,
        description: jsonData['description'] ?? 'Imported from clipboard',
        sortOrder: jsonData['sortOrder'] ?? 0,
        enabledModVariants: (jsonData['enabledModVariants'] as List)
            .map((variant) => ShallowModVariant(
                  modId: variant['modId'] ?? '',
                  modName: variant['modName'],
                  smolVariantId: variant['smolVariantId'] ?? '',
                  version: variant['version'] != null 
                      ? Version.parse(variant['version'].toString(), sanitizeInput: true)
                      : null,
                ))
            .toList(),
        dateCreated: jsonData['dateCreated'] != null 
            ? DateTime.parse(jsonData['dateCreated'])
            : DateTime.now(),
        dateModified: DateTime.now(), // Always update modified time on import
      );

      // Add or update the profile
      final notifier = ref.read(modProfilesProvider.notifier);
      if (existingProfileWithId != null && finalId == originalId) {
        // Overwrite existing profile
        notifier.updateModProfile(profile);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully overwritten profile: ${profile.name}')),
        );
      } else {
        // Add new profile
        notifier.updateState(
          (prevState) => prevState.copyWith(
            modProfiles: [...?prevState.modProfiles, profile],
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully imported profile: ${profile.name}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to import profile: ${e.toString()}')),
      );
    }
  }

  String _generateUniqueProfileName(String baseName, List<ModProfile> existingProfiles) {
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

    var dateCreated = profile?.dateCreated ?? save!.saveDate;
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
                                  Constants.dateTimeFormat.format(
                                    dateCreated?.toLocal() ?? DateTime.now(),
                                  ),
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
                          message: 'Share mod list by copying the IDs to clipboard',
                          child: IconButton(
                            icon: const Icon(Icons.data_object),
                            onPressed: () {
                              _copyModListToClipboardAsJson(enabledModVariants);
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
                      return Row(
                        children: [
                          Expanded(
                            child: Text(
                              mod.modName ?? mod.modId,
                              overflow: TextOverflow.fade,
                              maxLines: 1,
                              style: theme.textTheme.labelLarge,
                            ),
                          ),
                          Text(
                            mod.version?.toString() ?? '???',
                            style: theme.textTheme.labelLarge,
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

  void _copyModListToClipboardAsJson(List<ShallowModVariant> enabledModVariants) {
    final enabledModVariantsJson = enabledModVariants.map((mod) => {
      "modId": mod.modId,
      "modName": mod.modName ?? mod.modId,
      "smolVariantId": mod.smolVariantId,
      "version": mod.version?.toString() ?? "Unknown"
    }).toList();

    final profile = widget.profile;
    final jsonOutput = {
      "id": profile?.id ?? "generated-profile",
      "name": profile?.name ?? "Current Mod Profile",
      "description": profile?.description ?? "Generated mod profile from TriOS",
      "sortOrder": profile?.sortOrder ?? 0,
      "enabledModVariants": enabledModVariantsJson,
      "dateCreated": (profile?.dateCreated ?? DateTime.now()).toIso8601String(),
      "dateModified": (profile?.dateModified ?? DateTime.now()).toIso8601String()
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(jsonOutput);
    
    Clipboard.setData(ClipboardData(text: jsonString));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mod list copied as JSON to clipboard')),
    );
  }
}
