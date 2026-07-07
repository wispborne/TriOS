import 'dart:io';

import 'package:flutter/material.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/weapon_viewer/models/weapon.dart';
import 'package:trios/weapon_viewer/widgets/weapon_codex_card.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/text_trios.dart';

/// Shows the full weapon details dialog — the same dialog opened by clicking a
/// row in the Weapons viewer. Extracted here so the Codex can open it too.
void showWeaponDetailsDialog(BuildContext context, Weapon w) {
  final theme = Theme.of(context);

  showDialog(
    context: context,
    builder: (ctx) {
      return Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildInfoPane(w, theme, ctx),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Wrap(
                        spacing: 4,
                        children: [
                          if (w.wpnFile != null)
                            IconButton(
                              tooltip: 'Open .wpn file',
                              icon: const Icon(Icons.edit_note),
                              onPressed: () =>
                                  w.wpnFile!.absolute.showInExplorer(),
                            ),
                          IconButton(
                            tooltip: 'Open weapon_data.csv',
                            icon: const Icon(Icons.edit_note),
                            onPressed: () =>
                                w.csvFile?.absolute.showInExplorer(),
                          ),
                          if (w.allSpriteFiles.isNotEmpty)
                            IconButton(
                              tooltip: 'Open weapon data folder(s)',
                              icon: const Icon(Icons.folder),
                              onPressed: () {
                                w.csvFile?.parent.path.openAsUriInBrowser();
                                final wpnParent = w.wpnFile?.parent;
                                if (wpnParent != null &&
                                    wpnParent.path != w.csvFile?.parent.path) {
                                  wpnParent.path.openAsUriInBrowser();
                                }
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

Column _buildInfoPane(Weapon w, ThemeData theme, BuildContext context) {
  final imagePaths = w.allSpriteFiles;

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
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  w.name ?? w.id,
                  style: theme.textTheme.titleLarge?.copyWith(
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SelectableText(w.id, style: theme.textTheme.labelSmall),
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
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: imagePaths
            .map(
              (p) => FutureBuilder<String?>(
                future: _getWeaponImagePath([p]),
                builder: (context, snap) {
                  final path = snap.data;
                  if (path == null) {
                    return const SizedBox.shrink();
                  }
                  return GestureDetector(
                    onTap: () => path.toFile().showInExplorer(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MovingTooltipWidget.image(
                          path: path,
                          child: Image.file(
                            File(path),
                            width: 56,
                            height: 56,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 56,
                          child: TextTriOS(
                            path.split(Platform.pathSeparator).last,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            )
            .toList(),
      ),
      const SizedBox(height: 8),
      WeaponCodexCard.create(weapon: w, showTitle: false, useAbbreviations: false),
      Divider(color: Theme.of(context).colorScheme.outline),
      _kv(
        w.modVariant != null ? 'Mod' : null,
        w.modVariant?.modInfo.nameOrId ?? 'Vanilla',
        theme,
      ),
      _kv('Type', w.weaponType?.toTitleCase(), theme),
      _kv('Size', w.size?.toTitleCase(), theme),
      _kv('Tech/Manufacturer', w.techManufacturer, theme),
      _kv('Spec Class', w.specClass, theme),
      _kv('Raw Type', w.type, theme),
      // Combat
      section('Combat'),
      Wrap(
        runSpacing: 6,
        children: [
          _chip('Dmg/Shot', _fmtNum(w.damagePerShot)),
          _chip('Dmg/Sec', _fmtNum(w.damagePerSecond)),
          _chip('EMP', _fmtNum(w.emp)),
          _chip('Impact', _fmtNum(w.impact)),
          _chip('Range', _fmtNum(w.range)),
          _chip('Turn Rate', _fmtNum(w.turnRate)),
          _chip('OP', _fmtNum(w.ops)),
        ],
      ),
      // Fire Mechanics
      section('Fire Mechanics'),
      Wrap(
        runSpacing: 6,
        children: [
          _chip('Ammo', _fmtNum(w.ammo)),
          _chip('Ammo/Sec', _fmtNum(w.ammoPerSec)),
          _chip('Reload Size', _fmtNum(w.reloadSize)),
          _chip('Energy/Shot', _fmtNum(w.energyPerShot)),
          _chip('Energy/Sec', _fmtNum(w.energyPerSecond)),
          _chip('Chargeup', _fmtNum(w.chargeup)),
          _chip('Chargedown', _fmtNum(w.chargedown)),
          _chip('Burst Size', _fmtNum(w.burstSize)),
          _chip('Burst Delay', _fmtNum(w.burstDelay)),
        ],
      ),
      // Accuracy & Spread
      section('Accuracy & Spread'),
      Wrap(
        runSpacing: 6,
        children: [
          _chip('Min Spread', _fmtNum(w.minSpread)),
          _chip('Max Spread', _fmtNum(w.maxSpread)),
          _chip('Spread/Shot', _fmtNum(w.spreadPerShot)),
          _chip('Spread Decay/Sec', _fmtNum(w.spreadDecayPerSec)),
          _chip('Autofire Acc Bonus', _fmtNum(w.autofireAccBonus)),
          if ((w.extraArcForAI ?? '').isNotEmpty)
            _chip('Extra Arc (AI)', w.extraArcForAI!),
        ],
      ),
      // Projectile
      section('Projectile'),
      Wrap(
        runSpacing: 6,
        children: [
          _chip('Beam Speed', _fmtNum(w.beamSpeed)),
          _chip('Proj Speed', _fmtNum(w.projSpeed)),
          _chip('Launch Speed', _fmtNum(w.launchSpeed)),
          _chip('Flight Time', _fmtNum(w.flightTime)),
          _chip('Proj HP', _fmtNum(w.projHitpoints)),
        ],
      ),
      // Misc
      section('Misc'),
      Wrap(
        runSpacing: 6,
        children: [
          _chip('Tier', _fmtNum(w.tier)),
          _chip('Rarity', _fmtNum(w.rarity)),
          _chip('Base Value', w.baseValue.asCredits()),
          if (w.number != null) _chip('Number', _fmtNum(w.number)),
          if (w.noDPSInTooltip == true) _chip('No DPS In Tooltip', 'Yes'),
          if ((w.hints ?? '').isNotEmpty) _chip('Hints', w.hints!),
          if ((w.tags ?? '').isNotEmpty) _chip('Tags', w.tags!),
          if ((w.groupTag ?? '').isNotEmpty) _chip('Group Tag', w.groupTag!),
          if ((w.forWeaponTooltip ?? '').isNotEmpty)
            _chip('For Weapon Tooltip', w.forWeaponTooltip!),
          if ((w.primaryRoleStr ?? '').isNotEmpty)
            _chip('Primary Role', w.primaryRoleStr!),
          if ((w.speedStr ?? '').isNotEmpty) _chip('Speed', w.speedStr!),
          if ((w.trackingStr ?? '').isNotEmpty)
            _chip('Tracking', w.trackingStr!),
          if ((w.turnRateStr ?? '').isNotEmpty)
            _chip('Turn Rate (txt)', w.turnRateStr!),
          if ((w.accuracyStr ?? '').isNotEmpty)
            _chip('Accuracy', w.accuracyStr!),
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

final Map<String, bool> _weaponImagePathCache = {};

Future<String?> _getWeaponImagePath(List<String> imagePaths) async {
  for (String path in imagePaths) {
    if (_weaponImagePathCache.containsKey(path)) {
      if (_weaponImagePathCache[path] == true) {
        return path;
      }
    } else {
      bool exists = await File(path).exists();
      _weaponImagePathCache[path] = exists;
      if (exists) {
        return path;
      }
    }
  }
  return null;
}
