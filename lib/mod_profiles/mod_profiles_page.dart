import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:trios/mod_manager/audit_page.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/widgets/disable.dart';
import 'package:trios/widgets/svg_image_icon.dart';

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

  final TextEditingController _nameController = TextEditingController();
  String? _editingProfileId;
  final actualAxisSpacing = 8;
  double axisSpacingForHeightHack = 8;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final modProfilesAsync = ref.watch(modProfilesProvider);
    final activeProfileId =
        ref.watch(appSettings.select((s) => s.activeModProfileId));
    final theme = Theme.of(context);
    const minHeight = 120.0;
    const cardPadding = 8.0;
    final dateTimeFormat = Constants.dateTimeFormat;

    return Tooltip(
      message: kDebugMode ? "" : "Work in progress",
      child: Disable(
        isEnabled: kDebugMode,
        child: Row(
          children: [
            Expanded(
              child: modProfilesAsync.when(
                data: (modProfiles) {
                  return AlignedGridView.count(
                    crossAxisSpacing: axisSpacingForHeightHack,
                    mainAxisSpacing: 10,
                    crossAxisCount: 2,
                    itemCount: modProfiles.modProfiles.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return ConstrainedBox(
                            constraints:
                                const BoxConstraints(minHeight: minHeight),
                            child:
                                IntrinsicHeight(child: _buildNewProfileCard()));
                      } else {
                        final profile = modProfiles.modProfiles[index - 1];
                        final isEditing = profile.id == _editingProfileId;
                        final isActiveProfile = profile.id == activeProfileId;

                        return ConstrainedBox(
                          constraints:
                              const BoxConstraints(minHeight: minHeight),
                          child: Card(
                            margin: const EdgeInsets.all(0),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: isActiveProfile
                                        ? theme.colorScheme.primary
                                        : Colors.transparent,
                                    width: 2),
                                borderRadius: BorderRadius.circular(
                                    ThemeManager.cornerRadius),
                              ),
                              child: Stack(
                                children: [
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: isEditing
                                        ? IconButton(
                                            icon: const Icon(Icons.check),
                                            onPressed: () {
                                              ref
                                                  .read(modProfilesProvider
                                                      .notifier)
                                                  .updateModProfile(
                                                    profile.copyWith(
                                                        name: _nameController
                                                            .text),
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
                                                _editingProfileId = profile.id;
                                                _nameController.text =
                                                    profile.name;
                                              });
                                            },
                                          ),
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                          padding: const EdgeInsets.only(
                                              left: 0,
                                              top: cardPadding,
                                              right: cardPadding + 24,
                                              bottom: cardPadding),
                                          child: Row(
                                            children: [
                                              // Blur(
                                              //   blur: isActiveProfile ? 5 : 0,
                                              //   child: IconButton(
                                              //       onPressed: () {
                                              //         _showActivateDialog(
                                              //             profile);
                                              //       },
                                              //       icon: Icon(
                                              //           Icons
                                              //               .power_settings_new,
                                              //           color: profile.id ==
                                              //                   activeProfileId
                                              //               ? theme.colorScheme
                                              //                   .primary
                                              //               : null)),
                                              // ),
                                              const SizedBox(
                                                width: 8,
                                              ),
                                              Expanded(
                                                child:
                                                    Builder(builder: (context) {
                                                  return isEditing
                                                      ? TextField(
                                                          controller:
                                                              _nameController,
                                                          decoration:
                                                              const InputDecoration(
                                                                  labelText:
                                                                      'Name'),
                                                        )
                                                      : Tooltip(
                                                          message: profile.name,
                                                          child: Text(
                                                              profile.name,
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style: theme
                                                                  .textTheme
                                                                  .bodyLarge
                                                                  ?.copyWith(
                                                                fontSize: 18,
                                                              )),
                                                        );
                                                }),
                                              ),
                                            ],
                                          )),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: cardPadding),
                                        child: Row(
                                          children: [
                                            Text(
                                              '${profile.enabledModVariants.length} mods',
                                              style: theme.textTheme.labelSmall,
                                            ),
                                            // bullet
                                            Text(" • ",
                                                style:
                                                    theme.textTheme.labelSmall),
                                            Tooltip(
                                              message:
                                                  'Created: ${dateTimeFormat.format(profile.dateCreated?.toLocal() ?? DateTime.now())}\n'
                                                  'Last modified: ${dateTimeFormat.format(profile.dateModified?.toLocal() ?? DateTime.now())}',
                                              child: Text(
                                                dateTimeFormat.format(profile
                                                        .dateCreated
                                                        ?.toLocal() ??
                                                    DateTime.now()),
                                                style:
                                                    theme.textTheme.labelSmall,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      TriOSExpansionTile(
                                        tilePadding: const EdgeInsets.symmetric(
                                            horizontal: cardPadding),
                                        title: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Spacer(),
                                            IconButton(
                                                icon: const SvgImageIcon(
                                                    "assets/images/icon-clone.svg"),
                                                tooltip: 'Duplicate profile',
                                                onPressed: () {
                                                  ref
                                                      .read(modProfilesProvider
                                                          .notifier)
                                                      .createModProfile(
                                                          '${profile.name} (Copy) ${DateTime.now().microsecondsSinceEpoch}',
                                                          enabledModVariants:
                                                              profile
                                                                  .enabledModVariants);
                                                }),
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.content_copy),
                                              tooltip:
                                                  'Copy mod list to clipboard',
                                              onPressed: () {
                                                _copyModListToClipboard(
                                                    profile);
                                              },
                                            ),
                                            Disable(
                                              isEnabled: modProfiles
                                                          .modProfiles.length >
                                                      1 &&
                                                  activeProfileId != profile.id,
                                              child: IconButton(
                                                icon: const Icon(Icons.delete),
                                                tooltip: 'Delete profile',
                                                onPressed: () {
                                                  showDialog(
                                                      context: context,
                                                      builder: (context) =>
                                                          AlertDialog(
                                                            title: const Text(
                                                                'Delete profile?'),
                                                            content: Text(
                                                                "Are you sure you want to delete profile '${profile.name}'?"),
                                                            actions: [
                                                              TextButton(
                                                                onPressed: () {
                                                                  Navigator.of(
                                                                          context)
                                                                      .pop();
                                                                },
                                                                child: const Text(
                                                                    'Cancel'),
                                                              ),
                                                              TextButton(
                                                                onPressed: () {
                                                                  Navigator.of(
                                                                          context)
                                                                      .pop();
                                                                  ref
                                                                      .read(modProfilesProvider
                                                                          .notifier)
                                                                      .removeModProfile(
                                                                          profile
                                                                              .id);
                                                                },
                                                                child: const Text(
                                                                    'Delete'),
                                                              ),
                                                            ],
                                                          ));
                                                },
                                              ),
                                            ),
                                            if (kDebugMode)
                                              Tooltip(
                                                  message: 'Id: ${profile.id}',
                                                  child: const Icon(
                                                      Icons.bug_report)),
                                            const SizedBox(width: 8),
                                            OutlinedButton(
                                                onPressed: isActiveProfile
                                                    ? null
                                                    : () {
                                                        ref
                                                            .read(
                                                                modProfilesProvider
                                                                    .notifier)
                                                            .showActivateDialog(
                                                                profile,
                                                                context);
                                                      },
                                                child: Text(isActiveProfile
                                                    ? 'Enabled'
                                                    : 'Enable')),
                                          ],
                                        ),
                                        // expansionAnimationStyle:
                                        //     AnimationStyle.noAnimation,
                                        controlAffinity:
                                            ListTileControlAffinity.leading,
                                        backgroundColor: theme
                                            .colorScheme.surfaceContainerLow,
                                        collapsedShape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                                ThemeManager.cornerRadius)),
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                                ThemeManager.cornerRadius)),
                                        dense: true,
                                        expansionAnimationStyle:
                                            AnimationStyle.noAnimation,
                                        onExpansionChanged: (isExpanded) {
                                          // This hack is needed to force the expansion tile to rebuild.
                                          // Without it, expanding a second tile doesn't remeasure heights and the row stays the wrong height.
                                          WidgetsBinding.instance
                                              .scheduleFrameCallback((_) {
                                            setState(() {
                                              axisSpacingForHeightHack =
                                                  actualAxisSpacing +
                                                      Random().nextInt(1000) *
                                                          .000001;
                                            });
                                          });
                                        },
                                        childrenPadding:
                                            const EdgeInsets.all(8),
                                        children: profile.enabledModVariants
                                            .map((mod) {
                                          return Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                    mod.modName ?? mod.modId,
                                                    overflow: TextOverflow.fade,
                                                    maxLines: 1,
                                                    style: theme
                                                        .textTheme.labelLarge),
                                              ),
                                              Text(
                                                  mod.version?.toString() ??
                                                      'Unknown',
                                                  style: theme
                                                      .textTheme.labelLarge),
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
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) =>
                    Center(child: Text('Error: $error')),
              ),
            ),
            SizedBox(
                width: 400,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Container(
                      // round edges
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(ThemeManager.cornerRadius),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: AuditPage()),
                )),
          ],
        ),
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
            ElevatedButton(
              onPressed: () {
                if (newProfileNameController.text.isNotEmpty) {
                  ref
                      .read(modProfilesProvider.notifier)
                      .createModProfile(newProfileNameController.text);
                  newProfileNameController.clear();
                }
              },
              child: const Text('Create Profile'),
            ),
          ],
        ),
      ),
    );
  }

  void _copyModListToClipboard(ModProfile profile) {
    final modList = profile.enabledModVariants
        .map((mod) =>
            '${mod.modName ?? mod.modId} - Version: ${mod.version ?? 'Unknown'}')
        .join('\n');
    Clipboard.setData(ClipboardData(text: modList));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mod list copied to clipboard')),
    );
  }
}
