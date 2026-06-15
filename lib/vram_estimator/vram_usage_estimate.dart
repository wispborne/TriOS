import 'package:collection/collection.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/vram_estimator/models/graphics_lib_config.dart';
import 'package:trios/vram_estimator/models/vram_checker_models.dart';

/// Estimated VRAM use for a set of mods, broken into the three contributors the
/// app reports everywhere: the mods' own (non-GraphicsLib) images, the
/// GraphicsLib contribution, and the vanilla baseline.
///
/// This is the single source of truth shared by the VRAM Estimator page bar,
/// the scan progress panel cohorts, and (eventually) the Mods page overlay, so
/// they can't disagree.
class VramUsageEstimate {
  final int totalMods;
  final int scannedCount;
  final int modsBytes;
  final int modsImageCount;
  final int gfxBytes;
  final int gfxImageCount;

  /// True when [gfxBytes] is the flat heuristic (GraphicsLib effects on but not
  /// preloading all maps) rather than a real per-image sum.
  final bool isApproxGfx;
  final int vanillaBytes;

  const VramUsageEstimate({
    required this.totalMods,
    required this.scannedCount,
    required this.modsBytes,
    required this.modsImageCount,
    required this.gfxBytes,
    required this.gfxImageCount,
    required this.isApproxGfx,
    required this.vanillaBytes,
  });

  int get unscannedCount => totalMods - scannedCount;

  int get totalBytes => modsBytes + gfxBytes + vanillaBytes;

  bool get hasNoMods => totalMods == 0;

  bool get hasNoScans => totalMods > 0 && scannedCount == 0;

  bool get hasData => scannedCount > 0;
}

/// Flat estimate used when GraphicsLib effects are enabled but "preload all
/// maps" is off, so we can't enumerate exactly which maps load.
const _approxGfxBytes = 200000000;

/// Computes [VramUsageEstimate] for [mods], looking up each mod's
/// enabled-or-highest variant in [vramMap].
VramUsageEstimate estimateVramUsageForMods(
  List<Mod> mods,
  Map<String, VramMod> vramMap, {
  required GraphicsLibConfig? graphicsLibConfig,
  required int vanillaBytes,
}) {
  final variants = mods
      .map((m) => m.findFirstEnabledOrHighestVersion)
      .nonNulls
      .toList();
  final estimates = variants.map((v) => vramMap[v.smolId]).nonNulls.toList();

  final modsBytes = estimates
      .map((e) => e.imagesNotIncludingGraphicsLib().sum())
      .sum;
  final modsImageCount = estimates
      .map((e) => e.imagesNotIncludingGraphicsLib().length)
      .sum;

  final preloadAll = graphicsLibConfig?.preloadAllMaps == true;
  int gfxBytes;
  int gfxImageCount;
  bool isApproxGfx;
  if (preloadAll) {
    final gfxBytesList = estimates
        .expand(
          (mod) => List.generate(
            mod.images.length,
            (i) => ModImageView(i, mod.images),
          ),
        )
        .where(
          (view) =>
              view.graphicsLibType != null &&
              view.isUsedBasedOnGraphicsLibConfig(graphicsLibConfig),
        )
        .map((view) => view.bytesUsed)
        .toList();
    gfxBytes = gfxBytesList.sum();
    gfxImageCount = gfxBytesList.length;
    isApproxGfx = false;
  } else if (graphicsLibConfig != null &&
      graphicsLibConfig.areAnyEffectsEnabled) {
    gfxBytes = _approxGfxBytes;
    gfxImageCount = 0;
    isApproxGfx = true;
  } else {
    gfxBytes = 0;
    gfxImageCount = 0;
    isApproxGfx = false;
  }

  return VramUsageEstimate(
    totalMods: mods.length,
    scannedCount: estimates.length,
    modsBytes: modsBytes.toInt(),
    modsImageCount: modsImageCount.toInt(),
    gfxBytes: gfxBytes,
    gfxImageCount: gfxImageCount,
    isApproxGfx: isApproxGfx,
    vanillaBytes: vanillaBytes,
  );
}
