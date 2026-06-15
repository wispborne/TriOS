import 'dart:async';
import 'dart:io';
import 'package:trios/trios/constants_theme.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/widgets/disable.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/svg_image_icon.dart';
import 'package:trios/widgets/text_link_button.dart';

import '../launcher/launcher.dart';
import '../models/launch_settings.dart';
import '../themes/theme_manager.dart';
import '../trios/app_state.dart';
import '../trios/constants.dart';
import '../trios/navigation.dart';
import '../trios/navigation_request.dart';
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
  late final TextEditingController _resControllerWidth;
  late final TextEditingController _resControllerHeight;

  @override
  void initState() {
    super.initState();
    try {
      starsectorLaunchPrefs = LauncherButton.getStarsectorLaunchPrefs();
    } catch (e) {
      Fimber.e("Failed to get default Starsector launch prefs", ex: e);
    }
    _resControllerWidth = TextEditingController();
    _resControllerHeight = TextEditingController();
    _syncControllerTexts();
  }

  @override
  void dispose() {
    _resControllerWidth.dispose();
    _resControllerHeight.dispose();
    _onClickedTimer?.cancel();
    super.dispose();
  }

  void _syncControllerTexts() {
    final launchSettings = ref.read(appSettings).launchSettings;
    final newWidth =
        launchSettings.resolutionWidth?.toString() ??
        starsectorLaunchPrefs?.resolution.split("x")[1] ??
        '';
    final newHeight =
        launchSettings.resolutionHeight?.toString() ??
        starsectorLaunchPrefs?.resolution.split("x")[0] ??
        '';
    if (_resControllerWidth.text != newWidth) {
      _resControllerWidth.text = newWidth;
    }
    if (_resControllerHeight.text != newHeight) {
      _resControllerHeight.text = newHeight;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      appSettings.select((value) => value.launchSettings),
      (_, _) => _syncControllerTexts(),
    );

    final enableDirectLaunch = ref.watch(
      appSettings.select((s) => s.enableDirectLaunch),
    );
    final isRunning = widget.isGameRunning || _onClickedTimer?.isActive == true;

    final showLauncherControls = enableDirectLaunch == true;
    return Disable(
      isEnabled: !isRunning,
      child: Stack(
        children: [
          Positioned(
            right: 0,
            child: Padding(
              padding: const EdgeInsets.only(left: 16, top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Tooltip(
                    message:
                        "EXPERIMENTAL\nIf you encounter strange issues in-game, disable this."
                        "\nPossible issues include: invisible ships, zoomed-in combat, no Windows title bar, probably more.",
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      borderRadius: BorderRadius.circular(
                        TriOSThemeConstants.cornerRadius,
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
                        textPadding: const EdgeInsets.only(left: 12, bottom: 0),
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
                        LauncherButton(showTextInsteadOfIcon: true),
                        const SizedBox(height: 8),
                        Row(
                          spacing: 4,
                          children: [
                            Builder(
                              builder: (context) {
                                final path = ref
                                    .watch(AppState.gameExecutable)
                                    .value
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
                                  style: Theme.of(
                                    context,
                                  ).textTheme.labelMedium,
                                );
                              },
                            ),
                            SizedBox(
                              height: 16,
                              width: 24,
                              child: MovingTooltipWidget.text(
                                message: "Change which file launches the game",
                                child: IconButton(
                                  onPressed: () {
                                    ref
                                        .read(
                                          AppState.navigationRequest.notifier,
                                        )
                                        .state = NavigationRequest(
                                      destination: TriOSTools.settings,
                                      highlightKey:
                                          "settings.starsectorLauncher",
                                    );
                                  },
                                  icon: Icon(Icons.edit, size: 16),
                                  padding: .zero,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          ref.watch(AppState.starsectorVersion).value ??
                              "Starsector version unknown",
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        Text(
                          ref.watch(AppState.modsFolder).value?.path ??
                              "No mods folder!",
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ],
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
                                        controller: _resControllerHeight,
                                        inputFormatters: <TextInputFormatter>[
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                        ],
                                        decoration: const InputDecoration(
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
                                        controller: _resControllerWidth,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: <TextInputFormatter>[
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                        ],
                                        decoration: const InputDecoration(
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
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Opacity(
                        opacity: 0.8,
                        child: Column(
                          children: [
                            Text(
                              "Note: These settings are separate from the normal launcher's settings.",
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "If you encounter strange issues in-game, disable Skip Launcher.",
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: TriOSThemeConstants
                                        .vanillaWarningColor
                                        .withAlpha(200),
                                  ),
                            ),
                            Text(
                              "Possible issues include: invisible ships, zoomed-in combat, no Windows title bar, probably more.",
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: TriOSThemeConstants
                                        .vanillaWarningColor
                                        .withAlpha(200),
                                  ),
                            ),
                          ],
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
