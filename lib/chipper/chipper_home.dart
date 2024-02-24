import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:fimber/fimber.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_info/platform_info.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/util.dart';

import 'app_state.dart' as state;
import 'app_state.dart';
import 'copy.dart';
import 'views/about_view.dart';
import 'views/desktop_drop_view.dart';

const chipperTitle = "Chipper";
const chipperVersion = "1.14.2";
const chipperTitleAndVersion = "$chipperTitle v$chipperVersion";
const chipperSubtitle = "A Starsector log viewer";

class ChipperApp extends ConsumerStatefulWidget {
  const ChipperApp({super.key});

  @override
  ConsumerState createState() => _ChipperAppState();
}

class _ChipperAppState extends ConsumerState<ChipperApp> with AutomaticKeepAliveClientMixin<ChipperApp> {
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.keyV, control: true): () => pasteLog(ref)},
      child: const MyHomePage(title: chipperTitleAndVersion, subTitle: chipperSubtitle),
    );
  }
}

Future<void> pasteLog(WidgetRef ref) async {
  var clipboardData = (await Clipboard.getData(Clipboard.kTextPlain))?.text;

  if (clipboardData?.isNotEmpty == true) {
    ref.read(state.logRawContents.notifier).update((state) {
      if (clipboardData == null) {
        return null;
      } else {
        LogFile(null, clipboardData);
      }
    });
  }
}

class MyHomePage extends ConsumerStatefulWidget {
  const MyHomePage({super.key, required this.title, this.subTitle});

  final String title;
  final String? subTitle;

  @override
  ConsumerState<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage> {
  LogChips? chips;

  @override
  void initState() {
    super.initState();
    ChipperState.loadedLog.addListener(() {
      setState(() {
        chips = ChipperState.loadedLog.chips;
      });
    });

    // Load default log file
    var gameFilesPath = defaultGameFilesPath()?.resolve("starsector.log") as File?;
    if (gameFilesPath != null && gameFilesPath.existsSync()) {
      gameFilesPath.readAsBytes().then((bytes) async {
        final content = utf8.decode(bytes.toList(), allowMalformed: true);
        return ref.read(state.logRawContents.notifier).state = LogFile(gameFilesPath.name, content);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(children: [
      Column(children: [
        Padding(
            padding: const EdgeInsets.all(0),
            child: Row(children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                Padding(
                  padding: const EdgeInsets.only(right: 24.0),
                  child: Image(
                      image: const AssetImage("assets/images/chipper/icon.png"),
                      width: 36,
                      height: 36,
                      color: theme.colorScheme.onBackground),
                ),
                if (chips != null)
                  TextButton.icon(
                      onPressed: () {
                        if (chips != null) {
                          Clipboard.setData(ClipboardData(
                              text:
                                  "${createSystemCopyString(chips)}\n\n${createModsCopyString(chips)}\n\n${createErrorsCopyString(chips)}"));
                        }
                      },
                      icon: const Icon(Icons.copy),
                      style: ButtonStyle(foregroundColor: MaterialStateProperty.all(theme.colorScheme.onBackground)),
                      label: const Text("Copy all")),
              ]),
              Row(mainAxisSize: MainAxisSize.min, children: [
                // Padding(
                //     padding: const EdgeInsets.only(top: 7),
                //     child: IconButton(
                //         onPressed: () => showMyDialog(context,
                //             title: const Text("Happy Halloween"), body: [Image.asset("assets/images/spooky.png")]),
                //         padding: EdgeInsets.zero,
                //         icon: const ImageIcon(
                //           AssetImage("assets/images/halloween.png"),
                //           size: 48,
                //         ))),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Row(
                    children: [
                      TextButton.icon(
                          label: const Text("About Chipper"),
                          onPressed: () => showChipperAboutDialog(context, theme),
                          icon: const Icon(Icons.info),
                          style:
                              ButtonStyle(foregroundColor: MaterialStateProperty.all(theme.colorScheme.onBackground))),
                    ],
                  ),
                )
              ])
            ])),
        // WavyLineWidget(
        //   color: theme.colorScheme.primary,
        // ),
        Expanded(
            child: Stack(children: [
          SizedBox(
              width: double.infinity,
              child: DesktopDrop(
                chips: chips,
              )),
          // const IgnorePointer(child: ChristmasLights())
        ]))
      ]),
      Align(
          alignment: Alignment.bottomRight,
          child: Padding(
              padding: const EdgeInsets.only(right: 20),
              child: FloatingActionButton(
                onPressed: () async {
                  try {
                    FilePickerResult? result = await FilePicker.platform.pickFiles();

                    if (result?.files.single != null) {
                      var file = result!.files.single;

                      if (Platform.I.isWeb) {
                        final content = utf8.decode(file.bytes!.toList(), allowMalformed: true);
                        ref.read(state.logRawContents.notifier).update((state) => LogFile(file.name, content));
                      } else {
                        final content = utf8.decode(file.bytes!.toList(), allowMalformed: true);
                        ref.read(state.logRawContents.notifier).update((state) => LogFile(file.name, content));
                      }
                    } else {
                      Fimber.w("Error reading file! $result");
                    }
                  } catch (e, stackTrace) {
                    Fimber.e("Error reading log file.", ex: e, stacktrace: stackTrace);
                  }
                },
                tooltip: 'Upload log file',
                child: const Icon(Icons.upload_file),
              ))),
    ]);
  }
}
