import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/ship_viewer/models/ship.dart';
import 'package:trios/ship_viewer/ships_page_controller.dart';
import 'package:trios/ship_viewer/widgets/ship_blueprint_view.dart';
import 'package:trios/ship_viewer/widgets/ship_codex_card.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/merge_mod_sources_view.dart';

/// Shows the full ship details dialog — the same dialog opened by clicking a
/// row in the Ships viewer. Extracted here so the Codex can open it too.
void showShipDetailsDialog(BuildContext context, WidgetRef ref, Ship s) {
  final theme = Theme.of(context);

  showDialog(
    context: context,
    builder: (ctx) {
      return Dialog(
        insetPadding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1050),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildShipInfoPane(
                    ctx,
                    s,
                    theme,
                    ref.read(shipsPageControllerProvider),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Wrap(
                        spacing: 4,
                        children: [
                          if (s.dataFile != null)
                            IconButton(
                              tooltip:
                                  'Open ${s.isSkin ? '.skin' : '.ship'} file',
                              icon: const Icon(Icons.edit_note),
                              onPressed: () =>
                                  s.dataFile!.absolute.showInExplorer(),
                            ),
                          IconButton(
                            tooltip: 'Open ship_data.csv',
                            icon: const Icon(Icons.edit_note),
                            onPressed: () =>
                                s.csvFile?.absolute.showInExplorer(),
                          ),
                          IconButton(
                            tooltip: 'Open Folder',
                            icon: const Icon(Icons.folder),
                            onPressed: () {
                              final gameCoreDir = ref
                                  .read(shipsPageControllerProvider.notifier)
                                  .getGameCoreDir();
                              _getPathForSpriteName(
                                s,
                                gameCoreDir,
                              ).parent.path.openAsUriInBrowser();
                            },
                          ),
                        ],
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

Directory _getPathForSpriteName(Ship item, Directory gameCoreDir) {
  return (item.modVariant == null ? gameCoreDir : item.modVariant!.modFolder)
      .resolve(item.spriteName ?? "")
      .toDirectory();
}

Widget _buildShipInfoPane(
  BuildContext context,
  Ship s,
  ThemeData theme,
  ShipsPageState controllerState,
) {
  Widget section(String title) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 4),
    child: Text(
      title,
      style: theme.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.primary,
      ),
    ),
  );

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        crossAxisAlignment: .start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                SelectableText(
                  s.hullNameForDisplay(),
                  style: theme.textTheme.titleLarge?.copyWith(
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SelectableText(s.id, style: theme.textTheme.labelSmall),
                if (s.isSkin && s.baseHullId != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      spacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Skin',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                        Text(
                          'of ${controllerState.hullNameById(s.baseHullId!)}',
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Close',
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      const SizedBox(height: 8),
      if (s.weaponSlots != null &&
          s.weaponSlots!.isNotEmpty &&
          s.spriteFile != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 140),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ShipBlueprintView(ship: s),
              ),
            ),
          ),
        ),
      ShipCodexCard.create(
        ship: s,
        shipSystemsMap: controllerState.shipSystemsMap,
        weaponsMap: controllerState.weaponsMap,
        hullmodsMap: controllerState.hullmodsMap,
        showTitle: false,
        showSprite: false,
        useAbbreviations: false,
      ),
      const SizedBox(height: 16),
      Padding(
        padding: const .only(bottom: 8),
        child: mergeModSourcesView(
          s.modSources,
          theme,
          fileLabel: 'Ship file',
          fallbackName: s.modVariant?.modInfo.nameOrId ?? 'Vanilla',
        ),
      ),
      _kv('Hull Size', s.hullSizeForDisplay(), theme),
      _kv('Designation', s.designation, theme),
      _kv('Style', s.style?.toTitleCase(), theme),
      _kv(
        'System',
        controllerState.shipSystemsMap[s.systemId ?? ""]?.name ?? s.systemId,
        theme,
      ),
      _kv(
        'Defense',
        controllerState.shipSystemsMap[s.defenseId ?? ""]?.name ?? s.defenseId,
        theme,
      ),
      _kv('Tech/Manufacturer', s.techManufacturer, theme),
      // Combat
      section('Combat'),
      Wrap(
        runSpacing: 6,
        children: [
          _chip('Fleet Pts', _fmtNum(s.fleetPts)),
          _chip('Hitpoints', _fmtNum(s.hitpoints)),
          _chip('Armor', _fmtNum(s.armorRating)),
          _chip('Max Flux', _fmtNum(s.maxFlux)),
          _chip('Flux Diss', _fmtNum(s.fluxDissipation)),
          _chip('Ordnance Pts', _fmtNum(s.ordnancePoints)),
          _chip('Fighter Bays', _fmtNum(s.fighterBays)),
          _chip('Weapons', _fmtNum(s.mountableWeaponSlotCount)),
          _chip('Built-in Wpns', _fmtNum(s.builtInWeapons?.length ?? 0)),
          _chip('Built-in Mods', _fmtNum(s.builtInMods?.length ?? 0)),
          _chip('Built-in Wings', _fmtNum(s.builtInWings?.length ?? 0)),
        ],
      ),
      // Shields / Phase
      if (s.shieldType != null) ...[
        section('Shield / Phase'),
        Wrap(
          runSpacing: 6,
          children: [
            _chip('Shield', s.shieldType!.toTitleCase()),
            _chip('Shield Arc', _fmtNum(s.shieldArc)),
            _chip('Shield Upkeep', _fmtNum(s.shieldUpkeep)),
            _chip('Shield Efficiency', _fmtNum(s.shieldEfficiency)),
            _chip('Phase Cost', _fmtNum(s.phaseCost)),
            _chip('Phase Upkeep', _fmtNum(s.phaseUpkeep)),
          ],
        ),
      ],
      // Mobility
      section('Mobility'),
      Wrap(
        runSpacing: 6,
        children: [
          _chip('Max Speed', _fmtNum(s.maxSpeed)),
          _chip('Acceleration', _fmtNum(s.acceleration)),
          _chip('Deceleration', _fmtNum(s.deceleration)),
          _chip('Turn Rate', _fmtNum(s.maxTurnRate)),
          _chip('Turn Accel', _fmtNum(s.turnAcceleration)),
          _chip('Mass', _fmtNum(s.mass)),
        ],
      ),
      // Crew & Logistics
      section('Crew & Logistics'),
      Wrap(
        runSpacing: 6,
        children: [
          _chip('Min Crew', _fmtNum(s.minCrew)),
          _chip('Max Crew', _fmtNum(s.maxCrew)),
          _chip('Cargo', _fmtNum(s.cargo)),
          _chip('Fuel', _fmtNum(s.fuel)),
          _chip('Fuel/LY', _fmtNum(s.fuelPerLY)),
          _chip('Range', _fmtNum(s.range)),
          _chip('Max Burn', _fmtNum(s.maxBurn)),
          _chip('Sensor Profile', _fmtNum(s.sensorProfile)),
          _chip('Sensor Strength', _fmtNum(s.sensorStrength)),
        ],
      ),
      // Economics & CR
      section('Economics & CR'),
      Wrap(
        runSpacing: 6,
        children: [
          _chip('Base Value', s.baseValue.asCredits()),
          _chip('CR%/Day', _fmtNum(s.crPercentPerDay)),
          _chip('CR to Deploy', _fmtNum(s.crToDeploy)),
          _chip('PPT (s)', _fmtNum(s.peakCrSec)),
          _chip('CR Loss/Sec', _fmtNum(s.crLossPerSec)),
          _chip('Supplies/Mo', _fmtNum(s.suppliesMo)),
          _chip('DP', _fmtNum(s.deploymentPoints)),
        ],
      ),
      // Misc
      section('Misc'),
      Wrap(
        runSpacing: 6,
        children: [
          _chip('Rarity', s.rarity ?? '-'),
          _chip('Break Prob', s.breakProb ?? '-'),
          _chip('Min Pieces', _fmtNum(s.minPieces)),
          _chip('Max Pieces', _fmtNum(s.maxPieces)),
          _chip('Travel Drive', s.travelDrive ?? '-'),
          _chip('Collision Radius', _fmtNum(s.collisionRadius)),
          if ((s.hints ?? []).isNotEmpty) _chip('Hints', s.hints!.join(', ')),
          if ((s.tags ?? []).isNotEmpty) _chip('Tags', s.tags!.join(', ')),
          if ((s.builtInMods ?? []).isNotEmpty)
            _chip('Built-in Mods', s.builtInMods!.join(', ')),
          if ((s.builtInWings ?? []).isNotEmpty)
            _chip('Built-in Wings', s.builtInWings!.join(', ')),
          if ((s.builtInWeapons ?? {}).isNotEmpty)
            _chip('Built-in Weapons', s.builtInWeapons!.values.join(', ')),
        ],
      ),
    ],
  );
}

String _fmtNum(num? n) => switch (n) {
  null => '-',
  double d => d.toStringAsFixed(d % 1 == 0 ? 0 : 2),
  _ => n.toString(),
};

Widget _kv(String? k, String? v, ThemeData theme) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: RichText(
      text: TextSpan(
        style: theme.textTheme.bodySmall,
        children: [
          if (k != null) TextSpan(text: '$k: '),
          TextSpan(
            text: (v == null || v.isEmpty) ? '-' : v,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    ),
  );
}

Widget _chip(String label, String value) {
  return Container(
    margin: const EdgeInsets.only(right: 4),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.05),
      borderRadius: BorderRadius.circular(16),
    ),
    child: SelectableText.rich(
      TextSpan(
        style: const TextStyle(fontSize: 11, color: Colors.white70),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          TextSpan(text: value),
        ],
      ),
    ),
  );
}
