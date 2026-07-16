import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:trios/faction_viewer/spawn_weights/spawn_weight_calculator.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/mod_icon.dart';
import 'package:trios/widgets/moving_tooltip.dart';

String formatShare(double share) => '${(share * 100).round()}%';

/// Explains what the "% from the base game" number means, in one tooltip.
String vanillaShareTooltip(FactionSpawnSummary summary) {
  final share = summary.vanillaShare;
  if (summary.totalWeight <= 0) {
    return 'This faction has no warships to spawn.';
  }
  if (share == null) {
    return 'Still reading the mods. The split will show once that finishes.';
  }
  final modCount = summary.topMods.length;
  return 'When the game builds a fleet for this faction, '
      '${formatShare(share)} of the chance to pick each ship comes from the '
      'base game. The rest comes from '
      '${modCount == 1 ? '1 mod' : '$modCount mods'}.\n\n'
      'This is a share of spawn chance, not a share of ships.';
}

/// Icon file path for each enabled mod, keyed by the mod's display name — the
/// same name used as an attribution source in the spawn-weight summary.
final _modIconPathsProvider = Provider<Map<String, String>>((ref) {
  final map = <String, String>{};
  for (final mod in ref.watch(AppState.mods)) {
    final variant = mod.findFirstEnabledOrHighestVersion;
    final name = variant?.modInfo.nameOrId;
    final iconPath = variant?.iconFilePath;
    if (name != null && iconPath != null && iconPath.isNotEmpty) {
      map[name] = iconPath;
    }
  }
  return map;
});

/// The main colour of a mod's icon, so a mod's slice matches its icon. Cached
/// per icon file (icons don't change at runtime). Null while it loads or if the
/// icon can't be read (e.g. a `.ico`, which Flutter can't decode).
final _modIconColorProvider = FutureProvider.family<Color?, String>((
  ref,
  iconPath,
) async {
  try {
    final palette = await PaletteGenerator.fromImageProvider(
      Image.file(iconPath.toFile()).image,
      maximumColorCount: 8,
    );
    final color = palette.dominantColor?.color ?? palette.vibrantColor?.color;
    if (color == null) return null;
    // Keep it readable on the card: same hue, lightness nudged into a visible
    // band so a very dark or very pale icon still shows as a coloured slice.
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness(hsl.lightness.clamp(0.4, 0.75)).toColor();
  } catch (_) {
    return null;
  }
});

/// One coloured slice of the bar: a contributor and how much of the faction's
/// spawn weight it owns.
class _BarSegment {
  final String label;
  final double share;
  final Color color;
  final String tooltip;

  /// The mod's icon, shown in the tooltip. Null for vanilla, the "still
  /// reading" slice, or a mod with no icon.
  final String? iconPath;

  const _BarSegment({
    required this.label,
    required this.share,
    required this.color,
    required this.tooltip,
    this.iconPath,
  });
}

/// A stacked bar of everyone who contributes to a faction's warship spawns:
/// the base game plus each mod, biggest slice first. Each mod slice is coloured
/// from its icon; each slice has a tooltip with the contributor and its share.
class VanillaShareBar extends ConsumerWidget {
  final FactionSpawnSummary summary;

  /// Height of the bar. The card uses a thinner one than the dialog.
  final double height;

  /// Fallback colour for a mod with no readable icon: a shade of the faction's
  /// own colour.
  final Color factionColor;

  /// When set, tooltips read "`mod`: 27% of `faction`'s spawn weight".
  final String? factionName;

  /// Whether to show the "Vanilla: X%" headline above the bar.
  final bool showLabel;

  const VanillaShareBar({
    super.key,
    required this.summary,
    required this.factionColor,
    this.height = 6,
    this.factionName,
    this.showLabel = false,
  });

