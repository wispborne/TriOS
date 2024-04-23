import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../launcher/launcher.dart';
import '../models/launch_settings.dart';
import '../trios/app_state.dart';
import '../trios/settings/settings.dart';
import '../themes/theme_manager.dart';
import '../widgets/checkbox_with_label.dart';
import '../widgets/disable.dart';

class LaunchWithSettings extends ConsumerStatefulWidget {
  const LaunchWithSettings({super.key});

  @override
  ConsumerState createState() => _LaunchWithSettingsState();
}

class _LaunchWithSettingsState extends ConsumerState<LaunchWithSettings> {
  late StarsectorVanillaLaunchPreferences? starsectorLaunchPrefs;

  @override
  void initState() {
    starsectorLaunchPrefs = Launcher.getStarsectorLaunchPrefs();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var resControllerWidth = TextEditingController(
        text: ref
                .watch(appSettings.select((value) => value.launchSettings))
                .resolutionWidth
                ?.toString() ??
            starsectorLaunchPrefs?.resolution.split("x")[1]);
    var resControllerHeight = TextEditingController(
        text: ref
                .watch(appSettings.select((value) => value.launchSettings))
                .resolutionHeight
                ?.toString() ??
            starsectorLaunchPrefs?.resolution.split("x")[0]);

    var isUsingJre23 = ref.watch(appSettings.select((value) => value.useJre23));
    // var currentScreenScaling = ref.watch(appSettings.select((value) => value.launchSettings)).screenScaling ??
    //     starsectorLaunchPrefs?.screenScaling ??
    //     1;

    return Row(
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
                          borderRadius:
                              BorderRadius.circular(ThemeManager.cornerRadius),
                        ),
                      ),
                      child: Text('LAUNCH',
                          style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontFamily: "Orbitron",
                              fontSize: 27,
                              color: Theme.of(context).colorScheme.onSecondary)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                        ref.watch(AppState.starsectorVersion).valueOrNull ??
                            "Starsector version unknown",
                        style: Theme.of(context).textTheme.labelMedium),
                  ),
                ],
              ),
            ),
            Tooltip(
              message: isUsingJre23 ?? false
                  ? "Currently unavailable using JRE 23\nClick Launch, then edit settings in the launcher that opens."
                  : "",
              child: Disable(
                isEnabled: !(isUsingJre23 ?? false),
                child: Padding(
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
                                          .watch(appSettings.select(
                                              (value) => value.launchSettings))
                                          .isFullscreen ??
                                      starsectorLaunchPrefs!.isFullscreen,
                                  onChanged: (bool? value) {
                                    ref.read(appSettings.notifier).update(
                                        (state) => state.copyWith(
                                            launchSettings: state.launchSettings
                                                .copyWith(
                                                    isFullscreen: value)));
                                  },
                                ),
                                CheckboxWithLabel(
                                  label: "Sound",
                                  value: ref
                                          .watch(appSettings.select(
                                              (value) => value.launchSettings))
                                          .hasSound ??
                                      starsectorLaunchPrefs!.hasSound,
                                  onChanged: (bool? value) {},
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
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    )),
                              ),
                            )
                          ]),
                  ),
                ),
              ),
            ),
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
    );
  }
}
