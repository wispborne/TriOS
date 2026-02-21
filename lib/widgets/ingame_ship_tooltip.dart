import 'dart:io';

import 'package:flutter/material.dart';
import 'package:trios/shipViewer/models/shipGpt.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/moving_tooltip.dart';

/// Builds tooltip content for ships, replicating the layout and
/// conditional logic of the game's `CargoTooltipFactory`.
class IngameShipTooltip {
  IngameShipTooltip._();

  static const _maxWidth = 400.0;

  // ───────────────────────── Convenience wrapper ─────────────────────────

  /// Wraps [child] in a [MovingTooltipWidget] that shows ship stats on hover.
  static Widget ship({required Ship ship, required Widget child}) {
    return Builder(
      builder: (context) => MovingTooltipWidget.framed(
        tooltipWidget: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxWidth),
          child: buildShipContent(ship, context),
        ),
        child: child,
      ),
    );
  }

  // ───────────────────────── Ship tooltip ─────────────────────────

  /// Builds the ship tooltip body with sections for combat, defense,
  /// mobility, logistics, and economics.
  static Widget buildShipContent(Ship ship, BuildContext context) {
    final theme = Theme.of(context);

    final shieldTypeUpper = ship.shieldType?.toUpperCase();
    final hasShield = shieldTypeUpper != null &&
        shieldTypeUpper != 'NONE' &&
        shieldTypeUpper != 'PHASE';
    final hasPhase = shieldTypeUpper == 'PHASE';

    final shipSprite = _shipSprite(ship);

    final dimStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Ship silhouette sprite ──
        if (shipSprite != null) ...[
          shipSprite,
          const SizedBox(height: 8),
        ],

        // ── Title ──
        Text(
          ship.hullNameForDisplay(),
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (ship.designation != null)
          Text(
            ship.designation!,
            style: dimStyle,
          ),

        // ── Manufacturer + hull size (matching O0Oo.java: "Design type: [name]") ──
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              if (ship.techManufacturer != null) ...[
                Text('Design type: ', style: dimStyle),
                Text(
                  ship.techManufacturer!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary.withValues(alpha: 0.85),
                  ),
                ),
                Text(
                  '  \u2022  ${ship.hullSizeForDisplay()}',
                  style: dimStyle,
                ),
              ] else
                Text(ship.hullSizeForDisplay(), style: dimStyle),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // ════════════ Combat data ════════════
        _heading('Combat data', theme),
        const SizedBox(height: 4),
        _grid(theme, [
          if (ship.fleetPts != null) _row('Fleet points', _fmt(ship.fleetPts)),
          _row('Hull integrity', _fmt(ship.hitpoints)),
          _row('Armor rating', _fmt(ship.armorRating)),
          _gap,
          _row('Flux capacity', _fmt(ship.maxFlux)),
          _row('Flux dissipation', _fmt(ship.fluxDissipation)),
          if (ship.ordnancePoints != null)
            _row('Ordnance points', _fmt(ship.ordnancePoints)),
          if (ship.fighterBays != null && ship.fighterBays! > 0)
            _row('Fighter bays', _fmt(ship.fighterBays)),
          if (ship.mountableWeaponSlotCount > 0)
            _row('Weapon slots', '${ship.mountableWeaponSlotCount}'),
        ]),

        // ════════════ Defense ════════════
        if (hasShield || hasPhase) ...[
          const SizedBox(height: 8),
          _heading(hasPhase ? 'Phase cloak' : 'Shield data', theme),
          const SizedBox(height: 4),
          _grid(theme, [
            if (hasShield) ...[
              _row('Shield type', ship.shieldType!.toTitleCase()),
              if (ship.shieldArc != null)
                _row('Shield arc', '${_fmt(ship.shieldArc)}\u00B0'),
              if (ship.shieldUpkeep != null)
                _row('Shield upkeep', _fmt(ship.shieldUpkeep)),
              if (ship.shieldEfficiency != null)
                _row(
                  'Shield efficiency',
                  _fmt(ship.shieldEfficiency, forceDecimal: true),
                ),
            ],
            if (hasPhase) ...[
              if (ship.phaseCost != null)
                _row('Phase cost', _fmt(ship.phaseCost, forceDecimal: true)),
              if (ship.phaseUpkeep != null)
                _row(
                  'Phase upkeep',
                  _fmt(ship.phaseUpkeep, forceDecimal: true),
                ),
            ],
          ]),
        ],

        // ════════════ Mobility ════════════
        const SizedBox(height: 8),
        _heading('Mobility', theme),
        const SizedBox(height: 4),
        _grid(theme, [
          _row('Max speed', _fmt(ship.maxSpeed)),
          if (ship.acceleration != null)
            _row('Acceleration', _fmt(ship.acceleration)),
          if (ship.deceleration != null)
            _row('Deceleration', _fmt(ship.deceleration)),
          if (ship.maxTurnRate != null)
            _row('Max turn rate', '${_fmt(ship.maxTurnRate)}\u00B0/s'),
          if (ship.turnAcceleration != null)
            _row(
              'Turn acceleration',
              '${_fmt(ship.turnAcceleration)}\u00B0/s\u00B2',
            ),
          if (ship.mass != null) _row('Mass', _fmt(ship.mass)),
        ]),

        // ════════════ Logistics ════════════
        const SizedBox(height: 8),
        _heading('Logistics', theme),
        const SizedBox(height: 4),
        _grid(theme, [
          if (ship.minCrew != null || ship.maxCrew != null)
            _row('Crew', '${_fmt(ship.minCrew)} \u2013 ${_fmt(ship.maxCrew)}'),
          if (ship.cargo != null) _row('Cargo', _fmt(ship.cargo)),
          if (ship.fuel != null) _row('Fuel', _fmt(ship.fuel)),
          if (ship.fuelPerLY != null)
            _row('Fuel / light-year', _fmt(ship.fuelPerLY)),
          if (ship.range != null) _row('Range (ly)', _fmt(ship.range)),
          if (ship.maxBurn != null) _row('Max burn', _fmt(ship.maxBurn)),
        ]),

        // ════════════ Economics & CR ════════════
        const SizedBox(height: 8),
        _heading('Economics', theme),
        const SizedBox(height: 4),
        _grid(theme, [
          if (ship.baseValue != null) _row('Base value', _fmt(ship.baseValue)),
          if (ship.suppliesRec != null)
            _row('Supplies to recover', _fmt(ship.suppliesRec)),
          if (ship.suppliesMo != null)
            _row('Maintenance / month', _fmt(ship.suppliesMo)),
          _gap,
          if (ship.crToDeploy != null)
            _row('CR to deploy', '${_fmt(ship.crToDeploy! * 100)}%'),
          if (ship.crPercentPerDay != null)
            _row(
              'CR % / day',
              '${_fmt(ship.crPercentPerDay, forceDecimal: true)}%',
            ),
          if (ship.peakCrSec != null)
            _row('Peak deployment time', _fmt(ship.peakCrSec)),
          if (ship.crLossPerSec != null)
            _row(
              'CR degradation rate',
              _fmt(ship.crLossPerSec, forceDecimal: true),
            ),
        ]),
      ],
    );
  }
}

