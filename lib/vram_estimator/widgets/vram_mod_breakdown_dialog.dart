import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/relative_timestamp.dart';
import 'package:trios/vram_estimator/graphics_lib_config_provider.dart';
import 'package:trios/vram_estimator/models/graphics_lib_config.dart';
import 'package:trios/vram_estimator/models/graphics_lib_info.dart';
import 'package:trios/vram_estimator/models/vram_checker_models.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/viewer_search_box.dart';

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
    final referencedBy = view.referencedBy;
    if (referencedBy != null) {
      for (final entry in referencedBy) {
        if (entry.toLowerCase().contains(query)) return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final graphicsLibConfig = ref.watch(graphicsLibConfigProvider);
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
    final unreferencedTable = mod.unreferencedImages;
    final unreferencedViews = unreferencedTable == null
        ? const <ModImageView>[]
        : List.generate(
            unreferencedTable.length,
            (i) => ModImageView(i, unreferencedTable),
          );

    final referencedByType = _groupByGraphicsLibType(
      referencedViews,
      graphicsLibConfig,
    );

    final totalReferencedWithoutGraphicsLib = referencedViews
        .where((view) => view.graphicsLibType == null)
        .map((view) => view.bytesUsed)
        .sum;
    final totalReferencedGraphicsLibActive = referencedViews
        .where(
          (view) =>
              view.graphicsLibType != null &&
              view.isUsedBasedOnGraphicsLibConfig(graphicsLibConfig),
        )
        .map((view) => view.bytesUsed)
        .sum;
    final totalUnreferenced = unreferencedViews
        .where((view) => view.graphicsLibType == null)
        .map((view) => view.bytesUsed)
        .sum;

    // Filter by search query (case-insensitive). Empty query = pass through.
    final query = _query.trim().toLowerCase();
    final filteredReferenced = query.isEmpty
        ? referencedViews
        : referencedViews
              .where((view) => _matches(view, query, mod.info.modFolder))
              .toList();
    final filteredUnreferenced = query.isEmpty
        ? unreferencedViews
        : unreferencedViews
              .where((view) => _matches(view, query, mod.info.modFolder))
              .toList();

    String tabLabel(String base, int filtered, int total) =>
        query.isEmpty ? '$base ($total)' : '$base ($filtered / $total)';

    return AlertDialog(
      icon: null,
      title: Text("VRAM Estimate: ${mod.info.formattedName}"),
      content: SizedBox(
        width: 900,
        child: DefaultTabController(
          length: unreferencedViews.isEmpty ? 1 : 2,
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
                totalReferencedWithoutGraphicsLib:
                    totalReferencedWithoutGraphicsLib,
                totalReferencedGraphicsLibActive:
                    totalReferencedGraphicsLibActive,
                totalUnreferenced: totalUnreferenced,
                graphicsLibBreakdown: referencedByType,
                hasUnreferenced: unreferencedViews.isNotEmpty,
                graphicsLibConfig: graphicsLibConfig,
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
                        if (unreferencedViews.isNotEmpty)
                          Tab(
                            text: tabLabel(
                              'Unreferenced',
                              filteredUnreferenced.length,
                              unreferencedViews.length,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const .only(bottom: 4),
                    child: ViewerSearchBox(
                      searchController: _searchController,
                      hintText: 'Search path or referenced-by…',
                      onChanged: (value) => setState(() => _query = value),
                      onClear: () => setState(() => _query = ''),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _ImagesTable(
                      views: filteredReferenced,
                      modFolder: mod.info.modFolder,
                      graphicsLibConfig: graphicsLibConfig,
                    ),
                    if (unreferencedViews.isNotEmpty)
                      _ImagesTable(
                        views: filteredUnreferenced,
                        modFolder: mod.info.modFolder,
                        graphicsLibConfig: graphicsLibConfig,
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

  Map<MapType?, int> _groupByGraphicsLibType(
    List<ModImageView> views,
    GraphicsLibConfig? graphicsLibConfig,
  ) {
    final out = <MapType?, int>{};
    for (final view in views) {
      out[view.graphicsLibType] =
          (out[view.graphicsLibType] ?? 0) + view.bytesUsed;
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
        "Status:${mod.isEnabled ? 'Enabled' : 'Disabled'}",
        mod.isEnabled
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface.withOpacity(0.4),
      ),
      _chip(
        theme,
        "Method: ${mod.unreferencedImages == null ? 'Scan All' : 'Selective Scan'}",
        theme.colorScheme.onSurface,
      ),
      if ((mod.graphicsLibEntries ?? []).isNotEmpty)
        _chip(
          theme,
          'GraphicsLib CSV: ${mod.graphicsLibEntries!.length} entries',
          theme.colorScheme.onSurface,
        ),
      if (scannedAtLocal != null)
        MovingTooltipWidget.text(
          message: 'Last scanned ${scannedAtLocal.relativeTimestamp()}',
          child: _chip(
            theme,
            'Last scan: ${Constants.dateTimeFormat.format(scannedAtLocal)}',
            theme.colorScheme.onSurface,
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
  final int totalReferencedWithoutGraphicsLib;
  final int totalReferencedGraphicsLibActive;
  final int totalUnreferenced;
  final Map<MapType?, int> graphicsLibBreakdown;
  final bool hasUnreferenced;
  final GraphicsLibConfig? graphicsLibConfig;

  const _TotalsCard({
    required this.theme,
    required this.totalReferencedWithoutGraphicsLib,
    required this.totalReferencedGraphicsLibActive,
    required this.totalUnreferenced,
    required this.graphicsLibBreakdown,
    required this.hasUnreferenced,
    required this.graphicsLibConfig,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <_TotalsRow>[
      _TotalsRow(
        'Base textures (excl. GraphicsLib)',
        totalReferencedWithoutGraphicsLib,
      ),
    ];

    for (final type in MapType.values) {
      final bytes = graphicsLibBreakdown[type] ?? 0;
      if (bytes == 0) continue;
      final active = _mapTypeActive(type, graphicsLibConfig);
      final reason = _inactiveReason(type, graphicsLibConfig);
      rows.add(
        _TotalsRow(
          'GraphicsLib ${type.name} maps',
          bytes,
          muted: !active,
          suffix: active ? '' : ' ($reason)',
        ),
      );
    }

    final total =
        totalReferencedWithoutGraphicsLib + totalReferencedGraphicsLibActive;

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
            ...rows.map((row) => _totalsLine(theme, row)),
            const Divider(height: 16),
            _totalsLine(
              theme,
              _TotalsRow(
                'Referenced total (counted against VRAM)',
                total,
                emphasize: true,
              ),
            ),
            if (hasUnreferenced) ...[
              const SizedBox(height: 8),
              MovingTooltipWidget.text(
                message:
                    'Images on disk with no detected reference. '
                    'May include dev leftovers or paths constructed dynamically '
                    "in Java.",
                child: _totalsLine(
                  theme,
                  _TotalsRow(
                    'Unreferenced (not counted)',
                    totalUnreferenced,
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

  bool _mapTypeActive(MapType type, GraphicsLibConfig? graphicsLibConfig) {
    if (graphicsLibConfig == null) return false;
    // Maps only count toward steady-state VRAM when preloadAllMaps is on.
    // Otherwise GraphicsLib streams them in/out as ships appear on
    // screen, so they don't contribute meaningfully to the loaded set.
    if (!graphicsLibConfig.preloadAllMaps) return false;
    return switch (type) {
      MapType.Normal => graphicsLibConfig.areGfxLibNormalMapsEnabled,
      MapType.Material => graphicsLibConfig.areGfxLibMaterialMapsEnabled,
      MapType.Surface => graphicsLibConfig.areGfxLibSurfaceMapsEnabled,
    };
  }

  /// Human-readable reason a map type isn't counting. Differentiates
  /// "type is off entirely" from "maps stream on-demand because
  /// preloadAllMaps is off" — the latter is the common case and users
  /// benefit from understanding that the bytes aren't a concern.
  String _inactiveReason(MapType type, GraphicsLibConfig? graphicsLibConfig) {
    if (graphicsLibConfig == null) return 'GraphicsLib not enabled';
    final typeEnabled = switch (type) {
      MapType.Normal => graphicsLibConfig.areGfxLibNormalMapsEnabled,
      MapType.Material => graphicsLibConfig.areGfxLibMaterialMapsEnabled,
      MapType.Surface => graphicsLibConfig.areGfxLibSurfaceMapsEnabled,
    };
    if (!typeEnabled) return 'type disabled in GraphicsLib config';
    if (!graphicsLibConfig.preloadAllMaps) {
      return 'streamed on-demand by GraphicsLib; not counted';
    }
    return 'not counted';
  }

  Widget _totalsLine(ThemeData theme, _TotalsRow row) {
    final baseStyle =
        (row.emphasize
            ? theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)
            : theme.textTheme.bodyMedium) ??
        const TextStyle();
    final color = row.muted
        ? theme.colorScheme.onSurface.withOpacity(0.5)
        : baseStyle.color;
    final style = baseStyle.copyWith(
      color: color,
      fontStyle: row.italic ? FontStyle.italic : FontStyle.normal,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text('${row.label}${row.suffix}', style: style)),
          Text(row.bytes.bytesAsReadableMB(), style: style),
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
  final GraphicsLibConfig? graphicsLibConfig;
  final bool isUnreferencedTab;

  const _ImagesTable({
    required this.views,
    required this.modFolder,
    required this.graphicsLibConfig,
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

  GraphicsLibConfig? get graphicsLibConfig => widget.graphicsLibConfig;

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
          Expanded(flex: 4, child: Text('Explanation', style: style)),
          Expanded(
            flex: 2,
            child: Text('Dimensions', style: style, textAlign: TextAlign.end),
          ),
          Expanded(
            flex: 2,
            child: Text('GraphicsLib', style: style, textAlign: TextAlign.end),
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
    final isGraphicsLib = view.graphicsLibType != null;
    final active = isGraphicsLib
        ? view.isUsedBasedOnGraphicsLibConfig(graphicsLibConfig)
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
    final relativePath = p.relative(view.file.path, from: modFolder);
    final dimensions = '${view.textureWidth}×${view.textureHeight}';
    final graphicsLibLabel = view.graphicsLibType == null
        ? (view.imageType == ImageType.background ? 'bg' : '-')
        : view.graphicsLibType!.name.toLowerCase();

    final referencedBy = view.referencedBy;
    final explanationLabel = _explanationLabel(
      view,
      referencedBy,
      isUnreferencedTab,
    );
    final hasExplanation = explanationLabel != '—';
    final explanationStyle = style?.copyWith(
      color: hasExplanation
          ? color
          : theme.colorScheme.onSurface.withOpacity(0.4),
      fontStyle: hasExplanation ? FontStyle.normal : FontStyle.italic,
    );

    final tooltipMessage = [
      relativePath,
      'Dimensions (POT): $dimensions',
      'Channels × bits: ${view.bitsInAllChannelsSum}',
      'Type: ${view.imageType.name}${isGraphicsLib ? " · GraphicsLib ${view.graphicsLibType!.name}" : ""}',
      if (view.vanillaReplacementCost > 0 &&
          view.vanillaReplacementCost >= view.bytesUsed)
        'Replaces a vanilla file already counted in vanilla VRAM, so adds nothing extra.',
      if (view.vanillaReplacementCost > 0 &&
          view.vanillaReplacementCost < view.bytesUsed)
        'Replaces a vanilla file (${view.vanillaReplacementCost.bytesAsReadableMB()}) with a larger version. Only the extra ${(view.bytesUsed - view.vanillaReplacementCost).bytesAsReadableMB()} counts.',
      if (referencedBy != null && referencedBy.isNotEmpty)
        'Referenced by:\n${referencedBy.map((e) => "  $e").join("\n")}',
      if (referencedBy == null && !isUnreferencedTab)
        'No attribution recorded (folder-scan mode, or background file).',
      if (isGraphicsLib && !active)
        'Not counted; ${_graphicsLibRowReason(view, graphicsLibConfig)}',
      if (view.imageType == ImageType.background)
        'Background; only the largest oversized one counts',
    ].join('\n');

    return MovingTooltipWidget(
      tooltipWidget: Card(
        color: kDarkTooltipBackground,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 32,
            children: [
              Text(
                tooltipMessage,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 150,
                  maxHeight: 150,
                ),
                child: Image.file(
                  view.file,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.none,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ),
      child: InkWell(
        onTap: () => view.file.showInExplorer(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: Text(
                  relativePath,
                  style: style,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 4,
                child: Text(
                  explanationLabel,
                  style: explanationStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(dimensions, style: style, textAlign: TextAlign.end),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  graphicsLibLabel,
                  style: style,
                  textAlign: TextAlign.end,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  max(
                    0,
                    view.bytesUsed - view.vanillaReplacementCost,
                  ).bytesAsReadableMB(),
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

  String _graphicsLibRowReason(
    ModImageView view,
    GraphicsLibConfig? graphicsLibConfig,
  ) {
    final type = view.graphicsLibType!;
    if (graphicsLibConfig == null) return 'GraphicsLib not enabled';
    final typeEnabled = switch (type) {
      MapType.Normal => graphicsLibConfig.areGfxLibNormalMapsEnabled,
      MapType.Material => graphicsLibConfig.areGfxLibMaterialMapsEnabled,
      MapType.Surface => graphicsLibConfig.areGfxLibSurfaceMapsEnabled,
    };
    if (!typeEnabled) {
      return 'GraphicsLib ${type.name} maps disabled in config';
    }
    if (!graphicsLibConfig.preloadAllMaps) {
      return 'GraphicsLib loads/unloads ${type.name} maps on-demand when preloadAllMaps is off';
    }
    return '${type.name} maps not counted';
  }

  String _explanationLabel(
    ModImageView view,
    List<String>? referencedBy,
    bool isUnreferencedTab,
  ) {
    final parts = <String>[];

    if (view.vanillaReplacementCost > 0) {
      if (view.vanillaReplacementCost >= view.bytesUsed) {
        parts.add('Replaces vanilla, no extra VRAM');
      } else {
        final extra = (view.bytesUsed - view.vanillaReplacementCost)
            .bytesAsReadableMB();
        parts.add('Replaces vanilla, $extra larger');
      }
    }

    if (isUnreferencedTab) {
      parts.add('(unreferenced)');
    } else if (referencedBy != null && referencedBy.isNotEmpty) {
      parts.add(referencedBy.join(', '));
    }

    if (view.imageType == ImageType.background) {
      parts.add('background');
    }

    return parts.isEmpty ? '—' : parts.join(' · ');
  }
}
