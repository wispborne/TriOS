import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/launcher/launcher.dart';
import 'package:trios/trios/trios_theme.dart';
import 'package:trios/widgets/checkbox_with_label.dart';
import 'package:trios/widgets/under_construction_overlay.dart';

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
    var resControllerHeight = TextEditingController(text: starsectorLaunchPrefs?.resolution.split("x")[0]);
    var resControllerWidth = TextEditingController(text: starsectorLaunchPrefs?.resolution.split("x")[1]);

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
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.secondary,
                      blurRadius: 5,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Container(
                  // decoration: BoxDecoration(
                  //   borderRadius: BorderRadius.circular(TriOSTheme.cornerRadius),
                  //   border: Border.all(
                  //     width: 1,
                  //     color: Colors.black38,
                  //   ),
                  // ),
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
            ),
            UnderConstructionOverlay(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: (starsectorLaunchPrefs == null
                        ? []
                        : [
                            CheckboxWithLabel(
                              label: "Fullscreen",
                              value: starsectorLaunchPrefs.isFullscreen,
                              onChanged: (bool? value) {},
                            ),
                            CheckboxWithLabel(
                              label: "Sound",
                              value: starsectorLaunchPrefs.hasSound,
                              onChanged: (bool? value) {},
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
                                Text(" x ", style: Theme.of(context).textTheme.headlineSmall),
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
                                ),
                                const Text("Resolution")
                              ],
                            ),
                          ]),
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
