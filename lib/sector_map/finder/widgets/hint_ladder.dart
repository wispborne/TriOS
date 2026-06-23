import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/sector_map/finder/finder_criteria.dart';
import 'package:trios/sector_map/finder/finder_engine.dart';
import 'package:trios/sector_map/models/sector.dart';
import 'package:trios/sector_map/sector_map_controller.dart';
import 'package:trios/sector_map/widgets/sector_map_painter.dart';
import 'package:trios/widgets/moving_tooltip.dart';

/// The escalating reveal: a single Hint button that steps from "somewhere in
/// these N constellations" down to the exact system, then hands off to the
/// atlas. Positions stay hidden until the player asks for them.
class HintLadder extends ConsumerWidget {
  final Sector sector;
  final FinderEngine engine;

  /// Reveal steps. At [maxLevel] the exact system is shown in the finder; the
  /// optional final "Show on the map" button then hands off to the atlas.
  static const int maxLevel = 4;

  /// How many constellations the first rung shows (true one + decoys).
  static const int firstRungBreadth = 5;

  const HintLadder({super.key, required this.sector, required this.engine});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(sectorMapControllerProvider);
    final controller = ref.read(sectorMapControllerProvider.notifier);

    final matches = engine.filter(state.criteria);

    if (matches.isEmpty) {
      return _ZeroMatchHelp(engine: engine, criteria: state.criteria);
    }

    final matchIndex = state.matchIndex % matches.length;
    final match = matches[matchIndex];
    final level = state.revealLevel;

    final reveal = _revealSets(match, level);

