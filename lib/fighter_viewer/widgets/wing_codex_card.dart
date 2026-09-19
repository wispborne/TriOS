import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/codex/models/codex_entry.dart';
import 'package:trios/descriptions/description_entry.dart';
import 'package:trios/descriptions/descriptions_manager.dart';
import 'package:trios/fighter_viewer/models/wing.dart';
import 'package:trios/fighter_viewer/widgets/wing_formation_view.dart';
import 'package:trios/hullmod_viewer/models/hullmod.dart';
import 'package:trios/ship_systems_manager/ship_system.dart';
import 'package:trios/ship_viewer/models/ship.dart';
import 'package:trios/ship_viewer/widgets/ship_codex_card.dart';
import 'package:trios/trios/constants_theme.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/weapon_viewer/models/weapon.dart';
import 'package:trios/widgets/description_with_substitutions.dart';
import 'package:trios/widgets/ingame_tooltip_shared.dart';

/// Fighter Codex card using wing data and the ship behind it. Combat stats and
/// description come from the ship; fitted weapons also come from the wing's
/// `.variant` file. Wings have no entry in `descriptions.csv`.
class WingCodexCard {
  WingCodexCard._();

  /// Below this width the technical data and the formation picture stack.
  static const _stackBreakpoint = 500.0;

  /// Widest the technical data gets when the picture sits beside it. The game
  /// keeps this column narrow, so values stay close to their labels.
  static const _technicalDataMaxWidth = 400.0;

  /// Width of the technical data's value column. Wide enough for a role like
  /// "Support Fighter", which the grid's default 70px limit cuts off.
  static const _technicalDataValueWidth = 120.0;

  /// [onShipTap] is called when the ship link is clicked. When null, or when
  /// the wing's hull did not resolve, the ship is shown as plain text (or
  /// omitted) rather than a link.
  ///
  /// [title] is the name shown at the top — the ship behind the wing. Falls
  /// back to the wing id when not given.
  ///
  /// [ship] is the ship behind the wing, if it resolved. Without it the ship
  /// rows, system, hull mods, description, and picture are left out, and only
  /// the `.variant` weapons are listed.
  ///
  /// [onEntitySelected] makes the system, weapons, and hull mods clickable
  /// (inside the Codex). When null they stay hover-only.
  static Widget create({
    required Wing wing,
    required Map<String, ShipSystem> shipSystemsMap,
    required Map<String, Weapon> weaponsMap,
    required Map<String, Hullmod> hullmodsMap,
    Ship? ship,
    String? title,
    VoidCallback? onShipTap,
    CodexEntitySelected? onEntitySelected,
  }) {
    // An empty system column means no system, same as a missing one.
    final systemId = (ship?.systemId ?? '').isEmpty ? null : ship!.systemId;
    return Consumer(
      builder: (context, ref, _) => _buildContent(
        wing,
        context,
        ship: ship,
        systemId: systemId,
        systemDescription: systemId == null
            ? null
            : ref.watch(
                descriptionProvider((
                  systemId,
                  DescriptionEntry.typeShipSystem,
                )),
              ),
        shipDescription: ship == null
            ? null
            : ref.watch(
                descriptionProvider((ship.id, DescriptionEntry.typeShip)),
              ),
        shipSystemsMap: shipSystemsMap,
        weaponsMap: weaponsMap,
        hullmodsMap: hullmodsMap,
        title: title,
        onShipTap: onShipTap,
        onEntitySelected: onEntitySelected,
      ),
    );
  }

