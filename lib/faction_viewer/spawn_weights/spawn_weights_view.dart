import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:trios/faction_viewer/faction_viewer_controller.dart';
import 'package:trios/faction_viewer/models/faction.dart';
import 'package:trios/faction_viewer/spawn_weights/ship_roles_manager.dart';
import 'package:trios/faction_viewer/spawn_weights/spawn_weight_calculator.dart';
import 'package:trios/faction_viewer/spawn_weights/vanilla_share_bar.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/trios_dropdown_menu.dart';
import 'package:trios/widgets/trios_expansion_tile.dart';
import 'package:url_launcher/url_launcher_string.dart';

/// The full weighted ship list the game picks from, for one faction and one
/// role. Rows are grouped by ship, because that's how people think about
/// fleets; the files themselves store one entry per loadout.
class SpawnWeightsView extends ConsumerWidget {
  final List<Faction> factions;
  final String searchQuery;

  const SpawnWeightsView({
    super.key,
    required this.factions,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(factionViewerControllerProvider);
    final controller = ref.read(factionViewerControllerProvider.notifier);

    if (factions.isEmpty) {
      return const Center(child: Text('No factions found.'));
    }

    final onlyEnabledMods = state.onlyEnabledMods;

    if (!ref.watch(spawnWeightsReadyProvider(onlyEnabledMods))) {
      return const Center(child: Text('Calculating spawn weights…'));
    }

    final faction = factions.firstWhere(
      (f) => f.mergeKey == state.persisted.spawnFactionKey,
      orElse: () => factions.first,
    );
    final weights = ref.watch(
      factionSpawnWeightsProvider((
        mergeKey: faction.mergeKey,
        onlyEnabledMods: onlyEnabledMods,
      )),
    );
    // If the chosen role has no ships for this faction, follow the game's own
    // fallback chain so we open on the role that actually spawns something,
    // instead of an empty table.
    final role = _resolveDisplayRole(state.persisted.spawnRole, weights);
    final entries = weights.byRole[role] ?? const [];

    return Padding(
      padding: .all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          _buildPickers(context, theme, faction, weights, role, controller),
          Expanded(
            child: entries.isEmpty
                ? _buildEmptyRole(theme, role, weights.fallbackByRole[role])
                : _SpawnWeightTable(
                    faction: faction,
                    entries: entries,
                    searchQuery: searchQuery,
                    onlyEnabledMods: onlyEnabledMods,
                  ),
          ),
          _buildFooterNote(theme, weights.summary),
        ],
      ),
    );
  }

  Widget _buildPickers(
    BuildContext context,
    ThemeData theme,
    Faction faction,
    FactionSpawnWeights weights,
    String role,
    FactionViewerController controller,
  ) {
    final roles = weights.byRole.keys.toList()..sort();

    return Row(
      spacing: 16,
      children: [
        Text('Faction', style: theme.textTheme.bodySmall),
        SizedBox(
          width: 220,
          child: TriOSDropdownMenu<String>(
            initialSelection: faction.mergeKey,
            onSelected: (key) {
              if (key != null) controller.setSpawnFaction(key);
            },
            dropdownMenuEntries: [
              for (final f in factions)
                DropdownMenuEntry(value: f.mergeKey, label: f.displayName),
            ],
          ),
        ),
        Text('Role', style: theme.textTheme.bodySmall),
        SizedBox(
          width: 220,
          child: TriOSDropdownMenu<String>(
            initialSelection: roles.contains(role) ? role : roles.firstOrNull,
            onSelected: (value) {
              if (value != null) controller.setSpawnRole(value);
            },
            dropdownMenuEntries: [
              for (final r in roles) DropdownMenuEntry(value: r, label: r),
            ],
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 220,
              child: VanillaShareBar(
                summary: weights.summary,
                height: 8,
                factionColor: faction.factionColor,
                factionName: faction.displayName,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// The role to actually show. If [selected] has ships, use it. Otherwise
  /// walk the game's fallback chain (empty combat roles fall back to smaller
  /// sizes) until a role with ships is found. If nothing in the chain has
  /// ships, return [selected] so the empty-state message still makes sense.
  String _resolveDisplayRole(String selected, FactionSpawnWeights weights) {
    var role = selected;
    final seen = <String>{};
    while (seen.add(role)) {
      final entries = weights.byRole[role];
      if (entries != null && entries.isNotEmpty) return role;
      final fallback = weights.fallbackByRole[role];
      if (fallback == null) break;
      role = fallback;
    }
    return selected;
  }

  Widget _buildEmptyRole(ThemeData theme, String role, String? fallback) {
    return Center(
      child: Padding(
        padding: .all(24),
        child: Text(
          fallback == null
              ? 'Nothing to spawn in "$role" for this faction.'
              : 'Nothing to spawn in "$role" for this faction, so the game '
                    'picks from "$fallback" instead.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildFooterNote(ThemeData theme, FactionSpawnSummary summary) {
    final skipped = summary.skippedEntries;
    return Text(
      'These numbers are approximate. They miss a few things: '
      'ships that mods add in code, the game trimming ships that cost too many '
      'fleet points, combat freighters being mixed in, and mods that fully '
      'replace a file instead of adding to it.'
      '${skipped > 0 ? '\n$skipped entries were left out because their ship '
                'is not installed.' : ''}',
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontStyle: .italic,
      ),
    );
  }
}

class _SpawnWeightTable extends ConsumerWidget {
  final Faction faction;
  final List<SpawnWeightEntry> entries;
  final String searchQuery;
  final bool onlyEnabledMods;

  const _SpawnWeightTable({
    required this.faction,
    required this.entries,
    required this.searchQuery,
    required this.onlyEnabledMods,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final total = entries.fold<double>(0, (sum, e) => sum + e.weight);

    // Group by ship, biggest share first.
    final byHull = <String, List<SpawnWeightEntry>>{};
    for (final entry in entries) {
      byHull.putIfAbsent(entry.hullId, () => []).add(entry);
    }
    final query = searchQuery.trim().toLowerCase();
    final groups = byHull.values.where((group) {
      if (query.isEmpty) return true;
      return group.first.shipName.toLowerCase().contains(query);
    }).toList();
    groups.sort((a, b) => _sum(b).compareTo(_sum(a)));

    if (groups.isEmpty) {
      return Center(
        child: Text(
          'No ships match your search.',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    final hasPriority = groups.any((g) => g.first.isPriority);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasPriority) _buildPriorityLegend(theme),
        _buildHeaderRow(theme),
        Expanded(
          child: ListView.builder(
            itemCount: groups.length,
            itemBuilder: (context, index) =>
                _buildShipGroup(context, ref, theme, groups[index], total),
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityLegend(ThemeData theme) {
    return Padding(
      padding: .only(left: 40, bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          Icon(Icons.star, size: 14, color: theme.colorScheme.tertiary),
          Text(
            'Priority ship — the faction favors these, so they spawn more '
            'than their weight alone suggests.',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  double _sum(List<SpawnWeightEntry> group) =>
      group.fold<double>(0, (sum, e) => sum + e.weight);

  Widget _buildHeaderRow(ThemeData theme) {
    final style = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.bold,
    );
    return Padding(
      padding: .fromLTRB(40, 4, 48, 4),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text('Ship', style: style)),
          Expanded(flex: 2, child: Text('Size', style: style)),
          Expanded(flex: 2, child: Text('Weight', style: style)),
          Expanded(flex: 2, child: Text('Share', style: style)),
          Expanded(flex: 3, child: Text('Set by', style: style)),
        ],
      ),
    );
  }

  Widget _buildShipGroup(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    List<SpawnWeightEntry> group,
    double total,
  ) {
    final first = group.first;
    final groupWeight = _sum(group);
    final sources = group.map((e) => e.source ?? 'Unknown').toSet().toList()
      ..sort();

    return TriOSExpansionTile(
      dense: true,
      childrenPadding: .only(left: 40, bottom: 4),
      title: _row(
        theme: theme,
        name: first.shipName,
        size: _prettySize(first.hullSize),
        weight: groupWeight,
        total: total,
        setBy: sources.join(', '),
        bold: true,
        isPriority: first.isPriority,
      ),
      children: [
        for (final entry in group)
          Padding(
            padding: .only(right: 8),
            child: Row(
              children: [
                Expanded(
                  child: _row(
                    theme: theme,
                    name: entry.loadoutId,
                    size: '',
                    weight: entry.weight,
                    total: total,
                    setBy: entry.source ?? 'Unknown',
                    bold: false,
                  ),
                ),
                _buildOpenFileButton(context, ref, entry),
              ],
            ),
          ),
      ],
    );
  }

  Widget _row({
    required ThemeData theme,
    required String name,
    required String size,
    required double weight,
    required double total,
    required String setBy,
    required bool bold,
    bool isPriority = false,
  }) {
    final style =
        (bold ? theme.textTheme.bodySmall : theme.textTheme.labelSmall)
            ?.copyWith(
              fontWeight: bold ? FontWeight.w500 : FontWeight.normal,
              fontFeatures: [const FontFeature.tabularFigures()],
            );
    final share = total > 0 ? weight / total : 0.0;

    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Row(
            children: [
              if (isPriority)
                MovingTooltipWidget.text(
                  message:
                      'Priority ship: this faction favors it, so it '
                      'spawns more often than its weight alone suggests.',
                  child: Padding(
                    padding: .only(right: 4),
                    child: Icon(
                      Icons.star,
                      size: 14,
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                ),
              Flexible(
                child: Text(
                  name,
                  style: style,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Expanded(flex: 2, child: Text(size, style: style)),
        Expanded(flex: 2, child: Text(_trimZeros(weight), style: style)),
        Expanded(
          flex: 2,
          child: Text('${(share * 100).toStringAsFixed(1)}%', style: style),
        ),
        Expanded(
          flex: 3,
          child: Text(setBy, style: style, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  Widget _buildOpenFileButton(
    BuildContext context,
    WidgetRef ref,
    SpawnWeightEntry entry,
  ) {
    final file = _fileThatSetWeight(ref, entry);
    if (file == null) return const SizedBox(width: 32);

    return MovingTooltipWidget.text(
      message: 'Open the file that set this weight\n${file.path}',
      child: IconButton(
        icon: const Icon(Icons.open_in_new, size: 16),
        visualDensity: VisualDensity.compact,
        onPressed: () => launchUrlString(file.path),
      ),
    );
  }

  /// The `default_ship_roles.json` or `.faction` file the weight came from.
  File? _fileThatSetWeight(WidgetRef ref, SpawnWeightEntry entry) {
    final source = entry.source;
    if (source == null) return null;

    if (entry.origin == WeightOrigin.defaultShipRoles) {
      final roles = ref.watch(mergedShipRolesProvider(onlyEnabledMods)).value;
      final file = roles?.sourceFiles[source];
      return file != null && file.existsSync() ? file : null;
    }

    final gameCoreDir = ref.watch(AppState.gameCoreFolder).value;
    for (final factionSource in faction.sources) {
      if (factionSource.name != source) continue;
      final folder = factionSource.modVariant is ModVariant
          ? (factionSource.modVariant as ModVariant).modFolder
          : gameCoreDir;
      if (folder == null) continue;
      final file = File(
        p.join(
          folder.path,
          'data',
          'world',
          'factions',
          '${faction.mergeKey}.faction',
        ),
      );
      if (file.existsSync()) return file;
    }
    return null;
  }
}

String _prettySize(String? hullSize) => switch (hullSize?.toUpperCase()) {
  'FRIGATE' => 'Frigate',
  'DESTROYER' => 'Destroyer',
  'CRUISER' => 'Cruiser',
  'CAPITAL_SHIP' => 'Capital',
  'FIGHTER' => 'Fighter',
  null => '',
  _ => hullSize!,
};

String _trimZeros(double value) {
  final text = value.toStringAsFixed(2);
  return text.endsWith('.00') ? text.substring(0, text.length - 3) : text;
}
