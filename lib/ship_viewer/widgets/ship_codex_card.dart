import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/codex/models/codex_entry.dart';
import 'package:trios/codex/widgets/codex_reference_link.dart';
import 'package:trios/descriptions/description_entry.dart';
import 'package:trios/descriptions/descriptions_manager.dart';
import 'package:trios/hullmod_viewer/models/hullmod.dart';
import 'package:trios/hullmod_viewer/widgets/hullmod_codex_card.dart';
import 'package:trios/ship_systems_manager/ship_system.dart';
import 'package:trios/ship_viewer/models/ship.dart';
import 'package:trios/ship_viewer/models/ship_weapon_slot.dart';
import 'package:trios/ship_viewer/widgets/ship_blueprint_view.dart';
import 'package:trios/trios/constants_theme.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/weapon_viewer/models/weapon.dart';
import 'package:trios/weapon_viewer/widgets/weapon_codex_card.dart';
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
  ///
  /// When [onEntitySelected] is set (inside the Codex), the child also becomes
  /// clickable and a tap navigates to this ship. Null everywhere else, so the
  /// viewer tabs keep their hover-only behaviour.
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
    CodexEntitySelected? onEntitySelected,
  }) {
    return MovingTooltipWidget.starsector(
      tooltipWidgetBuilder: (_) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxWidth),
        child: Consumer(
          builder: (context, ref, _) => _buildShipContent(
            ship,
            shipSystemsMap,
            weaponsMap,
            context,
            hullmodsMap: hullmodsMap,
            description: ref.watch(
              descriptionProvider((ship.id, DescriptionEntry.typeShip)),
            ),
            systemDescription: ship.systemId == null
                ? null
                : ref.watch(
                    descriptionProvider((
                      ship.systemId!,
                      DescriptionEntry.typeShipSystem,
                    )),
                  ),
            showTitle: showTitle,
            showSprite: showSprite,
            showDescription: showDescription,
            useAbbreviations: useAbbreviations,
          ),
        ),
      ),
      child: asCodexLink(child, onEntitySelected, (
        CodexEntryType.ship,
        ship.id,
      )),
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
    CodexEntitySelected? onEntitySelected,
  }) {
    return Consumer(
      builder: (context, ref, _) => _buildShipContent(
        ship,
        shipSystemsMap,
        weaponsMap,
        context,
        hullmodsMap: hullmodsMap,
        description: ref.watch(
          descriptionProvider((ship.id, DescriptionEntry.typeShip)),
        ),
        systemDescription: ship.systemId == null
            ? null
            : ref.watch(
                descriptionProvider((
                  ship.systemId!,
                  DescriptionEntry.typeShipSystem,
                )),
              ),
        showTitle: showTitle,
        showSprite: showSprite,
        showDescription: showDescription,
        useAbbreviations: useAbbreviations,
        onEntitySelected: onEntitySelected,
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
    DescriptionEntry? description,
    DescriptionEntry? systemDescription,
    bool showTitle = true,
    bool showSprite = true,
    bool showDescription = true,
    bool useAbbreviations = false,
    CodexEntitySelected? onEntitySelected,
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

    final sprite = showSprite ? _shipSprite(ship) : null;
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
        _statsSection(
          sprite: sprite,
          // ── Logistical Data (columns 1 & 2) ──
          logistical: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 4,
            children: [
              tooltipSectionHeader('Logistical data', theme, highlightColor),
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
                          indentLevel: 1,
                        ),
                      if (ship.suppliesRec != null)
                        tooltipRow(
                          'Recovery (supplies)',
                          tooltipFmt(ship.suppliesRec),
                          color: crColor,
                          indentLevel: 1,
                        ),
                      if (ship.deploymentPoints != null)
                        tooltipRow(
                          'Deployment points',
                          tooltipFmt(ship.deploymentPoints),
                          color: dpColor,
                          indentLevel: 1,
                        ),
                      if (ship.peakCrSec != null)
                        tooltipRow(
                          'Peak performance (sec)',
                          _peakTime(ship.peakCrSec!),
                          color: crColor,
                        ),
                      // if (ship.minCrew != null || ship.maxCrew != null)
                      //   tooltipRow(
                      //     'Crew complement',
                      //     '${tooltipFmt(ship.minCrew)} / ${tooltipFmt(ship.min)}',
                      //     color: crewColor,
                      //   ),
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
                        tooltipRow('Maximum burn', tooltipFmt(ship.maxBurn)),
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
          // ── Combat Performance (column 3) ──
          combat: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 4,
            children: [
              tooltipSectionHeader('Combat performance', theme, highlightColor),
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
                      tooltipFmt(
                        (ship.shieldUpkeep ?? 1.0) *
                            (ship.fluxDissipation ?? 1.0),
                      ),
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
                crossAxisAlignment: .start,
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
                          child: asCodexLink(
                            Text(
                              _toDisplay(
                                shipSystemsMap[ship.systemId!]?.name ??
                                    ship.systemId!,
                              ),
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color:
                                    TriOSThemeConstants.vanillaYellowGoldColor,
                              ),
                            ),
                            // Only a link when the system resolves in the
                            // index; otherwise plain text, not a broken link.
                            shipSystemsMap.containsKey(ship.systemId!)
                                ? onEntitySelected
                                : null,
                            (CodexEntryType.shipSystem, ship.systemId!),
                          ),
                        ),
                      ],
                    ),
                  if (ship.systemId != null && systemDescription != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 78),
                      child: Text(
                        (systemDescription.text3 ??
                                systemDescription.text1 ??
                                '')
                            .trim(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
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
                          child: _armamentWrap(
                            armamentGroups,
                            theme,
                            TriOSThemeConstants.vanillaYellowGoldColor,
                            onEntitySelected,
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
                          child: _hullModWrap(
                            hullMods,
                            hullmodsMap,
                            theme,
                            onEntitySelected,
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
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.10),
                ),
                Expanded(
                  child: Padding(
                    padding: const .symmetric(horizontal: 8.0, vertical: 8),
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
                          biggerLineBreaks: false,
                        ),
                      ],
                    ),
                  ),
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.10),
                ),
              ],
            ),
          ),
          tooltipHairline(theme),
        ],
      ],
    );
  }
}

