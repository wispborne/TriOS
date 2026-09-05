import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/ship_viewer/engine_styles_manager.dart';
import 'package:trios/ship_viewer/hull_styles_manager.dart';
import 'package:trios/ship_viewer/ship_manager.dart';
import 'package:trios/utils/decoded_image_cache.dart';
import 'package:trios/viewer_cache/graphics_index_manager.dart';

typedef RefreshShipViewer = void Function();

/// Reloads the files used by the Ships page.
final refreshShipViewerProvider = Provider<RefreshShipViewer>((ref) {
  return () {
    // Refresh means "look at every file again", so skip no sources and drop
    // decoded images whose files may have changed in place.
    ref.read(shipSourcesProvider.notifier).requestFullParse();
    ref.read(graphicsIndexProvider.notifier).requestFullParse();
    clearDecodedImageCache();

    ref.invalidate(shipSourcesProvider);
    ref.invalidate(graphicsIndexProvider);
    ref.invalidate(engineStylesProvider);
    ref.invalidate(engineGlowSpritesProvider);
    ref.invalidate(hullStyleShieldColorsProvider);
    ref.invalidate(shieldSpritesProvider);
    ref.invalidate(shieldTextureOverridesProvider);
  };
});
