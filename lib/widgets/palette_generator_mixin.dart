import 'package:material_ui/material_ui.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';

/// How wide the icon is decoded when picking colors out of it.
const _paletteSampleWidth = 64;

mixin PaletteGeneratorMixin<T extends StatefulWidget> on State<T> {
  PaletteGenerator? paletteGenerator;

  // Shhh
  // Will not update if mod changes the icon during runtime.
  static final Map<String, PaletteGenerator?> _cachedThemes = {};

  @override
  void initState() {
    super.initState();
    _generatePalette();
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    _generatePalette();
  }

  Future<void> _generatePalette() async {
    final iconPath = getIconPath();

    if (_cachedThemes.containsKey(iconPath)) {
      paletteGenerator = _cachedThemes[iconPath];
    } else if (iconPath?.isNotEmpty == true) {
      // Decode the icon small. We only want the handful of colors in it, and
      // a full-size decode of every mod icon stays in Flutter's image cache
      // afterwards. 64px gives the same colors for a fraction of the memory.
      final icon = ResizeImage(
        FileImage(iconPath!.toFile()),
        width: _paletteSampleWidth,
        allowUpscaling: false,
      );
      paletteGenerator = await PaletteGenerator.fromImageProvider(icon);
      Fimber.v(() => "Generated palette for $iconPath");
      _cachedThemes[iconPath] = paletteGenerator;
    } else {
      paletteGenerator = null;
    }

    if (!mounted) return;

    setState(() {});
  }

  String? getIconPath();
}
