import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/relative_timestamp.dart';
import 'package:trios/vram_estimator/graphics_lib_config_provider.dart';
import 'package:trios/vram_estimator/models/graphics_lib_config.dart';
import 'package:trios/vram_estimator/models/graphics_lib_info.dart';
import 'package:trios/vram_estimator/models/vram_checker_models.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/text_trios.dart';
import 'package:trios/widgets/viewer_search_box.dart';

final _scannedAtFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

/// Detailed breakdown of a single mod's VRAM estimate. Shown when the
/// user taps a mod row on the VRAM estimator page.
class VramModBreakdownDialog extends ConsumerStatefulWidget {
  final VramMod initialMod;

  const VramModBreakdownDialog({super.key, required VramMod mod})
    : initialMod = mod;

  static Future<void> show(BuildContext context, VramMod mod) {
    return showDialog(
      context: context,
      builder: (_) => VramModBreakdownDialog(mod: mod),
    );
  }

  @override
  ConsumerState<VramModBreakdownDialog> createState() =>
      _VramModBreakdownDialogState();
}

class _VramModBreakdownDialogState
    extends ConsumerState<VramModBreakdownDialog> {
  final SearchController _searchController = SearchController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// True when [view]'s file path or any of its `referencedBy` attributions
  /// contain [query] (case-insensitive). Empty query matches everything.
  bool _matches(ModImageView view, String query, String modFolder) {
    if (query.isEmpty) return true;
    final path = p.relative(view.file.path, from: modFolder).toLowerCase();
    if (path.contains(query)) return true;
    final refBy = view.referencedBy;
    if (refBy != null) {
      for (final entry in refBy) {
        if (entry.toLowerCase().contains(query)) return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gfxConfig = ref.watch(graphicsLibConfigProvider);
    final vramState = ref.watch(AppState.vramEstimatorProvider).value;
    // Prefer the freshest VramMod for this smolId so a rescan updates the
    // dialog live. Fall back to the one the caller passed in when the state
    // is still loading or the entry hasn't been re-emitted yet.
    final mod =
        vramState?.modVramInfo[widget.initialMod.info.smolId] ??
        widget.initialMod;

    final isGlobalScanning = vramState?.isScanning ?? false;
    final scanningName = vramState?.currentlyScanningModName;
    final thisName = mod.info.name ?? mod.info.modId;
    final isScanningThisMod = isGlobalScanning && scanningName == thisName;

    final referencedViews = List.generate(
      mod.images.length,
      (i) => ModImageView(i, mod.images),
    );
    final unrefTable = mod.unreferencedImages;
    final unrefViews = unrefTable == null
        ? const <ModImageView>[]
        : List.generate(unrefTable.length, (i) => ModImageView(i, unrefTable));

    final refByType = _groupByGfxType(referencedViews, gfxConfig);
    final unrefByType = _groupByGfxType(unrefViews, gfxConfig);

    final totalRefNonGfx = referencedViews
        .where((v) => v.graphicsLibType == null)
        .map((v) => v.bytesUsed)
        .sum;
    final totalRefGfxActive = referencedViews
        .where(
          (v) =>
              v.graphicsLibType != null &&
              v.isUsedBasedOnGraphicsLibConfig(gfxConfig),
        )
        .map((v) => v.bytesUsed)
        .sum;
    final totalUnref = unrefViews
        .where((v) => v.graphicsLibType == null)
        .map((v) => v.bytesUsed)
        .sum;

    // Filter by search query (case-insensitive). Empty query = pass through.
    final q = _query.trim().toLowerCase();
    final filteredReferenced = q.isEmpty
        ? referencedViews
        : referencedViews
              .where((v) => _matches(v, q, mod.info.modFolder))
              .toList();
    final filteredUnref = q.isEmpty
        ? unrefViews
        : unrefViews
              .where((v) => _matches(v, q, mod.info.modFolder))
              .toList();

    String tabLabel(String base, int filtered, int total) =>
        q.isEmpty ? '$base ($total)' : '$base ($filtered / $total)';

    return AlertDialog(
      icon: const Icon(Icons.memory),
      title: Text(mod.info.formattedName),
      content: SizedBox(
        width: 900,
        height: 600,
        child: DefaultTabController(
          length: unrefViews.isEmpty ? 1 : 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeaderRow(
                mod: mod,
                isScanningThisMod: isScanningThisMod,
                canRescan: !isGlobalScanning,
                onRescan: () => _rescanThisMod(ref, mod),
              ),
              const SizedBox(height: 12),
              _TotalsCard(
                theme: theme,
                totalRefNonGfx: totalRefNonGfx,
                totalRefGfxActive: totalRefGfxActive,
                totalUnref: totalUnref,
                gfxBreakdown: refByType,
                hasUnref: unrefViews.isNotEmpty,
                gfxConfig: gfxConfig,
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      tabs: [
                        Tab(
                          text: tabLabel(
                            'Referenced',
                            filteredReferenced.length,
                            referencedViews.length,
                          ),
                        ),
                        if (unrefViews.isNotEmpty)
                          Tab(
                            text: tabLabel(
                              'Unreferenced',
                              filteredUnref.length,
                              unrefViews.length,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ViewerSearchBox(
                    searchController: _searchController,
                    hintText: 'Search path or referenced-by…',
                    onChanged: (value) => setState(() => _query = value),
                    onClear: () => setState(() => _query = ''),
                  ),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _ImagesTable(
                      views: filteredReferenced,
                      modFolder: mod.info.modFolder,
                      gfxConfig: gfxConfig,
                    ),
                    if (unrefViews.isNotEmpty)
                      _ImagesTable(
                        views: filteredUnref,
                        modFolder: mod.info.modFolder,
                        gfxConfig: gfxConfig,
                        isUnreferencedTab: true,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Future<void> _rescanThisMod(WidgetRef ref, VramMod mod) async {
    final mods = ref.read(AppState.mods);
    final modEntry = mods.firstWhereOrNull((m) => m.id == mod.info.modId);
    final variant = modEntry?.findFirstEnabledOrHighestVersion;
    if (variant == null) return;
    await ref
        .read(AppState.vramEstimatorProvider.notifier)
        .startEstimating(variantsToCheck: [variant]);
  }

  Map<MapType?, int> _groupByGfxType(
    List<ModImageView> views,
    GraphicsLibConfig? cfg,
  ) {
    final out = <MapType?, int>{};
    for (final v in views) {
      out[v.graphicsLibType] = (out[v.graphicsLibType] ?? 0) + v.bytesUsed;
    }
    return out;
  }
}

class _HeaderRow extends StatelessWidget {
  final VramMod mod;
  final bool isScanningThisMod;
  final bool canRescan;
  final VoidCallback onRescan;

  const _HeaderRow({
    required this.mod,
    required this.isScanningThisMod,
    required this.canRescan,
    required this.onRescan,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scannedAtLocal = mod.scannedAt?.toLocal();
    final chips = <Widget>[
      _chip(
        theme,
        mod.isEnabled ? 'Enabled' : 'Disabled',
        mod.isEnabled
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface.withOpacity(0.4),
      ),
      _chip(
        theme,
        mod.unreferencedImages == null ? 'folder-scan' : 'referenced selector',
        theme.colorScheme.secondary,
      ),
      if ((mod.graphicsLibEntries ?? []).isNotEmpty)
        _chip(
          theme,
          'GraphicsLib CSV: ${mod.graphicsLibEntries!.length} entries',
          theme.colorScheme.tertiary,
        ),
      if (scannedAtLocal != null)
        MovingTooltipWidget.text(
          message: 'Scanned ${scannedAtLocal.relativeTimestamp()}',
          child: _chip(
            theme,
            'Scanned ${_scannedAtFormat.format(scannedAtLocal)}',
            theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: Wrap(spacing: 8, runSpacing: 4, children: chips)),
        const SizedBox(width: 8),
        _RescanButton(
          isScanning: isScanningThisMod,
          enabled: canRescan || isScanningThisMod,
          onPressed: canRescan ? onRescan : null,
        ),
      ],
    );
  }

  Widget _chip(ThemeData theme, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        border: Border.all(color: color.withOpacity(0.6)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

class _RescanButton extends StatefulWidget {
  final bool isScanning;
  final bool enabled;
  final VoidCallback? onPressed;

  const _RescanButton({
    required this.isScanning,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_RescanButton> createState() => _RescanButtonState();
}

class _RescanButtonState extends State<_RescanButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    duration: const Duration(seconds: 1),
    vsync: this,
  );

  @override
  void initState() {
    super.initState();
    if (widget.isScanning) _anim.repeat();
  }

  @override
  void didUpdateWidget(_RescanButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isScanning && !_anim.isAnimating) {
      _anim.repeat();
    } else if (!widget.isScanning && _anim.isAnimating) {
      _anim.stop();
      _anim.value = 0;
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tooltip = widget.isScanning
        ? 'Rescanning this mod…'
        : widget.enabled
        ? 'Rescan this mod'
        : 'Scan in progress — rescan unavailable';
    return MovingTooltipWidget.text(
      message: tooltip,
      child: IconButton(
        onPressed: widget.onPressed,
        icon: AnimatedBuilder(
          animation: _anim,
          builder: (_, child) => Transform.rotate(
            angle: _anim.value * 2.0 * 3.141592,
            child: child,
          ),
          child: const Icon(Icons.refresh),
        ),
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  final ThemeData theme;
  final int totalRefNonGfx;
  final int totalRefGfxActive;
  final int totalUnref;
  final Map<MapType?, int> gfxBreakdown;
  final bool hasUnref;
  final GraphicsLibConfig? gfxConfig;

  const _TotalsCard({
    required this.theme,
    required this.totalRefNonGfx,
    required this.totalRefGfxActive,
    required this.totalUnref,
    required this.gfxBreakdown,
    required this.hasUnref,
    required this.gfxConfig,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <_TotalsRow>[
      _TotalsRow('Base textures (excl. GraphicsLib)', totalRefNonGfx),
    ];

    for (final type in MapType.values) {
      final bytes = gfxBreakdown[type] ?? 0;
      if (bytes == 0) continue;
      final active = _mapTypeActive(type, gfxConfig);
      final reason = _inactiveReason(type, gfxConfig);
      rows.add(
        _TotalsRow(
          'GraphicsLib ${type.name} maps',
          bytes,
          muted: !active,
          suffix: active ? '' : ' ($reason)',
        ),
      );
    }

    final total = totalRefNonGfx + totalRefGfxActive;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Totals',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...rows.map((r) => _totalsLine(theme, r)),
            const Divider(height: 16),
            _totalsLine(
              theme,
              _TotalsRow(
                'Referenced total (counted against VRAM)',
                total,
                emphasize: true,
              ),
            ),
            if (hasUnref) ...[
              const SizedBox(height: 8),
              MovingTooltipWidget.text(
                message:
                    'Advisory — images on disk with no detected reference. '
                    'May include dev leftovers or paths constructed dynamically '
                    "in Java that the parsers can't see.",
                child: _totalsLine(
                  theme,
                  _TotalsRow(
                    'Unreferenced (advisory, not counted)',
                    totalUnref,
                    muted: true,
                    italic: true,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _mapTypeActive(MapType type, GraphicsLibConfig? cfg) {
    if (cfg == null) return false;
    // Maps only count toward steady-state VRAM when preloadAllMaps is on.
    // Otherwise GraphicsLib streams them in/out as ships appear on
    // screen, so they don't contribute meaningfully to the loaded set.
    if (!cfg.preloadAllMaps) return false;
    return switch (type) {
      MapType.Normal => cfg.areGfxLibNormalMapsEnabled,
      MapType.Material => cfg.areGfxLibMaterialMapsEnabled,
      MapType.Surface => cfg.areGfxLibSurfaceMapsEnabled,
    };
  }

  /// Human-readable reason a map type isn't counting. Differentiates
  /// "type is off entirely" from "maps stream on-demand because
  /// preloadAllMaps is off" — the latter is the common case and users
  /// benefit from understanding that the bytes aren't a concern.
  String _inactiveReason(MapType type, GraphicsLibConfig? cfg) {
    if (cfg == null) return 'GraphicsLib not enabled';
    final typeEnabled = switch (type) {
      MapType.Normal => cfg.areGfxLibNormalMapsEnabled,
      MapType.Material => cfg.areGfxLibMaterialMapsEnabled,
      MapType.Surface => cfg.areGfxLibSurfaceMapsEnabled,
    };
    if (!typeEnabled) return 'type disabled in GfxLib config';
    if (!cfg.preloadAllMaps) {
      return 'streamed on-demand by GfxLib; not counted';
    }
    return 'not counted';
  }

  Widget _totalsLine(ThemeData theme, _TotalsRow r) {
    final baseStyle =
        (r.emphasize
            ? theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)
            : theme.textTheme.bodyMedium) ??
        const TextStyle();
    final color = r.muted
        ? theme.colorScheme.onSurface.withOpacity(0.5)
        : baseStyle.color;
    final style = baseStyle.copyWith(
      color: color,
      fontStyle: r.italic ? FontStyle.italic : FontStyle.normal,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text('${r.label}${r.suffix}', style: style)),
          Text(r.bytes.bytesAsReadableMB(), style: style),
        ],
      ),
    );
  }
}

class _TotalsRow {
  final String label;
  final int bytes;
  final bool emphasize;
  final bool muted;
  final bool italic;
  final String suffix;

  const _TotalsRow(
    this.label,
    this.bytes, {
    this.emphasize = false,
    this.muted = false,
    this.italic = false,
    this.suffix = '',
  });
}

class _ImagesTable extends StatefulWidget {
  final List<ModImageView> views;
  final String modFolder;
  final GraphicsLibConfig? gfxConfig;
  final bool isUnreferencedTab;

  const _ImagesTable({
    required this.views,
    required this.modFolder,
    required this.gfxConfig,
    this.isUnreferencedTab = false,
  });

  @override
  State<_ImagesTable> createState() => _ImagesTableState();
}

class _ImagesTableState extends State<_ImagesTable> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<ModImageView> get views => widget.views;

  String get modFolder => widget.modFolder;

  GraphicsLibConfig? get gfxConfig => widget.gfxConfig;

  bool get isUnreferencedTab => widget.isUnreferencedTab;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sorted = [...views]
      ..sort((a, b) => b.bytesUsed.compareTo(a.bytesUsed));

    if (sorted.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            isUnreferencedTab
                ? 'No unreferenced images.'
                : 'No referenced images counted.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
      );
    }

    return Scrollbar(
      controller: _scrollController,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: sorted.length + 1,
        itemBuilder: (context, i) {
          if (i == 0) return _header(theme);
          final view = sorted[i - 1];
          return _row(context, theme, view);
        },
      ),
    );
  }

  Widget _header(ThemeData theme) {
    final style = theme.textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurface.withOpacity(0.7),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          Expanded(flex: 5, child: Text('File', style: style)),
          Expanded(flex: 4, child: Text('Referenced by', style: style)),
          Expanded(
            flex: 2,
            child: Text('Dimensions', style: style, textAlign: TextAlign.end),
          ),
          Expanded(
            flex: 2,
            child: Text('GfxLib', style: style, textAlign: TextAlign.end),
          ),
          Expanded(
            flex: 2,
            child: Text('Bytes', style: style, textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, ThemeData theme, ModImageView view) {
    final isGfx = view.graphicsLibType != null;
    final active = isGfx
        ? view.isUsedBasedOnGraphicsLibConfig(gfxConfig)
        : true;
    final muted = !active || view.imageType == ImageType.background;
    final color = muted
        ? theme.colorScheme.onSurface.withOpacity(0.55)
        : theme.colorScheme.onSurface;
    final style = theme.textTheme.bodySmall?.copyWith(
      color: color,
      fontFamily: 'Roboto Mono',
      fontFamilyFallback: const ['Consolas', 'Courier New', 'Monaco'],
    );
    final relPath = p.relative(view.file.path, from: modFolder);
    final dims = '${view.textureWidth}×${view.textureHeight}';
    final gfxLabel = view.graphicsLibType == null
        ? (view.imageType == ImageType.background ? 'bg' : '-')
        : view.graphicsLibType!.name.toLowerCase();

    final refBy = view.referencedBy;
    final refByLabel = _referencedByLabel(refBy, isUnreferencedTab);
    final refByStyle = style?.copyWith(
      color: refBy == null || refBy.isEmpty
          ? theme.colorScheme.onSurface.withOpacity(0.4)
          : color,
      fontStyle: refBy == null || refBy.isEmpty
          ? FontStyle.italic
          : FontStyle.normal,
    );

    return MovingTooltipWidget.text(
      message: [
        relPath,
        'Dimensions (POT): $dims',
        'Channels × bits: ${view.bitsInAllChannelsSum}',
        'Type: ${view.imageType.name}${isGfx ? " · GfxLib ${view.graphicsLibType!.name}" : ""}',
        if (refBy != null && refBy.isNotEmpty)
          'Referenced by:\n${refBy.map((e) => "  $e").join("\n")}',
        if (refBy == null && !isUnreferencedTab)
          'No attribution recorded (folder-scan mode, or background file).',
        if (isGfx && !active) 'Not counted; ${_gfxRowReason(view, gfxConfig)}',
        if (view.imageType == ImageType.background)
          'Background; only the largest oversized one counts',
      ].join('\n'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: SelectionArea(
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: TextTriOS(
                  relPath,
                  style: style,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 4,
                child: Text(
                  refByLabel,
                  style: refByStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(dims, style: style, textAlign: TextAlign.end),
              ),
              Expanded(
                flex: 2,
                child: Text(gfxLabel, style: style, textAlign: TextAlign.end),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  view.bytesUsed.bytesAsReadableMB(),
                  style: style,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _gfxRowReason(ModImageView view, GraphicsLibConfig? cfg) {
    final type = view.graphicsLibType!;
    if (cfg == null) return 'GraphicsLib not enabled';
    final typeEnabled = switch (type) {
      MapType.Normal => cfg.areGfxLibNormalMapsEnabled,
      MapType.Material => cfg.areGfxLibMaterialMapsEnabled,
      MapType.Surface => cfg.areGfxLibSurfaceMapsEnabled,
    };
    if (!typeEnabled) {
      return 'GraphicsLib ${type.name} maps disabled in config';
    }
    if (!cfg.preloadAllMaps) {
      return 'GraphicsLib loads/unloads ${type.name} maps on-demand when preloadAllMaps is off';
    }
    return '${type.name} maps not counted';
  }

  String _referencedByLabel(List<String>? refBy, bool isUnreferencedTab) {
    if (isUnreferencedTab) {
      return '(unreferenced)';
    }
    if (refBy == null) {
      // No attribution available (folder-scan, or a special-case row like
      // a background that's counted without going through parser matching).
      return '—';
    }
    if (refBy.isEmpty) {
      return '—';
    }
    return refBy.join(', ');
  }
}
