import 'dart:io';

import 'package:flutter/material.dart';
import 'package:trios/shipSystemsManager/ship_system.dart';
import 'package:trios/shipViewer/models/shipGpt.dart';
import 'package:trios/shipViewer/models/ship_weapon_slot.dart';
import 'package:trios/shipViewer/ship_module_resolver.dart';
import 'package:trios/shipViewer/widgets/ship_sprite_composite.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/weaponViewer/models/weapon.dart';
import 'package:trios/widgets/moving_tooltip.dart';

/// Builds tooltip content for ships, replicating the layout of the game's
/// ship codex panel: title, two-column stats with sprite, system, mounts,
/// armaments, hull mods, and design-type footer.
class IngameShipTooltip {
  IngameShipTooltip._();

  static const _maxWidth = 720.0;

  // ───────────────────────── Convenience wrapper ─────────────────────────

  /// Wraps [child] in a [MovingTooltipWidget] that shows ship stats on hover.
  static Widget ship({
    required Ship ship,
    required Map<String, ShipSystem> shipSystemsMap,
    required Map<String, Weapon> weaponsMap,
    required Widget child,
    List<ResolvedModule> modules = const [],
  }) {
    return Builder(
      builder: (context) => MovingTooltipWidget.framed(
        tooltipWidget: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxWidth),
          child: buildShipContent(
            ship,
            shipSystemsMap,
            weaponsMap,
            context,
            modules: modules,
          ),
        ),
        child: child,
      ),
    );
  }

  // ───────────────────────── Ship tooltip ─────────────────────────

  static Widget buildShipContent(
    Ship ship,
    Map<String, ShipSystem> shipSystemsMap,
    Map<String, Weapon> weaponsMap,
    BuildContext context, {
    List<ResolvedModule> modules = const [],
  }) {
    final theme = Theme.of(context);
    final highlightColor = theme.colorScheme.primary;

    final shieldUpper = ship.shieldType?.toUpperCase();
    final hasShield =
        shieldUpper != null && shieldUpper != 'NONE' && shieldUpper != 'PHASE';
    final hasPhase = shieldUpper == 'PHASE';
    final defenseLabel = hasPhase
        ? 'Phase cloak'
        : hasShield
        ? '${ship.shieldType!.toTitleCase()} shield'
        : 'None';

    final sprite = _shipSprite(ship, modules);
    final mountGroups = _groupMounts(ship);
    final hasBays = (ship.fighterBays ?? 0) > 0;
    final List<String> armaments = [
      ...(ship.builtInWeapons?.values ?? const Iterable.empty()).map(
        (id) => weaponsMap[id]?.name ?? _toDisplay(id),
      ),
      ...(ship.builtInWings ?? const []).map(
        (id) => _toDisplay(id),
      ),
    ];
    final hullMods = ship.builtInMods ?? const [];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Title ──
        _buildTitle(ship, theme, highlightColor),
        const SizedBox(height: 8),

        // ════════ Two columns: Logistical Data | Combat Performance + Sprite ════════
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 16,
          children: [
            // ── Left: Logistical Data ──
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 4,
                children: [
                  _sectionHeader('Logistical data', theme, highlightColor),
                  Row(
                    children: [
                      Expanded(
                        child: _statsGrid(theme, [
                          if (ship.crToDeploy != null)
                            _row(
                              'CR per deployment',
                              '${_fmt(ship.crToDeploy)}%',
                            ),
                          if (ship.crPercentPerDay != null)
                            _row(
                              'CR recovery/day',
                              '${_fmt(ship.crPercentPerDay)}%/day',
                            ),
                          if (ship.fleetPts != null)
                            _row('Deployment points', _fmt(ship.fleetPts)),
                          if (ship.peakCrSec != null)
                            _row(
                              'Peak performance',
                              _peakTime(ship.peakCrSec!),
                            ),
                          _gap,
                          if (ship.minCrew != null || ship.maxCrew != null)
                            _row(
                              'Crew',
                              ship.minCrew == ship.maxCrew
                                  ? _fmt(ship.maxCrew)
                                  : '${_fmt(ship.minCrew)} \u2013 ${_fmt(ship.maxCrew)}',
                            ),
                          _row('Hull size', ship.hullSizeForDisplay()),
                          if (ship.ordnancePoints != null)
                            _row('Ordnance points', _fmt(ship.ordnancePoints)),
                        ]),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _statsGrid(theme, [
                          if (ship.suppliesMo != null)
                            _row('Maintenance/month', _fmt(ship.suppliesMo)),
                          if (ship.suppliesRec != null)
                            _row('Supplies to recover', _fmt(ship.suppliesRec)),
                          if (ship.cargo != null)
                            _row('Cargo', _fmt(ship.cargo)),
                          if (ship.fuel != null)
                            _row('Fuel capacity', _fmt(ship.fuel)),
                          if (ship.maxBurn != null)
                            _row('Max burn', _fmt(ship.maxBurn)),
                          if (ship.fuelPerLY != null)
                            _row('Fuel/light-year', _fmt(ship.fuelPerLY)),
                        ]),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Middle: Combat Performance ──
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 4,
                children: [
                  _sectionHeader('Combat performance', theme, highlightColor),
                  _statsGrid(theme, [
                    if (ship.hitpoints != null)
                      _row('Hull integrity', _fmt(ship.hitpoints)),
                    if (ship.armorRating != null)
                      _row('Armor rating', _fmt(ship.armorRating)),
                    _gap,
                    _row('Defense', defenseLabel),
                    if (hasShield) ...[
                      if (ship.shieldArc != null)
                        _row('Shield arc', '${_fmt(ship.shieldArc)}\u00B0'),
                      if (ship.shieldUpkeep != null)
                        _row('Shield upkeep/sec', _fmt(ship.shieldUpkeep)),
                      if (ship.shieldEfficiency != null)
                        _row(
                          'Shield flux/damage',
                          _fmt(ship.shieldEfficiency, forceDecimal: true),
                        ),
                    ],
                    if (hasPhase) ...[
                      if (ship.phaseCost != null)
                        _row(
                          'Phase cost',
                          _fmt(ship.phaseCost, forceDecimal: true),
                        ),
                      if (ship.phaseUpkeep != null)
                        _row(
                          'Phase upkeep/sec',
                          _fmt(ship.phaseUpkeep, forceDecimal: true),
                        ),
                    ],
                    _gap,
                    if (ship.maxFlux != null)
                      _row('Flux capacity', _fmt(ship.maxFlux)),
                    if (ship.fluxDissipation != null)
                      _row('Flux dissipation', _fmt(ship.fluxDissipation)),
                    _gap,
                    if (ship.maxSpeed != null)
                      _row('Top speed', _fmt(ship.maxSpeed)),
                    if (ship.maxTurnRate != null)
                      _row('Turn rate', '${_fmt(ship.maxTurnRate)}\u00B0/s'),
                    if (ship.acceleration != null)
                      _row('Acceleration', _fmt(ship.acceleration)),
                    if (ship.mass != null) _row('Mass', _fmt(ship.mass)),
                  ]),
                ],
              ),
            ),
            ?sprite,
          ],
        ),

        // ════════ System / Mounts / Armaments / Hull Mods ════════
        if (ship.systemId != null ||
            mountGroups.isNotEmpty ||
            hasBays ||
            armaments.isNotEmpty ||
            hullMods.isNotEmpty) ...[
          const SizedBox(height: 8),
          _hairline(theme),
          const SizedBox(height: 6),
          Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 4,
            children: [
              if (ship.systemId != null)
                Row(
                  spacing: 8,
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text('System:', style: theme.textTheme.bodySmall),
                    ),
                    Expanded(
                      child: Text(
                        _toDisplay(
                          shipSystemsMap[ship.systemId!]?.name ??
                              ship.systemId!,
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: highlightColor.withValues(alpha: 0.85),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              if (mountGroups.isNotEmpty || hasBays)
                Row(
                  spacing: 8,
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text('Mounts:', style: theme.textTheme.bodySmall),
                    ),
                    Expanded(
                      child: _mountWrap(
                        mountGroups,
                        ship.fighterBays,
                        theme,
                        highlightColor,
                      ),
                    ),
                  ],
                ),
              if (armaments.isNotEmpty)
                Row(
                  spacing: 8,
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        'Armaments:',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        armaments.join(", "),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.80,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              if (hullMods.isNotEmpty)
                Row(
                  spacing: 8,
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        'Hull Mods:',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        hullMods.map(_toDisplay).join(", "),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.80,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],

        // ════════ Design type footer ════════
        if (ship.techManufacturer != null) ...[
          const SizedBox(height: 8),
          _hairline(theme),
          const SizedBox(height: 6),
          Row(
            spacing: 6,
            children: [
              Text(
                'Design type:',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.50),
                ),
              ),
              Text(
                ship.techManufacturer!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: highlightColor.withValues(alpha: 0.90),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ───────────────────────── Layout helpers ─────────────────────────

/// Title block: ship name, optional designation as subtitle.
Widget _buildTitle(Ship ship, ThemeData theme, Color highlightColor) {
  final name = ship.hullNameForDisplay();
  final designation = ship.designation;
  final subtitle = designation != null && designation != name
      ? designation
      : null;

  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        name,
        style: theme.textTheme.titleMedium?.copyWith(
          color: highlightColor,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
      if (subtitle != null)
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: highlightColor.withValues(alpha: 0.60),
          ),
        ),
    ],
  );
}

/// Gold-accented section header bar with left border stripe.
Widget _sectionHeader(String text, ThemeData theme, Color highlightColor) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
    decoration: BoxDecoration(
      color: highlightColor.withValues(alpha: 0.10),
      border: Border(
        left: BorderSide(
          color: highlightColor.withValues(alpha: 0.65),
          width: 2,
        ),
      ),
    ),
    child: Center(
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: highlightColor.withValues(alpha: 0.90),
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    ),
  );
}

/// Thin 1 dp horizontal rule between sections.
Widget _hairline(ThemeData theme) => Divider(
  height: 1,
  thickness: 1,
  color: theme.colorScheme.onSurface.withValues(alpha: 0.10),
);

/// Ship silhouette sprite constrained to 128 px tall, or null if unavailable.
/// When [modules] is non-empty, renders the composite sprite with modules.
Widget? _shipSprite(Ship ship, List<ResolvedModule> modules) {
  final path = ship.spriteFile;
  if (path == null) return null;

  if (modules.isNotEmpty) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 128),
      child: ShipSpriteComposite(
        ship: ship,
        modules: modules,
        fit: BoxFit.contain,
      ),
    );
  }

  return ConstrainedBox(
    constraints: const BoxConstraints(maxHeight: 128),
    child: Image.file(
      File(path),
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    ),
  );
}

