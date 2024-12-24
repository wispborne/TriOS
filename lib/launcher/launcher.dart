import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter_color/flutter_color.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:plist_parser/plist_parser.dart';
import 'package:trios/jre_manager/jre_manager_logic.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/models/enabled_mods.dart';
import 'package:trios/models/launch_settings.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/thirdparty/dartx/io/file_system_entity.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/utils/platform_paths.dart';
import 'package:trios/widgets/disable.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/stroke_text.dart';
import 'package:trios/widgets/svg_image_icon.dart';
import 'package:win32_registry/win32_registry.dart';

import '../themes/theme_manager.dart';

class LaunchPrecheckError {
  final String message;
  final ModVariant? requiringModVariant;
  final String? fixActionName;
  final Future<void> Function()?
      doFix; // Assuming the fix action might be asynchronous

  LaunchPrecheckError({
    required this.message,
    this.requiringModVariant,
    this.fixActionName,
    this.doFix,
  });
}

class Launcher extends HookConsumerWidget {
  const Launcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var theme = Theme.of(context);
    final isGameRunning = ref.watch(AppState.isGameRunning).valueOrNull == true;
    final buttonBackgroundColor = isGameRunning
        ? theme.disabledColor
        : theme.colorScheme.surfaceContainer;

    // Animation controllers for hover and tap effects
    final hoverController = useAnimationController(
      duration: const Duration(milliseconds: 100),
    );
    final tapController = useAnimationController(
      duration: const Duration(milliseconds: 100),
    );

    final scaleAnimation = Tween<double>(begin: 1.0, end: 1.00).animate(
      CurvedAnimation(parent: hoverController, curve: Curves.easeInOut),
    );