  /// A shade of the faction colour, used only when a mod has no icon to pull a
  /// colour from: same hue, stepped light-to-dark so fallbacks stay distinct.
  static Color _modShade(Color factionColor, int index, int count) {
    final hsl = HSLColor.fromColor(factionColor);
    if (count <= 1) {
      return hsl.withLightness(hsl.lightness.clamp(0.4, 0.65)).toColor();
    }
    final t = index / (count - 1); // 0 = biggest, 1 = smallest
    return hsl.withLightness((0.66 - t * 0.38).clamp(0.0, 1.0)).toColor();
  }

  String _tooltipFor(String name, double share) {
    final pct = formatShare(share);
    return factionName == null
        ? '$name: $pct'
        : "$name: $pct of $factionName's spawn weight";
  }

  /// Wraps a slice in its tooltip: a framed icon + text when the mod has an
  /// icon, otherwise plain text.
  Widget _sliceTooltip(ThemeData theme, _BarSegment segment, Widget child) {
    final iconPath = segment.iconPath;
    if (iconPath == null) {
      return MovingTooltipWidget.text(message: segment.tooltip, child: child);
    }
    return MovingTooltipWidget.framed(
      tooltipWidget: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            ModIcon(iconPath, size: 24,),
            Flexible(
              child: Text(segment.tooltip, style: theme.textTheme.bodySmall),
            ),
          ],
        ),
      ),
      child: child,
    );
  }

  List<_BarSegment> _segments(
    ThemeData theme,
    WidgetRef ref,
    Map<String, String> iconPaths,
  ) {
    final total = summary.totalWeight;
    if (total <= 0) return const [];

    final segments = <_BarSegment>[];

    final vanillaWeight = summary.vanillaWeight;
    if (vanillaWeight > 0) {
      final share = vanillaWeight / total;
      segments.add(
        _BarSegment(
          label: 'Vanilla',
          share: share,
          color: theme.colorScheme.onSurface,
          tooltip: _tooltipFor('Vanilla', share),
        ),
      );
    }

    final mods = summary.topMods; // already biggest-first, vanilla excluded
    for (var i = 0; i < mods.length; i++) {
      final name = mods[i].key;
      final share = mods[i].value / total;
      final iconPath = iconPaths[name];
      final iconColor = iconPath == null
          ? null
          : ref.watch(_modIconColorProvider(iconPath)).value;
      segments.add(
        _BarSegment(
          label: name,
          share: share,
          color: iconColor ?? _modShade(factionColor, i, mods.length),
          tooltip: _tooltipFor(name, share),
          iconPath: iconPath,
        ),
      );
    }

    if (summary.unknownWeight > 0) {
      final share = summary.unknownWeight / total;
      segments.add(
        _BarSegment(
          label: 'Still reading mods',
          share: share,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
          tooltip: "Still reading the mods — this part isn't sorted yet.",
        ),
      );
    }

    return segments;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final share = summary.vanillaShare;
    final segments = _segments(theme, ref, ref.watch(_modIconPathsProvider));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 2,
      children: [
        if (showLabel)
          MovingTooltipWidget.text(
            message: vanillaShareTooltip(summary),
            child: Text(
              share == null ? 'Vanilla: —' : 'Vanilla: ${formatShare(share)}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontFeatures: [const FontFeature.tabularFigures()],
              ),
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: segments.isEmpty
                ? ColoredBox(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
                  )
                : Row(
                    // Stretch so each slice fills the bar's full height.
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 1,
                    children: [
                      for (final segment in segments)
                        Expanded(
                          // Scale to ints for flex; clamp so even a tiny
                          // contributor stays present (with its tooltip).
                          flex: (segment.share * 10000).round().clamp(
                            1,
                            1 << 30,
                          ),
                          // The tooltip lays its child out with loosened
                          // constraints, so a bare ColoredBox would collapse to
                          // nothing — expand it to fill the slice.
                          child: _sliceTooltip(
                            theme,
                            segment,
                            SizedBox.expand(
                              child: ColoredBox(color: segment.color),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
