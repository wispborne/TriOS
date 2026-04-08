import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/descriptions/description_entry.dart';
import 'package:trios/descriptions/descriptions_manager.dart';
import 'package:trios/hullmod_viewer/models/hullmod.dart';
import 'package:trios/ship_systems_manager/ship_system.dart';
import 'package:trios/ship_viewer/models/ship_gpt.dart';
import 'package:trios/ship_viewer/models/ship_weapon_slot.dart';
import 'package:trios/ship_viewer/ship_module_resolver.dart';
import 'package:trios/ship_viewer/widgets/ship_blueprint_view.dart';
import 'package:trios/trios/constants_theme.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/weapon_viewer/models/weapon.dart';
import 'package:trios/widgets/description_with_substitutions.dart';
import 'package:trios/widgets/ingame_tooltip_shared.dart';
import 'package:trios/widgets/moving_tooltip.dart';

/// Builds tooltip content for ships, replicating the layout of the game's
/// ship codex panel: title, two-column stats with sprite, system, mounts,
/// armaments, hull mods, and design-type footer.
class ShipCodexCard {
  ShipCodexCard._();

  static const _maxWidth = 780.0;

  // ───────────────────────── Convenience wrapper ─────────────────────────

  /// Wraps [child] in a [MovingTooltipWidget] that shows ship stats on hover.
  static Widget tooltip({
    required Ship ship,
    required Map<String, ShipSystem> shipSystemsMap,
    required Map<String, Weapon> weaponsMap,
    required Widget child,
    Map<String, Hullmod> hullmodsMap = const {},
    bool showTitle = true,
    bool showSprite = true,
    bool showDescription = true,
    bool useAbbreviations = true,
  }) {
    return MovingTooltipWidget.starsector(
      tooltipWidget: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxWidth),
        child: Consumer(
          builder: (context, ref, _) => _buildShipContent(
            ship,
            shipSystemsMap,
            weaponsMap,
            context,
            hullmodsMap: hullmodsMap,
            modules: ref.watch(resolvedModulesProvider(ship.id)),
            description: ref.watch(
              descriptionProvider((ship.id, DescriptionEntry.typeShip)),
            ),
            showTitle: showTitle,
            showSprite: showSprite,
            showDescription: showDescription,
            useAbbreviations: useAbbreviations,
          ),
        ),
      ),
      child: child,
    );
  }

  static Widget create({
    required Ship ship,
    required Map<String, ShipSystem> shipSystemsMap,
    required Map<String, Weapon> weaponsMap,
    Map<String, Hullmod> hullmodsMap = const {},
    bool showTitle = true,
    bool showSprite = true,
    bool showDescription = true,
    bool useAbbreviations = true,
  }) {
    return Consumer(
      builder: (context, ref, _) => _buildShipContent(
        ship,
        shipSystemsMap,
        weaponsMap,
        context,
        hullmodsMap: hullmodsMap,
        modules: ref.watch(resolvedModulesProvider(ship.id)),
        description: ref.watch(
          descriptionProvider((ship.id, DescriptionEntry.typeShip)),
        ),
        showTitle: showTitle,
        showSprite: showSprite,
        showDescription: showDescription,
        useAbbreviations: useAbbreviations,
      ),
    );
  }

  // ───────────────────────── Ship tooltip ─────────────────────────

  static Widget _buildShipContent(
    Ship ship,
    Map<String, ShipSystem> shipSystemsMap,
    Map<String, Weapon> weaponsMap,
    BuildContext context, {
    Map<String, Hullmod> hullmodsMap = const {},
    List<ResolvedModule> modules = const [],
    DescriptionEntry? description,
    bool showTitle = true,
    bool showSprite = true,
    bool showDescription = true,
    bool useAbbreviations = false,
  }) {
    final theme = Theme.of(context);
    final highlightColor = TriOSThemeConstants.vanillaCyanColor;

    final shieldUpper = ship.shieldType?.toUpperCase();
    final hasShield =
        shieldUpper != null && shieldUpper != 'NONE' && shieldUpper != 'PHASE';
    final hasPhase = shieldUpper == 'PHASE';
    final isTruePhaseShip = hasPhase && ship.defenseId == 'phasecloak';
    final defenseLabel = isTruePhaseShip
        ? 'Phase cloak'
        : hasPhase
        ? shipSystemsMap[ship.defenseId ?? '']?.name ??
              ship.defenseId ??
              'Phase cloak'
        : hasShield
        ? '${ship.shieldType!.toTitleCase()} shield'
        : 'None';
    final defenseRowLabel = hasPhase && !isTruePhaseShip
        ? 'Special'
        : 'Defense';
    const crColor = Color(0xFFa4b6ab);
    const crewColor = Color(0xFF40ab80);
    const fuelColor = Color(0xFFf58630);
    const dpColor = Color(0xFF4ca8bf);
    const cargoColor = Color(0xFFb2b082);

    final sprite = showSprite ? _shipSprite(ship, modules) : null;
    final mountGroups = _groupMounts(ship);
    final hasBays = (ship.fighterBays ?? 0) > 0;
    final armamentGroups = _groupArmaments(ship, weaponsMap);
    final hullMods = ship.builtInMods ?? const [];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Title ──
        if (showTitle) ...[
          tooltipTitleWithDesignType(
            ship.hullNameForDisplay(),
            ship.designation != null &&
                    ship.designation != ship.hullNameForDisplay()
                ? ship.designation
                : null,
            false,
            theme,
          ),
          const SizedBox(height: 8),
        ],

        // ════════ Three columns: Logistical (1+2) | Combat (3) + Sprite ════════
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 16,
          children: [
            // ── Logistical Data (columns 1 & 2) ──
            Expanded(
              flex: 2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 4,
                children: [
                  tooltipSectionHeader(
                    'Logistical data',
                    theme,
                    highlightColor,
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 8,
                    children: [
                      // ── Column 1 ──
                      Expanded(
                        child: tooltipStatsGrid(theme, [
                          if (ship.crToDeploy != null)
                            tooltipRow(
                              'CR per deployment',
                              '${tooltipFmt(ship.crToDeploy)}%',
                              color: crColor,
                            ),
                          if (ship.crPercentPerDay != null)
                            tooltipRow(
                              'Recovery (/day)',
                              '${tooltipFmt(ship.crPercentPerDay)}%',
                              color: crColor,
                            ),
                          if (ship.suppliesRec != null)
                            tooltipRow(
                              'Recovery (supplies)',
                              tooltipFmt(ship.suppliesRec),
                              color: crColor,
                            ),
                          if (ship.fleetPts != null)
                            tooltipRow(
                              'Deployment points',
                              tooltipFmt(ship.fleetPts),
                              color: dpColor,
                            ),
                          if (ship.peakCrSec != null)
                            tooltipRow(
                              'Peak performance',
                              _peakTime(ship.peakCrSec!),
                              color: crColor,
                            ),
                          if (ship.minCrew != null || ship.maxCrew != null)
                            tooltipRow(
                              'Crew complement',
                              '${tooltipFmt(ship.minCrew)} / ${tooltipFmt(ship.maxCrew)}',
                              color: crewColor,
                            ),
                          tooltipGap,
                          tooltipRow('Hull size', ship.hullSizeForDisplay()),
                          if (ship.ordnancePoints != null)
                            tooltipRow(
                              'Ordnance points',
                              tooltipFmt(ship.ordnancePoints),
                            ),
                        ]),
                      ),
                      // ── Column 2 ──
                      Expanded(
                        child: tooltipStatsGrid(theme, [
                          if (ship.suppliesMo != null)
                            tooltipRow(
                              useAbbreviations
                                  ? 'Maintenance (sup/mo)'
                                  : 'Maintenance (supplies/month)',
                              tooltipFmt(ship.suppliesMo),
                              color: crColor,
                            ),
                          if (ship.cargo != null)
                            tooltipRow(
                              'Cargo capacity',
                              tooltipFmt(ship.cargo),
                              color: cargoColor,
                            ),
                          if (ship.maxCrew != null)
                            tooltipRow(
                              'Maximum crew',
                              tooltipFmt(ship.maxCrew),
                              color: crewColor,
                            ),
                          if (ship.minCrew != null)
                            tooltipRow(
                              'Skeleton crew',
                              tooltipFmt(ship.minCrew),
                              color: crewColor,
                            ),
                          if (ship.fuel != null)
                            tooltipRow(
                              'Fuel capacity',
                              tooltipFmt(ship.fuel),
                              color: fuelColor,
                            ),
                          if (ship.maxBurn != null)
                            tooltipRow(
                              'Maximum burn',
                              tooltipFmt(ship.maxBurn),
                            ),
                          if (ship.fuelPerLY != null)
                            tooltipRow(
                              'Fuel/ly, jump cost',
                              tooltipFmt(ship.fuelPerLY),
                            ),
                          if (ship.sensorProfile != null)
                            tooltipRow(
                              'Sensor profile',
                              tooltipFmt(ship.sensorProfile),
                            ),
                          if (ship.sensorStrength != null)
                            tooltipRow(
                              'Sensor strength',
                              tooltipFmt(ship.sensorStrength),
                            ),
                        ]),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Combat Performance (column 3) ──
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 4,
                children: [
                  tooltipSectionHeader(
                    'Combat performance',
                    theme,
                    highlightColor,
                  ),
                  tooltipStatsGrid(theme, [
                    if (ship.hitpoints != null)
                      tooltipRow('Hull integrity', tooltipFmt(ship.hitpoints)),
                    if (ship.armorRating != null)
                      tooltipRow('Armor rating', tooltipFmt(ship.armorRating)),
                    tooltipRow(defenseRowLabel, defenseLabel),
                    if (hasShield) ...[
                      if (ship.shieldArc != null)
                        tooltipRow(
                          'Shield arc',
                          '${tooltipFmt(ship.shieldArc)}\u00B0',
                        ),
                      if (ship.shieldUpkeep != null)
                        tooltipRow(
                          'Shield upkeep/sec',
                          tooltipFmt(ship.shieldUpkeep),
                        ),
                      if (ship.shieldEfficiency != null)
                        tooltipRow(
                          'Shield flux/damage',
                          tooltipFmt(ship.shieldEfficiency, forceDecimal: true),
                        ),
                    ],
                    if (isTruePhaseShip) ...[
                      if (ship.phaseCost != null)
                        tooltipRow(
                          'Cloak activation cost',
                          tooltipFmt(ship.phaseCost),
                        ),
                      if (ship.phaseUpkeep != null)
                        tooltipRow(
                          'Cloak upkeep/sec',
                          tooltipFmt(ship.phaseUpkeep),
                        ),
                    ],
                    if (ship.maxFlux != null)
                      tooltipRow('Flux capacity', tooltipFmt(ship.maxFlux)),
                    if (ship.fluxDissipation != null)
                      tooltipRow(
                        'Flux dissipation',
                        tooltipFmt(ship.fluxDissipation),
                      ),
                    if (ship.maxSpeed != null)
                      tooltipRow('Top speed', tooltipFmt(ship.maxSpeed)),
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
            armamentGroups.isNotEmpty ||
            hullMods.isNotEmpty) ...[
          const SizedBox(height: 8),
          tooltipHairline(theme),
          const SizedBox(height: 6),
          Builder(
            builder: (context) {
              final labelWidth = 70.0;
              return Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 4,
                children: [
                  if (ship.systemId != null)
                    Row(
                      spacing: 8,
                      children: [
                        SizedBox(
                          width: labelWidth,
                          child: Text(
                            'System:',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            _toDisplay(
                              shipSystemsMap[ship.systemId!]?.name ??
                                  ship.systemId!,
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: TriOSThemeConstants.vanillaYellowGoldColor,
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
                          width: labelWidth,
                          child: Text(
                            'Mounts:',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                        Expanded(
                          child: _mountWrap(
                            mountGroups,
                            ship.fighterBays,
                            theme,
                            TriOSThemeConstants.vanillaYellowGoldColor,
                          ),
                        ),
                      ],
                    ),
                  if (armamentGroups.isNotEmpty)
                    Row(
                      spacing: 8,
                      children: [
                        SizedBox(
                          width: labelWidth,
                          child: Text(
                            'Armaments:',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                        Expanded(
                          child: _mountWrap(
                            armamentGroups,
                            null,
                            theme,
                            TriOSThemeConstants.vanillaYellowGoldColor,
                          ),
                        ),
                      ],
                    ),
                  if (hullMods.isNotEmpty)
                    Row(
                      spacing: 8,
                      children: [
                        SizedBox(
                          width: labelWidth,
                          child: Text(
                            'Hull Mods:',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            hullMods
                                .map(
                                  (id) =>
                                      hullmodsMap[id]?.name ?? _toDisplay(id),
                                )
                                .join(", "),
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                ],
              );
            },
          ),
        ],

        // ════════ Description ════════
        if (showDescription && description?.text1 != null) ...[
          const SizedBox(height: 8),
          tooltipHairline(theme),
          const SizedBox(height: 6),
          Padding(
            padding: const .symmetric(horizontal: 16.0, vertical: 8),
            child: Column(
              children: [
                // ════════ Design type ════════
                if (ship.techManufacturer != null) ...[
                  tooltipDesignTypeRow(ship.techManufacturer!, theme),
                  const SizedBox(height: 6),
                ],
                DescriptionWithSubstitutions(
                  description: description!.text1!,
                  baseStyle: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ───────────────────────── Layout helpers ─────────────────────────

/// Ship silhouette sprite constrained to 128 px tall, or null if unavailable.
/// When [modules] is non-empty, renders the composite sprite with modules.
Widget? _shipSprite(Ship ship, List<ResolvedModule> modules) {
  final path = ship.spriteFile;
  if (path == null) return null;

  if (modules.isNotEmpty) {
    return SizedBox(
      width: 150,
      height: 200,
      child: ShipBlueprintView.minimal(ship: ship, cacheWidth: 150),
    );
  }

  return SizedBox(
    width: 150,
    height: 200,
    child: Image.file(
      File(path),
      fit: .scaleDown,
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

/// Groups built-in weapons and wings by display name and returns a count map.
/// Weapon entries include size/type from the [Weapon] model when available,
/// mirroring the mount grouping style (e.g. "Tachyon Lance (Large Energy)").
Map<String, int> _groupArmaments(Ship ship, Map<String, Weapon> weaponsMap) {
  final groups = <String, int>{};
  for (final id
      in ship.builtInWeapons?.values ?? const Iterable<String>.empty()) {
    final weapon = weaponsMap[id];
    if (weapon?.isHidden() == true) continue;
    var name = weapon?.name ?? _toDisplay(id);
    if (weapon?.size != null && weapon?.effectiveMountType != null) {
      name +=
          ' (${weapon!.size!.toTitleCase()} ${weapon.effectiveMountType!.toTitleCase()})';
    }
    groups[name] = (groups[name] ?? 0) + 1;
  }
  for (final id in ship.builtInWings ?? const <String>[]) {
    final name = _toDisplay(id);
    groups[name] = (groups[name] ?? 0) + 1;
  }
  return groups;
}

/// Renders mount groups + fighter bays as a wrapping list of rich-text items
/// with the count portion highlighted in [highlightColor].
Widget _mountWrap(
  Map<String, int> groups,
  double? fighterBays,
  ThemeData theme,
  Color highlightColor,
) {
  final baseStyle = theme.textTheme.bodySmall;
  final countStyle = baseStyle?.copyWith(
    color: highlightColor,
    fontWeight: FontWeight.bold,
  );

  final items = <({String count, String label})>[
    ...groups.entries.map(
      (e) => (count: '${e.value}\u00D7', label: ' ${e.key}'),
    ),
    if (fighterBays != null && fighterBays > 0)
      (count: '${tooltipFmt(fighterBays)}\u00D7', label: ' Fighter bay'),
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
    secs >= 60 ? '${tooltipFmt(secs / 60)} min' : '${tooltipFmt(secs)} s';
