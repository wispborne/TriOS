import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/descriptions/description_entry.dart';
import 'package:trios/descriptions/descriptions_manager.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/weapon_viewer/models/weapon.dart';
import 'package:trios/weapon_viewer/widgets/weapon_mount_indicator.dart';
import 'package:trios/widgets/description_with_substitutions.dart';
import 'package:trios/widgets/ingame_tooltip_shared.dart';
import 'package:trios/widgets/moving_tooltip.dart';

/// Builds tooltip content for weapons, replicating the layout and
/// conditional logic of the game's `CargoTooltipFactory`.
class IngameWeaponTooltip {
  IngameWeaponTooltip._();

  static const _maxWidth = 400.0;

  // ───────────────────────── Convenience wrapper ─────────────────────────

  /// Wraps [child] in a [MovingTooltipWidget] that shows weapon stats on hover.
  static Widget weapon({required Weapon weapon, required Widget child}) {
    return MovingTooltipWidget.starsector(
      tooltipWidget: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxWidth),
        child: Consumer(
          builder: (context, ref, _) => buildWeaponContent(
            weapon,
            context,
            description: ref.watch(
              descriptionProvider((weapon.id, DescriptionEntry.typeWeapon)),
            ),
          ),
        ),
      ),
      child: child,
    );
  }

  // ───────────────────────── Weapon tooltip ─────────────────────────

  /// Builds the weapon tooltip body, mimicking the game's weapon tooltip with
  /// Primary Data and Ancillary Data sections.
  static Widget buildWeaponContent(
    Weapon weapon,
    BuildContext context, {
    DescriptionEntry? description,
  }) {
    final theme = Theme.of(context);
    final highlightColor = ThemeManager.vanillaCyanColor;

    final isBeam = weapon.specClass?.toLowerCase().contains('beam') == true;
    final isMissile =
        weapon.effectiveMountType?.toUpperCase() == 'MISSILE' ||
        weapon.specClass?.toLowerCase().contains('missile') == true;
    final isSoftFlux = isBeam || weapon.tagsAsSet.contains('damage_soft_flux');
    final showStats = !weapon.tagsAsSet.contains('no_standard_data');
    final noDPS = weapon.noDPSInTooltip == true;
    final usesAmmo = weapon.ammo != null && weapon.ammo! > 0;
    final hasReload =
        usesAmmo && weapon.ammoPerSec != null && weapon.ammoPerSec! > 0;
    final isEnergyType = weapon.effectiveMountType?.toUpperCase() == 'ENERGY';
    // Ammo present but no reload/recharge — game's `var66`.
    final limitedAmmo = usesAmmo && !hasReload;

    // ── Derived stats (faithful to WeaponSpreadsheetLoader in the game JAR) ──
    //
    // For BEAM weapons the game reads `damage/second` straight from the CSV and
    // computes fluxPerDam = energyPerSecond / dps.
    //
    // For PROJECTILE weapons `damage/second` is absent from the CSV; the game
    // computes everything from the raw timing columns:
    //   cycleTime  = chargeup + chargedown + burstDelay * (burstSize - 1)
    //   dps        = damagePerShot * burstSize / cycleTime
    //   fluxPerDam = (chargeup*energyPerSecond + energyPerShot*burstSize)
    //                / max(1, damagePerShot * burstSize)
    //   fluxPerSec = dps * fluxPerDam
    //   sustainedDps = damagePerShot * ammoPerSecond  (ammo-regen limited)

    final int burstSize = weapon.burstSize?.toInt().clamp(1, 99999) ?? 1;
    final double chargeup = weapon.chargeup ?? 0.0;
    final double chargedown = weapon.chargedown ?? 0.0; // refireDelay for proj.
    final double burstDelay = weapon.burstDelay ?? 0.0;

    // chargeTime + refireDelay + burstDelay * (burstSize - 1)
    final double cycleTime =
        chargeup +
        chargedown +
        burstDelay * (burstSize > 1 ? (burstSize - 1).toDouble() : 0.0);

    // Effective burst DPS.
    double? effectiveDps;
    if (isBeam) {
      final v = weapon.damagePerSecond ?? 0;
      if (v > 0) effectiveDps = v.toDouble();
    } else {
      final dmg = weapon.damagePerShot ?? 0.0;
      if (dmg > 0 && cycleTime > 0) effectiveDps = dmg * burstSize / cycleTime;
    }

    // Sustained (ammo-regen) DPS: damagePerShot * ammoPerSecond.
    double? sustainedDps;
    if (effectiveDps != null &&
        !isBeam &&
        weapon.ammoPerSec != null &&
        weapon.ammoPerSec! > 0 &&
        weapon.damagePerShot != null) {
      final s = weapon.damagePerShot! * weapon.ammoPerSec!;
      if ((s - effectiveDps).abs() / effectiveDps >= 0.01) sustainedDps = s;
    }

    // Total flux per firing cycle: chargeup*energyPerSecond + energyPerShot*burstSize
    final double totalFluxPerCycle =
        chargeup * (weapon.energyPerSecond ?? 0.0) +
        (weapon.energyPerShot ?? 0.0) * burstSize;

    // Flux / damage.
    double? fluxPerDam;
    if (isBeam) {
      if (effectiveDps != null &&
          effectiveDps > 0 &&
          (weapon.energyPerSecond ?? 0) > 0) {
        fluxPerDam = weapon.energyPerSecond! / effectiveDps;
      }
    } else {
      final totalDmg = (weapon.damagePerShot ?? 0.0) * burstSize;
      if (totalFluxPerCycle > 0) {
        fluxPerDam = totalFluxPerCycle / math.max(1.0, totalDmg);
      }
    }

    // Flux / second = dps * fluxPerDam.
    // Fallback for beams where effectiveDps couldn't be resolved.
    double? fluxPerSecond;
    if (effectiveDps != null && fluxPerDam != null) {
      fluxPerSecond = effectiveDps * fluxPerDam;
    } else if (isBeam && (weapon.energyPerSecond ?? 0) > 0) {
      fluxPerSecond = weapon.energyPerSecond!.toDouble();
    }

    // Sustained flux / second = sustainedDps * fluxPerDam.
    final double? sustainedFluxPerSecond =
        (sustainedDps != null && fluxPerDam != null)
        ? sustainedDps! * fluxPerDam!
        : null;

    // hasSustained mirrors game's `var67` (dps ≠ sustainedDps) and controls
    // whether both DPS and Flux/second rows show the "(sustained)" variant.
    final bool hasSustained = sustainedDps != null;
    final bool hasFluxCost = (fluxPerSecond ?? 0) > 0;

    // Refire delay display value (projectile weapons only).
    // Game: refireDelay + burstFireDuration = chargedown + chargeup + burstDelay*(burstSize-1)
    //     = cycleTime
    final double? refireDelaySeconds = !isBeam && cycleTime > 0
        ? cycleTime
        : null;

    final showBurstSize =
        isMissile && weapon.burstSize != null && weapon.burstSize! > 1;
    final showRefireDelay = refireDelaySeconds != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Title & manufacturer ──
        tooltipTitleWithDesignType(
          weapon.name ?? weapon.id,
          weapon.techManufacturer,
          true,
          theme,
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
        tooltipSectionHeader('Primary data', theme, highlightColor),
        const SizedBox(height: 4),
        _iconRow(
              icon: _weaponSprite(weapon),
              child: tooltipStatsGrid(theme, [
                if (weapon.primaryRoleStr != null)
                  tooltipRow('Primary role', weapon.primaryRoleStr!),
                tooltipRow('Mount type', _mountType(weapon)),
                ..._mountNotes(weapon),
                // "Counts as X for stat modifiers" when mount type differs from
                // actual weapon type.
                if (weapon.weaponType != null &&
                    weapon.mountTypeOverride != null &&
                    weapon.weaponType!.toUpperCase() !=
                        weapon.mountTypeOverride!.toUpperCase())
                  tooltipNote(
                    'Counts as ${weapon.weaponType!.toTitleCase()} for stat modifiers',
                  ),
                if (weapon.ops != null)
                  tooltipRow('Ordnance points', '${weapon.ops}'),
                tooltipGap,

                if (showStats) ...[
                  if (weapon.range != null)
                    tooltipRow('Range', tooltipFmt(weapon.range)),
                  if (!isBeam && weapon.damagePerShot != null)
                    tooltipRow('Damage', tooltipFmt(weapon.damagePerShot)),
                  if (!noDPS && effectiveDps != null)
                    tooltipRow(
                      hasSustained
                          ? 'Damage / second (sustained)'
                          : 'Damage / second',
                      hasSustained
                          ? '${tooltipFmt(effectiveDps)} (${tooltipFmt(sustainedDps)})'
                          : tooltipFmt(effectiveDps),
                    ),
                  if (weapon.emp != null && weapon.emp! > 0)
                    tooltipRow(
                      isBeam ? 'EMP DPS' : 'EMP damage',
                      tooltipFmt(weapon.emp),
                    ),
                  tooltipGap,
                ],

                // Flux cost section.
                if (hasFluxCost) ...[
                  if (!noDPS && fluxPerSecond != null)
                    tooltipRow(
                      hasSustained
                          ? 'Flux / second (sustained)'
                          : 'Flux / second',
                      hasSustained && sustainedFluxPerSecond != null
                          ? '${tooltipFmt(fluxPerSecond)} (${tooltipFmt(sustainedFluxPerSecond)})'
                          : tooltipFmt(fluxPerSecond),
                    ),
                  if (!isBeam && (weapon.energyPerShot ?? 0) > 0)
                    tooltipRow('Flux / shot', tooltipFmt(weapon.energyPerShot)),
                  if (fluxPerDam != null)
                    tooltipRow(
                      weapon.emp != null && weapon.emp! > 0
                          ? 'Flux / non-EMP damage'
                          : 'Flux / damage',
                      tooltipFmt(fluxPerDam, forceDecimal: true),
                    ),
                  if (limitedAmmo) ...[
                    tooltipGap,
                    tooltipNoteRight(
                      'Limited ${isEnergyType ? "charges" : "ammo"}'
                      ' (${tooltipFmt(weapon.ammo)})',
                    ),
                  ],
                ] else if (limitedAmmo) ...[
                  tooltipNoteRight(
                    'No flux cost to fire, limited '
                    '${isEnergyType ? "charges" : "ammo"} (${tooltipFmt(weapon.ammo)})',
                  ),
                ] else ...[
                  tooltipNote('No flux cost to fire'),
                ],
              ]),
            ) ??
            const SizedBox(),

        // Custom primary text (game: customPrimary with %s highlights).
        if ((weapon.customPrimary ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: DescriptionWithSubstitutions(
              description: weapon.customPrimary!,
              highlightValues: weapon.customPrimaryHL,
              highlightColor: ThemeManager.vanillaYellowGoldColor,
              baseStyle: theme.textTheme.bodySmall,
            ),
          ),

        const SizedBox(height: 8),

        // ════════════ Ancillary data ════════════
        tooltipSectionHeader('Ancillary data', theme, highlightColor),
        const SizedBox(height: 4),
        _iconRow(
              icon: SizedBox(width: 80), //_damageTypeIcon(weapon, theme),
              child: tooltipStatsGrid(theme, [
                if (showStats) ...[
                  tooltipRow('Damage type', _damageTypeName(weapon, isBeam)),
                  if (_damageTypeDesc(weapon, isSoftFlux).isNotEmpty)
                    tooltipNoteRight(_damageTypeDesc(weapon, isSoftFlux)),
                  tooltipGap,

                  // Core ancillary stats — shown for all weapon types.
                  if (weapon.accuracyStr != null)
                    tooltipRow('Accuracy', weapon.accuracyStr!)
                  else if (isBeam)
                    tooltipRow('Accuracy', 'Perfect')
                  else if (weapon.maxSpread != null)
                    tooltipRow(
                      'Accuracy',
                      _accuracyDisplayName(weapon.maxSpread!),
                    ),
                  if (weapon.turnRateStr != null)
                    tooltipRow('Turn rate', weapon.turnRateStr!)
                  else if (weapon.turnRate != null)
                    tooltipRow(
                      'Turn rate',
                      _turnRateDisplayName(weapon.turnRate!),
                    ),

                  // Missile-specific stats.
                  if (isMissile) ...[
                    tooltipGap,
                    if (weapon.speedStr != null || weapon.projSpeed != null)
                      tooltipRow(
                        'Speed',
                        weapon.speedStr ?? tooltipFmt(weapon.projSpeed),
                      ),
                    if (weapon.trackingStr != null)
                      tooltipRow('Tracking', weapon.trackingStr!),
                    if (weapon.projHitpoints != null &&
                        weapon.projHitpoints! > 0)
                      tooltipRow('Hitpoints', tooltipFmt(weapon.projHitpoints)),
                  ],
                ],

                // Ammo / charges — missiles only.
                if (usesAmmo && hasReload) ...[
                  tooltipGap,
                  tooltipRow(
                    isEnergyType ? 'Max charges' : 'Max ammo',
                    tooltipFmt(weapon.ammo),
                  ),
                  if (weapon.reloadSize != null && weapon.ammoPerSec! > 0)
                    tooltipRow(
                      isEnergyType ? 'Seconds / recharge' : 'Seconds / reload',
                      tooltipFmt(weapon.reloadSize! / weapon.ammoPerSec!),
                    ),
                  if (weapon.reloadSize != null)
                    tooltipRow(
                      isEnergyType ? 'Charges gained' : 'Reload size',
                      tooltipFmt(weapon.reloadSize),
                    ),
                ] else if (isMissile && usesAmmo) ...[
                  tooltipGap,
                  tooltipRow(
                    isEnergyType ? 'Charges' : 'Ammo',
                    tooltipFmt(weapon.ammo),
                  ),
                ],

                if (showBurstSize || showRefireDelay) tooltipGap,

                // Burst size — missiles only.
                if (showBurstSize)
                  tooltipRow('Burst size', '${weapon.burstSize}'),

                if (showRefireDelay)
                  tooltipRow(
                    'Refire delay (seconds)',
                    tooltipFmt(refireDelaySeconds),
                  ),
              ]),
            ) ??
            const SizedBox(),

        // Custom ancillary text.
        if ((weapon.customAncillary ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: DescriptionWithSubstitutions(
              description: weapon.customAncillary!,
              highlightValues: weapon.customAncillaryHL,
              highlightColor: theme.colorScheme.primary,
              baseStyle: theme.textTheme.bodySmall,
            ),
          ),

        // ════════ Description from descriptions.csv ════════
        if (description?.text1 != null) ...[
          const SizedBox(height: 8),
          tooltipHairline(theme),
          const SizedBox(height: 6),
          DescriptionWithSubstitutions(
            description: description!.text1!,
            baseStyle: theme.textTheme.bodySmall,
          ),
        ],
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

/// Returns an 80×80 weapon turret sprite with geometric mount-type indicator,
/// matching the game's codex weapon display.
Widget? _weaponSprite(Weapon weapon) {
  if (weapon.turretSprite == null && weapon.effectiveMountType == null)
    return null;
  return WeaponMountIndicator(weapon: weapon, size: 80);
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

/// Maps maxSpread to the game's accuracy display name.
/// Thresholds from `Oo0O.getAccuracyDisplayName` in the game JAR.
String _accuracyDisplayName(double maxSpread) {
  if (maxSpread <= 0) return 'Perfect';
  if (maxSpread <= 2) return 'Excellent';
  if (maxSpread <= 5) return 'Good';
  if (maxSpread <= 10) return 'Medium';
  if (maxSpread <= 15) return 'Poor';
  if (maxSpread <= 20) return 'Very Poor';
  return 'Terrible';
}

/// Maps turnRate to the game's display name.
/// Thresholds from `BaseWeaponSpec.getTurnRateDisplayName` in the game JAR.
String _turnRateDisplayName(double turnRate) {
  if (turnRate <= 0) return "Can't turn";
  if (turnRate <= 5) return 'Very Slow';
  if (turnRate <= 15) return 'Slow';
  if (turnRate <= 25) return 'Medium';
  if (turnRate <= 35) return 'Fast';
  if (turnRate <= 50) return 'Very Fast';
  return 'Excellent';
}

/// Returns the game's description sentence for the damage type,
/// with " (no hard flux)" appended for soft-flux weapons (beams, etc.).
String _damageTypeDesc(Weapon weapon, bool isSoftFlux) {
  final base = switch (weapon.damageType?.toUpperCase()) {
    'KINETIC' => '200% vs shields, 50% vs armor',
    'HIGH_EXPLOSIVE' => '200% vs armor, 50% vs shields',
    'FRAGMENTATION' => '25% vs shields and armor, 100% vs hull',
    'ENERGY' => '100% vs shield, armor, and hull',
    _ => '',
  };
  if (base.isEmpty) return '';
  return isSoftFlux ? '$base (no hard flux)' : base;
}

/// Returns "Size, Type" for mount display, title-cased.
String _mountType(Weapon w) {
  final parts = <String>[];
  if (w.size != null) parts.add(w.size!.toTitleCase());
  if (w.effectiveMountType != null)
    parts.add(w.effectiveMountType!.toTitleCase());
  return parts.isEmpty ? '-' : parts.join(', ');
}

/// Slot compatibility notes for special mount types.
List<TooltipStatEntry> _mountNotes(Weapon w) {
  final note = switch (w.effectiveMountType?.toUpperCase()) {
    'HYBRID' => 'Requires a Ballistic, Energy, or Hybrid slot',
    'SYNERGY' => 'Requires an Energy, Missile, or Synergy slot',
    'COMPOSITE' => 'Requires a Ballistic, Missile, or Composite slot',
    'UNIVERSAL' => 'Can be installed in any type of slot',
    _ => null,
  };
  if (note == null) return const [];
  return [TooltipStatEntry(label: '', value: note, isNote: true)];
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
    return _isCtrl
        ? widget.ctrlBuilder(context)
        : widget.defaultBuilder(context);
  }
}
