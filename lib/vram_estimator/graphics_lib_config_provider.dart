import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/vram_estimator/models/graphics_lib_config.dart';

final graphicsLibConfigProvider = Provider<GraphicsLibConfig?>((ref) {
  final mods = ref.watch(AppState.mods);
  final graphicsLib =
      mods
          .firstWhereOrNull((element) => element.id == Constants.graphicsLibId)
          ?.findFirstEnabled;

  if (graphicsLib == null) {
    return null;
  }

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
});
