import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:trios/sector_map/models/sector.dart';
import 'package:trios/sector_map/widgets/sector_map_painter.dart';
import 'package:trios/widgets/tooltip_frame.dart';

/// Interactive hyperspace overview: pan (drag), zoom (wheel/pinch), hover
/// tooltip, click-to-select. Pan/zoom/hover are local state for performance.
class SectorMapCanvas extends StatefulWidget {
  final Sector sector;
  final Map<String, Color> factionColors;
  final Color Function(String factionId) colorFor;
  final String Function(String factionId) nameFor;
  final Set<String> hiddenFactionIds;
  final String? selectedSystemId;

  /// Bumped by the controller to request recentering on [selectedSystemId].
  final int focusRequest;
  final ValueChanged<String?> onSelect;

  const SectorMapCanvas({
    super.key,
    required this.sector,
    required this.factionColors,
    required this.colorFor,
    required this.nameFor,
    required this.hiddenFactionIds,
    required this.selectedSystemId,
    required this.focusRequest,
    required this.onSelect,
  });

  @override
  State<SectorMapCanvas> createState() => _SectorMapCanvasState();
}

class _SectorMapCanvasState extends State<SectorMapCanvas> {
  Offset _offset = Offset.zero;
  double _scale = 0.01;
  bool _fitted = false;
  Size _viewport = Size.zero;

  String? _hoveredId;
  Offset _cursor = Offset.zero;

  // pan/zoom gesture scratch
  late Offset _startOffset;
  late double _startScale;
  late Offset _startFocal;

  static const double _hitThreshold = 14.0;
  static const double _minScale = 0.002;
  static const double _maxScale = 0.5;

  SectorViewTransform get _transform => SectorViewTransform(_offset, _scale);

  @override
  void didUpdateWidget(SectorMapCanvas old) {
    super.didUpdateWidget(old);
    if (!identical(widget.sector, old.sector)) {
      // new save loaded — refit on next layout
      _fitted = false;
      _hoveredId = null;
      return;
    }
    if (widget.focusRequest != old.focusRequest &&
        widget.selectedSystemId != null) {
      _focusOn(widget.selectedSystemId!);
    }
  }

  void _fit(Size size) {
    final systems = widget.sector.systems;
    if (systems.isEmpty) return;
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
    final scale =
        math.min(size.width / spanX, size.height / spanY) * 0.88;
    final cx = (minX + maxX) / 2;
    final cy = (minY + maxY) / 2;
    setState(() {
      _scale = scale.clamp(_minScale, _maxScale);
      _offset = Offset(
        size.width / 2 - cx * _scale,
        size.height / 2 + cy * _scale,
      );
      _fitted = true;
    });
  }

  void _focusOn(String systemId) {
    final s = widget.sector.systems
        .where((e) => e.id == systemId)
        .cast<SectorSystem?>()
        .firstWhere((e) => true, orElse: () => null);
    if (s == null || _viewport == Size.zero) return;
    final scale = math.max(_scale, 0.06).clamp(_minScale, _maxScale);
    setState(() {
      _scale = scale;
      _offset = Offset(
        _viewport.width / 2 - s.x * _scale,
        _viewport.height / 2 + s.y * _scale,
      );
    });
  }

  SectorSystem? _hitTest(Offset local) {
    SectorSystem? best;
    double bestDist = _hitThreshold;
    for (final s in widget.sector.systems) {
      final p = _transform.worldToScreen(s.position);
      final d = (p - local).distance;
      if (d < bestDist) {
        bestDist = d;
        best = s;
      }
    }
    return best;
  }

  void _onScroll(PointerScrollEvent e) {
    final factor = math.exp(-e.scrollDelta.dy * 0.0015);
    final newScale = (_scale * factor).clamp(_minScale, _maxScale);
    if (newScale == _scale) return;
    // keep the world point under the cursor fixed
    final world = _transform.screenToWorld(e.localPosition);
    setState(() {
      _scale = newScale;
      _offset = Offset(
        e.localPosition.dx - world.dx * newScale,
        e.localPosition.dy + world.dy * newScale,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        _viewport = size;
        if (!_fitted && size.width > 0 && size.height > 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_fitted) _fit(size);
          });
        }

        return Listener(
          onPointerSignal: (signal) {
            if (signal is PointerScrollEvent) _onScroll(signal);
          },
          child: MouseRegion(
            onHover: (e) {
              final hit = _hitTest(e.localPosition);
              if (hit?.id != _hoveredId || _hoveredId != null) {
                setState(() {
                  _hoveredId = hit?.id;
                  _cursor = e.localPosition;
                });
              }
            },
            onExit: (_) {
              if (_hoveredId != null) setState(() => _hoveredId = null);
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onScaleStart: (d) {
                _startOffset = _offset;
                _startScale = _scale;
                _startFocal = d.localFocalPoint;
              },
              onScaleUpdate: (d) {
                setState(() {
                  final newScale = (_startScale * d.scale).clamp(
                    _minScale,
                    _maxScale,
                  );
                  // translate by focal movement, then scale around focal point
                  final pannedOffset =
                      _startOffset + (d.localFocalPoint - _startFocal);
                  if (d.scale == 1.0) {
                    _offset = pannedOffset;
                  } else {
                    final t = SectorViewTransform(pannedOffset, _startScale);
                    final world = t.screenToWorld(d.localFocalPoint);
                    _offset = Offset(
                      d.localFocalPoint.dx - world.dx * newScale,
                      d.localFocalPoint.dy + world.dy * newScale,
                    );
                    _scale = newScale;
                  }
                });
              },
              onTapUp: (d) {
                final hit = _hitTest(d.localPosition);
                widget.onSelect(hit?.id);
              },
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: SectorMapPainter(
                        systems: widget.sector.systems,
                        constellations: widget.sector.constellations,
                        factionColors: widget.factionColors,
                        transform: _transform,
                        colorFor: widget.colorFor,
                        hiddenFactionIds: widget.hiddenFactionIds,
                        selectedSystemId: widget.selectedSystemId,
                        hoveredSystemId: _hoveredId,
                        playerLocation: widget.sector.playerLocation,
                        accentColor: theme.colorScheme.secondary,
                        labelColor: theme.colorScheme.onSurface,
                        hullColor: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  if (_hoveredId != null) _buildTooltip(context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTooltip(BuildContext context) {
    final s = widget.sector.systems.firstWhere((e) => e.id == _hoveredId);
    final theme = Theme.of(context);
    // position near cursor, clamped within the viewport
    const w = 220.0;
    final left = (_cursor.dx + 16)
        .clamp(0.0, math.max(0.0, _viewport.width - w))
        .toDouble();
    final top = (_cursor.dy + 12)
        .clamp(0.0, math.max(0.0, _viewport.height - 140))
        .toDouble();

    return Positioned(
      left: left,
      top: top,
      child: IgnorePointer(
        child: TooltipFrame(
          child: SizedBox(
            width: w,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  s.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  [
                    if (s.constellationId != null)
                      _conName(s.constellationId!),
                    s.type,
                  ].join(' • '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 4),
                if (s.markets.isEmpty)
                  Text(
                    'Uninhabited',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else
                  ...s.markets.map(
                    (m) => Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          margin: const EdgeInsets.only(right: 6, top: 2),
                          decoration: BoxDecoration(
                            color: widget.colorFor(m.factionId),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            widget.nameFor(m.factionId),
                            style: theme.textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          'size ${m.size}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _conName(String id) => widget.sector.constellations
      .firstWhere(
        (c) => c.id == id,
        orElse: () => const SectorConstellation(id: '', name: ''),
      )
      .name;
}
