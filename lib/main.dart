import 'dart:io';

import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vram_estimator_flutter/extensions.dart';
import 'package:vram_estimator_flutter/models/enabled_mods.dart';
import 'package:vram_estimator_flutter/util.dart';
import 'package:vram_estimator_flutter/vram_checker.dart';
import 'package:vram_estimator_flutter/widgets/bar_chart.dart';
import 'package:vram_estimator_flutter/widgets/graph_radio_selector.dart';
import 'package:vram_estimator_flutter/widgets/pie_chart.dart';
import 'package:vram_estimator_flutter/widgets/spinning_refresh_button.dart';
import 'package:window_size/window_size.dart';

import 'main.mapper.g.dart' show initializeJsonMapper;
import 'models/graphics_lib_config.dart';
import 'models/mod_result.dart';

const version = "1.0.0";
const appTitle = "VRAM Estimator v$version";
const appSubtitle = "by Wisp";

void main() {
  initializeJsonMapper();
  runApp(const ProviderScope(child: MyApp()));
  setWindowTitle(appTitle);
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Flutter Demo',
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
  Map<String, Mod> modVramInfo = {};
  bool isScanning = false;
  GraphType graphType = GraphType.pie;

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

  _updatePaths() {
    setState(() {
      gameFiles = gameFilesPath(gamePath!)!;
      vanillaRulesCsv = getVanillaRulesCsvInGameFiles(gameFiles!);
      modsFolder = modFolderPath(gamePath!)!;
      modRulesCsvs = getAllRulesCsvsInModsFolder(modsFolder!);

      gamePathTextController.text = gamePath!.path;
    });
  }

  void _getVramUsage() async {
    if (isScanning) return;

    setState(() {
      isScanning = true;
    });

    final info = await VramChecker(
      enabledModIds: getEnabledMods(),
      modIdsToCheck: null,
      foldersToCheck: modsFolder == null ? [] : [modsFolder!],
      graphicsLibConfig: GraphicsLibConfig(
        areAnyEffectsEnabled: false,
        areGfxLibMaterialMapsEnabled: false,
        areGfxLibNormalMapsEnabled: false,
        areGfxLibSurfaceMapsEnabled: false,
      ),
      showCountedFiles: true,
      showSkippedFiles: true,
      showGfxLibDebugOutput: true,
      showPerformance: true,
      modProgressOut: (mod) {
        // update modVramInfo with each mod's progress
        setState(() {
          modVramInfo = modVramInfo..[mod.info.id] = mod;
        });
      },
      debugOut: print,
      verboseOut: print,
    ).check();

    setState(() {
      isScanning = false;
      modVramInfo = info.fold<Map<String, Mod>>(
          {},
          (previousValue, element) =>
              previousValue..[element.info.id] = element); // sort by mod size
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
    var sortedModData = modVramInfo.values
        .sortedByDescending<num>((mod) => mod.totalBytesForMod)
        .toList();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
          Text(widget.subtitle, style: Theme.of(context).textTheme.bodyMedium)
        ]),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Row(
                children: [
                  SpinningRefreshButton(
                    onPressed: () {
                      if (!isScanning) _getVramUsage();
                    },
                    isScanning: isScanning,
                    tooltip: 'Estimate VRAM',
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Text(
                      '${modVramInfo.length} mods scanned',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                  Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(left: 32.0),
                    child: Card.outlined(
                      child: SizedBox(
                        width: 300,
                        child: GraphTypeSelector(
                            onGraphTypeChanged: (GraphType type) {
                          setState(() {
                            graphType = type;
                          });
                        }),
                      ),
                    ),
                  ),
                ],
              ),
              if (modVramInfo.isNotEmpty)
                Expanded(
                  child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                          child: switch (graphType) {
                        GraphType.pie =>
                          VramPieChart(modVramInfo: sortedModData),
                        GraphType.bar =>
                          VramBarChart(modVramInfo: sortedModData),
                      })),
                ),
              // ElevatedButton(
              //   onPressed: () async {
              //     Squadron.setId('HELLO_WORLD');
              //     Squadron.logLevel = SquadronLogLevel.config;
              //     Squadron.setLogger(ConsoleSquadronLogger());
              //
              //     final worker = ReadImageHeadersWorker();
              //     var path =
              //         "C:/Program Files (x86)/Fractal Softworks/Starsector-0.97a/mods/persean-chronicles/graphics/telos/ships/telos_avalok.png";
              //     Squadron.info(await worker.readGeneric(path));
              //     Squadron.info(await worker.readPng(path));
              //   },
              //   child: const Text('Test'),
              // )
            ],
          ),
        ),
      ),
    );
  }
}
