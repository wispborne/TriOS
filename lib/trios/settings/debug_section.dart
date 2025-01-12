import 'dart:async';
import 'dart:io';

import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toastification/toastification.dart';
import 'package:trios/libarchive/libarchive.dart';
import 'package:trios/mod_profiles/mod_profiles_manager.dart';
import 'package:trios/models/download_progress.dart';
import 'package:trios/onboarding/onboarding_page.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/utils/network_util.dart';
import 'package:trios/weaponViewer/weaponsManager.dart';
import 'package:trios/widgets/checkbox_with_label.dart';
import 'package:trios/widgets/download_progress_indicator.dart';
import 'package:trios/widgets/moving_tooltip.dart';

import '../../utils/util.dart';
import '../../widgets/self_update_toast.dart';
import '../app_state.dart';
import '../download_manager/download_manager.dart';
import '../self_updater/script_generator.dart';
import '../toasts/mod_added_toast.dart';

class SettingsDebugSection extends ConsumerStatefulWidget {
  const SettingsDebugSection({super.key});

  @override
  ConsumerState<SettingsDebugSection> createState() =>
      _SettingsDebugSectionState();
}

class _SettingsDebugSectionState extends ConsumerState<SettingsDebugSection> {
  List<Release>? _releases;
  Release? _selectedRelease;
  bool _includePrereleases = false;

  @override
  void initState() {
    super.initState();
    _fetchReleases();
  }

