import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/jre_manager/jre_manager_logic.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/widgets/disable.dart';
import 'package:trios/widgets/svg_image_icon.dart';
import 'package:trios/widgets/text_link_button.dart';

import '../launcher/launcher.dart';
import '../models/launch_settings.dart';
import '../themes/theme_manager.dart';
import '../trios/app_state.dart';
import '../trios/constants.dart';
import '../utils/util.dart';
import '../widgets/checkbox_with_label.dart';

class LaunchWithSettings extends ConsumerStatefulWidget {
  final bool isGameRunning;

  const LaunchWithSettings({super.key, required this.isGameRunning});

  @override
  ConsumerState createState() => _LaunchWithSettingsState();
}

class _LaunchWithSettingsState extends ConsumerState<LaunchWithSettings> {
  StarsectorVanillaLaunchPreferences? starsectorLaunchPrefs;
  Timer? _onClickedTimer;

  @override
  void initState() {
    try {
      starsectorLaunchPrefs = LauncherButton.getStarsectorLaunchPrefs();
    } catch (e) {
      Fimber.e("Failed to get default Starsector launch prefs", ex: e);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final resControllerWidth = TextEditingController(
      text:
          ref
              .watch(appSettings.select((value) => value.launchSettings))
              .resolutionWidth
              ?.toString() ??
          starsectorLaunchPrefs?.resolution.split("x")[1],
    );
    final resControllerHeight = TextEditingController(
      text:
          ref
              .watch(appSettings.select((value) => value.launchSettings))
              .resolutionHeight
              ?.toString() ??
          starsectorLaunchPrefs?.resolution.split("x")[0],
    );

    // final gameDir = ref.read(appSettings.select((value) => value.gameDir));
    final isUsingCustomJre = ref
        .watch(jreManagerProvider)
        .valueOrNull
        ?.activeJre
        ?.isCustomJre;
    // var currentScreenScaling = ref.watch(appSettings.select((value) => value.launchSettings)).screenScaling ??
    //     starsectorLaunchPrefs?.screenScaling ??
    //     1;

    final enableDirectLaunch = ref.watch(
      appSettings.select((s) => s.enableDirectLaunch),
    );
    final isRunning = widget.isGameRunning || _onClickedTimer?.isActive == true;

    final showLauncherControls =
        isUsingCustomJre != true && enableDirectLaunch == true;
    return Disable(
      isEnabled: !isRunning,
      child: Stack(
        children: [
          if (isUsingCustomJre != true)
            Positioned(
              right: 0,
              child: Padding(
                padding: const EdgeInsets.only(left: 16, top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Tooltip(
                      message:
                          "EXPERIMENTAL\nIf you encounter strange issues in-game, disable this.\nPossible issues include: zoomed-in combat, no Windows title bar, invisible ships, probably more.",
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error,
                        borderRadius: BorderRadius.circular(
                          ThemeManager.cornerRadius,
                        ),
                      ),
                      child: Opacity(
                        opacity: enableDirectLaunch ? 1 : 0.8,
                        child: CheckboxWithLabel(
                          labelWidget: Row(
                            children: [
                              Text(
                                "Skip Launcher",
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                              if (enableDirectLaunch)
                                Transform.rotate(
                                  angle: .6,
                                  child: SvgImageIcon(
                                    "assets/images/icon-experimental.svg",
                                    width: 20,
                                    color: Theme.of(
                                      context,
                                    ).iconTheme.color?.withValues(alpha: 0.8),
                                  ),
                                ),
                            ],
                          ),
                          textPadding: const EdgeInsets.only(
                            left: 12,
                            bottom: 0,
                          ),
                          flipCheckboxAndLabel: true,
                          value: enableDirectLaunch,
                          showGlow: enableDirectLaunch,
                          onChanged: (bool? value) {
                            if (value == null) return;
                            ref
                                .read(appSettings.notifier)
                                .update(
                                  (s) => s.copyWith(enableDirectLaunch: value),
                                );
                          },
                        ),
                      ),
                    ),
                    // Padding(
                    //   padding: const EdgeInsets.only(right: 42),
                    //   child: Text("(experimental)", style: Theme.of(context).textTheme.labelSmall),
                    // ),
                  ],
                ),
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
                        true
                            ? LauncherButton(showTextInsteadOfIcon: true)
                            : Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    ThemeManager.cornerRadius,
                                  ),
                                  border: Border.all(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.secondary,
                                    strokeAlign: BorderSide.strokeAlignOutside,
                                    width: 2,
                                  ),
                                ),
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (isRunning) return;
                                    _onClickedTimer?.cancel();
                                    _onClickedTimer = Timer(
                                      const Duration(seconds: 5),
                                      () => {},
                                    );
                                    LauncherButton.launchGame(ref, context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.secondary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        ThemeManager.cornerRadius,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    isRunning ? "RUNNING..." : "LAUNCH",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontFamily: "Orbitron",
                                      fontSize: 27,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSecondary,
                                    ),
                                  ),
                                ),
                              ),
                        const SizedBox(height: 8),
                        Tooltip(
                          message:
                              "${Constants.appName} is not required to launch the game.",
                          child: Builder(
                            builder: (context) {
                              final path = ref
                                  .watch(AppState.gameExecutable)
                                  .valueOrNull
                                  ?.absolute
                                  .path
                                  .let((p) {
                                    return currentPlatform !=
                                            TargetPlatform.macOS
                                        ? p.let(
                                            (p) => p.toFile().relativePath(
                                              ref
                                                  .watch(AppState.gameFolder)
                                                  .value!,
                                            ),
                                          )
                                        : File(p).nameWithExtension;
                                  });

                              return Text(
                                path ?? "No game exe",
                                style: Theme.of(context).textTheme.labelMedium,
                              );
                            },
                          ),
                        ),
                        Text(
                          ref.watch(AppState.starsectorVersion).valueOrNull ??
                              "Starsector version unknown",
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        // Removed because it's shown on the JRE & RAM Settings tile now.
                        // Builder(builder: (context) {
                        //   final activeJre =
                        //       ref.watch(AppState.activeJre).valueOrNull?.version;
                        //   return Text(
                        //       activeJre != null
                        //           ? "Java ${activeJre.versionString}"
                        //           : "Java version unknown",
                        //       style: Theme.of(context).textTheme.labelMedium);
                        // }),
                        Text(
                          ref
                                  .watch(AppState.modsFolder).valueOrNull
                                  ?.path ??
                              "No mods folder!",
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ],
                    ),
                  ),
                  if (isUsingCustomJre == true)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: CheckboxWithLabel(
                        label: "Show Console (log output) Window",
                        value:
                            ref.watch(
                              appSettings.select(
                                (value) => value.showCustomJreConsoleWindow,
                              ),
                            ) ??
                            false,
                        onChanged: (bool? value) {
                          ref
                              .read(appSettings.notifier)
                              .update(
                                (state) => state.copyWith(
                                  showCustomJreConsoleWindow: value ?? false,
                                ),
                              );
                        },
                      ),
                    ),
                  if (showLauncherControls)
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
                                      value:
                                          ref
                                              .watch(
                                                appSettings.select(
                                                  (value) =>
                                                      value.launchSettings,
                                                ),
                                              )
                                              .isFullscreen ??
                                          starsectorLaunchPrefs!.isFullscreen,
                                      onChanged: (bool? value) {
                                        ref
                                            .read(appSettings.notifier)
                                            .update(
                                              (state) => state.copyWith(
                                                launchSettings: state
                                                    .launchSettings
                                                    .copyWith(
                                                      isFullscreen: value,
                                                    ),
                                              ),
                                            );
                                      },
                                    ),
                                    CheckboxWithLabel(
                                      label: "Sound",
                                      value:
                                          ref
                                              .watch(
                                                appSettings.select(
                                                  (value) =>
                                                      value.launchSettings,
                                                ),
                                              )
                                              .hasSound ??
                                          starsectorLaunchPrefs!.hasSound,
                                      onChanged: (bool? value) {
                                        ref
                                            .read(appSettings.notifier)
                                            .update(
                                              (state) => state.copyWith(
                                                launchSettings: state
                                                    .launchSettings
                                                    .copyWith(hasSound: value),
                                              ),
                                            );
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
                                      child: TextField(
                                        controller: resControllerHeight,
                                        inputFormatters: <TextInputFormatter>[
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                        ],
                                        decoration: const InputDecoration(
                                          // errorText: gamePathExists ? null : "Path does not exist",
                                          labelText: 'Width',
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 2),
                                      child: Text(
                                        " x ",
                                        style: Theme.of(
                                          context,
                                        ).textTheme.headlineSmall,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 50,
                                      child: TextField(
                                        controller: resControllerWidth,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: <TextInputFormatter>[
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                        ],
                                        decoration: const InputDecoration(
                                          // errorText: gamePathExists ? null : "Path does not exist",
                                          labelText: 'Height',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Tooltip(
                                    message:
                                        "Use your non-TriOS launcher settings instead",
                                    child: Opacity(
                                      opacity: 0.8,
                                      child: TextLinkButton(
                                        onPressed: () {
                                          ref
                                              .read(appSettings.notifier)
                                              .update(
                                                (s) => s.copyWith(
                                                  launchSettings:
                                                      const LaunchSettings(),
                                                ),
                                              );
                                          setState(
                                            () {},
                                          ); // Force refresh widget to update text fields to default.
                                        },
                                        text: "Clear Custom Launch Settings",
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ),
                                  ),
                                ),
                              ]),
                      ),
                    ),
                  if (showLauncherControls)
                    Opacity(
                      opacity: 0.8,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Text(
                          "Note: These settings are separate from the normal launcher's settings.",
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
