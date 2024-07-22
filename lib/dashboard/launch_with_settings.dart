import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/jre_manager/jre_entry.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';

import '../jre_manager/jre_manager_logic.dart';
import '../launcher/launcher.dart';
import '../models/launch_settings.dart';
import '../themes/theme_manager.dart';
import '../trios/app_state.dart';
import '../trios/settings/settings.dart';
import '../widgets/checkbox_with_label.dart';

class LaunchWithSettings extends ConsumerStatefulWidget {
  const LaunchWithSettings({super.key});

  @override
  ConsumerState createState() => _LaunchWithSettingsState();
}

class _LaunchWithSettingsState extends ConsumerState<LaunchWithSettings> {
  StarsectorVanillaLaunchPreferences? starsectorLaunchPrefs;

  @override
  void initState() {
    try {
      starsectorLaunchPrefs = Launcher.getStarsectorLaunchPrefs();
    } catch (e) {
      Fimber.e("Failed to get default Starsector launch prefs", ex: e);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final resControllerWidth = TextEditingController(
        text: ref
                .watch(appSettings.select((value) => value.launchSettings))
                .resolutionWidth
                ?.toString() ??
            starsectorLaunchPrefs?.resolution.split("x")[1]);
    final resControllerHeight = TextEditingController(
        text: ref
                .watch(appSettings.select((value) => value.launchSettings))
                .resolutionHeight
                ?.toString() ??
            starsectorLaunchPrefs?.resolution.split("x")[0]);

    final gameDir = ref.read(appSettings.select((value) => value.gameDir));
    final isUsingJre23 =
        ref.watch(appSettings.select((value) => value.useJre23));
    // var currentScreenScaling = ref.watch(appSettings.select((value) => value.launchSettings)).screenScaling ??
    //     starsectorLaunchPrefs?.screenScaling ??
    //     1;

    final enableDirectLaunch =
        ref.watch(appSettings.select((s) => s.enableDirectLaunch));
    return Stack(
      children: [
        if (isUsingJre23 != true)
          Positioned(
            right: 0,
            child: Padding(
              padding: const EdgeInsets.only(left: 16, top: 12),
              child: CheckboxWithLabel(
                  label: "Skip Game Launcher",
                  textPadding: const EdgeInsets.only(left: 12, bottom: 0),
                  labelStyle: Theme.of(context).textTheme.labelMedium,
                  flipCheckboxAndLabel: true,
                  value: enableDirectLaunch,
                  onChanged: (bool? value) {
                    if (value == null) return;
                    ref
                        .read(appSettings.notifier)
                        .update((s) => s.copyWith(enableDirectLaunch: value));
                  }),
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(ThemeManager.cornerRadius),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.secondary,
                            strokeAlign: BorderSide.strokeAlignOutside,
                            width: 2,
                          ),
                        ),
                        child: ElevatedButton(
                          onPressed: () => Launcher.launchGame(ref, context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.secondary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  ThemeManager.cornerRadius),
                            ),
                          ),
                          child: Text('LAUNCH',
                              style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontFamily: "Orbitron",
                                  fontSize: 27,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSecondary)),
                        ),
                      ),
                      Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                              ref
                                      .watch(AppState.starsectorVersion)
                                      .valueOrNull ??
                                  "Starsector version unknown",
                              style: Theme.of(context).textTheme.labelMedium)),
                      FutureBuilder<List<JreEntry>>(
                          future: findJREs(gameDir?.path),
                          builder: (BuildContext context,
                              AsyncSnapshot<List<JreEntry>> jres) {
                            var activeJre = jres.data
                                .orEmpty()
                                .firstWhereOrNull((jre) =>
                                    jre.isActive(ref, jres.data ?? []));
                            return Text(
                                activeJre != null
                                    ? "Java ${activeJre.versionString}"
                                    : "Java version unknown",
                                style: Theme.of(context).textTheme.labelMedium);
                          }),
                      Text(
                          ref
                                  .watch(appSettings.select((s) => s.modsDir))
                                  ?.path ??
                              "No mods folder!",
                          style: Theme.of(context).textTheme.labelMedium),
                    ],
                  ),
                ),
                if (isUsingJre23 == true)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: CheckboxWithLabel(
                      label: "Show JRE 23 Console Window",
                      value: ref.watch(appSettings.select(
                              (value) => value.showJre23ConsoleWindow)) ??
                          false,
                      onChanged: (bool? value) {
                        ref.read(appSettings.notifier).update((state) => state
                            .copyWith(showJre23ConsoleWindow: value ?? false));
                      },
                    ),
                  ),
                if (isUsingJre23 != true && enableDirectLaunch == true)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: (starsectorLaunchPrefs == null
                          ? []
                          : [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CheckboxWithLabel(
                                    label: "Fullscreen",
                                    value: ref
                                            .watch(appSettings.select((value) =>
                                                value.launchSettings))
                                            .isFullscreen ??
                                        starsectorLaunchPrefs!.isFullscreen,
                                    onChanged: (bool? value) {
                                      ref.read(appSettings.notifier).update(
                                          (state) => state.copyWith(
                                              launchSettings:
                                                  state.launchSettings.copyWith(
                                                      isFullscreen: value)));
                                    },
                                  ),
                                  CheckboxWithLabel(
                                    label: "Sound",
                                    value: ref
                                            .watch(appSettings.select((value) =>
                                                value.launchSettings))
                                            .hasSound ??
                                        starsectorLaunchPrefs!.hasSound,
                                    onChanged: (bool? value) {
                                      ref.read(appSettings.notifier).update(
                                          (state) => state.copyWith(
                                              launchSettings: state
                                                  .launchSettings
                                                  .copyWith(hasSound: value)));
                                    },
                                  ),
                                ],
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 50,
                                    height: 50,
                                    child: TextField(
                                      controller: resControllerHeight,
                                      inputFormatters: <TextInputFormatter>[
                                        FilteringTextInputFormatter.digitsOnly
                                      ],
                                      decoration: const InputDecoration(
                                        // errorText: gamePathExists ? null : "Path does not exist",
                                        labelText: 'Width',
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: Text(" x ",
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall),
                                  ),
                                  SizedBox(
                                    width: 50,
                                    height: 50,
                                    child: TextField(
                                      controller: resControllerWidth,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: <TextInputFormatter>[
                                        FilteringTextInputFormatter.digitsOnly
                                      ],
                                      decoration: const InputDecoration(
                                        // errorText: gamePathExists ? null : "Path does not exist",
                                        labelText: 'Height',
                                      ),
                                    ),
                                  )
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 32),
                                child: Tooltip(
                                  message:
                                      "Use your non-TriOS launcher settings instead",
                                  child: OutlinedButton(
                                      onPressed: () {
                                        ref.read(appSettings.notifier).update(
                                            (s) => s.copyWith(
                                                launchSettings:
                                                    const LaunchSettings()));
                                        setState(
                                            () {}); // Force refresh widget to update text fields to default.
                                      },
                                      child: Text(
                                        "Clear Custom Launch Settings",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      )),
                                ),
                              )
                            ]),
                    ),
                  ),
                if (isUsingJre23 != true)
                  Opacity(
                      opacity: 0.8,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Text(
                            "Note: These settings are separate from the normal launcher's settings.",
                            style: Theme.of(context).textTheme.labelMedium),
                      )),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
