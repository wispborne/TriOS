import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/codex/models/codex_entry.dart';
import 'package:trios/codex/widgets/codex_reference_link.dart';
import 'package:trios/descriptions/description_entry.dart';
import 'package:trios/descriptions/descriptions_manager.dart';
import 'package:trios/trios/constants_theme.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/weapon_viewer/models/weapon.dart';
import 'package:trios/weapon_viewer/widgets/weapon_mount_indicator.dart';
import 'package:trios/widgets/description_with_substitutions.dart';
import 'package:trios/widgets/ingame_tooltip_shared.dart';
import 'package:trios/widgets/moving_tooltip.dart';

/// Builds tooltip content for weapons, replicating the layout and
/// conditional logic of the game's `CargoTooltipFactory`.
class WeaponCodexCard {
  WeaponCodexCard._();

  static const _maxWidth = 400.0;

  /// Fixed width of the values column in the weapon tooltip stats grid.
  /// Keeps Primary / Ancillary sections vertically aligned regardless of
  /// whether a row shows a plain number or a composite like "120 (85)".
  static const _statsValueColumnWidth = 160.0;

  // ───────────────────────── Convenience wrapper ─────────────────────────

  /// Wraps [child] in a [MovingTooltipWidget] that shows weapon stats on hover.
  ///
  /// When [onEntitySelected] is set (inside the Codex), the child also becomes
  /// clickable and a tap navigates to this weapon. Null everywhere else, so the
  /// viewer tabs keep their hover-only behaviour.
  static Widget tooltip({
    required Weapon weapon,
    required Widget child,
    bool showTitle = true,
    bool showSprite = true,
    bool showDescription = true,
    bool useAbbreviations = false,
    CodexEntitySelected? onEntitySelected,
  }) {
    return MovingTooltipWidget.starsector(
      tooltipWidget: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxWidth),
        child: SingleChildScrollView(
          child: Consumer(
            builder: (context, ref, _) => _buildWeaponContent(
              weapon,
              context,
              description: ref.watch(
                descriptionProvider((weapon.id, DescriptionEntry.typeWeapon)),
              ),
              showTitle: showTitle,
              showSprite: showSprite,
              showDescription: showDescription,
              useAbbreviations: useAbbreviations,
            ),
          ),
        ),
      ),
      child: asCodexLink(
        child,
        onEntitySelected,
        (CodexEntryType.weapon, weapon.id),
      ),
    );
  }

  static Widget create({
    required Weapon weapon,
    bool showTitle = true,
    bool showSprite = true,
    bool showDescription = true,
    bool useAbbreviations = false,
  }) {
    return Consumer(
      builder: (context, ref, _) => _buildWeaponContent(
        weapon,
        context,
        description: ref.watch(
          descriptionProvider((weapon.id, DescriptionEntry.typeWeapon)),
        ),
        showTitle: showTitle,
        showSprite: showSprite,
        showDescription: showDescription,
        useAbbreviations: useAbbreviations,
      ),
    );
  }

  // ───────────────────────── Weapon tooltip ─────────────────────────

  /// Builds the weapon tooltip body, mimicking the game's weapon tooltip with
  /// Primary Data and Ancillary Data sections.
  static Widget _buildWeaponContent(
    Weapon weapon,
    BuildContext context, {
    DescriptionEntry? description,
    bool showTitle = true,
    bool showSprite = true,
    bool showDescription = true,
    bool useAbbreviations = false,
  }) {
    final theme = Theme.of(context);
    final highlightColor = TriOSThemeConstants.vanillaCyanColor;

    final isBeam = weapon.isBeam;
    final isMissile =
        weapon.effectiveMountType?.toUpperCase() == 'MISSILE' ||
        weapon.specClass?.toLowerCase().contains('missile') == true;
    final hasMissileDisplay =
        isMissile || weapon.speedStr != null || weapon.trackingStr != null;
    final isSoftFlux = isBeam || weapon.tagsAsSet.contains('damage_soft_flux');
    final showStats = !weapon.tagsAsSet.contains('no_standard_data');
    final noDPS = weapon.noDPSInTooltip == true;
    final usesAmmo = weapon.ammo != null && weapon.ammo! > 0;
    final hasReload =
        usesAmmo && weapon.ammoPerSec != null && weapon.ammoPerSec! > 0;
    final isEnergyType = weapon.effectiveMountType?.toUpperCase() == 'ENERGY';
    // Ammo present but no reload/recharge — game's `var66`.
    final limitedAmmo = usesAmmo && !hasReload;

    // ── Derived stats (memoized on the Weapon model) ──
    final isBurstBeam = weapon.isBurstBeam;
    final effectiveDps = weapon.effectiveDps;
    final sustainedDps = weapon.sustainedDps;
    final burstBeamDamage = weapon.burstDamage;
    final fluxPerDam = weapon.fluxPerDamage;
    final fluxPerSecond = weapon.fluxPerSecond;
    final sustainedFluxPerSecond = weapon.sustainedFluxPerSecond;
    final empDisplay = weapon.empPerActivation;
    final hasSustained = weapon.hasSustainedDps;
    final hasFluxCost = (fluxPerSecond ?? 0) > 0;
    final refireDelaySeconds = weapon.refireDelay;

    final hasBurst =
        !isBeam && weapon.burstSize != null && weapon.burstSize! > 1;
    final showDamageMultiplier =
        hasBurst &&
        weapon.burstSize! < 1000 &&
        (weapon.ammo == null || weapon.ammo! > weapon.burstSize!);
    final showRefireDelay = refireDelaySeconds != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Title & manufacturer ──
        if (showTitle) ...[
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
        ],

        // ════════════ Primary data ════════════
        tooltipSectionHeader('Primary data', theme, highlightColor),
        const SizedBox(height: 4),
        _iconRow(
              icon: showSprite ? _weaponSprite(weapon) : null,
              child: tooltipStatsGrid(theme, [
                if (weapon.primaryRoleStr ?? description?.text2
                    case final role?)
                  tooltipRow('Primary role', role),
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
                    rightAlign: true,
                  ),
                if (weapon.ops != null)
                  tooltipRow('Ordnance points', '${weapon.ops}'),
                tooltipGap,

                if (showStats) ...[
                  if (weapon.range != null)
                    tooltipRow('Range', tooltipFmt(weapon.range)),
                  if (isBurstBeam && burstBeamDamage != null)
                    tooltipRow('Damage', tooltipFmt(burstBeamDamage))
                  else if (!isBeam && weapon.damagePerShot != null)
                    tooltipRow(
                      'Damage',
                      showDamageMultiplier
                          ? '${tooltipFmt(weapon.damagePerShot)}x${weapon.burstSize!.toInt()}'
                          : tooltipFmt(weapon.damagePerShot),
                    ),
                  if (!noDPS && effectiveDps != null)
                    tooltipRow(
                      hasSustained
                          ? 'Damage / second (sustained)'
                          : 'Damage / second',
                      hasSustained
                          ? '${tooltipFmt(effectiveDps)} (${tooltipFmt(sustainedDps)})'
                          : tooltipFmt(effectiveDps),
                    ),
                  if (empDisplay != null && empDisplay > 0)
                    tooltipRow(
                      isBeam && !isBurstBeam ? 'EMP DPS' : 'EMP damage',
                      tooltipFmt(empDisplay),
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
                    tooltipNote(
                      'Limited ${isEnergyType ? "charges" : "ammo"}'
                      ' (${tooltipFmt(weapon.ammo)})',
                      rightAlign: true,
                    ),
                  ],
                ] else if (limitedAmmo) ...[
                  tooltipNote(
                    'No flux cost to fire, limited '
                    '${isEnergyType ? "charges" : "ammo"} (${tooltipFmt(weapon.ammo)})',
                    rightAlign: true,
                  ),
                ] else ...[
                  tooltipNote('No flux cost to fire'),
                ],
              ], valueColumnWidth: _statsValueColumnWidth),
            ) ??
            const SizedBox(),

        // Custom primary text (game: customPrimary with %s highlights).
        if ((weapon.customPrimary ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: DescriptionWithSubstitutions(
              description: weapon.customPrimary!,
              highlightValues: weapon.customPrimaryHL,
              highlightColor: TriOSThemeConstants.vanillaYellowGoldColor,
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
                    tooltipNote(
                      _damageTypeDesc(weapon, isSoftFlux),
                      rightAlign: true,
                    ),
                  tooltipGap,

                  // Game shows each stat independently if its value
                  // is non-null, in order: Speed, Tracking, Hitpoints,
                  // Accuracy, Turn rate.
                  if (weapon.speedStr != null ||
                      (isMissile && weapon.projSpeed != null))
                    tooltipRow(
                      'Speed',
                      weapon.speedStr ?? tooltipFmt(weapon.projSpeed),
                    ),
                  if (weapon.trackingStr != null)
                    tooltipRow('Tracking', weapon.trackingStr!),
                  if (hasMissileDisplay &&
                      weapon.projHitpoints != null &&
                      weapon.projHitpoints! > 0)
                    tooltipRow('Hitpoints', tooltipFmt(weapon.projHitpoints)),
                  if (weapon.accuracyStr != null)
                    tooltipRow('Accuracy', weapon.accuracyStr!)
                  else if (!hasMissileDisplay && isBeam)
                    tooltipRow('Accuracy', 'Perfect')
                  else if (!hasMissileDisplay)
                    tooltipRow(
                      'Accuracy',
                      _accuracyDisplayName(weapon.maxSpread ?? 0),
                    ),
                  if (weapon.turnRateStr != null)
                    tooltipRow('Turn rate', weapon.turnRateStr!)
                  else if (!hasMissileDisplay && weapon.turnRate != null)
                    tooltipRow(
                      'Turn rate',
                      _turnRateDisplayName(weapon.turnRate!),
                    ),
                ],

                // Ammo / charges — missiles only.
                if (usesAmmo && hasReload) ...[
                  tooltipGap,
                  tooltipRow(
                    isEnergyType ? 'Max charges' : 'Max ammo',
                    tooltipFmt(weapon.ammo),
                  ),
                  if (weapon.ammoPerSec! > 0)
                    tooltipRow(
                      isEnergyType ? 'Seconds / recharge' : 'Seconds / reload',
                      tooltipFmt(
                        (weapon.reloadSize ?? 1.0) / weapon.ammoPerSec!,
                      ),
                    ),
                  tooltipRow(
                    isEnergyType ? 'Charges gained' : 'Reload size',
                    tooltipFmt(weapon.reloadSize ?? 1.0),
                  ),
                ],

                if (hasBurst || showRefireDelay) tooltipGap,

                if (hasBurst)
                  tooltipRow('Burst size', '${weapon.burstSize!.toInt()}'),

                if (showRefireDelay)
                  tooltipRow(
                    'Refire delay (seconds)',
                    tooltipFmt(refireDelaySeconds),
                  ),
              ], valueColumnWidth: _statsValueColumnWidth),
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
        if (showDescription && description?.text1 != null) ...[
          const SizedBox(height: 8),
          tooltipHairline(theme),

          if (weapon.baseValue != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text.rich(
                TextSpan(
                  text: 'Base value: ',
                  style: theme.textTheme.bodySmall,
                  children: [
                    TextSpan(
                      text: weapon.baseValue?.asCredits(),
                      style: TextStyle(
                        color: TriOSThemeConstants.vanillaYellowGoldColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
  return [
    TooltipStatEntry(label: '', value: note, isNote: true, rightAlign: true),
  ];
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