/// Groups mountable slots by "Size Type" and returns a size-sorted map.
Map<String, int> _groupMounts(Ship ship) {
  final groups = <String, int>{};
  for (final ShipWeaponSlot slot in ship.weaponSlots ?? const []) {
    if (!slot.isMountable) continue;
    final key = '${slot.size.toTitleCase()} ${slot.type.toTitleCase()}';
    groups[key] = (groups[key] ?? 0) + 1;
  }
  const sizeOrder = {'Large': 0, 'Medium': 1, 'Small': 2};
  return Map.fromEntries(
    groups.entries.toList()..sort((a, b) {
      final aO = sizeOrder[a.key.split(' ').first] ?? 9;
      final bO = sizeOrder[b.key.split(' ').first] ?? 9;
      return aO != bO ? aO.compareTo(bO) : a.key.compareTo(b.key);
    }),
  );
}

/// Renders mount groups + fighter bays as a wrapping list of rich-text items
/// with the count portion highlighted in [highlightColor].
Widget _mountWrap(
  Map<String, int> groups,
  double? fighterBays,
  ThemeData theme,
  Color highlightColor,
) {
  final baseStyle = theme.textTheme.bodySmall?.copyWith(
    color: theme.colorScheme.onSurface.withValues(alpha: 0.80),
  );
  final countStyle = baseStyle?.copyWith(
    color: highlightColor.withValues(alpha: 0.85),
    fontWeight: FontWeight.bold,
  );

  final items = <({String count, String label})>[
    ...groups.entries.map(
      (e) => (count: '${e.value}\u00D7', label: ' ${e.key}'),
    ),
    if (fighterBays != null && fighterBays > 0)
      (count: '${_fmt(fighterBays)}\u00D7', label: ' Fighter bay'),
  ];

  return Wrap(
    spacing: 16,
    runSpacing: 2,
    children: items
        .map(
          (item) => Text.rich(
            TextSpan(
              children: [
                TextSpan(text: item.count, style: countStyle),
                TextSpan(text: item.label, style: baseStyle),
              ],
            ),
          ),
        )
        .toList(),
  );
}

