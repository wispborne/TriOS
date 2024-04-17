import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/conditional_wrap.dart';
import 'package:trios/widgets/disable_if_cannot_write_mods.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vs_scrollbar/vs_scrollbar.dart';

import '../mod_manager/version_checker.dart';
import '../models/mod_variant.dart';
import '../models/version.dart';
import '../trios/app_state.dart';
import '../trios/download_manager/download_manager.dart';
import 'mod_list_basic_entry.dart';

class ModListMini extends ConsumerStatefulWidget {
  const ModListMini({super.key});

  @override
  ConsumerState createState() => _ModListMiniState();
}

class _ModListMiniState extends ConsumerState<ModListMini>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final enabledModIds = ref.watch(AppState.enabledModIds).valueOrNull;
    final modListAsync = ref.watch(AppState.modVariants);
    final modList = modListAsync.valueOrNull
        ?.groupBy((ModVariant a) => a.modInfo.id)
        .values
        .map((variants) => variants.maxByOrNull((variant) =>
            (variant.modInfo.version ?? const Version(raw: "0.0.0"))))
        .whereType<ModVariant>()
        .toList();
    final versionCheck = ref.watch(versionCheckResults).valueOrNull;
    final isRefreshing =
        (modListAsync.isLoading || ref.watch(versionCheckResults).isLoading);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Text("Mods",
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontSize: 20)),
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Tooltip(
                                message: "Refresh mods and recheck versions",
                                child: IconButton(
                                  icon: ConditionalWrap(
                                      condition: isRefreshing,
                                      wrapper: (child) => Animate(
                                          onComplete: (c) => c.repeat(),
                                          effects: [
                                            RotateEffect(duration: 2000.ms)
                                          ],
                                          child: child),
                                      child: const Icon(Icons.refresh)),
                                  padding: const EdgeInsets.only(right: 8.0),
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    ref.invalidate(AppState.modVariants);
                                  },
                                )),
                            Tooltip(
                              message: "Copy mod info",
                              child: IconButton(
                                icon: const Icon(Icons.copy),
                                padding: EdgeInsets.zero,
                                iconSize: 20,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  if (modList == null) return;
                                  Clipboard.setData(ClipboardData(
                                      text:
                                          "Mods (${modList.length})\n${modList.map((e) => false ? "${e.modInfo.id} ${e.modInfo.version}" : "${e.modInfo.name}  v${e.modInfo.version}  [${e.modInfo.id}]").join('\n')}"));
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                    content:
                                        Text("Copied mod info to clipboard."),
                                  ));
                                },
                              ),
                            ),
                            Tooltip(
                              message: "Add new mod",
                              child: DisableIfCannotWriteMods(
                                child: IconButton(
                                    icon: const Icon(Icons.add),
                                    padding: EdgeInsets.only(left: 8),
                                    iconSize: 20,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      FilePicker.platform
                                          .pickFiles(allowMultiple: true)
                                          .then((value) {
                                        if (value == null) return;

                                        final file =
                                            File(value.files.single.path!);
                                        installModFromArchiveWithDefaultUI(
                                            file, ref, context);
                                      });
                                    }),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Expanded(
            child: modListAsync.when(
              data: (_) {
                var modsWithUpdates = modList!
                    .map((e) => e as ModVariant?)
                    .filter((mod) {
                      if (mod?.versionCheckerInfo == null) return false;

                      final localVersionCheck = mod!.versionCheckerInfo;
                      final remoteVersionCheck = versionCheck?[mod.smolId];
                      return compareLocalAndRemoteVersions(
                                  localVersionCheck, remoteVersionCheck) ==
                              -1 &&
                          remoteVersionCheck?.error == null;
                    })
                    .sortedBy((info) => info?.modInfo.name ?? "")
                    .toList();
                final listItems = modsWithUpdates +
                    (modsWithUpdates.isEmpty ? [] : [null]) + // Divider
                    (modList
                        // .filter((mod) => mod.versionCheckerInfo == null)
                        .sortedBy((info) => info.modInfo.name ?? "")
                        .toList());
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        "${enabledModIds?.length ?? 0} of ${modList.length} enabled",
                        style: Theme.of(context).textTheme.labelMedium),
                    Expanded(
                      child: VsScrollbar(
                        controller: _scrollController,
                        isAlwaysShown: true,
                        showTrackOnHover: true,
                        child: DisableIfCannotWriteMods(
                          child: ListView.builder(
                              shrinkWrap: true,
                              controller: _scrollController,
                              itemCount: listItems.length, // UPDATES title
                              itemBuilder: (context, index) {
                                if (index == 0 && modsWithUpdates.isNotEmpty) {
                                  return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Divider(),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 4, right: 8),
                                          child: Row(
                                            children: [
                                              Text("UPDATES",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelMedium),
                                              const Spacer(),
                                              Tooltip(
                                                  message:
                                                      "Download all ${modsWithUpdates.whereType<ModVariant>().length} updates",
                                                  child: IconButton(
                                                      onPressed: () {
                                                        _onClickedDownloadModUpdatesDialog(
                                                            modsWithUpdates,
                                                            versionCheck,
                                                            context);
                                                      },
                                                      icon: Icon(Icons.update,
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .primary))),
                                            ],
                                          ),
                                        ),
                                      ]);
                                }
                                final modVariant = listItems[index];
                                if (modVariant == null) {
                                  return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Divider(),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 4.0),
                                          child: Text("ALL MODS",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelMedium),
                                        ),
                                      ]);
                                }

                                return ContextMenuRegion(
                                  contextMenu:
                                      buildContextMenu(modVariant, ref),
                                  child: ModListBasicEntry(
                                      mod: modVariant,
                                      isEnabled: enabledModIds?.contains(
                                              modVariant.modInfo.id) ??
                                          false),
                                );
                              }),
                        ),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(
                  child: SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator())),
              error: (error, stackTrace) => Text('Error: $error'),
            ),
          ),
        ].animate(interval: 400.ms).fade(duration: 300.ms),
      ),
    );
  }

  void _onClickedDownloadModUpdatesDialog(List<ModVariant?> modsWithUpdates,
      Map<String, VersionCheckResult>? versionCheck, BuildContext context) {
    downloadUpdates() {
      for (var mod in modsWithUpdates) {
        if (mod == null) continue;
        final remoteVersionCheck = versionCheck?[mod.smolId];
        if (remoteVersionCheck?.remoteVersion != null) {
          downloadUpdateViaBrowser(
              remoteVersionCheck!.remoteVersion!, ref, context,
              modInfo: mod.modInfo);
        }
      }
    }

    // Confirm if # updates is more than 5
    if (modsWithUpdates.length <= 5) {
      downloadUpdates();
    } else {
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("Are you sure?"),
              content: Text(
                  "Download updates for ${modsWithUpdates.whereType<ModVariant>().length} mods?"),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text("Cancel")),
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      downloadUpdates();
                    },
                    child: const Text("Download")),
              ],
            );
          });
    }
  }

  ContextMenu buildContextMenu(ModVariant modVariant, WidgetRef ref) {
    final currentStarsectorVersion =
        ref.read(appSettings.select((s) => s.lastStarsectorVersion));
    return ContextMenu(
      entries: <ContextMenuEntry>[
        MenuItem(
            label: 'Open Folder',
            icon: Icons.folder,
            onSelected: () {
              launchUrl(
                  Uri.parse("file:${modVariant.modsFolder.absolute.path}"));
            }),
        if (currentStarsectorVersion != null)
          MenuItem(
              label: 'Force to $currentStarsectorVersion',
              icon: Icons.local_hospital,
              onSelected: () {
                forceChangeModGameVersion(modVariant, currentStarsectorVersion);
                ref.invalidate(AppState.modVariants);
              }),
      ],
      padding: const EdgeInsets.all(8.0),
    );
  }
}