    return Stack(
      children: [
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              final transform = _fitTransform(size);
              final sigma = switch (level) {
                <= 1 => 7.0,
                2 => 4.0,
                3 => 2.0,
                _ => 0.0,
              };
              final painter = CustomPaint(
                size: size,
                painter: _RevealPainter(
                  sector: sector,
                  transform: transform,
                  revealedConstellationIds: reveal.constellationIds,
                  exactSystem: level >= 4 ? match.system : null,
                  hullColor: theme.colorScheme.primary,
                  accentColor: theme.colorScheme.secondary,
                  labelColor: theme.colorScheme.onSurface,
                  showConstellationLabel: level >= 3,
                ),
              );
              return sigma > 0
                  ? ImageFiltered(
                      imageFilter: ui.ImageFilter.blur(
                        sigmaX: sigma,
                        sigmaY: sigma,
                      ),
                      child: painter,
                    )
                  : painter;
            },
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: _HintControls(
            theme: theme,
            level: level,
            matchOrdinal: matchIndex + 1,
            totalMatches: matches.length,
            match: match,
            revealText: _revealText(match, level, reveal),
            onReveal: () => controller.bumpReveal(maxLevel),
            onShowOnMap: () => controller
              ..setMode(SectorMapMode.atlas)
              ..focusSystem(match.system.id),
            onNextMatch: () => controller.nextMatch(matches.length),
            onReset: controller.resetReveal,
          ),
        ),
      ],
    );
  }

  ({Set<String> constellationIds}) _revealSets(ScoredSystem match, int level) {
    final conId = match.system.constellationId;
    if (level <= 0 || conId == null) {
      return (constellationIds: const <String>{});
    }
    final breadth = switch (level) {
      1 => firstRungBreadth,
      2 => 2,
      _ => 1,
    };
    return (constellationIds: _nearestConstellations(conId, breadth));
  }

  /// The target constellation plus its nearest neighbours, as decoys.
  Set<String> _nearestConstellations(String targetId, int count) {
    final centroids = _constellationCentroids();
    final target = centroids[targetId];
    if (target == null) return {targetId};
    final others = centroids.entries.where((e) => e.key != targetId).toList()
      ..sort(
        (a, b) => (a.value - target).distanceSquared.compareTo(
          (b.value - target).distanceSquared,
        ),
      );
    return {
      targetId,
      for (final e in others.take(count - 1)) e.key,
    };
  }

  Map<String, Offset> _constellationCentroids() {
    final sums = <String, Offset>{};
    final counts = <String, int>{};
    for (final s in sector.systems) {
      final id = s.constellationId;
      if (id == null) continue;
      sums[id] = (sums[id] ?? Offset.zero) + s.position;
      counts[id] = (counts[id] ?? 0) + 1;
    }
    return {
      for (final id in sums.keys) id: sums[id]! / counts[id]!.toDouble(),
    };
  }

  String _revealText(
    ScoredSystem match,
    int level,
    ({Set<String> constellationIds}) reveal,
  ) {
    if (level <= 0) {
      return 'Tune the knobs until the count is small, then reveal a hint to '
          'your best match.';
    }
    final conName = match.system.constellationId == null
        ? null
        : _conName(match.system.constellationId!);
    return switch (level) {
      1 => 'Somewhere in one of these ${reveal.constellationIds.length} '
          'constellations.',
      2 => 'Narrowed to these ${reveal.constellationIds.length} '
          'constellations.',
      3 => conName == null
          ? 'In an unnamed region of deep space.'
          : 'In the $conName constellation.',
      _ => '${match.system.name}'
          '${conName == null ? '' : ' — $conName'} '
          '(hazard from ${(_minHazardPct(match.system))}%).',
    };
  }

  int _minHazardPct(SectorSystem s) {
    if (s.planets.isEmpty) return 100;
    final min = s.planets.map((p) => p.hazardRating).reduce(math.min);
    return (min * 100).round();
  }

  String _conName(String id) => sector.constellations
      .firstWhere(
        (c) => c.id == id,
        orElse: () => const SectorConstellation(id: '', name: ''),
      )
      .name;

  SectorViewTransform _fitTransform(Size size) {
    final systems = sector.systems;
    if (systems.isEmpty || size.isEmpty) {
      return const SectorViewTransform(Offset.zero, 0.01);
    }
    var minX = double.infinity,
        minY = double.infinity,
        maxX = -double.infinity,
        maxY = -double.infinity;
    for (final s in systems) {
      minX = math.min(minX, s.x);
      maxX = math.max(maxX, s.x);
      minY = math.min(minY, s.y);
      maxY = math.max(maxY, s.y);
    }
    final spanX = math.max(1.0, maxX - minX);
    final spanY = math.max(1.0, maxY - minY);
    final scale = math.min(size.width / spanX, size.height / spanY) * 0.85;
    final cx = (minX + maxX) / 2;
    final cy = (minY + maxY) / 2;
    return SectorViewTransform(
      Offset(size.width / 2 - cx * scale, size.height / 2 + cy * scale),
      scale,
    );
  }
}

class _HintControls extends StatelessWidget {
  final ThemeData theme;
  final int level;
  final int matchOrdinal;
  final int totalMatches;
  final ScoredSystem match;
  final String revealText;
  final VoidCallback onReveal;
  final VoidCallback onShowOnMap;
  final VoidCallback onNextMatch;
  final VoidCallback onReset;

