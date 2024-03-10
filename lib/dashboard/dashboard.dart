import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/launcher/launcher.dart';
import 'package:trios/models/launch_settings.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/trios/trios_theme.dart';
import 'package:trios/widgets/checkbox_with_label.dart';
import 'package:trios/widgets/disable.dart';

class Dashboard extends ConsumerStatefulWidget {
  const Dashboard({super.key});

  @override
  ConsumerState createState() => _DashboardState();
}

class _DashboardState extends ConsumerState<Dashboard> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    var starsectorLaunchPrefs = Launcher.getStarsectorLaunchPrefs();
    var resControllerWidth = TextEditingController(
        text: ref.watch(appSettings.select((value) => value.launchSettings)).resolutionWidth?.toString() ??
            starsectorLaunchPrefs?.resolution.split("x")[1]);
    var resControllerHeight = TextEditingController(
        text: ref.watch(appSettings.select((value) => value.launchSettings)).resolutionHeight?.toString() ??
            starsectorLaunchPrefs?.resolution.split("x")[0]);

    var isUsingJre23 = ref.watch(appSettings.select((value) => value.useJre23));

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Container(
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
            ),
            Tooltip(
              message: isUsingJre23 ? "Currently unavailable using JRE 23" : "",
              child: Disable(
                isEnabled: !isUsingJre23,
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
                                    value: ref.watch(appSettings.select((value) => value.launchSettings)).isFullscreen ??
                                        starsectorLaunchPrefs.isFullscreen,
                                    onChanged: (bool? value) {
                                      ref.read(appSettings.notifier).update((state) => state.copyWith(
                                          launchSettings: state.launchSettings.copyWith(isFullscreen: value)));
                                    },
                                  ),
                                  CheckboxWithLabel(
                                    label: "Sound",
                                    value: ref.watch(appSettings.select((value) => value.launchSettings)).hasSound ??
                                        starsectorLaunchPrefs.hasSound,
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
                                      inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
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
                                      inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
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
                                  message: "Revert to use default Vanilla settings.",
                                  child: ElevatedButton(
                                      onPressed: () => ref
                                          .read(appSettings.notifier)
                                          .update((s) => s.copyWith(launchSettings: const LaunchSettings())),
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
    );
  }
}
