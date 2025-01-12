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
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/disable.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/svg_image_icon.dart';

import '../models/mod_variant.dart';
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
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontSize: 20),
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
                                        "\n\nYou can also generate profiles from your saves."),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text("OK"),
                                      ),
                                    ],
                                  );
                                });
                          }),
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
                                )));
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
                    padding:
                        const EdgeInsets.only(left: 4, right: 4, bottom: 4),
                    child: Row(
                      children: [
                        Text(
                          'Save Games',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontSize: 20),
                        ),
                        const Spacer(),
                        MovingTooltipWidget.text(
                          message: 'Reread from Saves folder',
                          child: IconButton(
                              onPressed: () {
                                ref.invalidate(saveFileProvider);
                              },
                              icon: const Icon(Icons.refresh)),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: saveGamesAsync.when(
                      data: (saveGames) {
                        saveGames = saveGames
                            .sortedByButBetter((save) =>
                                save.saveDate ??
                                DateTime.fromMicrosecondsSinceEpoch(0))
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
                      borderRadius:
                          BorderRadius.circular(ThemeManager.cornerRadius),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: const AuditPage()),
              )),
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
                decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 8.0),
            Row(
              children: [
                const Spacer(),
                MovingTooltipWidget.text(
                  message: "Creates a new profile using your current mods."
                      "\nDoes not set it to active.",
                  child: OutlinedButton(
                    onPressed: () {
                      if (newProfileNameController.text.isNotEmpty) {
                        ref.read(modProfilesProvider.notifier).createModProfile(
                            newProfileNameController.text,
                            enabledModVariants: ref
                                .read(AppState.enabledModVariants)
                                .map((mod) =>
                                    ShallowModVariant.fromModVariant(mod))
                                .toList());
                        newProfileNameController.clear();
                      }
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
    final activeProfileId =
        ref.watch(appSettings.select((s) => s.activeModProfileId));
    final isActiveProfile = profile?.id == activeProfileId;
    final isGameRunning = ref.watch(AppState.isGameRunning).value == true;

    var enabledModVariants = profile?.enabledModVariants ??
        save!.mods
            .map((mod) => ShallowModVariant(
                modId: mod.id,
                modName: mod.name,
                version: mod.version,
                smolVariantId: createSmolId(mod.id, mod.version)))
            .toList();

    final modRootFolders = [
      ref.watch(appSettings.select((s) => s.gameCoreDir)),
      ...ref
          .watch(AppState.mods)
          .map((mod) => mod.findFirstEnabledOrHighestVersion?.modFolder)
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
                width: 2),
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
                            ref
                                .read(modProfilesProvider.notifier)
                                .updateModProfile(
                                  profile!.copyWith(name: _nameController.text),
                                );
                            setState(() {
                              _editingProfileId = null;
                            });
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
                          const SizedBox(
                            width: 8,
                          ),
                          if (save?.portraitPath != null)
                            Builder(
                              builder: (context) {
                                var portraitImage = modRootFolders
                                    .map((dir) => dir
                                        .resolve(save!.portraitPath!)
                                        .toFile())
                                    .firstWhereOrNull(
                                        (file) => file.existsSync());

                                if (portraitImage == null) {
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
                                      child: Image.file(
                                        portraitImage,
                                        width: _isPortraitExpanded ? null : 36,
                                        // Toggle width: full size or thumbnail
                                        height: _isPortraitExpanded
                                            ? null
                                            : 36, // Optional: toggle height as well
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          Expanded(
                            child: Builder(builder: (context) {
                              return isEditing
                                  ? TextField(
                                      controller: _nameController,
                                      decoration: const InputDecoration(
                                          labelText: 'Name'),
                                    )
                                  : MovingTooltipWidget.text(
                                      message:
                                          profile?.name ?? save?.characterName,
                                      child: Text(
                                          profile?.name ?? save!.characterName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.bodyLarge
                                              ?.copyWith(
                                            fontSize: 18,
                                          )),
                                    );
                            }),
                          ),
                        ],
                      )),
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
                                Text("  •  ",
                                    style: theme.textTheme.labelSmall),
                                Text(
                                  Constants.gameDateFormat.format(
                                      DateTime.fromMicrosecondsSinceEpoch(
                                          save.gameTimestamp! * 1000)),
                                  style: theme.textTheme.labelSmall,
                                ),
                              ],
                            ),
                          Row(
                            children: [
                              Text(
                                '${enabledModVariants.length} mods',
                              ),
                              // bullet
                              Text("  •  ", style: theme.textTheme.labelSmall),
                              MovingTooltipWidget.text(
                                message:
                                    'Created: ${Constants.dateTimeFormat.format(dateCreated?.toLocal() ?? DateTime.now())}'
                                    '\nLast modified: ${Constants.dateTimeFormat.format(profile?.dateModified?.toLocal() ?? DateTime.now())}',
                                child: Text(
                                  Constants.dateTimeFormat.format(
                                      dateCreated?.toLocal() ?? DateTime.now()),
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
                                    "assets/images/icon-clone.svg"),
                                onPressed: () {
                                  ref
                                      .read(modProfilesProvider.notifier)
                                      .cloneModProfile(profile!);
                                }),
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
                        if (!isSaveGame)
                          Disable(
                            isEnabled: widget.modProfiles!.length > 1 &&
                                activeProfileId != profile?.id,
                            child: MovingTooltipWidget.text(
                              message: 'Delete profile',
                              child: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                            title:
                                                const Text('Delete profile?'),
                                            content: Text(
                                                "Are you sure you want to delete profile '${profile?.name}'?"),
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
                                                      .read(modProfilesProvider
                                                          .notifier)
                                                      .removeModProfile(
                                                          profile!.id);
                                                },
                                                child: const Text('Delete'),
                                              ),
                                            ],
                                          ));
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
                                  "assets/images/icon-folder-open.svg"),
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
                                              .read(
                                                  modProfilesProvider.notifier)
                                              .showActivateDialog(
                                                  profile!, context);
                                        },
                                  child: Text(
                                      isActiveProfile ? 'Enabled' : 'Enable')),
                            ),
                          ),
                        if (isSaveGame)
                          OutlinedButton(
                              onPressed: () {
                                ref
                                    .read(modProfilesProvider.notifier)
                                    .createModProfile(save!.characterName,
                                        enabledModVariants: enabledModVariants);
                              },
                              child: const Text("Create Profile")),
                      ],
                    ),
                    // expansionAnimationStyle:
                    //     AnimationStyle.noAnimation,
                    controlAffinity: ListTileControlAffinity.leading,
                    backgroundColor: theme.colorScheme.surfaceContainerLow,
                    collapsedShape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(ThemeManager.cornerRadius)),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(ThemeManager.cornerRadius)),
                    dense: true,
                    expansionAnimationStyle: AnimationStyle.noAnimation,
                    onExpansionChanged: (isExpanded) {
                      // This hack is needed to force the expansion tile to rebuild.
                      // Without it, expanding a second tile doesn't remeasure heights and the row stays the wrong height.
                      WidgetsBinding.instance.scheduleFrameCallback((_) {
                        setState(() {
                          // todo this might need to reference the parent widget's actualAxisSpacing
                          axisSpacingForHeightHack = widget.actualAxisSpacing +
                              Random().nextInt(1000) * .000001;
                        });
                      });
                    },
                    childrenPadding: const EdgeInsets.all(8),
                    children: enabledModVariants.map((mod) {
                      return Row(
                        children: [
                          Expanded(
                            child: Text(mod.modName ?? mod.modId,
                                overflow: TextOverflow.fade,
                                maxLines: 1,
                                style: theme.textTheme.labelLarge),
                          ),
                          Text(mod.version?.toString() ?? '???',
                              style: theme.textTheme.labelLarge),
                        ],
                      );
                    }).toList(),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _copyModListToClipboard(List<ShallowModVariant> enabledModVariants) {
    final modList = enabledModVariants
        .map((mod) =>
            '${mod.modName ?? mod.modId} - Version: ${mod.version ?? 'Unknown'}')
        .join('\n');
    Clipboard.setData(ClipboardData(text: modList));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mod list copied to clipboard')),
    );
  }
}