  static Widget _buildContent(
    Wing wing,
    BuildContext context, {
    required Ship? ship,
    required String? systemId,
    required DescriptionEntry? systemDescription,
    required DescriptionEntry? shipDescription,
    required Map<String, ShipSystem> shipSystemsMap,
    required Map<String, Weapon> weaponsMap,
    required Map<String, Hullmod> hullmodsMap,
    String? title,
    VoidCallback? onShipTap,
    CodexEntitySelected? onEntitySelected,
  }) {
    final theme = Theme.of(context);
    final highlightColor = TriOSThemeConstants.vanillaCyanColor;
    final valueColor = TriOSThemeConstants.vanillaYellowGoldColor;

    // The variant fits weapons by slot id, and may also list built-in slots,
    // so merge by slot rather than adding the two lists together.
    final armamentGroups = groupWeaponArmaments(
      {...?ship?.builtInWeapons, ...wing.weaponsBySlot}.values,
      weaponsMap,
      forFighter: true,
    );
    // Fighters often list their hull mods in the `.variant` rather than as
    // hull built-ins, so show both, without repeats.
    final hullMods = {...?ship?.builtInMods, ...wing.variantHullMods}.toList();
    const labelWidth = 70.0;

    final wingTags = (wing.tags ?? '')
        .split(',')
        .map((t) => t.trim().toLowerCase())
        .where((t) => t.isNotEmpty)
        .toSet();
    final designType = ship?.techManufacturer;
    final showDesignType =
        designType != null &&
        designType.isNotEmpty &&
        designType.toLowerCase() != 'common';
    final descriptionText = shipDescription?.text1;
    final showBaseValue =
        wing.baseValue != null && !wingTags.contains('no_sell');

    final technicalData = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 4,
      children: [
        tooltipSectionHeader('Technical data', theme, highlightColor),
        tooltipStatsGrid(
          theme,
          _technicalDataRows(wing, ship, wingTags, shipSystemsMap, valueColor),
          valueColumnWidth: _technicalDataValueWidth,
        ),
      ],
    );
    final picture = ship == null
        ? null
        : SizedBox.square(
            dimension: 200,
            child: WingFormationView(wing: wing, ship: ship),
          );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        tooltipTitle(title ?? wing.id, theme),
        const SizedBox(height: 8),