  void _fetchReleases() {
    NetworkUtils.getAllReleases(
      Uri.parse(Constants.githubLatestRelease),
      includePrereleases: _includePrereleases,
      limit: 50,
    ).then((value) => setState(() => _releases = value));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Row(
            children: [
              DropdownMenu<Release?>(
                dropdownMenuEntries: _releases?.map((release) {
                      return DropdownMenuEntry(
                        value: release,
                        label: release.tagName,
                      );
                    }).toList() ??
                    [],
                onSelected: (value) {
                  setState(() {
                    _selectedRelease = value;
                  });
                },
              ),
              MovingTooltipWidget.text(
                message: "CAUTION: May mess up TriOS's settings (not mods)."
                    "\nGoing back in time is not tested. Recommend backing up your settings first (click Log File button to open folder).",
                warningLevel: TooltipWarningLevel.error,
                child: ElevatedButton.icon(
                    icon: _selectedRelease != null
                        ? const Icon(Icons.settings_backup_restore, size: 20)
                        : null,
                    onPressed: () {
                      if (_selectedRelease != null) {
                        ref
                            .watch(AppState.selfUpdate.notifier)
                            .updateSelf(_selectedRelease!);
                      }
                    },
                    label: Text(_selectedRelease == null
                        ? "<- Select a release"
                        : 'Update to ${_selectedRelease?.tagName}')),
              ),
              CheckboxWithLabel(
                value: _includePrereleases,
                label: "Include pre-releases",
                onChanged: (value) {
                  setState(() {
                    _includePrereleases = value ?? false;
                    _fetchReleases();
                  });
                },
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.security_update_good),
            onPressed: () async {
              ref
                  .watch(AppState.selfUpdate.notifier)
                  .getLatestRelease()
                  .then((release) {
                if (release == null) {
                  Fimber.d("No release found");
                  return;
                }

                toastification.showCustom(
                  context: context,
                  builder: (context, item) => SelfUpdateToast(release, item),
                );
              });
            },
            label: const Text('Check for update (allow older versions)'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.folder_special),
            onPressed: () {
              final folder = Constants.configDataFolderPath;
              folder.openInExplorer();
            },
            label: const Text('Open ${Constants.appName} Settings Folder'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.restart_alt),
            onPressed: () async {
              showDialog(
                context: context,
                builder: (context) => const OnboardingCarousel(),
                barrierDismissible: false,
              );
            },
            label: const Text('Show Initial Setup Dialog'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.play_arrow),
            onPressed: () async {
              // hardcoded name
              runZonedGuarded(() {
                ref.read(AppState.selfUpdate.notifier).runSelfUpdateScript(File(
                    "${Platform.resolvedExecutable.toFile().parent.path}/update-trios/${ScriptGenerator.scriptName()}"));
              }, (error, stackTrace) {
                showSnackBar(
                  context: context,
                  content: Text(
                    "Error running self-update script: $error",
                  ),
                );
              });
            },
            label: const Text('Run existing self-update script if exists'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.cloud_download_rounded),
            onPressed: () {
              final testMod = ref
                  .read(AppState.modVariants)
                  .valueOrNull
                  .orEmpty()
                  .firstWhere((variant) =>
                      variant.modInfo.id.equalsIgnoreCase("magiclib"));
              ref.read(downloadManager.notifier).addDownload(
                    "${testMod.modInfo.nameOrId} ${testMod.bestVersion}",
                    testMod.versionCheckerInfo!.directDownloadURL!,
                    Directory.systemTemp,
                    modInfo: testMod.modInfo,
                  );
            },
            label: const Text('Redownload MagicLib (shows toast)'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.notification_add),
            onPressed: () {
              final testMod = ref
                  .read(AppState.modVariants)
                  .valueOrNull
                  .orEmpty()
                  .firstWhere((variant) =>
                      variant.modInfo.id.equalsIgnoreCase("magiclib"));
              toastification.showCustom(
                context: context,
                builder: (context, item) => ModAddedToast(testMod, item),
              );
            },
            label: const Text('Show Mod Added Toast for MagicLib'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.clean_hands),
            onPressed: () {
              // confirmation prompt
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text("Are you sure?"),
                    content: const Text("This will wipe TriOS's settings."),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          ref
                              .read(AppState.modAudit.notifier)
                              .updateState((_) => []);
                          ref
                              .read(appSettings.notifier)
                              .update((_) => Settings());
                        },
                        child: const Text('Wipe Settings'),
                      ),
                    ],
                  );
                },
              );
            },
            label: const Text('Wipe Settings'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.nearby_error),
            onPressed: () {
              throw Exception("This is a test error");
            },
            label: const Text('Throw error'),
          ),
        ),
        SizedBox(
          width: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.system_security_update_warning),
                  onPressed: () async {
                    final latestRelease = await ref
                        .watch(AppState.selfUpdate.notifier)
                        .getLatestRelease();
                    ref
                        .read(AppState.selfUpdate.notifier)
                        .updateSelf(latestRelease!);
                  },
                  label: const Text("Force Update"),
                ),
              ),
              const SizedBox(height: 4),
              TriOSDownloadProgressIndicator(
                value: ref.watch(AppState.selfUpdate).valueOrNull ??
                    const TriOSDownloadProgress(0, 1, isIndeterminate: false),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.developer_mode),
            onPressed: () {
              getStarsectorVersionFromObf(
                      ref.watch(appSettings.select((s) => s.gameCoreDir))!)
                  .then((value) {
                showSnackBar(
                  context: ref.read(AppState.appContext)!,
                  content: Text("Game version: $value"),
                );
              });
            },
            label: const Text('Read game version from starfarer_obf.jar.'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.diversity_1),
            onPressed: () {
              showSnackBar(
                context: ref.read(AppState.appContext)!,
                content: Text(ref
                        .refresh(weaponListNotifierProvider)
                        .valueOrNull
                        ?.toString() ??
                    "weh"),
              );
            },
            label: const Text('Read weapons'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Builder(builder: (context) {
            final path = "F:/Downloads/starsector_install-0.97a-RC11.exe";
            return MovingTooltipWidget.text(
              message: "Tries to read from '$path'",
              child: ElevatedButton.icon(
                icon: const Icon(Icons.folder_zip),
                onPressed: () async {
                  final entries =
                      LibArchive().listEntriesInArchive(path.toFile());
                  Fimber.i("Entries: ${entries.join('\n')}");
                },
                label: const Text('Read Starsector installer'),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: SelectionArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text(
                      "Note: the below information is not collected by TriOS.\nThis is here in case TriOS is misbehaving, to hopefully see if anything looks wrong.",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                      "Current directory (env variable): ${Directory.current.path}"),
                  const SizedBox(height: 8),
                  Text(
                      "Current directory based on executable: ${Platform.resolvedExecutable.toFile().parent}"),
                  const SizedBox(height: 8),
                  Text("Current executable: ${Platform.resolvedExecutable}"),
                  const SizedBox(height: 8),
                  Text("Temp folder: ${Directory.systemTemp.path}"),
                  const SizedBox(height: 8),
                  Text("Locale: ${Platform.localeName}"),
                  const SizedBox(height: 8),
                  Text(
                      "RAM usage: ${ProcessInfo.currentRss.bytesAsReadableMB()}"),
                  const SizedBox(height: 8),
                  Text(
                      "Max RAM usage: ${ProcessInfo.maxRss.bytesAsReadableMB()}"),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.settings),
                    label: const Text("Show Current App Settings"),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text("Settings"),
                            content: SingleChildScrollView(
                              child: SelectableText(ref
                                  .watch(appSettings)
                                  .toMap()
                                  .prettyPrintToml()),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.view_carousel),
                    label: const Text("Show Loaded Mod Profiles"),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text("Mod Profiles"),
                            content: SingleChildScrollView(
                              child: SelectableText(ref
                                      .watch(modProfilesProvider)
                                      .valueOrNull
                                      ?.toMap()
                                      .prettyPrintToml() ??
                                  ""),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.landscape),
                    label: const Text("Show Environment Variables"),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text("Environment Variables"),
                            content: SingleChildScrollView(
                              child: SelectableText(
                                  Platform.environment.prettyPrintToml() ?? ""),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.heart_broken),
                    label: const Text("Show Mod Compatibility"),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text("Mod Compatibility"),
                            content: SingleChildScrollView(
                              child: ModCompatibilityFilterWidget(),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text("Show Loaded Version Checker Cache"),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text("Version Checker Cache"),
                            content: SingleChildScrollView(
                              child: SelectableText(ref
                                      .watch(AppState.versionCheckResults)
                                      .valueOrNull
                                      ?.toMap()
                                      .prettyPrintJson() ??
                                  ""),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class DebugSettingsGroup extends StatelessWidget {
  final Widget child;

  const DebugSettingsGroup({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(ThemeManager.cornerRadius),
      child: Container(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        padding: const EdgeInsets.all(8),
        child: child,
      ),
    );
  }
}

class ModCompatibilityFilterWidget extends ConsumerStatefulWidget {
  const ModCompatibilityFilterWidget({super.key});

  @override
  ConsumerState<ModCompatibilityFilterWidget> createState() =>
      _ModCompatibilityFilterWidgetState();
}

class _ModCompatibilityFilterWidgetState
    extends ConsumerState<ModCompatibilityFilterWidget> {
  final _searchController = SearchController();

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      final allSmolIds = ref
              .watch(AppState.modVariants)
              .valueOrNull
              ?.map((variant) => variant.smolId)
              .toList() ??
          [];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Mod Compatibility"),
          SearchAnchor(
            searchController: _searchController,
            builder: (BuildContext context, SearchController controller) {
              return SearchBar(
                controller: controller,
                leading: const Icon(Icons.search),
                hintText: "Filter by variant id",
                backgroundColor: WidgetStateProperty.all(
                  Theme.of(context).colorScheme.surfaceContainer,
                ),
                onChanged: (value) {
                  controller.openView();
                },
                onTap: () {
                  controller.openView();
                },
              );
            },
            suggestionsBuilder:
                (BuildContext context, SearchController controller) {
              return allSmolIds
                  .where((id) => id.contains(controller.text))
                  .map((id) => ListTile(
                        title: Text(id),
                        onTap: () {
                          setState(() {
                            controller.closeView(id);
                          });
                        },
                      ))
                  .toList();
            },
          ),
          SelectableText(
            "${_searchController.text.ifBlank("(no search)")}:\n${ref.watch(AppState.modCompatibility)[_searchController.text]?.toString() ?? "(id not found)"}",
          ),
          const SizedBox(height: 24),
          Text("ALL Mods",
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(fontSize: 16, fontWeight: FontWeight.bold)),
          SelectableText(
            ref.watch(AppState.modCompatibility).entries.toList().join('\n'),
          ),
        ],
      );
    });
  }
}
