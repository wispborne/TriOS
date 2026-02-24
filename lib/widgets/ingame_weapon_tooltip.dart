import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/weaponViewer/models/weapon.dart';
import 'package:trios/widgets/moving_tooltip.dart';

/// Builds tooltip content for weapons, replicating the layout and
/// conditional logic of the game's `CargoTooltipFactory`.
class IngameWeaponTooltip {
  IngameWeaponTooltip._();

  static const _maxWidth = 400.0;

  // ───────────────────────── Convenience wrapper ─────────────────────────

  /// Wraps [child] in a [MovingTooltipWidget] that shows weapon stats on hover.
  static Widget weapon({required Weapon weapon, required Widget child}) {
    return Builder(
      builder: (context) => MovingTooltipWidget.framed(
        tooltipWidget: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxWidth),
          child: buildWeaponContent(weapon, context),
        ),
        child: child,
      ),
    );
  }

  // ───────────────────────── Weapon tooltip ─────────────────────────

  /// Builds the weapon tooltip body, mimicking the game's weapon tooltip with
  /// Primary Data and Ancillary Data sections.
  static Widget buildWeaponContent(Weapon weapon, BuildContext context) {
    final theme = Theme.of(context);

    final isBeam = weapon.specClass?.toLowerCase().contains('beam') == true;
    final isMissile =
        weapon.type?.toUpperCase() == 'MISSILE' ||
        weapon.specClass?.toLowerCase().contains('missile') == true;
    final isSoftFlux = isBeam || weapon.tagsAsSet.contains('damage_soft_flux');
    final showStats = !weapon.tagsAsSet.contains('no_standard_data');
    final noDPS = weapon.noDPSInTooltip == true;
    final usesAmmo = weapon.ammo != null && weapon.ammo! > 0;
    final hasReload =
        usesAmmo && weapon.ammoPerSec != null && weapon.ammoPerSec! > 0;
    final isEnergyType = weapon.type?.toUpperCase() == 'ENERGY';
    final hasFluxCost =
        weapon.energyPerSecond != null && weapon.energyPerSecond! > 0;

    // Flux / damage ratio (game: getDerivedStats().getFluxPerDam()).
    String? fluxPerDamage;
    if (hasFluxCost &&
        weapon.damagePerSecond != null &&
        weapon.damagePerSecond! > 0) {
      fluxPerDamage = _fmt(
        weapon.energyPerSecond! / weapon.damagePerSecond!,
        forceDecimal: true,
      );
    }

    // Sustained DPS approximation for burst weapons.
    // The game computes this internally; we approximate from CSV data.
    String? sustainedDps;
    String? sustainedFlux;
    if (!noDPS &&
        weapon.burstSize != null &&
        weapon.burstSize! > 1 &&
        weapon.burstDelay != null &&
        weapon.damagePerShot != null) {
      final burstDuration =
          (weapon.chargeup ?? 0) +
          (weapon.burstSize! - 1) * (weapon.chargedown ?? 0) +
          weapon.burstDelay!;
      if (burstDuration > 0) {
        final sus = weapon.damagePerShot! * weapon.burstSize! / burstDuration;
        final dps = weapon.damagePerSecond ?? 0;
        if (dps > 0 && (sus - dps).abs() / dps > 0.01) {
          sustainedDps = _fmt(sus);
        }
        if (hasFluxCost &&
            weapon.energyPerShot != null &&
            weapon.energyPerSecond != null) {
          final susFlux =
              weapon.energyPerShot! * weapon.burstSize! / burstDuration;
          final fps = weapon.energyPerSecond ?? 0;
          if (fps > 0 && (susFlux - fps).abs() / fps > 0.01) {
            sustainedFlux = _fmt(susFlux);
          }
        }
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Title & manufacturer ──
        Text(
          weapon.name ?? weapon.id,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (weapon.techManufacturer != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              weapon.techManufacturer!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),

        // Optional description/tooltip override text (from "for weapon tooltip>>" CSV col).
        if ((weapon.forWeaponTooltip ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              weapon.forWeaponTooltip!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

        const SizedBox(height: 8),

        // ════════════ Primary data ════════════
        _heading('Primary data', theme),
        const SizedBox(height: 4),
        _iconRow(
              icon: _weaponSprite(weapon),
              child: _grid(theme, [
                if (weapon.primaryRoleStr != null)
                  _row('Primary role', weapon.primaryRoleStr!),
                _row('Mount type', _mountType(weapon)),
                ..._mountNotes(weapon),
                // "Counts as X for stat modifiers" when mount type differs from
                // actual weapon type.
                if (weapon.weaponType != null &&
                    weapon.type != null &&
                    weapon.weaponType!.toUpperCase() !=
                        weapon.type!.toUpperCase())
                  _note(
                    'Counts as ${weapon.weaponType!.toTitleCase()} for stat modifiers',
                  ),
                if (weapon.ops != null)
                  _row('Ordnance points', '${weapon.ops}'),
                _gap,

                if (showStats) ...[
                  if (weapon.range != null) _row('Range', _fmt(weapon.range)),
                  if (!isBeam && weapon.damagePerShot != null)
                    _row('Damage', _fmt(weapon.damagePerShot)),
                  if (!noDPS && weapon.damagePerSecond != null)
                    _row(
                      sustainedDps != null
                          ? 'Damage / second (sustained)'
                          : 'Damage / second',
                      sustainedDps != null
                          ? '${_fmt(weapon.damagePerSecond)} ($sustainedDps)'
                          : _fmt(weapon.damagePerSecond),
                    ),
                  if (weapon.emp != null && weapon.emp! > 0)
                    _row(isBeam ? 'EMP DPS' : 'EMP damage', _fmt(weapon.emp)),
                  _gap,
                ],

                // Flux cost section.
                if (hasFluxCost) ...[
                  if (!noDPS && weapon.energyPerSecond != null)
                    _row(
                      sustainedFlux != null
                          ? 'Flux / second (sustained)'
                          : 'Flux / second',
                      sustainedFlux != null
                          ? '${_fmt(weapon.energyPerSecond)} ($sustainedFlux)'
                          : _fmt(weapon.energyPerSecond),
                    ),
                  if (weapon.energyPerShot != null)
                    _row('Flux / shot', _fmt(weapon.energyPerShot)),
                  if (fluxPerDamage != null)
                    _row(
                      weapon.emp != null && weapon.emp! > 0
                          ? 'Flux / non-EMP damage'
                          : 'Flux / damage',
                      fluxPerDamage,
                    ),
                ] else if (!usesAmmo) ...[
                  _note('No flux cost to fire'),
                ] else ...[
                  _note(
                    'No flux cost to fire, limited '
                    '${isEnergyType ? "charges" : "ammo"} (${_fmt(weapon.ammo)})',
                  ),
                ],
              ]),
            ) ??
            const SizedBox(),

        // Custom primary text (game: customPrimary with %s highlights).
        if ((weapon.customPrimary ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: weapon.customPrimary!.replaceSubstitutionsRich(
              weapon.customPrimaryHL,
              highlightColor: theme.colorScheme.primary,
              baseStyle: theme.textTheme.bodySmall,
            ),
          ),

        const SizedBox(height: 8),

        // ════════════ Ancillary data ════════════
        _heading('Ancillary data', theme),
        const SizedBox(height: 4),
        _iconRow(
              icon: _damageTypeIcon(weapon, theme),
              child: _grid(theme, [
                if (showStats) ...[
                  _row('Damage type', _damageTypeName(weapon, isBeam)),
                  if (_damageTypeDesc(weapon, isSoftFlux).isNotEmpty)
                    _note(_damageTypeDesc(weapon, isSoftFlux)),
                  _gap,

                  // Missile / projectile-specific stats.
                  if (weapon.speedStr != null ||
                      (isMissile && weapon.projSpeed != null))
                    _row('Speed', weapon.speedStr ?? _fmt(weapon.projSpeed)),
                  if (weapon.trackingStr != null)
                    _row('Tracking', weapon.trackingStr!),
                  if (weapon.projHitpoints != null && weapon.projHitpoints! > 0)
                    _row('Hitpoints', _fmt(weapon.projHitpoints)),

                  // Accuracy (beams are always perfect in the game).
                  if (weapon.accuracyStr != null)
                    _row('Accuracy', weapon.accuracyStr!)
                  else if (isBeam)
                    _row('Accuracy', 'Perfect'),

                  // Turn rate.
                  if (weapon.turnRateStr != null)
                    _row('Turn rate', weapon.turnRateStr!)
                  else if (weapon.turnRate != null)
                    _row('Turn rate', '${_fmt(weapon.turnRate)}\u00B0/s'),
                  _gap,
                ],

                // Ammo / charges with reload info.
                if (usesAmmo && hasReload) ...[
                  _row(
                    isEnergyType ? 'Max charges' : 'Max ammo',
                    _fmt(weapon.ammo),
                  ),
                  if (weapon.reloadSize != null && weapon.ammoPerSec! > 0)
                    _row(
                      isEnergyType ? 'Seconds / recharge' : 'Seconds / reload',
                      _fmt(weapon.reloadSize! / weapon.ammoPerSec!),
                    ),
                  if (weapon.reloadSize != null)
                    _row(
                      isEnergyType ? 'Charges gained' : 'Reload size',
                      _fmt(weapon.reloadSize),
                    ),
                  _gap,
                ] else if (usesAmmo) ...[
                  _row(isEnergyType ? 'Charges' : 'Ammo', _fmt(weapon.ammo)),
                  _gap,
                ],

                // Burst & refire.
                if (weapon.burstSize != null && weapon.burstSize! > 1)
                  _row('Burst size', '${weapon.burstSize}'),
                if (weapon.burstDelay != null)
                  _row('Refire delay (seconds)', _fmt(weapon.burstDelay)),
              ]),
            ) ??
            const SizedBox(),

        // Custom ancillary text.
        if ((weapon.customAncillary ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: weapon.customAncillary!.replaceSubstitutionsRich(
              weapon.customAncillaryHL,
              highlightColor: theme.colorScheme.primary,
              baseStyle: theme.textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}

// ───────────────────────── Private helpers ─────────────────────────

/// Lays an 80×80 [icon] to the left of [child], matching the game's layout
/// of weapon sprite / damage-type icon beside the stat grid.
Widget? _iconRow({required Widget? icon, required Widget child}) {
  if (icon == null) return child;
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 8,
    children: [
      icon,
      Expanded(child: child),
    ],
  );
}

/// Returns an 80×80 weapon turret sprite, or null if unavailable.
Widget? _weaponSprite(Weapon weapon) {
  final path = weapon.turretSprite;
  if (path == null) return null;
  final file = File(path);
  return SizedBox(
    width: 80,
    height: 80,
    child: Image.file(
      file,
      width: 80,
      height: 80,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stack) =>
          const SizedBox(width: 80, height: 80),
    ),
  );
}

/// Returns an 80×80 colored box representing the damage type,
/// matching the game's damage-type icon beside the Ancillary Data grid.
Widget _damageTypeIcon(Weapon weapon, ThemeData theme) {
  final color = switch (weapon.damageType?.toUpperCase()) {
    'KINETIC' => Colors.lightBlue.shade300,
    'HIGH_EXPLOSIVE' => Colors.orange.shade400,
    'FRAGMENTATION' => Colors.lightGreen.shade400,
    'ENERGY' => Colors.cyan.shade300,
    _ => theme.colorScheme.primary,
  };
  return Container(
    width: 80,
    height: 80,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      border: Border.all(color: color.withValues(alpha: 0.35)),
      borderRadius: BorderRadius.circular(4),
    ),
  );
}

/// Returns the game's display name for the weapon's damage type.
/// For beam weapons, appends " (Beam)" matching the Java `var68` logic.
String _damageTypeName(Weapon weapon, bool isBeam) {
  final name = switch (weapon.damageType?.toUpperCase()) {
    'KINETIC' => 'Kinetic',
    'HIGH_EXPLOSIVE' => 'High Explosive',
    'FRAGMENTATION' => 'Fragmentation',
    'ENERGY' => 'Energy',
    _ => 'Other',
  };
  return isBeam ? '$name (Beam)' : name;
}

/// Returns the game's description sentence for the damage type,
/// with " (no hard flux)" appended for soft-flux weapons (beams, etc.).
String _damageTypeDesc(Weapon weapon, bool isSoftFlux) {
  final base = switch (weapon.damageType?.toUpperCase()) {
    'KINETIC' => 'Damage to armor and hull, 50% vs shields.',
    'HIGH_EXPLOSIVE' => 'Damage to hull, 50% vs armor.',
    'FRAGMENTATION' => 'Damage to crew, 10% vs shields and 25% vs armor.',
    'ENERGY' => 'Damage to shields, 50% vs armor.',
    _ => '',
  };
  if (base.isEmpty) return '';
  return isSoftFlux ? '$base (no hard flux)' : base;
}

/// Returns "Size, Type" for mount display, title-cased.
String _mountType(Weapon w) {
  final parts = <String>[];
  if (w.size != null) parts.add(w.size!.toTitleCase());
  if (w.type != null) parts.add(w.type!.toTitleCase());
  return parts.isEmpty ? '-' : parts.join(', ');
}

/// Slot compatibility notes for special mount types.
List<_StatEntry> _mountNotes(Weapon w) {
  final note = switch (w.type?.toUpperCase()) {
    'HYBRID' => 'Requires a Ballistic, Energy, or Hybrid slot',
    'SYNERGY' => 'Requires an Energy, Missile, or Synergy slot',
    'COMPOSITE' => 'Requires a Ballistic, Missile, or Composite slot',
    'UNIVERSAL' => 'Can be installed in any type of slot',
    _ => null,
  };
  if (note == null) return const [];
  return [_StatEntry(label: '', value: note, isNote: true)];
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
    columnWidths: const {0: FlexColumnWidth(), 1: IntrinsicColumnWidth()},
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

// ─────────────────────────────────────────────────────────────────────────────

/// Switches between two tooltip content widgets depending on whether the
/// Control key is currently held.
///
/// Designed to be placed as the `tooltipWidget` of [MovingTooltipWidget.framed]
/// so it lives inside the overlay and can call [setState] the instant Ctrl is
/// pressed or released — no mouse movement required.
///
/// ```dart
/// MovingTooltipWidget.framed(
///   tooltipWidget: CtrlSwappedTooltip(
///     defaultBuilder: (ctx) => MyNormalContent(item, ctx),
///     ctrlBuilder:    (ctx) => IngameWeaponTooltip.buildWeaponContent(item, ctx),
///   ),
///   child: child,
/// )
/// ```
class CtrlSwappedTooltip extends StatefulWidget {
  /// Built when no Control key is held — the existing / default tooltip.
  final WidgetBuilder defaultBuilder;

  /// Built when the Control key is held — the game-style cargo tooltip.
  final WidgetBuilder ctrlBuilder;

  const CtrlSwappedTooltip({
    super.key,
    required this.defaultBuilder,
    required this.ctrlBuilder,
  });

  @override
  State<CtrlSwappedTooltip> createState() => _CtrlSwappedTooltipState();
}

class _CtrlSwappedTooltipState extends State<CtrlSwappedTooltip> {
  bool _isCtrl = false;

  @override
  void initState() {
    super.initState();
    _isCtrl = HardwareKeyboard.instance.isControlPressed;
    HardwareKeyboard.instance.addHandler(_handleKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKey);
    super.dispose();
  }

  bool _handleKey(KeyEvent event) {
    final ctrl = HardwareKeyboard.instance.isControlPressed;
    if (ctrl != _isCtrl) setState(() => _isCtrl = ctrl);
    return false; // don't consume the event
  }

  @override
  Widget build(BuildContext context) {
    // TODO swap to new tooltip in 1.3.x
    // return _isCtrl
    return true ? widget.ctrlBuilder(context) : widget.defaultBuilder(context);
  }
}