// ───────────────────────── Layout helpers ─────────────────────────

/// Below this width the stats section stacks vertically instead of sitting
/// three columns + sprite side by side (which needs ~700 px to stay readable).
const _statsStackBreakpoint = 700.0;

/// Lays out the logistical block, combat block, and sprite side by side when
/// there is room, or stacked vertically (sprite first) when the card is
/// narrow — e.g. in the Codex detail panel with the window shrunk.
Widget _statsSection({
  required Widget logistical,
  required Widget combat,
  Widget? sprite,
}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < _statsStackBreakpoint) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            if (sprite != null) Center(child: sprite),
            logistical,
            combat,
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          Expanded(flex: 2, child: logistical),
          Expanded(child: combat),
          ?sprite,
        ],
      );
    },
  );
}

/// Ship silhouette sprite constrained to 150×200, or null if unavailable.
/// Always renders the composite blueprint so decorative weapons show.
Widget? _shipSprite(Ship ship) {
  if (ship.spriteFile == null) return null;

  return SizedBox(
    width: 150,
    height: 200,
    child: ShipBlueprintView.minimal(ship: ship, cacheWidth: 150),
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

/// Groups built-in weapons and wings by display name, preserving the [Weapon]
/// object (for tooltips) and, for wings, the wing id (for the Codex link).
Map<String, ({int count, Weapon? weapon, String? wingId})> _groupArmaments(
  Ship ship,
  Map<String, Weapon> weaponsMap,
) {
  final groups = <String, ({int count, Weapon? weapon, String? wingId})>{};
  for (final id
      in ship.builtInWeapons?.values ?? const Iterable<String>.empty()) {
    final weapon = weaponsMap[id];
    if (weapon?.isHidden() == true) continue;
    var name = weapon?.name ?? _toDisplay(id);
    if (weapon?.size != null && weapon?.effectiveMountType != null) {
      name +=
          ' (${weapon!.size!.toTitleCase()} ${weapon.effectiveMountType!.toTitleCase()})';
    }
    final existing = groups[name];
    groups[name] = (
      count: (existing?.count ?? 0) + 1,
      weapon: weapon,
      wingId: null,
    );
  }
  for (final id in ship.builtInWings ?? const <String>[]) {
    final name = _toDisplay(id);
    final existing = groups[name];
    groups[name] = (
      count: (existing?.count ?? 0) + 1,
      weapon: null,
      wingId: id,
    );
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

/// Renders a ship's built-in armaments as one comma-joined line — the same look
/// whether or not the items are interactive. When a [Weapon] resolves, its entry
/// keeps its hover card (and, inside the Codex, click-to-open); wings link to
/// their fighter entry; unresolved entries (e.g. from a disabled mod) stay plain.
Widget _armamentWrap(
  Map<String, ({int count, Weapon? weapon, String? wingId})> groups,
  ThemeData theme,
  Color highlightColor,
  CodexEntitySelected? onEntitySelected,
) {
  final baseStyle = theme.textTheme.bodySmall;
  final countStyle = baseStyle?.copyWith(
    color: highlightColor,
    fontWeight: FontWeight.bold,
  );

  final entries = groups.entries.toList();
  return Text.rich(
    TextSpan(
      children: [
        for (var i = 0; i < entries.length; i++) ...[
          if (i > 0) TextSpan(text: ', ', style: baseStyle),
          _armamentSpan(entries[i], baseStyle, countStyle, onEntitySelected),
        ],
      ],
    ),
  );
}

/// One armament as an inline span: `count× name`, with the count highlighted.
/// Resolved weapons/wings get wrapped so they keep their hover card and click;
/// plain entries stay a bare span so the line reads identically either way.
InlineSpan _armamentSpan(
  MapEntry<String, ({int count, Weapon? weapon, String? wingId})> entry,
  TextStyle? baseStyle,
  TextStyle? countStyle,
  CodexEntitySelected? onEntitySelected,
) {
  final labelSpans = <InlineSpan>[
    TextSpan(text: '${entry.value.count}×', style: countStyle),
    TextSpan(text: ' ${entry.key}', style: baseStyle),
  ];

  final weapon = entry.value.weapon;
  if (weapon != null) {
    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: WeaponCodexCard.tooltip(
        weapon: weapon,
        onEntitySelected: onEntitySelected,
        child: Text.rich(TextSpan(children: labelSpans)),
      ),
    );
  }

  final wingId = entry.value.wingId;
  if (wingId != null) {
    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: asCodexLink(
        Text.rich(TextSpan(children: labelSpans)),
        onEntitySelected,
        (CodexEntryType.wing, wingId),
      ),
    );
  }

  return TextSpan(children: labelSpans);
}

/// Renders a ship's built-in hull mods as one comma-joined line — e.g.
/// `Reduced Explosion, Always Detaches` — the same look whether or not the items
/// are interactive. Each resolved hull mod keeps its hover card (and, inside the
/// Codex, click-to-open); an unresolved id (e.g. from a disabled mod) stays
/// plain.
Widget _hullModWrap(
  Iterable<String> hullMods,
  Map<String, Hullmod> hullmodsMap,
  ThemeData theme,
  CodexEntitySelected? onEntitySelected,
) {
  final baseStyle = theme.textTheme.bodySmall;
  final ids = hullMods.toList();

  return Text.rich(
    TextSpan(
      children: [
        for (var i = 0; i < ids.length; i++) ...[
          if (i > 0) TextSpan(text: ', ', style: baseStyle),
          _hullModSpan(ids[i], hullmodsMap, baseStyle, onEntitySelected),
        ],
      ],
    ),
  );
}

/// One hull mod as an inline span. A resolved hull mod keeps its hover card and
/// click; an unresolved id stays a bare span so the line reads identically.
InlineSpan _hullModSpan(
  String id,
  Map<String, Hullmod> hullmodsMap,
  TextStyle? baseStyle,
  CodexEntitySelected? onEntitySelected,
) {
  final hullmod = hullmodsMap[id];
  final name = hullmod?.name ?? _toDisplay(id);
  if (hullmod == null) return TextSpan(text: name, style: baseStyle);
  return WidgetSpan(
    alignment: PlaceholderAlignment.baseline,
    baseline: TextBaseline.alphabetic,
    child: HullmodCodexCard.tooltip(
      hullmod: hullmod,
      onEntitySelected: onEntitySelected,
      child: Text(name, style: baseStyle),
    ),
  );
}

/// Converts a snake_case / kebab-case id to a Title Cased display string.
String _toDisplay(String id) =>
    id.replaceAll('_', ' ').replaceAll('-', ' ').toTitleCase();

/// Converts peak CR seconds to a human-readable duration string.
String _peakTime(double secs) => tooltipFmt(secs);
// secs >= 60 ? '${tooltipFmt(secs / 60)} min' : '${tooltipFmt(secs)} s';
