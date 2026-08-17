import 'dart:io';

import 'package:collection/collection.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:trios/faction_viewer/faction_viewer_controller.dart';
import 'package:trios/faction_viewer/models/faction.dart';
import 'package:trios/faction_viewer/spawn_weights/ship_roles_manager.dart';
import 'package:trios/faction_viewer/spawn_weights/spawn_weight_calculator.dart';
import 'package:trios/faction_viewer/spawn_weights/vanilla_share_bar.dart';
import 'package:trios/hullmod_viewer/hullmods_manager.dart';
import 'package:trios/hullmod_viewer/models/hullmod.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/ship_systems_manager/ship_system.dart';
import 'package:trios/ship_systems_manager/ship_systems_manager.dart';
import 'package:trios/ship_viewer/models/ship.dart';
import 'package:trios/ship_viewer/widgets/ship_blueprint_view.dart';
import 'package:trios/ship_viewer/widgets/ship_codex_card.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/weapon_viewer/models/weapon.dart';
import 'package:trios/weapon_viewer/weapons_manager.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/rainbow/themed_progress_indicator.dart';
import 'package:trios/widgets/text_trios.dart';
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
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            ThemedCircularProgressIndicator(),
            Text('Calculating spawn weights…'),
          ],
        ),
      );
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
          _buildPickers(
            context,
            theme,
            faction,
            weights,
            role,
            state.persisted.spawnRole,
            controller,
          ),
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
    String selectedRole,
    FactionViewerController controller,
  ) {
    final roles = _sortRoles(weights.byRole.keys.toList());

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
              for (final r in roles)
                DropdownMenuEntry(value: r, label: _prettyRoleName(r)),
            ],
          ),
        ),
        Expanded(
          child: Row(
            spacing: 16,
            children: [
              Expanded(
                child: role == selectedRole
                    ? const SizedBox()
                    : TextTriOS(
                        'Nothing spawns in '
                        '"${_prettyRoleName(selectedRole)}" here, so the game '
                        'uses "${_prettyRoleName(role)}" instead.',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontStyle: .italic,
                        ),
                      ),
              ),
              SizedBox(
                width: 220,
                child: VanillaShareBar(
                  summary: weights.summary,
                  height: 8,
                  factionColor: faction.factionColor,
                  factionName: faction.displayName,
                  showLabel: true,
                ),
              ),
            ],
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
              ? 'Nothing to spawn in "${_prettyRoleName(role)}" for this '
                    'faction.'
              : 'Nothing to spawn in "${_prettyRoleName(role)}" for this '
                    'faction, so the game picks from '
                    '"${_prettyRoleName(fallback)}" instead.',
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
    final color = theme.colorScheme.onSurfaceVariant;
    return MovingTooltipWidget.text(
      message:
          'These numbers miss a few things:\n'
          '• ships that mods add in code\n'
          '• the game trimming ships that cost too many fleet points\n'
          '• combat freighters being mixed in\n'
          '• mods that fully replace a file instead of adding to it',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          Icon(Icons.info_outline, size: 14, color: color),
          Text(
            'These numbers are close, but not exact — hover for why.'
            '${skipped > 0 ? ' $skipped entries were left out because their '
                      'ship is not installed.' : ''}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontStyle: .italic,
            ),
          ),
        ],
      ),
    );
  }
}

/// Height and width of the ship sprite shown on each row.
const double _spriteSize = 32;

/// The ships, and the lookups [ShipCodexCard.tooltip] needs to describe one.
/// Kept in a single object so one build can hand it to every row.
class _ShipTooltipData {
  final Map<String, Ship> ships;
  final Map<String, ShipSystem> shipSystems;
  final Map<String, Weapon> weapons;
  final Map<String, Hullmod> hullmods;

  const _ShipTooltipData({
    required this.ships,
    required this.shipSystems,
    required this.weapons,
    required this.hullmods,
  });
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

