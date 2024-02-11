import 'dart:io';

import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:squadron/squadron.dart';
import 'package:vram_estimator_flutter/extensions.dart';
import 'package:vram_estimator_flutter/image_reader.dart';
import 'package:vram_estimator_flutter/models/enabled_mods.dart';
import 'package:vram_estimator_flutter/util.dart';
import 'package:vram_estimator_flutter/vram_checker.dart';
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
  int _counter = 0;

  late SharedPreferences _prefs;
  Directory? gamePath = defaultGamePath();
  Directory? gameFiles;
  File? vanillaRulesCsv;
  Directory? modsFolder;
  List<File> modRulesCsvs = [];
  final gamePathTextController = TextEditingController();
  String? pathError;
  List<Mod>? modVramInfo;

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
      debugOut: print,
      verboseOut: print,
    ).check();

    setState(() {
      modVramInfo = info;
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
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
          Text(widget.subtitle, style: Theme.of(context).textTheme.bodyMedium)
        ]),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (modVramInfo != null)
              SizedBox(
                  width: 450,
                  height: 450,
                  child: VramPieChart(modVramInfo: modVramInfo!)),
            FloatingActionButton(
              onPressed: _getVramUsage,
              tooltip: 'Estimate VRAM',
              child: const Icon(Icons.refresh),
            ),
            Text(
              '${modVramInfo?.length ?? 0} mods scanned',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            ElevatedButton(
              onPressed: () async {
                Squadron.setId('HELLO_WORLD');
                Squadron.logLevel = SquadronLogLevel.config;
                Squadron.setLogger(ConsoleSquadronLogger());

                final worker = ReadImageHeadersWorker();
                var path =
                    "C:/Program Files (x86)/Fractal Softworks/Starsector-0.97a/mods/persean-chronicles/graphics/telos/ships/telos_avalok.png";
                Squadron.info(await worker.readGeneric(path));
                Squadron.info(await worker.readPng(path));
              },
              child: const Text('Test'),
            )
          ],
        ),
      ),
    );
  }
}

class VramPieChart extends StatefulWidget {
  final List<Mod> modVramInfo;

  const VramPieChart({super.key, required this.modVramInfo});

  @override
  State createState() => VramPieChartState(modVramInfo: modVramInfo);
}

class VramPieChartState extends State {
  final List<Mod> modVramInfo;
  int touchedIndex = -1;

  VramPieChartState({required this.modVramInfo});

  List<PieChartSectionData> createSections(BuildContext context) {
    return modVramInfo
        .where((element) => element.totalBytesForMod > 0)
        .map((mod) {
      final isTouched = false; //i == touchedIndex;
      final fontSize = isTouched ? 25.0 : 12.0;
      final radius = isTouched ? 60.0 : 50.0;
      const shadows = [Shadow(color: Colors.black, blurRadius: 2)];
      return PieChartSectionData(
        color: stringToColor(mod.info.id).createMaterialColor().shade700,
        value: mod.totalBytesForMod.toDouble(),
        title: "${mod.info.name}\n${mod.totalBytesForMod.bytesAsReadableMB()}",
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          // color: AppColors.mainTextColor1,
          shadows: shadows,
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.3,
      child: Row(
        children: <Widget>[
          const SizedBox(
            height: 18,
          ),
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          touchedIndex = -1;
                          return;
                        }
                        touchedIndex = pieTouchResponse
                            .touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(
                    show: false,
                  ),
                  sectionsSpace: 1,
                  // centerSpaceRadius: 130,
                  sections: createSections(context),
                ),
              ),
            ),
          ),
          // const Column(
          //   mainAxisAlignment: MainAxisAlignment.end,
          //   crossAxisAlignment: CrossAxisAlignment.start,
          //   children: <Widget>[
          //     Indicator(
          //       color: AppColors.contentColorBlue,
          //       text: 'First',
          //       isSquare: true,
          //     ),
          //     SizedBox(
          //       height: 4,
          //     ),
          //     Indicator(
          //       color: AppColors.contentColorYellow,
          //       text: 'Second',
          //       isSquare: true,
          //     ),
          //     SizedBox(
          //       height: 4,
          //     ),
          //     Indicator(
          //       color: AppColors.contentColorPurple,
          //       text: 'Third',
          //       isSquare: true,
          //     ),
          //     SizedBox(
          //       height: 4,
          //     ),
          //     Indicator(
          //       color: AppColors.contentColorGreen,
          //       text: 'Fourth',
          //       isSquare: true,
          //     ),
          //     SizedBox(
          //       height: 18,
          //     ),
          //   ],
          // ),
          const SizedBox(
            width: 28,
          ),
        ],
      ),
    );
  }
}
