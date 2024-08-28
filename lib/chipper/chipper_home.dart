import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/utils/platform_paths.dart';

import '../trios/settings/settings.dart';
import 'chipper_state.dart';
import 'copy.dart';
import 'views/about_view.dart';
import 'views/chipper_home.dart';

const chipperTitle = "Chipper";
const chipperVersion = "1.14.2";
const chipperTitleAndVersion = "$chipperTitle v$chipperVersion";
const chipperSubtitle = "A Starsector log viewer";

class ChipperApp extends ConsumerStatefulWidget {
  const ChipperApp({super.key});

  @override
  ConsumerState createState() => _ChipperAppState();
}

loadDefaultLog(WidgetRef ref) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final gamePath =
        ref.read(appSettings.select((value) => value.gameDir))?.toDirectory();
    var gameFilesPath = getLogPath(gamePath!);

    if (gameFilesPath.existsSync()) {
      gameFilesPath.readAsBytes().then((bytes) async {
        final content = utf8.decode(bytes.toList(), allowMalformed: true);
        return ref
            .read(ChipperState.logRawContents.notifier)
            .parseLog(LogFile(gameFilesPath.path, content));
      });
    }
  });
}

class _ChipperAppState extends ConsumerState<ChipperApp>
    with AutomaticKeepAliveClientMixin<ChipperApp> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyV, control: true): () =>
            pasteLog(ref)
      },
      child: const MyHomePage(
          title: chipperTitleAndVersion, subTitle: chipperSubtitle),
    );
  }
}

Future<void> pasteLog(WidgetRef ref) async {
  var clipboardData = (await Clipboard.getData(Clipboard.kTextPlain))?.text;

  if (clipboardData?.isNotEmpty == true) {
    ref
        .read(ChipperState.logRawContents.notifier)
        .parseLog(clipboardData == null ? null : LogFile(null, clipboardData));
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

    if (ref.read(ChipperState.logRawContents).valueOrNull == null) {
      loadDefaultLog(ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    chips = ref.watch(ChipperState.logRawContents).valueOrNull;
    return Stack(children: [
      Column(children: [
        Card(
          margin: const EdgeInsets.all(0),
          child: Padding(
              padding: const EdgeInsets.all(4),
              child: Row(children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  TextButton.icon(
                      onPressed: () {
                        loadDefaultLog(ref);
                      },
                      icon: const Icon(Icons.refresh),
                      style: ButtonStyle(
                          foregroundColor: WidgetStateProperty.all(
                              theme.colorScheme.onSurface)),
                      label: const Text("Load my log")),
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
                        style: ButtonStyle(
                            foregroundColor: WidgetStateProperty.all(
                                theme.colorScheme.onSurface)),
                        label: const Text("Copy all")),
                  if (chips != null)
                    TextButton.icon(
                        onPressed: () {
                          if (chips != null && chips!.filepath != null) {
                            final file = File(chips!.filepath!);
                            OpenFilex.open(file.absolute.normalize.path);
                          }
                        },
                        icon: const Icon(Icons.launch),
                        style: ButtonStyle(
                            foregroundColor: WidgetStateProperty.all(
                                theme.colorScheme.onSurface)),
                        label: const Text("Open File")),
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
                            onPressed: () =>
                                showChipperAboutDialog(context, theme),
                            icon: const Icon(Icons.info),
                            style: ButtonStyle(
                                foregroundColor: WidgetStateProperty.all(
                                    theme.colorScheme.onSurface))),
                      ],
                    ),
                  )
                ])
              ])),
        ),
        // WavyLineWidget(
        //   color: theme.colorScheme.primary,
        // ),
        Expanded(
          child: DesktopDrop(
            chips: chips,
          ),
        ),
      ]),
      Align(
          alignment: Alignment.bottomRight,
          child: Padding(
              padding: const EdgeInsets.only(right: 20),
              child: FloatingActionButton(
                onPressed: () async {
                  try {
                    FilePickerResult? result =
                        await FilePicker.platform.pickFiles();

                    if (result?.files.single != null) {
                      var file = result!.files.single;

                      if (kIsWeb) {
                        final content = utf8.decode(file.bytes!.toList(),
                            allowMalformed: true);
                        ref
                            .read(ChipperState.logRawContents.notifier)
                            .parseLog(LogFile(file.path, content));
                      } else if (file.path != null) {
                        final content = utf8.decode(
                            File(file.path!).readAsBytesSync().toList(),
                            allowMalformed: true);
                        ref
                            .read(ChipperState.logRawContents.notifier)
                            .parseLog(LogFile(file.path, content));
                      }
                    } else {
                      Fimber.w("Error reading file! $result");
                    }
                  } catch (e, stackTrace) {
                    Fimber.e("Error reading log file.",
                        ex: e, stacktrace: stackTrace);
                  }
                },
                tooltip: 'Upload log file',
                child: const Icon(Icons.upload_file),
              ))),
    ]);
  }
}