    final tapScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: tapController, curve: Curves.easeOut),
    );

    final colorAnimation = ColorTween(
      begin: buttonBackgroundColor,
      end: buttonBackgroundColor.mix(theme.colorScheme.primary, 0.1),
    ).animate(hoverController);

    final boxShadowAnimation = Tween<double>(begin: 2, end: 10).animate(
      CurvedAnimation(parent: hoverController, curve: Curves.easeInOut),
    );

    return MovingTooltipWidget.framed(
      tooltipWidget: DefaultTextStyle.merge(
        style: theme.textTheme.labelLarge,
        child: isGameRunning
            ? const Text("Game is running")
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Launch ${ref.watch(AppState.starsectorVersion).valueOrNull}',
                    style: theme.textTheme.labelLarge
                        ?.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: "Java: ",
                        ),
                        TextSpan(
                          text: ref
                                  .watch(AppState.activeJre)
                                  .valueOrNull
                                  ?.version
                                  .versionString ??
                              "(unknown JRE)",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(
                          text: "\nRAM: ",
                        ),
                        TextSpan(
                          text:
                              "${ref.watch(currentRamAmountInMb).valueOrNull ?? "(unknown RAM)"} MB",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
      child: Disable(
        isEnabled: !isGameRunning,
        child: MouseRegion(
          onEnter: (_) => hoverController.forward(),
          onExit: (_) => hoverController.reverse(),
          child: GestureDetector(
            onTapDown: (_) => tapController.forward(),
            onTapUp: (_) => tapController.reverse(),
            onTapCancel: () => tapController.reverse(),
            onTap: () {
              try {
                launchGame(ref, context);
              } catch (e) {
                Fimber.e('Error launching game: $e');
              }
            },
            child: AnimatedBuilder(
              animation: Listenable.merge([hoverController, tapController]),
              builder: (context, child) {
                return Transform.scale(
                  scale: scaleAnimation.value * tapScaleAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorAnimation.value,
                      borderRadius:
                          BorderRadius.circular(ThemeManager.cornerRadius),
                      border: Border.all(
                        color: theme.colorScheme.primary.darker(15),
                        strokeAlign: BorderSide.strokeAlignOutside,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: boxShadowAnimation.value,
                          blurStyle: BlurStyle.normal,
                          color: theme.colorScheme.primary.withOpacity(0.25),
                          offset: Offset.zero,
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          blurRadius: 4,
                          blurStyle: BlurStyle.normal,
                          color:
                              Colors.black.mix(theme.colorScheme.primary, 0.5)!,
                          offset: Offset.zero,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: SizedBox(
                      height: 38,
                      width: 42,
                      child: Transform.translate(
                        offset: const Offset(0, -1),
                        child: Center(
                          child: StrokeText(
                            'S',
                            strokeWidth: 3,
                            borderOnTop: true,
                            strokeColor:
                                theme.colorScheme.surfaceTint.darker(70),
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontFamily: "Orbitron",
                              fontSize: 30,
                              color: theme.colorScheme.primary.darker(5),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Can throw exception
  static launchGame(WidgetRef ref, BuildContext context) async {
    final launchPrecheckFailures = performLaunchPrecheck(ref);
    final enableLauncherPrecheck =
        ref.read(appSettings.select((value) => value.enableLauncherPrecheck));

    if (launchPrecheckFailures.isNotEmpty && enableLauncherPrecheck) {
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Launch precheck failed'),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                ...launchPrecheckFailures
                    // .distinctBy((it) => it.message)
                    .map((failure) {
                  return ListTile(
                    title: Text(failure.message),
                    subtitle: failure.requiringModVariant != null
                        ? Text(failure
                            .requiringModVariant!.modInfo.formattedNameVersion)
                        : null,
                    trailing: failure.fixActionName != null
                        ? OutlinedButton(
                            onPressed: () async {
                              await failure.doFix!();
                              Navigator.of(context).pop();
                            },
                            child: Text(failure.fixActionName!),
                          )
                        : null,
                  );
                }),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                    onPressed: () => _launchGameWithoutPrecheck(ref),
                    icon: const SvgImageIcon("assets/images/icon-skip.svg"),
                    label: const Text('Launch anyway')),
              ]),
            );
          });
    } else {
      _launchGameWithoutPrecheck(ref);
    }
  }

  static void _launchGameWithoutPrecheck(WidgetRef ref) {
    if (ref.read(appSettings.select((value) => value.useJre23 ?? false))) {
      launchGameJre23(ref);
    } else {
      launchGameVanilla(ref);
    }
  }

  static List<LaunchPrecheckError> performLaunchPrecheck(WidgetRef ref) {
    final launchPrecheckFailures = <LaunchPrecheckError?>[];
    final mods = ref.read(AppState.mods);
    final modsFolder = ref.read(appSettings.select((it) => it.modsDir));
    final enabledMods = ref
        .read(AppState.enabledModsFile)
        .valueOrNull
        ?.filterOutMissingMods(mods)
        .enabledMods
        .toList();
    final enabledVariants =
        (mods.map((mod) => mod.findFirstEnabled)).nonNulls.toList();
    final modCompatibility = ref.read(AppState.modCompatibility);
    final currentGameVersion =
        ref.read(appSettings.select((s) => s.lastStarsectorVersion));

    if (enabledMods == null || enabledMods.isEmpty || modsFolder == null) {
      return [];
    }

    for (final variant in enabledVariants) {
      final compatibilityCheck = modCompatibility[variant.smolId];

      if (compatibilityCheck?.isGameCompatible == false) {
        launchPrecheckFailures.add(
          LaunchPrecheckError(
            message:
                'Mod ${variant.modInfo.name} requires game version ${variant.modInfo.gameVersion} and is not compatible with $currentGameVersion.',
            requiringModVariant: variant,
            fixActionName: "Force compatibility (not recommended)",
            doFix: () async {
              await ref
                  .read(modManager.notifier)
                  .forceChangeModGameVersion(variant, currentGameVersion!);
            },
          ),
        );
      }

      final dependencies = compatibilityCheck?.dependencyChecks ?? [];

      for (final dependency in dependencies) {
        final satisfaction = dependency.satisfiedAmount;

        launchPrecheckFailures.add(
          switch (satisfaction) {
            Missing _ => LaunchPrecheckError(
                message:
                    'Dependency ${dependency.dependency.name ?? dependency.dependency.id} is missing',
                requiringModVariant: variant,
                fixActionName: null,
                doFix: null,
              ),
            Disabled disabled => LaunchPrecheckError(
                message:
                    'Dependency ${dependency.dependency.name ?? dependency.dependency.id} is disabled',
                requiringModVariant: variant,
                fixActionName: "Enable",
                doFix: () async {
                  final mod = mods.firstWhereOrNull(
                      (mod) => mod.id == dependency.dependency.id);
                  if (mod != null) {
                    ref
                        .read(AppState.modVariants.notifier)
                        .changeActiveModVariant(mod, disabled.modVariant);
                  }
                },
              ),
            VersionInvalid _ => LaunchPrecheckError(
                message:
                    'Dependency ${dependency.dependency.name ?? dependency.dependency.id} has wrong version',
                requiringModVariant: variant,
                fixActionName: null,
                doFix: null,
              ),
            VersionWarning versionWarning => null,
            // LaunchPrecheckError(
            //       message:
            //           'Dependency ${dependency.dependency.name ?? dependency.dependency.id} has a different version, but may work.',
            //       requiringModVariant: variant,
            //       fixActionName: "Enable",
            //       doFix: () async {
            //         final mod = mods.firstWhereOrNull(
            //             (mod) => mod.id == dependency.dependency.id);
            //         if (mod != null) {
            //           ref
            //               .read(AppState.modVariants.notifier)
            //               .changeActiveModVariant(mod, versionWarning.modVariant);
            //         }
            //       },
            //     ),
            Satisfied _ => null,
          },
        );
      }
    }

    return launchPrecheckFailures.nonNulls.toList();
  }

  static StarsectorVanillaLaunchPreferences? getStarsectorLaunchPrefs() {
    if (Platform.isWindows) {
      return _getStarsectorLaunchPrefsWindows();
    } else if (Platform.isMacOS) {
      return _getStarsectorLaunchPrefsMacOS();
    } else {
      Fimber.w('Platform not yet supported for Direct Launch');
      return null;
    }
  }

  // serial	RegistryValueType.string	<redacted>
  // screen/Scale	RegistryValueType.string	1
  // num/A/A/Samples	RegistryValueType.string	0
  // resolution	RegistryValueType.string	1920x1080
  // fullscreen	RegistryValueType.string	false
  // controls/Version	RegistryValueType.string	6.3
  // controls1	RegistryValueType.string	{"/S/H/I/P_/S/T/R/A/F/E_/K/E/Y_2":{"c":"-1","f":""},"/C/M/E/N/U_/I/N/T/E/R/C/E/P/T_2":{"c":"-1","f":""},"/S/H/I/P_/S/T/R/A/F/E_/K/E/Y_1":{"c":"42","f":""},"/C/M/E/N/U_/L/I/G/H/T_/E/S/C/O/R/T_1":{"c":"38","f":""},"/C/M/E/N/U_/I/N/T/E/R/C/E/P/T_1":{"c":"46","f":""},"/C/M/E/N/U_/L/I/G/H/T_/E/S/C/O/R/T_2":{"c":"-1","f":""},"/C/M/E/N/U_/S/T/R/I/K/E_2":{"c":"-1","f":""},"/C/O/R/E_/A/B/I/L/I/T/Y_8_1":{"c":"9","f":""},"/C/O/R/E_/A/B/I/L/I/T/Y_8_2":{"c":"-1","f":""},"/C/M/E/N/U_/S/T/R/I/K/E_1":{"c":"31","f":""},"/S/H/I/P_/S/E/L/E/C/T_/G/R/O/U/P_7_1":{"c":"8","f":""},"/S/H/I/P_/V/E/N/T_/F/L/U/X_2":{"c":"-1","f":""},"/S/H/I/P_/V/E/N/T_/F/L/U/X_1":{"c":"47","f":""},"/S/H/I/P_/S/E/L/E/C/T_/G/R/O/U/P_7_2":{"c":"-1","f":""},"/C2_/M/O/R/E_/I/N/F/O_2":{"c":"-1","f":""},"/C2_/C/R/E/A/T/E_/G/R/O/U/P_10_2":{"c":"-1","f":""},"/C2_/M/O/R/E_/I/N/F/O_1":{"c":"23","f":""},"/C2_/C/R/E/A/T/E_/G/R/O/U/P_10_1":{"c":"11","f":"c"},"/S/H/I/P_/T/O/G/G/L/E_/G/R/O/U/P_1_2":{"c":"-1","f":""},"/S/H/I/P_/T/O/G/G/L/E_/G/R/O/U/P_1_1":{"c":"2","f":"c"},"/C2_/C/R/E/A/T/E_/G/R/O/U/P_3_1":{"c":"4","f":"c"},"/C2_/C/R/E/A/T/E_/G/R/O/U/P_3_2":{"c":"-1","f":""},"/S/H/I/P_/S/T/R/A/F/E_/R/I/G/H/T_/N/O/T/U/R/N_2":{"c":"-1","f":""},"/S/H/I/P_/H/O/L/D_/F/I/R/E_1":{"c":"45","f":""},"/S/H/I/P_/S/T/R/A/F/E_/R/I/G/H/T_/N/O/T/U/R/N_1":{"c":"18","f":""},"/S/H/I/P_/H/O/L/D_/F/I/R/E_2":{"c":"-1","f":""},"/C2_/S/E/L/E/C/T_/G/R/O/U/P_8_1":{"c":"9","f":""},"/C2_/P/A/N_/L/E/F/T_1":{"c":"203","f":""},"/C2_/P/A/N_/L/E/F/T_2":{"c":"75","f":""},"/C2_/S/E/L/E/C/T_/G/R/O/U/P_8_2":{"c":"-1","f":""},"/C/M/E/N/U_/H/A/R/A/S/S_2":{"c":"-1","f":""},"/S/H/I/P_/U/S/E_/S/Y/S/T/E/M_1":{"c":"33","f":""},"/S/H/I/P_/U/S/E_/S/Y/S/T/E/M_2":{"c":"-1","f":""},"/C/M/E/N/U_/H/A/R/A/S/S_1":{"c":"35","f":""},"/C/O/R/E_/A/B/I/L/I/T/Y_7_1":{"c":"8","f":""},"/C/O/R/E_/A/B/I/L/I/T/Y_7_2":{"c":"-1","f":""},"/C2_/S/H/O/W_/R/E/I/N/F/O/R/C/E/M/E/N/T/S_1":{"c":"34","f":""},"/C2_/S/H/O/W_/R/E/I/N/F/O/R/C/E/M/E/N/T/S_2":{"c":"-1","f":""},"/C2_/C/R/E/A/T/E_/G/R/O/U/P_2_2":{"c":"-1","f":""},"/C2_/C/R/E/A/T/E_/G/R/O/U/P_2_1":{"c":"3","f":"c"},"/C/M/E/N/U_/D/E/F/E/N/D_2":{"c":"-1","f":""},"/C2_/C/A/N/C/E/L_/A/S/S/I/G/N/M/E/N/T_2":{"c":"-1","f":""},"/C2_/C/A/N/C/E/L_/A/S/S/I/G/N/M/E/N/T_1":{"c":"49","f":""},"/C/M/E/N/U_/D/E/F/E/N/D_1":{"c":"32","f":""},"/C/M/E/N/U_/R/E/S/C/I/N/D_2":{"c":"-1","f":""},"/S/H/I/P_/F/I/R/E_2":{"c":"-1","f":""},"/C/M/E/N/U_/R/E/S/C/I/N/D_1":{"c":"24","f":""},"/G/O_/S/L/O/W_1":{"c":"31","f":""},"/S/H/I/P_/R/E/T/R/E/A/T_2":{"c":"-1","f":""},"/G/O_/S/L/O/W_2":{"c":"-1","f":""},"/S/H/I/P_/R/E/T/R/E/A/T_1":{"c":"28","f":""},"/C2_/S/E/L/E/C/T_/G/R/O/U/P_1_1":{"c":"2","f":""},"/C/M/E/N/U_/X/F/E/R_/C/O/M/M/A/N/D_2":{"c":"-1","f":""},"/S/H/I/P_/F/I/R/E_1":{"c":"2000","f":""},"/C2_/S/E/L/E/C/T_/G/R/O/U/P_1_2":{"c":"-1","f":""},"/C/M/E/N/U_/X/F/E/R_/C/O/M/M/A/N/D_1":{"c":"45","f":""},"/G/E/N/E/R/A/L_/P/A/U/S/E_1":{"c":"57","f":""},"/C/M/E/N/U_/R/E/T/R/E/A/T_1":{"c":"20","f":""},"/C/M/E/N/U_/R/E/T/R/E/A/T_2":{"c":"-1","f":""},"/G/E/N/E/R/A/L_/P/A/U/S/E_2":{"c":"-1","f":""},"/C2_/S/E/L/E/C/T_/G/R/O/U/P_9_2":{"c":"-1","f":""},"/C2_/S/E/L/E/C/T_/G/R/O/U/P_9_1":{"c":"10","f":""},"/C2_/T/O/G/G/L/E_/A/U/T/O/P/I/L/O/T_2":{"c":"-1","f":""},"/C/O/R/E_/A/B/I/L/I/T/Y_2_2":{"c":"-1","f":""},"/C2_/T/O/G/G/L/E_/A/U/T/O/P/I/L/O/T_1":{"c":"22","f":""},"/C/M/E/N/U_/F/U/L/L_/E/S/C/O/R/T_1":{"c":"35","f":""},"/C/M/E/N/U_/F/U/L/L_/E/S/C/O/R/T_2":{"c":"-1","f":""},"/S/H/I/P_/S/E/L/E/C/T_/G/R/O/U/P_5_2":{"c":"-1","f":""},"/C/O/R/E_/A/B/I/L/I/T/Y_2_1":{"c":"3","f":""},"/C/M/E/N/U_/R/E/M/O/V/E_/W/P_2":{"c":"-1","f":""},"/C/M/E/N/U_/R/E/M/O/V/E_/W/P_1":{"c":"17","f":""},"/S/H/I/P_/S/E/L/E/C/T_/G/R/O/U/P_5_1":{"c":"6","f":""},"/C2_/C/R/E/A/T/E_/G/R/O/U/P_5_1":{"c":"6","f":"c"},"/C2_/C/R/E/A/T/E_/G/R/O/U/P_5_2":{"c":"-1","f":""},"/C/M/E/N/U_/R/A/L/L/Y_/C/I/V/I/L/I/A/N_2":{"c":"-1","f":""},"/C2_/V/I/D/E/O_/F/E/E/D_1":{"c":"33","f":""},"/C2_/V/I/D/E/O_/F/E/E/D_2":{"c":"-1","f":""},"/S/H/I/P_/A/C/C/E/L/E/R/A/T/E_/B/A/C/K/W/A/R/D/S_1":{"c":"31","f":""},"/C/M/E/N/U_/R/A/L/L/Y_/C/I/V/I/L/I/A/N_1":{"c":"38","f":""},"/C/O/R/E_/A/B/I/L/I/T/Y_10_1":{"c":"11","f":""},"/C/O/R/E_/A/B/I/L/I/T/Y_10_2":{"c":"-1","f":""},"/S/H/I/P_/A/C/C/E/L/E/R/A/T/E_/B/A/C/K/W/A/R/D/S_2":{"c":"-1","f":""},"/C2_/S/E/L/E/C/T_/G/R/O/U/P_6_2":{"c":"-1","f":""},"/C2_/S/E/L/E/C/T_/G/R/O/U/P_6_1":{"c":"7","f":""},"/S/H/I/P_/D/E/C/E/L/E/R/A/T/E_2":{"c":"-1","f":""},"/S/H/I/P_/D/E/C/E/L/E/R/A/T/E_1":{"c":"46","f":""},"/C/O/R/E_/A/B/I/L/I/T/Y_/B/A/R_5_2":{"c":"-1","f":""},"/C/O/R/E_/A/B/I/L/I/T/Y_/B/A/R_5_1":{"c":"6","f":"c"},"/C/O/R/E_/A/B/I/L/I/T/Y_9_1":{"c":"10","f":""},"/C/O/R/E_/A/B/I/L/I/T/Y_9_2":{"c":"-1","f":""},"/S/H/I/P_/S/E/L/E/C/T_/G/R/O/U/P_6_2":{"c":"-1","f":""},"/S/H/I/P_/S/E/L/E/C/T_/G/R/O/U/P_6_1":{"c":"7","f":""},"/C/O/R/E_/A/B/I/L/I/T/Y_1_1":{"c":"2","f":""},"/C/O/R/E_/A/B/I/L/I/T/Y_1_2":{"c":"-1","f":""},"/S/H/I/P_/S/T/R/A/F/E_/L/E/F/T_/N/O/T/U/R/N_2":{"c":"-1","f":""},"/C2_/C/R/E/A/T/E_/G/R/O/U/P_4_2":{"c":"-1","f":""},"/S/H/I/P_/T/O/G/G/L/E_/G/R/O/U/P_7_2":{"c":"-1","f":""},"/C2_/C/R/E/A/T/E_/G/R/O/U/P_4_1":{"c":"5","f":"c"},"/S/H/I/P_/T/O/G/G/L/E_/G/R/O/U/P_7_1":{"c":"8","f":"c"},"/S/H/I/P_/S/T/R/A/F/E_/L/E/F/T_/N/O/T/U/R/N_1":{"c":"16","f":""},"/C2_/P/A/N_/U/P_2":{"c":"72","f":""},"/C2_/S/E/L/E/C/T_/G/R/O/U/P_7_1":{"c":"8","f":""},"/C2_/S/E/L/E/C/T_/G/R/O/U/P_7_2":{"c":"-1","f":""},"/S/H/I/P_/P/U/L/L_/B/A/C/K_/F/I/G/H/T/E/R/S_2":{"c":"21","f":""},"/S/H/I/P_/P/U/L/L_/B/A/C/K_/F/I/G/H/T/E/R/S_1":{"c":"44","f":""},"/C/O/R/E_/A/B/I/L/I/T/Y_/B/A/R_4_1":{"c":"5","f":"c"},"/G/E/N/E/R/A/L_/T/O/G/G/L/E_/U/I_2":{"c":"-1","f":""},"/G/E/N/E/R/A/L_/T/O/G/G/L/E_/U/I_1":{"c":"87","f":""},"/C/O/R/E_/A/B/I/L/I/T/Y_/B/A/R_4_2":{"c":"-1","f":""},"/C2_/V/I/D/E/O_/F/E/E/D_/Q/U/I/C/K_1":{"c":"16","f":""},"/C2_/V/I/D/E/O_/F/E/E/D_/Q/U/I/C/K_2"
  // controls2	RegistryValueType.string	:{"c":"-1","f":""},"/C2_/P/A/N_/D/O/W/N_1":{"c":"208","f":""},"/C2_/P/A/N_/D/O/W/N_2":{"c":"80","f":""},"/F/A/S/T_/F/O/R/W/A/R/D_1":{"c":"42","f":""},"/F/A/S/T_/F/O/R/W/A/R/D_2":{"c":"-1","f":""},"/C/O/R/E_/A/B/I/L/I/T/Y_4_1":{"c":"5","f":""},"/C/O/R/E_/A/B/I/L/I/T/Y_4_2":{"c":"-1","f":""},"/S/H/I/P_/T/U/R/N_/R/I/G/H/T_2":{"c":"-1","f":""},"/G/E/N/E/R/A/L_/E/X/P/A/N/D_/T/O/O/L/T/I/P_2":{"c":"-1","f":""},"/S/H/I/P_/T/U/R/N_/R/I/G/H/T_1":{"c":"32","f":""},"/C2_/P/A/N_/U/P_1":{"c":"200","f":""},"/S/H/I/P_/T/O/G/G/L/E_/G/R/O/U/P_5_1":{"c":"6","f":"c"},"/C/M/E/N/U_/A/V/O/I/D_2":{"c":"-1","f":""},"/S/H/I/P_/S/E/L/E/C/T_/G/R/O/U/P_3_1":{"c":"4","f":""},"/C/M/E/N/U_/A/V/O/I/D_1":{"c":"47","f":""},"/G/E/N/E/R/A/L_/E/X/P/A/N/D_/T/O/O/L/T/I/P_1":{"c":"59","f":""},"/S/H/I/P_/S/E/L/E/C/T_/G/R/O/U/P_3_2":{"c":"-1","f":""},"/C2_/C/R/E/A/T/E_/G/R/O/U/P_7_1":{"c":"8","f":"c"},"/C2_/C/R/E/A/T/E_/G/R/O/U/P_7_2":{"c":"-1","f":""},"/C/M/E/N/U_/S/E/A/R/C/H_/A/N/D_/D/E/S/T/R/O/Y_1":{"c":"31","f":""},"/S/H/I/P_/T/O/G/G/L/E_/G/R/O/U/P_6_2":{"c":"-1","f":""},"/C/M/E/N/U_/S/E/A/R/C/H_/A/N/D_/D/E/S/T/R/O/Y_2":{"c":"-1","f":""},"/S/H/I/P_/T/O/G/G/L/E_/G/R/O/U/P_6_1":{"c":"7","f":"c"},"/C/M/E/N/U_/R/A/L/L/Y_/T/A/S/K_/F/O/R/C/E_1":{"c":"21","f":""},"/C2_/S/E/L/E/C/T_/G/R/O/U/P_4_2":{"c":"-1","f":""},"/C/M/E/N/U_/R/A/L/L/Y_/T/A/S/K_/F/O/R/C/E_2":{"c":"-1","f":""},"/C/O/R/E_/A/B/I/L/I/T/Y_/B/A/R_3_2":{"c":"-1","f":""},"/C/O/R/E_/A/B/I/L/I/T/Y_/B/A/R_3_1":{"c":"4","f":"c"},"/C2_/S/E/L/E/C/T_/G/R/O/U/P_4_1":{"c":"5","f":""},"/C/M/E/N/U_/D/I/R/E/C/T_/R/E/T/R/E/A/T_2":{"c":"-1","f":""},"/C/M/E/N/U_/D/I/R/E/C/T_/R/E/T/R/E/A/T_1":{"c":"18","f":""},"/C/M/E/N/U_/D/E/S/T/R/O/Y/E/R_/E/S/C/O/R/T_1":{"c":"50","f":""},"/C/M/E/N/U_/D/E/S/T/R/O/Y/E/R_/E/S/C/O/R/T_2":{"c":"-1","f":""},"/S/H/I/P_/T/O/G/G/L/E_/W/E/A/P/O/N_/A/R/C/S_2":{"c":"0","f":""},"/S/H/I/P_/T/O/G/G/L/E_/W/E/A/P/O/N_/A/R/C/S_1":{"c":"41","f":""},"/G/E/N/E/R/A/L_/S/C/R/E/E/N/S/H/O/T_2":{"c":"-1","f":""},"/Q/U/I/C/K_/L/O/A/D_2":{"c":"-1","f":""},"/Q/U/I/C/K_/L/O/A/D_1":{"c":"67","f":""},"/C/O/R/E_/A/B/I/L/I/T/Y_3_1":{"c":"4","f":""},"/C/O/R/E_/A/B/I/L/I/T/Y_3_2":{"c":"-1","f":""},"/S/H/I/P_/T/O/G/G/L/E_/G/R/O/U/P_4_2":{"c":"-1","f":""},"/S/H/I/P_/T/A/R/G/E/T_/S/H/I/P_2":{"c":"-1","f":""},"/S/H/I/P_/T/O/G/G/L/E_/G/R/O/U/P_4_1":{"c":"5","f":"c"},"/S/H/I/P_/T/A/R/G/E/T_/S/H/I/P_1":{"c":"19","f":""},"/S/H/I/P_/S/E/L/E/C/T_/G/R/O/U/P_4_2":{"c":"-1","f":""},"/G/E/N/E/R/A/L_/S/C/R/E/E/N/S/H/O/T_1":{"c":"183","f":""},"/S/H/I/P_/S/E/L/E/C/T_/G/R/O/U/P_4_1":{"c":"5","f":""},"/C2_/C/R/E/A/T/E_/G/R/O/U/P_6_2":{"c":"-1","f":""},"/C2_/C/R/E/A/T/E_/G/R/O/U/P_6_1":{"c":"7","f":"c"},"/Q/U/I/C/K_/S/A/V/E_1":{"c":"63","f":""},"/S/H/I/P_/T/U/R/N_/L/E/F/T_2":{"c":"-1","f":""},"/Q/U/I/C/K_/S/A/V/E_2":{"c":"-1","f":""},"/S/H/I/P_/T/U/R/N_/L/E/F/T_1":{"c":"30","f":""},"/S/H/I/P_/T/O/G/G/L/E_/G/R/O/U/P_5_2":{"c":"-1","f":""},"/G/E/N/E/R/A/L_/Z/O/O/M_/I/N_1":{"c":"3000","f":""},"/G/E/N/E/R/A/L_/Z/O/O/M_/I/N_2":{"c":"-1","f":""},"/C/O/R/E_/A/B/I/L/I/T/Y_/B/A/R_2_1":{"c":"3","f":"c"},"/C2_/S/E/L/E/C/T_/G/R/O/U/P_5_1":{"c":"6","f":""},"/C2_/S/E/L/E/C/T_/G/R/O/U/P_5_2":{"c":"-1","f":""},"/C/O/R/E_/A/B/I/L/I/T/Y_/B/A/R_2_2":{"c":"-1","f":""},"/C/O/R/E_/A/B/I/L/I/T/Y_6_1":{"c":"7","f":""},"/C/M/E/N/U_/C/A/P/T/U/R/E_2":{"c":"-1","f":""},"/C/O/R/E_/A/B/I/L/I/T/Y_6_2":{"c":"-1","f":""},"/C/M/E/N/U_/C/A/P/T/U/R/E_1":{"c":"46","f":""},"/C2_/P/A/N_/R/I/G/H/T_2":{"c":"77","f":""},"/C2_/P/A/N_/R/I/G/H/T_1":{"c":"205","f":""},"/S/H/I/P_/T/O/G/G/L/E_/G/R/O/U/P_3_2":{"c":"-1","f":""},"/C/M/E/N/U_/T/A/R/G/E/T_1":{"c":"19","f":""},"/S/H/I/P_/S/E/L/E/C/T_/G/R/O/U/P_1_1":{"c":"2","f":""},"/S/H/I/P_/T/O/G/G/L/E_/G/R/O/U/P_3_1":{"c":"4","f":"c"},"/C/M/E/N/U_/T/A/R/G/E/T_2":{"c":"-1","f":""},"/S/H/I/P_/S/E/L/E/C/T_/G/R/O/U/P_1_2":{"c":"-1","f":""},"/S/H/I/P_/S/H/I/E/L/D/S_1":{"c":"2001","f":""},"/S/H/I/P_/S/H/I/E/L/D/S_2":{"c":"-1","f":""},"/C2_/C/R/E/A/T/E_/G/R/O/U/P_1_1":{"c":"2","f":"c"},"/C2_/C/R/E/A/T/E_/G/R/O/U/P_1_2":{"c":"-1","f":""},"/C2_/C/R/E/A/T/E_/G/R/O/U/P_9_1":{"c":"10","f":"c"},"/C2_/C/R/E/A/T/E_/G/R/O/U/P_9_2":{"c":"-1","f":""},"/C2_/S/E/L/E/C/T_/G/R/O/U/P_10_1":{"c":"11","f":""},"/C2_/S/E/L/E/C/T_/G/R/O/U/P_10_2":{"c":"-1","f":""},"/C2_/F/U/L/L_/R/E/T/R/E/A/T_1":{"c":"-1","f":""},"/C/O/R/E_/A/B/I/L/I/T/Y_/B/A/R_1_2":{"c":"-1","f":""},"/C2_/F/U/L/L_/R/E/T/R/E/A/T_2":{"c":"-1","f":""},"/C/O/R/E_/A/B/I/L/I/T/Y_/B/A/R_1_1":{"c":"2","f":"c"},"/C/M/E/N/U_/A/S/S/A/U/L/T_2":{"c":"-1","f":""},"/C2_/S/E/L/E/C/T_/G/R/O/U/P_2_2":{"c":"-1","f":""},"/C/M/E/N/U_/A/S/S/A/U/L/T_1":{"c":"30","f":""},"/C2_/S/E/L/E/C/T_/G/R/O/U/P_2_1":{"c":"3","f":""},"/S/H/I/P_/A/C/C/E/L/E/R/A/T/E_2":{"c":"-1","f":""},"/S/H/I/P_/A/C/C/E/L/E/R/A/T/E_1":{"c":"17","f":""},"/S/H/I/P_/T/O/G/G/L/E_/X/P/A/N_/M/O/D/E_1":{"c":"20","f":""},"/G/E/N/E/R/A/L_/Z/O/O/M_/O/U/T_1":{"c":"3001","f":""},"/G/E/N/E/R/A/L_/Z/O/O/M_/O/U/T_2":{"c":"-1","f":""},"/C/O/R/E_/A/B/I/L/I/T/Y_5_1":{"c":"6","f":""},"/C/O/R/E_/A/B/I/L/I/T/Y_5_2":{"c":"-1","f":""},"/S/H/I/P_/T/O/G/G/L/E_/X/P/A/N_/M/O/D/E_2":{"c":"-1","f":""},"/C/M/E/N/U_/E/N/G/A/G/E_2":{"c":"-1","f":""},"/C2_/S/E/A/R/C/H_/A/N/D_/D/E/S/T/R/O/Y_2":{"c":"-1","f":""},"/C/M/E/N/U_/E/N/G/A/G/E_1":{"c":"18","f":""},"/C2_/S/E/A/R/C/H_/A/N/D_/D/E/S/T/R/O/Y_1":{"c":"-1","f":""},"/S/H/I/P_/T/O/G/G/L/E_/G/R/O/U/P_2_2":{"c":"-1","f":""},"/S/H/I/P_/T/O/G/G/L/E_/G/R/O/U/P_2_1":{"c":"3","f":"c"},"/S/H/I/P_/S/E/L/E/C/T_/G/R/O/U/P_2_2":{"c":"-1","f":""},"/S/H/I/P_/S/E/L/E/C/T_/G/R/O/U/P_2_1":{"c":"3","f":""},"/C2_/C/R/E/A/T/E_/G/R/O/U/P_8_1":{"c":"9","f":"c"},"/S/H/I/P_/S/H/O/W_/W/A/R/R/O/O/M_1":{"c":"15","f":""},"/S/H/I/P_/S/H/O/W_/W/A/R/R/O/O/M_2":{"c":"-1","f":""},"/C2_/C/R/E/A/T/E_/G/R/O/U/P_8_2":{"c":"-1","f":""},"/C2_/S/E/L/E/C/T_/G/R/O/U/P_3_1":{"c":"4","f":""},"/C2_/S/E/L/E/C/T_/G/R/O/U/P_3_2":{"c":"-1","f":""}}
  // continue	RegistryValueType.string	..\saves\save_uftest_3768498736224501924
  // gameplay/Settings	RegistryValueType.string	{"damage/Floaties":true,"tooltip/Delay":0.10000000149011612,"pause/After/Battles":false,"autoturn/Mode":true,"disabled/Floaties":true,"battle/Size":400,"sound/Volume":0.699999988079071,"pause/After/Map":true,"enable/Ship/Explosion/Whiteout":false,"campaign/Diff":"normal","pause/After/Other":false,"speedup/Toggle":true,"music/Volume":0.5,"strafe/Lock":false}
  // can/Skip/Tutorial	RegistryValueType.string	true
  // memory	RegistryValueType.string	1024
  // memory/Auto	RegistryValueType.string	false
  // memory/Disabled	RegistryValueType.string	true
  // memory/Custom	RegistryValueType.string	false
  // first/Game/Run	RegistryValueType.string	false
  // sound	RegistryValueType.string	true
  static StarsectorVanillaLaunchPreferences _getStarsectorLaunchPrefsWindows() {
    const registryPath = r'Software\JavaSoft\Prefs\com\fs\starfarer';
    final key = Registry.openPath(RegistryHive.currentUser, path: registryPath);
    final prefs = StarsectorVanillaLaunchPreferences(
      isFullscreen:
          key.getValueAsString('fullscreen')?.equalsIgnoreCase("true") ?? false,
      resolution: key.getValueAsString('resolution') ?? '1920x1080',
      hasSound: key.getValueAsString('sound')?.equalsIgnoreCase("true") ?? true,
      numAASamples: key.getValueAsString('num/A/A/Samples')?.toIntOrNull(),
      screenScaling: key.getValueAsString('screen/Scale')?.toDoubleOrNull(),
    );
    key.close();

    Fimber.i('Reading Starsector settings from Registry:\n${prefs.toString()}');
    return prefs;
  }

  static StarsectorVanillaLaunchPreferences? _getStarsectorLaunchPrefsMacOS() {
    // /Users/username/Library/Preferences/com.fs.starfarer.plist
    try {
      final prefsFile = File(
          '${Platform.environment['HOME']}/Library/Preferences/com.fs.starfarer.plist');
      if (prefsFile.existsSync()) {
        final result = PlistParser()
            .parseFileSync(prefsFile.absolute.path)["/com/fs/starfarer/"];
        return StarsectorVanillaLaunchPreferences(
          isFullscreen:
              (result['fullscreen'] as String?)?.equalsIgnoreCase("true") ??
                  false,
          resolution: (result['resolution'] as String?) ?? '1920x1080',
          hasSound:
              (result['sound'] as String?)?.equalsIgnoreCase("true") ?? true,
          numAASamples: (result['numAASamples'] as String?)?.toIntOrNull(),
          screenScaling: (result['screenScale'] as String?)?.toDoubleOrNull(),
        );
      } else {
        Fimber.w('Starsector settings plist not found at $prefsFile');
      }
    } catch (e) {
      Fimber.e('Error reading Starsector settings from plist: $e');
    }
    return null;
  }

  // TODO: mac and linux
  /// Launches game with JRE 23.
  static launchGameJre23(WidgetRef ref) async {
    // Starsector folder
    final gameDir =
        ref.read(appSettings.select((value) => value.gameDir))?.toDirectory();
    final command =
        ref.read(appSettings.select((value) => value.showJre23ConsoleWindow))
            ? "start Miko_Rouge.bat"
            : "Miko_Silent.bat";

    Fimber.d("gameDir: $gameDir");
    final process = await Process.start(
      command,
      // Remove the `start ""` part to log all console output, including all Starsector logs.
      [],
      workingDirectory: gameDir?.path,
      runInShell: true,
    );
    process.stdout.transform(utf8.decoder).listen((data) {
      Fimber.i(data);
    });
    process.stderr.transform(utf8.decoder).listen((data) {
      Fimber.e(data);
    });
    // process.stdin.writeln("go");
  }

  // TODO: mac and linux
  /// Launches game without JRE 23.
  static launchGameVanilla(WidgetRef ref) async {
    // Starsector folder
    var gamePath =
        ref.read(appSettings.select((value) => value.gameDir))?.toDirectory();
    final gameCorePath = ref
        .read(appSettings.select((value) => value.gameCoreDir))
        ?.toDirectory();

    if (gamePath == null || gameCorePath == null) {
      Fimber.e('Game path or game core path not set');
      return;
    }

    final useDirectLaunch =
        ref.read(appSettings.select((value) => value.enableDirectLaunch));

    if (!useDirectLaunch) {
      launchGameUsingLauncher(gamePath);
      return;
    }

    var javaExe = getJavaExecutable(getJreDir(gamePath));
    var vmParams = getVmparamsFile(gamePath);

    if (javaExe.existsSync() != true) {
      Fimber.w('Java not found at $javaExe');
      return;
    } else if (vmParams.existsSync() != true) {
      Fimber.w('vmparams not found at $vmParams.');
      return;
    }

    var vmParamsContent = vmParams
        .readAsStringSync()
        .let((it) {
          if (Platform.isWindows) {
            return it.removePrefix("java.exe").split(' ');
          } else {
            return it.removePrefix("java").split('\n');
          }
        })
        .where((element) => element.isNotEmpty)
        .toList();

    LaunchSettings? launchPreferences;
    final customLaunchPrefs =
        ref.read(appSettings.select((value) => value.launchSettings));
    var vanillaPrefs = Launcher.getStarsectorLaunchPrefs()!.toLaunchSettings();
    launchPreferences = vanillaPrefs.overrideWith(customLaunchPrefs);
    final overrideArgs = _generateVmparamOverrides(
        launchPreferences, gameCorePath, vmParamsContent);

    if (Platform.isWindows) {
      List<String> finalVmparams = overrideArgs.entries
              .map((entry) => '${entry.key}=${entry.value}')
              .toList() +
          vmParamsContent
              // Remove any vanilla params that we're overriding.
              .filter((vanillaParam) => overrideArgs.entries
                  .none((entry) => vanillaParam.startsWith(entry.key)))
              .toList();

      Fimber.d('Final vmparams: $finalVmparams');
      Process.start(javaExe.absolute.path, finalVmparams,
          workingDirectory: gameCorePath.path,
          mode: ProcessStartMode.detached,
          includeParentEnvironment: true);
    } else if (Platform.isMacOS) {
      final vmparamsInFile = vmParams
          .readAsStringSync()
          .split("\n")
          .dropUntil((it) => it.contains("\$JAVA_HOME/bin/java"))
          .skip(1) // Skip the java line
          .takeWhile((it) => !it.contains('"\$@"'))
          .join("\n");
      // Replace ${EXTRAARGS} (part of vanilla script) with the custom args.
      final launchScript = vmparamsInFile
          .replaceAll("-cp",
              "-cp\n") // -cp needs to be a separate argument from its value
          // Otherwise the application will be called "Starsector" (with quotes)
          .replaceAll('"', "")
          .replaceAll(
              // Replace ${EXTRAARGS} with our Direct Launch args
              "\${EXTRAARGS}",
              overrideArgs.entries
                  .map((entry) => '${entry.key}=${entry.value}')
                  .join('\\ \n'))
          .split("\n")
          .map((e) => e.trim().trimEnd("\\").trim())
          .filter((it) => it.isNotNullOrEmpty())
          .toList();

      Fimber.i('Launching game using command: $launchScript');
      final process = await Process.start(javaExe.path, launchScript,
          workingDirectory: gameCorePath.absolute.path,
          mode: ProcessStartMode.detachedWithStdio,
          includeParentEnvironment: true,
          runInShell: true);
      Fimber.d(
          "Stdout: ${await process.stdout.transform(utf8.decoder).join()}");
      Fimber.w(
          "Stderr: ${await process.stderr.transform(utf8.decoder).join()}");
    } else {
      Fimber.w(
          'Platform not yet supported for direct launch, using normal launch');
      launchGameUsingLauncher(gamePath);
      return;
    }
  }

  static void launchGameUsingLauncher(Directory gamePath) {
    final gameExe = getGameExecutable(gamePath);
    if (Platform.isWindows) {
      if (gameExe.existsSync()) {
        Process.start(gameExe.absolute.path, [],
            workingDirectory: gamePath.path,
            mode: ProcessStartMode.detached,
            includeParentEnvironment: true);
      } else {
        Fimber.e('Game executable not found at $gameExe');
      }
    } else if (Platform.isMacOS) {
      // Use this way of checking if it exists because the MacOS one is actually a folder, not a file.
      if (FileSystemEntity.typeSync(gameExe.path) !=
          FileSystemEntityType.notFound) {
        Process.start("open", [gameExe.absolute.path],
            workingDirectory: gamePath.path,
            mode: ProcessStartMode.detached,
            includeParentEnvironment: true);
      } else {
        Fimber.e('Game executable not found at $gameExe');
      }
    } else if (Platform.isLinux) {
      Process.start("chmod", ["+x ${gameExe.absolute.path}"]);
      Process.start(
        "./${gameExe.name}",
        [],
        workingDirectory: gamePath.path,
        mode: ProcessStartMode.detached,
        includeParentEnvironment: true,
      );
      // OpenFilex.open(gameExe.absolute.path);
    } else {
      Fimber.e('Platform not supported for launching game');
    }
  }

  static Map<String, String?> _generateVmparamOverrides(
    LaunchSettings launchPrefs,
    Directory? starsectorCoreDir,
    List<String> vanillaVmparams,
  ) {
    final vmparamsKeysToAbsolutize = <String>[
      '-Djava.library.path',
      '-Dcom.fs.starfarer.settings.paths.saves',
      '-Dcom.fs.starfarer.settings.paths.screenshots',
      '-Dcom.fs.starfarer.settings.paths.mods',
      '-Dcom.fs.starfarer.settings.paths.logs',
    ];

    final overrideArgs = <String, String?>{
      '-DlaunchDirect': 'true',
      '-DstartFS': launchPrefs.isFullscreen.toString(),
      '-DstartSound': launchPrefs.hasSound.toString(),
      '-DstartRes':
          "${launchPrefs.resolutionWidth}x${launchPrefs.resolutionHeight}",
      '-DaaSamplesOverride': launchPrefs.numAASamples?.toString(),
      '-DscreenScale': launchPrefs.screenScaling?.toString(),
    };

    for (var key in vmparamsKeysToAbsolutize) {
      // Look through vmparams for the matching key, grab the value of it, and treat it as a relative path
      // to return an absolute one.
      final pair = vanillaVmparams
          .firstWhereOrNull((element) => element.startsWith('$key='));
      if (pair != null) {
        var value = pair.split('=').getOrNull(1);
        if (value != null) {
          overrideArgs[key] =
              starsectorCoreDir?.resolve(value).normalize().absolute.path;
        }
      }
    }

    return overrideArgs;
  }
}

class StarsectorVanillaLaunchPreferences {
  final bool isFullscreen;
  final String resolution;
  final bool hasSound;
  final int? numAASamples;
  final double? screenScaling;

  StarsectorVanillaLaunchPreferences({
    required this.isFullscreen,
    required this.resolution,
    required this.hasSound,
    this.numAASamples,
    this.screenScaling,
  });

  @override
  String toString() {
    return 'StarsectorVanillaLaunchPreferences{isFullscreen: $isFullscreen, resolution: $resolution, hasSound: $hasSound, numAASamples: $numAASamples, screenScaling: $screenScaling}';
  }

  LaunchSettings toLaunchSettings() {
    return LaunchSettings(
      isFullscreen: isFullscreen,
      resolutionWidth: int.tryParse(resolution.split('x').getOrNull(0) ?? ''),
      resolutionHeight: int.tryParse(resolution.split('x').getOrNull(1) ?? ''),
      hasSound: hasSound,
      numAASamples: numAASamples,
      screenScaling: screenScaling,
    );
  }
}
