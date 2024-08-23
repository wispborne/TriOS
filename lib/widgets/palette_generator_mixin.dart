import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';

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
      final icon = Image.file(iconPath!.toFile());
      paletteGenerator = await PaletteGenerator.fromImageProvider(icon.image);
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
