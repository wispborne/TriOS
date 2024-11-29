import 'dart:async';
import 'dart:io';

import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toastification/toastification.dart';
import 'package:trios/mod_profiles/mod_profiles_manager.dart';
import 'package:trios/models/download_progress.dart';
import 'package:trios/onboarding/onboarding_page.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/weaponViewer/weaponsManager.dart';
import 'package:trios/widgets/download_progress_indicator.dart';

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
  final searchController = SearchController();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: ElevatedButton(
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
            child: const Text('Check for update (allow older versions)'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: ElevatedButton(
            onPressed: () async {
              showDialog(
                context: context,
                builder: (context) => const OnboardingCarousel(),
                barrierDismissible: false,
              );
            },
            child: const Text('Show Initial Setup Dialog'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: ElevatedButton(
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
            child: const Text('Run existing self-update script if exists'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: ElevatedButton(
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
            child: const Text('Redownload MagicLib (shows toast)'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: ElevatedButton(
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
            child: const Text('Show Mod Added Toast for MagicLib'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: ElevatedButton(
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
                              .update((_) => []);
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
            child: const Text('Wipe Settings'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: ElevatedButton(
            onPressed: () {
              throw Exception("This is a test error");
            },
            child: const Text('Throw error'),
          ),
        ),
        SizedBox(
          width: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: ElevatedButton(
                  onPressed: () async {
                    final latestRelease = await ref
                        .watch(AppState.selfUpdate.notifier)
                        .getLatestRelease();
                    ref
                        .read(AppState.selfUpdate.notifier)
                        .updateSelf(latestRelease!);
                  },
                  child: const Text("Force Update"),
                ),
              ),
              const SizedBox(height: 4),
              TriOSDownloadProgressIndicator(
                value: ref.watch(AppState.selfUpdate).valueOrNull ??
                    const TriOSDownloadProgress(0, 0, isIndeterminate: true),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: ElevatedButton(
            onPressed: () {
              getStarsectorVersionFromObf().then((value) {
                showSnackBar(
                  context: context,
                  content: Text("Game version: $value"),
                );
              });
            },
            child: const Text('Read game version from starfarer_obf.jar.'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: ElevatedButton(
            onPressed: () {
              showSnackBar(
                context: context,
                content: Text(ref
                        .refresh(weaponListNotifierProvider)
                        .valueOrNull
                        ?.toString() ??
                    "weh"),
              );
            },
            child: const Text('Read weapons'),
          ),
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
                  DebugSettingsGroup(
                    child: Text(
                        "Settings\n${ref.watch(appSettings).toMap().prettyPrintToml()}"),
                  ),
                  const SizedBox(height: 8),
                  DebugSettingsGroup(
                    child: Text(
                      "Mod Profiles\n${ref.watch(modProfilesProvider).valueOrNull}",
                    ),
                  ),
                  const SizedBox(height: 8),
                  DebugSettingsGroup(
                    child: Text(
                      "Environment variables\n${Platform.environment}",
                    ),
                  ),
                  const SizedBox(height: 8),
                  DebugSettingsGroup(
                    child: Builder(builder: (context) {
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
                            searchController: searchController,
                            builder: (BuildContext context,
                                SearchController controller) {
                              return SearchBar(
                                controller: controller,
                                leading: const Icon(Icons.search),
                                hintText: "Filter by variant id",
                                backgroundColor: WidgetStateProperty.all(
                                  Theme.of(context)
                                      .colorScheme
                                      .surfaceContainer,
                                ),
                                onChanged: (value) {
                                  controller.openView();
                                },
                                onTap: () {
                                  controller.openView();
                                },
                              );
                            },
                            suggestionsBuilder: (BuildContext context,
                                SearchController controller) {
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
                          Text(
                            "${searchController.text}:\n${ref.watch(AppState.modCompatibility)[searchController.text]?.toString() ?? "(id not found)"}",
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "ALL\n${ref.watch(AppState.modCompatibility)}",
                          ),
                        ],
                      );
                    }),
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