  /// Reads what the ship hover tooltip needs. These are all shared lookups, so
  /// a rebuild here (every search keystroke, say) reads them rather than
  /// rebuilding a map of every weapon and hullmod installed.
  _ShipTooltipData _tooltipData(WidgetRef ref) {
    return _ShipTooltipData(
      ships: ref.watch(shipsByHullIdProvider) ?? const {},
      shipSystems: ref.watch(shipSystemsByIdProvider),
      weapons: ref.watch(weaponsByIdProvider(onlyEnabledMods)),
      hullmods: ref.watch(hullmodsByIdProvider),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final total = entries.fold<double>(0, (sum, e) => sum + e.weight);
    final tooltipData = _tooltipData(ref);

    // Group by ship, biggest share first.
    final byHull = <String, List<SpawnWeightEntry>>{};
    for (final entry in entries) {
      byHull.putIfAbsent(entry.hullId, () => []).add(entry);
    }
    final query = searchQuery.trim().toLowerCase();
    final groups = byHull.values.where((group) {
      if (query.isEmpty) return true;
      final first = group.first;
      return first.shipName.toLowerCase().contains(query) ||
          first.hullId.toLowerCase().contains(query) ||
          group.any((e) => e.loadoutId.toLowerCase().contains(query));
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
    // Groups are sorted biggest-first, so the first one sets the scale for
    // the little share bars.
    final maxGroupWeight = _sum(groups.first);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasPriority) _buildPriorityLegend(theme),
        _buildHeaderRow(theme),
        Expanded(
          child: ListView.builder(
            itemCount: groups.length,
            itemBuilder: (context, index) => _buildShipGroup(
              context,
              ref,
              theme,
              groups[index],
              total,
              maxGroupWeight,
              tooltipData,
            ),
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

    Widget header(int flex, String label, {String? tooltip}) {
      final text = Text(label, style: style);
      return Expanded(
        flex: flex,
        child: tooltip == null
            ? text
            : MovingTooltipWidget.text(
                message: tooltip,
                child: Align(alignment: .centerLeft, child: text),
              ),
      );
    }

    return Padding(
      padding: .fromLTRB(40, 4, 48, 4),
      child: Row(
        children: [
          header(4, 'Ship'),
          header(2, 'Size'),
          header(
            2,
            'Weight',
            tooltip:
                'The number the game files give this ship.\n'
                'Higher means it gets picked more often.',
          ),
          header(
            2,
            'Share',
            tooltip: "This ship's slice of the total weight for this role.",
          ),
          header(
            3,
            'Set by',
            tooltip:
                'The mod (or the base game) whose file set this weight.',
          ),
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
    double maxGroupWeight,
    _ShipTooltipData tooltipData,
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
        barFraction: maxGroupWeight > 0 ? groupWeight / maxGroupWeight : 0,
        ship: tooltipData.ships[first.hullId],
        tooltipData: tooltipData,
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
    double barFraction = 0,
    Ship? ship,
    _ShipTooltipData? tooltipData,
  }) {
    final style =
        (bold ? theme.textTheme.bodySmall : theme.textTheme.labelSmall)
            ?.copyWith(
              fontWeight: bold ? FontWeight.w500 : FontWeight.normal,
              fontFeatures: [const FontFeature.tabularFigures()],
            );
    final share = total > 0 ? weight / total : 0.0;

    Widget nameCell = Row(
      children: [
        if (ship != null)
          Padding(
            padding: .only(right: 6),
            child: SizedBox(
              width: _spriteSize,
              height: _spriteSize,
              child: ShipBlueprintView.minimal(
                ship: ship,
                cacheWidth: _spriteSize.toInt(),
                clipContent: false,
              ),
            ),
          ),
        Flexible(
          child: Text(name, style: style, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
    if (ship != null && tooltipData != null) {
      nameCell = ShipCodexCard.tooltip(
        ship: ship,
        shipSystemsMap: tooltipData.shipSystems,
        weaponsMap: tooltipData.weapons,
        hullmodsMap: tooltipData.hullmods,
        child: nameCell,
      );
    }

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
              Flexible(child: nameCell),
            ],
          ),
        ),
        Expanded(flex: 2, child: Text(size, style: style)),
        Expanded(flex: 2, child: Text(_trimZeros(weight), style: style)),
        Expanded(
          flex: 2,
          child: Row(
            children: [
              SizedBox(
                width: 48,
                child: Text(_formatSharePercent(share), style: style),
              ),
              if (barFraction > 0)
                Expanded(
                  child: Padding(
                    padding: .only(right: 16),
                    child: Container(
                      height: 4,
                      alignment: AlignmentDirectional.centerStart,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.08,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        widthFactor: barFraction.clamp(0.0, 1.0),
                        heightFactor: 1,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.55,
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
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

/// Matches the gap before each capital letter in a name like "combatSmall".
final _beforeCapital = RegExp(r'(?<=[a-z0-9])(?=[A-Z])');

/// Turns a role id into readable words: "combatSmall" → "Combat Small".
String _prettyRoleName(String role) {
  final words = role
      .replaceAllMapped(_beforeCapital, (_) => ' ')
      .replaceAll('_', ' ');
  return words
      .split(' ')
      .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
      .join(' ');
}

const _roleSizeOrder = ['small', 'medium', 'large', 'capital'];

/// Sorts roles by name, then small → medium → large → capital within a family.
/// Plain alphabetical order would put "combatCapital" before "combatSmall".
List<String> _sortRoles(List<String> roles) {
  /// The role's family name, plus its place in [_roleSizeOrder] (-1 if the
  /// name doesn't end in a size).
  (String, int) sortKey(String role) {
    final lower = role.toLowerCase();
    for (var i = 0; i < _roleSizeOrder.length; i++) {
      final size = _roleSizeOrder[i];
      if (lower.endsWith(size)) {
        return (lower.substring(0, lower.length - size.length), i);
      }
    }
    return (lower, -1);
  }

  return roles.sorted((a, b) {
    final (familyA, sizeA) = sortKey(a);
    final (familyB, sizeB) = sortKey(b);
    final byFamily = familyA.compareTo(familyB);
    return byFamily != 0 ? byFamily : sizeA.compareTo(sizeB);
  });
}

/// "12.3%", with a floor so tiny-but-real chances don't show as "0.0%".
String _formatSharePercent(double share) {
  if (share > 0 && share < 0.001) return '<0.1%';
  return '${(share * 100).toStringAsFixed(1)}%';
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
