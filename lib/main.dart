import 'dart:io';

import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vram_estimator_flutter/models/enabled_mods.dart';
import 'package:vram_estimator_flutter/util.dart';
import 'package:vram_estimator_flutter/vram_checker.dart';

import 'main.mapper.g.dart' show initializeJsonMapper;
import 'models/graphics_lib_config.dart';

void main() {
  initializeJsonMapper();
  runApp(const ProviderScope(child: MyApp()));
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
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  late SharedPreferences _prefs;
  Directory? gamePath = defaultGamePath();
  Directory? gameFiles = null;
  File? vanillaRulesCsv = null;
  Directory? modsFolder = null;
  List<File> modRulesCsvs = [];
  final gamePathTextController = TextEditingController();
  String? pathError;

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

  void _incrementCounter() {
    VramChecker(
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
      _counter++;
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
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