        LayoutBuilder(
          builder: (context, constraints) {
            if (picture == null) return technicalData;
            if (constraints.maxWidth < _stackBreakpoint) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 8,
                children: [
                  Center(child: picture),
                  technicalData,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 16,
              children: [
                Flexible(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: _technicalDataMaxWidth,
                    ),
                    child: technicalData,
                  ),
                ),
                Expanded(child: Center(child: picture)),
              ],
            );
          },
        ),

        if (ship != null || armamentGroups.isNotEmpty) ...[
          const SizedBox(height: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              if (ship != null)
                ...shipSystemRows(
                  systemId: systemId,
                  shipSystemsMap: shipSystemsMap,
                  systemDescription: systemDescription,
                  theme: theme,
                  labelWidth: labelWidth,
                  onEntitySelected: onEntitySelected,
                ),
              if (armamentGroups.isNotEmpty)
                _labelledLine(
                  'Armaments:',
                  armamentWrap(
                    armamentGroups,
                    theme,
                    valueColor,
                    onEntitySelected,
                  ),
                  theme,
                  labelWidth,
                ),
              if (hullMods.isNotEmpty)
                _labelledLine(
                  'Hull mods:',
                  hullModWrap(hullMods, hullmodsMap, theme, onEntitySelected),
                  theme,
                  labelWidth,
                ),
            ],
          ),
        ],

        if (showDesignType || descriptionText != null || showBaseValue) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.10),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 6,
              children: [
                if (showDesignType) tooltipDesignTypeRow(designType, theme),
                if (descriptionText != null)
                  DescriptionWithSubstitutions(
                    description: descriptionText,
                    baseStyle: theme.textTheme.bodySmall,
                    biggerLineBreaks: false,
                  ),
                if (showBaseValue)
                  Text.rich(
                    TextSpan(
                      style: theme.textTheme.bodySmall,
                      children: [
                        const TextSpan(text: 'Base value: '),
                        TextSpan(
                          text: wing.baseValue.asCredits(),
                          style: TextStyle(color: valueColor),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],

        if (wing.fleetPts != null ||
            wing.tier != null ||
            wing.rarity != null) ...[
          const SizedBox(height: 8),
          tooltipSectionHeader('Wing data', theme, highlightColor),
          const SizedBox(height: 4),
          tooltipStatsGrid(theme, [
            if (wing.fleetPts != null)
              tooltipRow('Fleet points', tooltipFmt(wing.fleetPts)),
            if (wing.tier != null) tooltipRow('Tier', tooltipFmt(wing.tier)),
            if (wing.rarity != null)
              tooltipRow('Rarity', tooltipFmt(wing.rarity)),
          ]),
        ],
        if (wing.modVariant != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Mod: ${wing.modVariant?.modInfo.nameOrId ?? "Vanilla"}',
              style: theme.textTheme.bodySmall,
            ),
          ),
      ],
    );
  }

  /// Builds technical data in game order. Swarm wings omit the game's hidden
  /// rows.
  static List<TooltipStatEntry> _technicalDataRows(
    Wing wing,
    Ship? ship,
    Set<String> wingTags,
    Map<String, ShipSystem> shipSystemsMap,
    Color valueColor,
  ) {
    TooltipStatEntry row(String label, num? value) =>
        tooltipRow(label, tooltipFmt(value), color: valueColor);

    final isSwarm = wingTags.contains('swarm_fighter');
    final isSupport = wing.role?.toUpperCase() == 'SUPPORT';
    final primaryRole = (wing.roleDesc ?? '').isNotEmpty
        ? wing.roleDesc!
        : wing.role?.toLowerCase().toTitleCase();

    final shipRows = <TooltipStatEntry>[
      if (ship != null) ...[
        if (ship.hitpoints != null) row('Hull integrity', ship.hitpoints),
        if ((ship.armorRating ?? 0) > 1) row('Armor rating', ship.armorRating),
        ?_defenseRow(ship, shipSystemsMap, valueColor),
        if (ship.maxSpeed != null) row('Top speed', ship.maxSpeed),
      ],
    ];

    return [
      if (primaryRole != null)
        tooltipRow('Primary role', primaryRole, color: valueColor),
      if (!isSwarm) ...[
        if (wing.opCost != null) row('Ordnance points', wing.opCost),
        if (ship?.minCrew != null) row('Crew per fighter', ship!.minCrew),
        if (wing.range != null)
          row(
            isSupport ? 'Maximum support range' : 'Maximum engagement range',
            wing.range,
          ),
        tooltipGap,
        if (wing.numCraft != null) row('Fighters in wing', wing.numCraft),
        if (wing.refit != null)
          row('Base replacement time (seconds)', wing.refit),
      ],
      if (shipRows.isNotEmpty) ...[tooltipGap, ...shipRows],
    ];
  }

  /// The shield or phase row, following the game: "Omni shield" or "Front
  /// shield" with the ship's max flux, or a phase row. Null for no shield.
  static TooltipStatEntry? _defenseRow(
    Ship ship,
    Map<String, ShipSystem> shipSystemsMap,
    Color valueColor,
  ) {
    final shieldType = ship.shieldType?.toUpperCase();
    if (shieldType == null || shieldType == 'NONE') return null;
    if (shieldType == 'PHASE') {
      // The standard cloak is Defense; other phase systems are Special.
      final isStandardCloak =
          ship.defenseId == null || ship.defenseId == 'phasecloak';
      return isStandardCloak
          ? tooltipRow('Defense', 'Phase Cloak', color: valueColor)
          : tooltipRow(
              'Special',
              shipSystemsMap[ship.defenseId]?.name ??
                  ship.defenseId!.toTitleCase(),
              color: valueColor,
            );
    }
    if (ship.maxFlux == null) return null;
    // The game shows the flux capacity here, not the shield arc.
    return tooltipRow(
      shieldType == 'FRONT' ? 'Front shield' : 'Omni shield',
      tooltipFmt(ship.maxFlux),
      color: valueColor,
    );
  }

  static Widget _labelledLine(
    String label,
    Widget content,
    ThemeData theme,
    double labelWidth,
  ) {
    return Row(
      spacing: 8,
      children: [
        SizedBox(
          width: labelWidth,
          child: Text(label, style: theme.textTheme.bodySmall),
        ),
        Expanded(child: content),
      ],
    );
  }
}

/// Compact inline text link, sized for use inside a card (unlike the pill-style
/// [TextLinkButton]).
class _InlineLink extends StatefulWidget {
  final String text;
  final VoidCallback onTap;

  const _InlineLink({required this.text, required this.onTap});

  @override
  State<_InlineLink> createState() => _InlineLinkState();
}

class _InlineLinkState extends State<_InlineLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Text(
          widget.text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.primary,
            decoration: _hovered ? TextDecoration.underline : null,
          ),
        ),
      ),
    );
  }
}