/// Renders a collection of raw IDs as small labelled chips.
Widget _idWrap(Iterable<String> ids, ThemeData theme) {
  return Wrap(
    spacing: 4,
    runSpacing: 4,
    children: ids.map((id) => _idChip(id, theme)).toList(),
  );
}

Widget _idChip(String id, ThemeData theme) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
    decoration: BoxDecoration(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.07),
      border: Border.all(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.18),
      ),
      borderRadius: BorderRadius.circular(3),
    ),
    child: Text(
      _toDisplay(id),
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
      ),
    ),
  );
}

/// Converts a snake_case / kebab-case id to a Title Cased display string.
String _toDisplay(String id) =>
    id.replaceAll('_', ' ').replaceAll('-', ' ').toTitleCase();

/// Converts peak CR seconds to a human-readable duration string.
String _peakTime(double secs) =>
    secs >= 60 ? '${_fmt(secs / 60)} min' : '${_fmt(secs)} s';

// ───────────────────────── Stats grid ─────────────────────────

/// Builds a two-column [Table] from a list of [_StatEntry] items.
Widget _statsGrid(ThemeData theme, List<_StatEntry> entries) {
  return Table(
    columnWidths: const {0: FlexColumnWidth(), 1: IntrinsicColumnWidth()},
    defaultVerticalAlignment: TableCellVerticalAlignment.baseline,
    textBaseline: TextBaseline.alphabetic,
    children: entries.map((e) => e._build(theme)).toList(),
  );
}

