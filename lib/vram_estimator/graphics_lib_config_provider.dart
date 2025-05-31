import 'dart:io';

import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:trios/models/mod.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/vram_estimator/models/graphics_lib_config.dart';
import 'package:trios/vram_estimator/models/graphics_lib_lunaconfig.dart';

ModVariant? _previousGraphicsLibVariant;
ModVariant? _previousLunalibVariant;
GraphicsLibConfig? _prevState;

final graphicsLibConfigProvider = Provider<GraphicsLibConfig?>((ref) {
  final mods = ref.watch(AppState.mods);
  final newState = _buildNewState(mods, ref);
  _prevState = newState;
  return newState;
});

// Rebuilds the GraphicsLibConfig only if GraphicsLib or LunaLib mod variants change.
GraphicsLibConfig? _buildNewState(List<Mod> mods, Ref<GraphicsLibConfig?> ref) {
  final graphicsLib = mods
      .firstWhereOrNull((element) => element.id == Constants.graphicsLibId)
      ?.findFirstEnabled;

  if (graphicsLib == null) {
    _previousGraphicsLibVariant = graphicsLib;
    return null;
  }

  final lunalib = mods
      .firstWhereOrNull((element) => element.id == Constants.lunalibId)
      ?.findFirstEnabled;

  // Don't evaluate if GraphicsLib version and LunaLib didn't change.
  // Avoids re-reading GRAPHICS_OPTIONS.ini more than once per app run unless needed.
  if (graphicsLib == _previousGraphicsLibVariant &&
      _previousLunalibVariant == lunalib) {
    return _prevState;
  }

  _previousGraphicsLibVariant = graphicsLib;
  _previousLunalibVariant = lunalib;
  GraphicsLibConfig graphicsLibConfig = GraphicsLibConfig.disabled;

  if (lunalib != null) {
    final gameFolder = ref.watch(AppState.gameFolder).valueOrNull;
    final lunalibGraphicsLibConfigFile = gameFolder
        ?.resolve(
          p.join(
            Constants.savesCommonFolderName,
            "LunaSettings",
            "${graphicsLib.modInfo.id}.json.data",
          ),
        )
        .toFile();

    if (lunalibGraphicsLibConfigFile != null &&
        lunalibGraphicsLibConfigFile.existsSync()) {
      final config = GraphicsLibLunaConfigMapper.fromJson(
        lunalibGraphicsLibConfigFile.readAsStringSync().fixJson(),
      );
      Fimber.d("Lunalib config for GraphicsLib: $config");

      graphicsLibConfig = config.toGraphicsLibConfig();
    }
  } else {
    File configFile = graphicsLib.modFolder
        .resolve("GRAPHICS_OPTIONS.ini")
        .toFile();
    if (!configFile.existsSync()) {
      Fimber.d("GraphicsLib config file not found: ${configFile.path}");
      return null;
    }

    graphicsLibConfig = GraphicsLibConfigMapper.fromJson(
      configFile.readAsStringSync().fixJson(),
    );
    Fimber.d("GraphicsLib config: $graphicsLibConfig");
  }

  if (!graphicsLibConfig.areAnyEffectsEnabled) {
    return GraphicsLibConfig.disabled;
  } else {
    return graphicsLibConfig;
  }
}
