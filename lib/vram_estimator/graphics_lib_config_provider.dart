import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/vram_estimator/models/graphics_lib_config.dart';

ModVariant? _previousGraphicsLibState;
GraphicsLibConfig? _prevState;

final graphicsLibConfigProvider = Provider<GraphicsLibConfig?>((ref) {
  final mods = ref.watch(AppState.mods);
  final newState = _buildNewState(mods);
  _prevState = newState;
  return newState;
});

GraphicsLibConfig? _buildNewState(List<Mod> mods) {
  final graphicsLib =
      mods
          .firstWhereOrNull((element) => element.id == Constants.graphicsLibId)
          ?.findFirstEnabled;

  if (graphicsLib == null) {
    _previousGraphicsLibState = graphicsLib;
    return null;
  }

  // Don't evaluate if GraphicsLib didn't change.
  // Avoids re-reading GRAPHICS_OPTIONS.ini when not necessary.
  if (graphicsLib == _previousGraphicsLibState) {
    return _prevState;
  }

  _previousGraphicsLibState = graphicsLib;

  final configFile =
      graphicsLib.modFolder.resolve("GRAPHICS_OPTIONS.ini").toFile();
  if (!configFile.existsSync()) {
    Fimber.d("Graphics lib config file not found: ${configFile.path}");
    return null;
  }

  final config = GraphicsLibConfigMapper.fromJson(
    configFile.readAsStringSync().fixJson(),
  );
  Fimber.d("Graphics lib config: $config");
  if (!config.areAnyEffectsEnabled) {
    return GraphicsLibConfig.disabled;
  } else {
    return config;
  }
}