/// A label–value stat row.
_StatEntry _row(String label, String value) =>
    _StatEntry(label: label, value: value);

/// An empty spacer row.
const _gap = _StatEntry.gap();

/// Formats a number to match the game's display logic.
///
/// Integer-valued numbers render without decimals. Small fractional values
/// show 1–2 decimal places; large ones (|n| > 10) are rounded.
/// [forceDecimal] prevents the integer shortcut (used for ratios like
/// flux-per-damage).
String _fmt(num? n, {bool forceDecimal = false}) {
  if (n == null) return '-';
  final v = n.toDouble();

  if (!forceDecimal && (v.roundToDouble() - v).abs() < 1e-4) {
    return v.round().toString();
  }

  if ((v * 100).round() == (v * 10).round() * 10) {
    return v.abs() > 10 ? v.round().toString() : v.toStringAsFixed(1);
  }

  return v.abs() > 10 ? v.round().toString() : v.toStringAsFixed(2);
}

// ─────────────────────────────────────────────────────────────────────────────

/// Lightweight descriptor for a single stat row or spacer in a [Table].
class _StatEntry {
  final String label;
  final String value;
  final bool _isGap;

  const _StatEntry({required this.label, required this.value}) : _isGap = false;

  const _StatEntry.gap() : label = '', value = '', _isGap = true;

  TableRow _build(ThemeData theme) {
    if (_isGap) {
      return const TableRow(
        children: [SizedBox(height: 5), SizedBox(height: 5)],
      );
    }

    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 1, bottom: 1),
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.95),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