// ───────────────────────── Private helpers ─────────────────────────

/// Returns a full-width ship silhouette sprite constrained to 120 px tall,
/// or null if the resolved sprite path is unavailable.
Widget? _shipSprite(Ship ship) {
  final path = ship.spriteFile;
  if (path == null) return null;
  return Container(
    constraints: const BoxConstraints(maxHeight: 120),
    alignment: Alignment.center,
    child: Image.file(
      File(path),
      fit: BoxFit.contain,
      errorBuilder: (context, error, stack) => const SizedBox.shrink(),
    ),
  );
}

/// Colored section heading bar.
Widget _heading(String text, ThemeData theme) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
    decoration: BoxDecoration(
      color: theme.colorScheme.primary.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: theme.textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.primary,
      ),
    ),
  );
}

/// Builds a two-column [Table] from a list of [_StatEntry] items.
Widget _grid(ThemeData theme, List<_StatEntry> entries) {
  return Table(
    columnWidths: const {
      0: FlexColumnWidth(),
      1: IntrinsicColumnWidth(),
    },
    defaultVerticalAlignment: TableCellVerticalAlignment.baseline,
    textBaseline: TextBaseline.alphabetic,
    children: entries.map((e) => e._build(theme)).toList(),
  );
}

/// A label-value stat row.
_StatEntry _row(String label, String value) =>
    _StatEntry(label: label, value: value);

/// A full-width informational note (empty label, dimmer text).
_StatEntry _note(String text) =>
    _StatEntry(label: '', value: text, isNote: true);

/// An empty separator row.
const _gap = _StatEntry.gap();

/// Formats a number to match the game's display logic.
///
/// Integer-valued numbers render without decimals. Small fractional values
/// show 1-2 decimal places; large ones (|n| > 10) are rounded.
/// [forceDecimal] prevents the integer shortcut (used for ratios like
/// flux-per-damage).
String _fmt(num? n, {bool forceDecimal = false}) {
  if (n == null) return '-';
  final v = n.toDouble();

  // Integer check (game: Math.abs(Math.round(var0) - var0) < 1E-4).
  if (!forceDecimal && (v.roundToDouble() - v).abs() < 1e-4) {
    return v.round().toString();
  }

  // 1-decimal check (game: round(v*100) == round(v*10)*10).
  if ((v * 100).round() == (v * 10).round() * 10) {
    return v.abs() > 10 ? v.round().toString() : v.toStringAsFixed(1);
  }

  // 2 decimals.
  return v.abs() > 10 ? v.round().toString() : v.toStringAsFixed(2);
}

// ─────────────────────────────────────────────────────────────────────────────

/// Lightweight descriptor for a single stat row or separator in a [Table].
class _StatEntry {
  final String label;
  final String value;
  final bool isNote;
  final bool _isGap;

  const _StatEntry({
    required this.label,
    required this.value,
    this.isNote = false,
  }) : _isGap = false;

  const _StatEntry.gap()
      : label = '',
        value = '',
        isNote = false,
        _isGap = true;

  TableRow _build(ThemeData theme) {
    if (_isGap) {
      return const TableRow(
        children: [SizedBox(height: 6), SizedBox(height: 6)],
      );
    }

    final dimColor = theme.colorScheme.onSurface.withValues(alpha: 0.55);

    // Full-width note (no label).
    if (label.isEmpty) {
      return TableRow(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                color: dimColor,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox.shrink(),
        ],
      );
    }

    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 1, bottom: 1),
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
