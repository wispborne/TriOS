import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/models/enabled_mods.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/checkbox_with_label.dart';
import 'package:trios/widgets/conditional_wrap.dart';
import 'package:trios/widgets/disable_if_cannot_write_mods.dart';
import 'package:vs_scrollbar/vs_scrollbar.dart';

import '../mod_manager/mod_context_menu.dart';
import '../mod_manager/smol3.dart';
import '../mod_manager/version_checker.dart';
import '../models/mod.dart';
import '../trios/app_state.dart';
import '../trios/download_manager/download_manager.dart';
import '../utils/search.dart';
import '../widgets/add_new_mods_button.dart';
import 'mod_list_basic_entry.dart';

class ModListMini extends ConsumerStatefulWidget {
  const ModListMini({super.key});

  @override
  ConsumerState createState() => _ModListMiniState();
}

class _ModListMiniState extends ConsumerState<ModListMini>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final searchController = SearchController();
  bool hideDisabled = false;

  @override
  Widget build(BuildContext context) {
    final fullModList = ref.watch(AppState.mods);
    final enabledModIds = ref
        .watch(AppState.enabledModsFile)
        .valueOrNull
        ?.filterOutMissingMods(fullModList)
        .enabledMods;
    final modVariants = ref.watch(AppState.modVariants);
    final query = ref.watch(searchQuery);

    List<Mod> filteredModList = fullModList
        .let((mods) => hideDisabled
            ? mods
                .where((mod) => !hideDisabled || mod.hasEnabledVariant)
                .toList()
            : mods)
        .let((mods) => query.isEmpty ? mods : searchMods(mods, query) ?? []);

    final versionCheck = ref.watch(AppState.versionCheckResults).valueOrNull;
    final isRefreshing = (modVariants.isLoading ||
        ref.watch(AppState.versionCheckResults).isLoading);
    searchController.value = TextEditingValue(text: query);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Mods",
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontSize: 20)),
                            Padding(
                              padding: const EdgeInsets.only(left: 0),
                              child: Text(
                                  "${enabledModIds?.length ?? 0} of ${fullModList.length} enabled",
                                  style:
                                      Theme.of(context).textTheme.labelMedium),
                            ),
                          ],
                        ),
                        Align(
                          alignment: Alignment.topRight,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Tooltip(
                                      message:
                                          "Refresh mods and recheck versions",
                                      child: IconButton(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4),
                                        icon: ConditionalWrap(
                                            condition: isRefreshing,
                                            wrapper: (child) => Animate(
                                                onComplete: (c) => c.repeat(),
                                                effects: [
                                                  RotateEffect(
                                                      duration: 2000.ms)
                                                ],
                                                child: child),
                                            child: const Icon(Icons.refresh)),
                                        onPressed: () {
                                          AppState.skipCacheOnNextVersionCheck =
                                              true;
                                          ref.invalidate(AppState.modVariants);
                                        },
                                        constraints: const BoxConstraints(),
                                      )),
                                  Tooltip(
                                    message: "Copy mod info",
                                    child: IconButton(
                                      icon: const Icon(Icons.copy),
                                      iconSize: 20,
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4),
                                      onPressed: () {
                                        final enabledModsList = enabledModIds
                                            .orEmpty()
                                            .map((id) => filteredModList
                                                .firstWhereOrNull(
                                                    (mod) => mod.id == id))
                                            .whereNotNull()
                                            .toList()
                                            .sortedMods;
                                        Clipboard.setData(ClipboardData(
                                            text:
                                                "Mods (${enabledModsList.length})\n${enabledModsList.map((mod) {
                                          final variant = mod
                                              .findFirstEnabledOrHighestVersion;
                                          return false
                                              ? "${mod.id} ${variant?.modInfo.version}"
                                              : "${variant?.modInfo.name}  v${variant?.modInfo.version}  [${mod.id}]";
                                        }).join('\n')}"));
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                          content: Text(
                                              "Copied mod info to clipboard."),
                                        ));
                                      },
                                    ),
                                  ),
                                  const AddNewModsButton(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 4)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.only(top: 8, bottom: 4, right: 4),
                      child: SizedBox(
                        height: 30,
                        child: ModListBasicSearch(query),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 8, right: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 20,
                            child: CheckboxWithLabel(
                              value: hideDisabled,
                              onChanged: (newValue) {
                                setState(() {
                                  hideDisabled = newValue ?? false;
                                });
                              },
                              checkboxScale: 0.8,
                              textPadding: const EdgeInsets.all(0),
                              labelWidget: Text("Hide Disabled",
                                  style: theme.textTheme.labelMedium),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Expanded(
            child: modVariants.when(
              data: (_) {
                final isUpdatesFieldShown =
                    ref.watch(appSettings.select((s) => s.isUpdatesFieldShown));
                var modsWithUpdates = <Mod?>[null] +
                    filteredModList
                        .map((e) => e as Mod?)
                        .filter((mod) {
                          final variant = mod?.findHighestVersion;
                          if (variant?.versionCheckerInfo == null) return false;

                          final localVersionCheck = variant!.versionCheckerInfo;
                          final remoteVersionCheck =
                              versionCheck?[variant.smolId];
                          return compareLocalAndRemoteVersions(
                                      localVersionCheck, remoteVersionCheck) ==
                                  -1 &&
                              remoteVersionCheck?.error == null;
                        })
                        .toList()
                        .sortedMods;
                final updatesToDisplay =
                    (isUpdatesFieldShown ? modsWithUpdates : <Mod?>[null]);
                final listItems = updatesToDisplay +
                    (modsWithUpdates.isEmpty ? [] : [null]) +
                    (filteredModList.sortedMods.toList());

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                                if (index == 0 &&
                                    modsWithUpdates.whereNotNull().isNotEmpty) {
                                  return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Divider(),
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(right: 8),
                                          child: Row(
                                            children: [
                                              Text(
                                                  "UPDATES (${modsWithUpdates.whereNotNull().length}${isUpdatesFieldShown ? "" : " hidden"})",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelMedium),
                                              IconButton(
                                                onPressed: () => ref
                                                    .read(appSettings.notifier)
                                                    .update((s) => s.copyWith(
                                                        isUpdatesFieldShown: !s
                                                            .isUpdatesFieldShown)),
                                                constraints:
                                                    const BoxConstraints(),
                                                icon: Icon(
                                                    isUpdatesFieldShown
                                                        ? Icons.visibility
                                                        : Icons.visibility_off,
                                                    size: 15,
                                                    color: theme
                                                        .colorScheme.onSurface),
                                              ),
                                              const Spacer(),
                                              Tooltip(
                                                  message:
                                                      "Download all ${modsWithUpdates.whereNotNull().length} updates",
                                                  child: SizedBox(
                                                    child: TextButton.icon(
                                                        label: const Text(
                                                            "Update All"),
                                                        onPressed: () {
                                                          _onClickedDownloadModUpdatesDialog(
                                                              modsWithUpdates,
                                                              versionCheck,
                                                              context);
                                                        },
                                                        icon: Icon(Icons.update,
                                                            size: 24,
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .primary)),
                                                  )),
                                            ],
                                          ),
                                        ),
                                      ]);
                                }
                                final mod = listItems[index];

                                // Hide the second "ALL MODS" title if there are no updates.
                                // Definitely a hack. Proper fix would be to change `listItems`
                                // to a container/viewmodel instead of mods.
                                if (updatesToDisplay.whereNotNull().isEmpty &&
                                    mod == null &&
                                    index == 1) {
                                  return Container();
                                }

                                if (mod == null) {
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
                                      buildModContextMenu(mod, ref, context),
                                  child: ModListBasicEntry(
                                      mod: mod,
                                      isEnabled:
                                          enabledModIds?.contains(mod.id) ??
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

  SearchAnchor ModListBasicSearch(String query) {
    return SearchAnchor(
      searchController: searchController,
      builder: (BuildContext context, SearchController controller) {
        return SearchBar(
            controller: controller,
            leading: const Icon(Icons.search),
            hintText: "Filter...",
            trailing: [
              query.isEmpty
                  ? Container()
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        controller.clear();
                        ref.read(searchQuery.notifier).state = "";
                      },
                    )
            ],
            backgroundColor: WidgetStateProperty.all(
                Theme.of(context).colorScheme.surfaceContainer),
            onChanged: (value) {
              ref.read(searchQuery.notifier).state = value;
            });
      },
      suggestionsBuilder: (BuildContext context, SearchController controller) {
        return [];
      },
    );
  }

  void _onClickedDownloadModUpdatesDialog(List<Mod?> modsWithUpdates,
      Map<String, VersionCheckResult>? versionCheck, BuildContext context) {
    downloadUpdates() {
      for (var mod in modsWithUpdates) {
        if (mod == null) continue;
        final variant = mod.findHighestVersion!;
        final remoteVersionCheck = versionCheck?[variant.smolId];
        if (remoteVersionCheck?.remoteVersion != null) {
          ref.read(downloadManager.notifier).downloadUpdateViaBrowser(
                remoteVersionCheck!.remoteVersion!,
                context,
                activateVariantOnComplete: false,
                modInfo: variant.modInfo,
              );
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
                  "Download updates for ${modsWithUpdates.whereType<Mod>().length} mods?"),
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
}
