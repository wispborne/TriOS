import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_color/flutter_color.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toastification/toastification.dart';
import 'package:trios/chipper/utils.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/mod_profiles/save_reader.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/thirdparty/dartx/iterable.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/disable.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/svg_image_icon.dart';

import '../models/mod_variant.dart';
import '../widgets/trios_expansion_tile.dart';
import 'mod_profiles_manager.dart';
import 'models/mod_profile.dart';

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
  Map<String, ModChange> _changesByModId = {};

  @override
  void initState() {
    super.initState();
    // Compute once after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _recomputeChanges();
    });
  }

  void _recomputeChanges() {
    try {
      final profile = widget.profile;
      final save = widget.save;
      final allMods = ref.read(AppState.mods);
      final modVariants = ref.read(AppState.modVariants).valueOrNull ?? [];

      final computed = ModProfileManagerNotifier.computeModProfileChanges(
        profile ??
            ModProfile.newProfile(
              "",
              save?.mods.map((m) => m.toShallowModVariant()).toList() ?? [],
            ),
        allMods,
        modVariants,
        modVariants, // For the sake of checking whether we have mods or not, treat all mods as enabled.
      ).associateBy((m) => m.modId);

      if (mounted) {
        setState(() {
          _changesByModId = computed;
        });
      }
    } catch (_) {
      // In case of any transient read errors, fall back to empty
      if (mounted) {
        setState(() {
          _changesByModId = {};
        });
      }
    }
  }

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

    // Recompute whenever the installed mods list changes
    ref.listen<List<Mod>>(AppState.mods, (_, __) {
      _recomputeChanges();
    });

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
      ref.watch(AppState.gameCoreFolder).valueOrNull,
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
                        // MovingTooltipWidget.text(
                        //   message: 'Copy mod list to clipboard',
                        //   child: IconButton(
                        //     icon: const Icon(Icons.content_copy),
                        //     onPressed: () {
                        //       _copyModListToClipboard(enabledModVariants);
                        //     },
                        //   ),
                        // ),
                        MovingTooltipWidget.text(
                          message: 'Copy mod profile to clipboard',
                          child: IconButton(
                            icon: const Icon(Icons.content_copy),
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
                      final change = _changesByModId[mod.modId];
                      final textColor = switch (change?.changeType) {
                        ModChangeType.missingMod => theme.colorScheme.error,
                        ModChangeType.missingVariant =>
                          theme.colorScheme.error.mix(warningColor, 0.5),
                        _ => null,
                      };

                      return MovingTooltipWidget.text(
                        message: switch (change?.changeType) {
                          ModChangeType.missingMod => "Mod not found",
                          ModChangeType.missingVariant =>
                            "Version ${mod.version} not found for ${mod.nameOrId}. You have ${change?.fromVariant?.modInfo.version} installed.",
                          _ => null,
                        },
                        child: Row(
                          children: [
                            if (change?.changeType ==
                                    ModChangeType.missingMod ||
                                change?.changeType ==
                                    ModChangeType.missingVariant)
                              Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: MovingTooltipWidget.text(
                                  message: 'Search Catalog',
                                  child: IconButton.outlined(
                                    icon: Icon(Icons.search),
                                    iconSize: 16,
                                    color: theme.colorScheme.primary,
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(2),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color: theme.colorScheme.primary
                                            .withAlpha(128),
                                      ),
                                    ),
                                    onPressed: () {
                                      showAlertDialog(
                                        context,
                                        title: "WIP",
                                        content: "Unimplemented",
                                      );
                                    },
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
                        ),
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
}
