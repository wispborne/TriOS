import 'dart:io';

import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vram_estimator_flutter/extensions.dart';
import 'package:vram_estimator_flutter/models/enabled_mods.dart';
import 'package:vram_estimator_flutter/settings/settingsSaver.dart';
import 'package:vram_estimator_flutter/util.dart';
import 'package:vram_estimator_flutter/vram_estimator/vram_estimator.dart';
import 'package:vram_estimator_flutter/widgets/graph_radio_selector.dart';
import 'package:window_size/window_size.dart';

import 'main.mapper.g.dart' show initializeJsonMapper;
import 'models/mod_result.dart';

const version = "1.0.0";
const appTitle = "TriOS v$version";
const appSubtitle = "by Wisp";

void main() {
  initializeJsonMapper();

  runApp(ProviderScope(observers: [SettingSaver()], child: const TriOSApp()));
  setWindowTitle(appTitle);
}

class TriOSApp extends ConsumerWidget {
  const TriOSApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      // title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: appTitle, subtitle: appSubtitle),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late SharedPreferences _prefs;
  Directory? gamePath = defaultGamePath();
  Directory? gameFiles;
  File? vanillaRulesCsv;
  Directory? modsFolder;
  List<File> modRulesCsvs = [];
  final gamePathTextController = TextEditingController();
  String? pathError;
  bool isScanning = false;
  GraphType graphType = GraphType.pie;
  Map<String, Mod> modVramInfo = {};
  List<Mod> modVramInfoToShow = [];
  Tuple2<int?, int?> viewRangeEnds = Tuple2(null, null);

  @override
  void initState() {
    super.initState();

    SharedPreferences.getInstance().then((prefs) {
      _prefs = prefs;
      setState(() {
        gamePath =
            Directory(_prefs.getString('gamePath') ?? defaultGamePath()!.path);
        if (!gamePath!.existsSync()) {
          gamePath = Directory(defaultGamePath()!.path);
        }
      });
      _updatePaths();
    });
  }

  _do() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      gamePath =
          // Directory(_prefs.getString('gamePath') ?? defaultGamePath()!.path);
          Directory(defaultGamePath()!.path);
    });
    _updatePaths();
  }

  @override
  void didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);

    // if (oldWidget. != modVramInfoToShow) {
    setState(() {
      modVramInfoToShow = modVramInfo.values.toList().sublist(
          viewRangeEnds.item1 ?? 0, viewRangeEnds.item2 ?? modVramInfo.length);
    });
    // }
  }

  _updatePaths() {
    setState(() {
      gameFiles = gameFilesPath(gamePath!)!;
      vanillaRulesCsv = getVanillaRulesCsvInGameFiles(gameFiles!);
      modsFolder = modFolderPath(gamePath!)!;
      modRulesCsvs = getAllRulesCsvsInModsFolder(modsFolder!);

      gamePathTextController.text = gamePath!.path;
    });
  }

  List<String>? getEnabledMods() => modsFolder == null
      ? null
      : JsonMapper.deserialize<EnabledMods>(
              File(p.join(modsFolder!.path, "enabled_mods.json"))
                  .readAsStringSync())
          ?.enabledMods;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Row(
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
              Text(widget.subtitle,
                  style: Theme.of(context).textTheme.bodyMedium)
            ]),
            Expanded(
              child: TextField(
                controller: gamePathTextController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Starsector Folder',
                ),
              ),
            ),
          ],
        ),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: VramEstimatorPage(
          title: "VRAM Estimator",
          subtitle: "Estimate VRAM usage for mods",
        ),
      ),
    );
  }
}