  const _HintControls({
    required this.theme,
    required this.level,
    required this.matchOrdinal,
    required this.totalMatches,
    required this.match,
    required this.revealText,
    required this.onReveal,
    required this.onShowOnMap,
    required this.onNextMatch,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final atMax = level >= HintLadder.maxLevel;
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Text(
              '$totalMatches systems fit'
              '${totalMatches > 1 ? '  •  best match $matchOrdinal of $totalMatches' : ''}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            Text(revealText, style: theme.textTheme.titleMedium),
            Row(
              spacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: atMax ? onShowOnMap : onReveal,
                  icon: Icon(atMax ? Icons.public : Icons.visibility, size: 18),
                  label: Text(
                    level <= 0
                        ? 'Reveal a hint'
                        : atMax
                        ? 'Show on the map'
                        : 'Narrow it down',
                  ),
                ),
                if (totalMatches > 1)
                  MovingTooltipWidget.text(
                    message: 'Reveal the next-best match instead',
                    child: OutlinedButton.icon(
                      onPressed: onNextMatch,
                      icon: const Icon(Icons.skip_next, size: 18),
                      label: const Text('Different match'),
                    ),
                  ),
                if (level > 0)
                  TextButton(onPressed: onReset, child: const Text('Reset')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ZeroMatchHelp extends StatelessWidget {
  final FinderEngine engine;
  final FinderCriteria criteria;

  const _ZeroMatchHelp({required this.engine, required this.criteria});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hints = engine.bottleneck(criteria);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Text('No systems fit', style: theme.textTheme.titleMedium),
                if (hints.isEmpty)
                  Text(
                    'Loosen the knobs to find some matches.',
                    style: theme.textTheme.bodyMedium,
                  )
                else ...[
                  Text(
                    'Relaxing one of these would help:',
                    style: theme.textTheme.bodyMedium,
                  ),
                  for (final h in hints.take(4))
                    Text(
                      '• Turn off ${h.constraint} → ${h.countIfRemoved} fit',
                      style: theme.textTheme.bodyMedium,
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints only the revealed constellation hulls (plus the exact system dot at
/// the final rung). Everything else is left dark so nothing leaks.
class _RevealPainter extends CustomPainter {
  final Sector sector;
  final SectorViewTransform transform;
  final Set<String> revealedConstellationIds;
  final SectorSystem? exactSystem;
  final Color hullColor;
  final Color accentColor;
  final Color labelColor;
  final bool showConstellationLabel;

  _RevealPainter({
    required this.sector,
    required this.transform,
    required this.revealedConstellationIds,
    required this.exactSystem,
    required this.hullColor,
    required this.accentColor,
    required this.labelColor,
    required this.showConstellationLabel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final byCon = <String, List<Offset>>{};
    for (final s in sector.systems) {
      final id = s.constellationId;
      if (id == null || !revealedConstellationIds.contains(id)) continue;
      (byCon[id] ??= []).add(transform.worldToScreen(s.position));
    }

    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = hullColor.withValues(alpha: 0.10);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = hullColor.withValues(alpha: 0.5);

    byCon.forEach((id, pts) {
      final centroid = pts.reduce((a, b) => a + b) / pts.length.toDouble();
      if (pts.length >= 3) {
        final hull = SectorMapPainter.convexHull(pts);
        final path = Path()..addPolygon(hull, true);
        canvas.drawPath(path, fill);
        canvas.drawPath(path, stroke);
      } else {
        canvas.drawCircle(centroid, 40, fill);
        canvas.drawCircle(centroid, 40, stroke);
      }
      // faint dots for member systems (no labels — keeps it vague)
      for (final p in pts) {
        canvas.drawCircle(
          p,
          2.0,
          Paint()..color = labelColor.withValues(alpha: 0.4),
        );
      }
      if (showConstellationLabel) {
        _drawLabel(canvas, _conName(id), centroid, hullColor, center: true);
      }
    });

    // Final rung: the exact system, lit and labelled.
    final exact = exactSystem;
    if (exact != null) {
      final c = transform.worldToScreen(exact.position);
      canvas.drawCircle(c, 5, Paint()..color = accentColor);
      canvas.drawCircle(
        c,
        10,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = accentColor.withValues(alpha: 0.8),
      );
      _drawLabel(canvas, exact.name, c + const Offset(12, -8), labelColor);
    }
  }

  String _conName(String id) => sector.constellations
      .firstWhere(
        (c) => c.id == id,
        orElse: () => const SectorConstellation(id: '', name: ''),
      )
      .name;

  void _drawLabel(
    Canvas canvas,
    String text,
    Offset at,
    Color color, {
    bool center = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          shadows: const [Shadow(color: Colors.black, blurRadius: 3)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final pos = center ? at - Offset(tp.width / 2, tp.height / 2) : at;
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _RevealPainter old) =>
      old.revealedConstellationIds != revealedConstellationIds ||
      old.exactSystem?.id != exactSystem?.id ||
      old.transform.offset != transform.offset ||
      old.transform.scale != transform.scale ||
      old.showConstellationLabel != showConstellationLabel;
}
