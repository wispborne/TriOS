import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/chipper/chipper_home.dart';
import 'package:trios/launcher/launcher.dart';
import 'package:trios/models/launch_settings.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/trios/trios_theme.dart';
import 'package:trios/widgets/checkbox_with_label.dart';
import 'package:trios/widgets/disable.dart';

import '../chipper/chipper_state.dart';
import '../chipper/views/chipper_log.dart';
import 'mod_list_basic.dart';

class Dashboard extends ConsumerStatefulWidget {
  const Dashboard({super.key});

  @override
  ConsumerState createState() => _DashboardState();
}

class _DashboardState extends ConsumerState<Dashboard> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  late StarsectorVanillaLaunchPreferences? starsectorLaunchPrefs;

  @override
  void initState() {
    super.initState();
    starsectorLaunchPrefs = Launcher.getStarsectorLaunchPrefs();
    if (ref.read(ChipperState.logRawContents).valueOrNull == null) {
      loadDefaultLog(ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    var resControllerWidth = TextEditingController(
        text: ref.watch(appSettings.select((value) => value.launchSettings)).resolutionWidth?.toString() ??
            starsectorLaunchPrefs?.resolution.split("x")[1]);
    var resControllerHeight = TextEditingController(
        text: ref.watch(appSettings.select((value) => value.launchSettings)).resolutionHeight?.toString() ??
            starsectorLaunchPrefs?.resolution.split("x")[0]);

    var isUsingJre23 = ref.watch(appSettings.select((value) => value.useJre23));
    // var currentScreenScaling = ref.watch(appSettings.select((value) => value.launchSettings)).screenScaling ??
    //     starsectorLaunchPrefs?.screenScaling ??
    //     1;

    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
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
                                borderRadius: BorderRadius.circular(TriOSTheme.cornerRadius),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.secondary,
                                  strokeAlign: BorderSide.strokeAlignOutside,
                                  width: 2,
                                ),
                              ),
                              child: ElevatedButton(
                                onPressed: () => Launcher.launchGame(ref),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.secondary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(TriOSTheme.cornerRadius),
                                  ),
                                ),
                                child: Text('LAUNCH',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontFamily: "Orbitron",
                                        fontSize: 27,
                                        color: Theme.of(context).colorScheme.onPrimary)),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                  ref.watch(AppState.starsectorVersion).valueOrNull ?? "Starsector version unknown",
                                  style: Theme.of(context).textTheme.labelMedium),
                            ),
                          ],
                        ),
                      ),
                      Tooltip(
                        message: isUsingJre23 ?? false ? "Currently unavailable using JRE 23" : "",
                        child: Disable(
                          isEnabled: !(isUsingJre23 ?? false),
                          child: Card(
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
                                                      .watch(appSettings.select((value) => value.launchSettings))
                                                      .isFullscreen ??
                                                  starsectorLaunchPrefs!.isFullscreen,
                                              onChanged: (bool? value) {
                                                ref.read(appSettings.notifier).update((state) => state.copyWith(
                                                    launchSettings:
                                                        state.launchSettings.copyWith(isFullscreen: value)));
                                              },
                                            ),
                                            CheckboxWithLabel(
                                              label: "Sound",
                                              value: ref
                                                      .watch(appSettings.select((value) => value.launchSettings))
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
                                              child: Text(" x ", style: Theme.of(context).textTheme.headlineSmall),
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
                                            message: "Use your non-TriOS launcher settings instead",
                                            child: OutlinedButton(
                                                onPressed: () {
                                                  ref.read(appSettings.notifier).update(
                                                      (s) => s.copyWith(launchSettings: const LaunchSettings()));
                                                  setState(
                                                      () {}); // Force refresh widget to update text fields to default.
                                                },
                                                child: Text(
                                                  "Clear Custom Launch Settings",
                                                  style: Theme.of(context).textTheme.bodySmall,
                                                )),
                                          ),
                                        )
                                      ]),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Opacity(
                          opacity: 0.8,
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text("Note: These settings are separate from the normal launcher's settings.",
                                style: Theme.of(context).textTheme.labelMedium),
                          )),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: SizedBox(
                    height: 150,
                    child: Builder(builder: (context) {
                      // ChipperState.loadedLog.addListener(() {
                      //   setState(() {});
                      // });
                      final errors = ref.watch(ChipperState.logRawContents).valueOrNull?.errorBlock;
                      if (errors != null) {
                        return DefaultTextStyle.merge(
                            child: ChipperLog(errors: errors, showInfoLogs: true),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14));
                      } else {
                        return const SizedBox(
                            width: 350,
                            child: Column(
                              children: [
                                Text("No log loaded"),
                              ],
                            ));
                      }
                    }),
                  ),
                ),
              )
            ],
          ),
        ),
        const SizedBox(width: 350, child: Card(child: ModListMini()))
      ],
    );
  }
}
