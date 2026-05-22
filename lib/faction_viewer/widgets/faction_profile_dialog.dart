import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:trios/faction_viewer/models/faction.dart';
import 'package:trios/hullmod_viewer/hullmods_manager.dart';
import 'package:trios/hullmod_viewer/models/hullmod.dart';
import 'package:trios/hullmod_viewer/widgets/hullmod_codex_card.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/ship_systems_manager/ship_systems_manager.dart';
import 'package:trios/ship_viewer/models/ship.dart';
import 'package:trios/ship_viewer/ship_manager.dart';
import 'package:trios/ship_viewer/widgets/ship_codex_card.dart';
import 'package:trios/weapon_viewer/models/weapon.dart';
import 'package:trios/weapon_viewer/weapons_manager.dart';
import 'package:trios/weapon_viewer/widgets/weapon_codex_card.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/widgets/display_chip.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/trios_expansion_tile.dart';
import 'package:url_launcher/url_launcher_string.dart';

class FactionProfileDialog extends ConsumerWidget {
  final Faction faction;
  final Directory? gameCoreDir;

  const FactionProfileDialog({
    super.key,
    required this.faction,
    required this.gameCoreDir,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final factionColor = faction.factionColor;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: factionColor,
      brightness: Theme.of(context).brightness,
    );

    Widget content = _buildContent(context, factionColor, ref);
    content = Theme(
      data: Theme.of(context).copyWith(colorScheme: colorScheme),
      child: content,
    );

    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: content,
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    Color factionColor,
    WidgetRef ref,
  ) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        _buildHeader(context, theme, factionColor),
        Flexible(
          child: SingleChildScrollView(
            padding: .all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (faction.doctrine != null) ...[
                  _sectionTitle('Doctrine', theme),
                  const SizedBox(height: 8),
                  _buildDoctrineSection(theme, factionColor),
                  const SizedBox(height: 16),
                ],
                _sectionTitle('Fleet', theme),
                const SizedBox(height: 8),
                Theme(data: theme, child: _buildFleetSection(theme, ref)),
                const SizedBox(height: 16),
                if (faction.malePortraits.isNotEmpty ||
                    faction.femalePortraits.isNotEmpty) ...[
                  _sectionTitle('Portraits', theme),
                  const SizedBox(height: 8),
                  _buildPortraitsSection(theme, ref),
                  const SizedBox(height: 16),
                ],
                if (faction.customFlags.isNotEmpty) ...[
                  _sectionTitle('Behavior', theme),
                  const SizedBox(height: 8),
                  Theme(data: theme, child: _buildBehaviorSection(theme)),
                  const SizedBox(height: 16),
                ],
                _sectionTitle('Mods that add/modify this faction', theme),
                const SizedBox(height: 8),
                _buildSourceSection(theme),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    Color factionColor,
  ) {
    return Container(
      color: factionColor.withValues(alpha: 0.15),
      padding: .fromLTRB(16, 12, 8, 12),
      child: Row(
        children: [
          _buildLogo(48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  faction.displayNameBest,
                  style: theme.textTheme.headlineSmall,
                ),
                if (faction.shipNamePrefix != null)
                  Text(
                    'Ship prefix: ${faction.shipNamePrefix}',
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          MovingTooltipWidget.text(
            message: 'Faction color',
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: factionColor,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
            ),
          ),
          _buildOverflowMenu(context),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  List<(File, String)> _factionFiles() {
    final files = <(File, String)>[];
    for (final source in faction.sources) {
      final folder = source.modVariant is ModVariant
          ? (source.modVariant as ModVariant).modFolder
          : gameCoreDir;
      if (folder == null) continue;
      final file = File(
        p.join(
          folder.path,
          'data',
          'world',
          'factions',
          '${faction.id}.faction',
        ),
      );
      if (file.existsSync()) files.add((file, source.name));
    }
    return files;
  }

  Widget _buildOverflowMenu(BuildContext context) {
    final files = _factionFiles();
    if (files.isEmpty) return const SizedBox.shrink();

    final showSource = files.length > 1;

    return PopupMenuButton<void>(
      icon: const Icon(Icons.more_vert),
      tooltip: 'More options',
      itemBuilder: (context) {
        final items = <PopupMenuEntry<void>>[];
        for (var i = 0; i < files.length; i++) {
          final (file, sourceName) = files[i];
          final suffix = showSource ? ' ($sourceName)' : '';
          items.add(
            PopupMenuItem(
              onTap: () => launchUrlString(file.path),
              child: ListTile(
                leading: const Icon(Icons.open_in_new),
                title: Text('Open .faction file$suffix'),
                dense: true,
              ),
            ),
          );
          items.add(
            PopupMenuItem(
              onTap: () => launchUrlString(file.parent.path),
              child: ListTile(
                leading: const Icon(Icons.folder_open),
                title: Text('Open faction folder$suffix'),
                dense: true,
              ),
            ),
          );
          if (i < files.length - 1) items.add(const PopupMenuDivider());
        }
        return items;
      },
    );
  }

  Widget _buildLogo(double size) {
    final logoFile = faction.resolveImageFile(faction.logo, gameCoreDir);
    if (logoFile == null) {
      return SizedBox(
        width: size,
        height: size,
        child: Icon(Icons.flag, size: size * 0.6),
      );
    }

    return MovingTooltipWidget.image(
      path: logoFile.path,
      child: SizedBox(
        width: size,
        height: size,
        child: Image.file(
          logoFile,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => Icon(Icons.flag, size: size * 0.6),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildDoctrineSection(ThemeData theme, Color factionColor) {
    final d = faction.doctrine!;
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _doctrineBar('Warships', d.warships, 5, factionColor, theme),
        _doctrineBar('Carriers', d.carriers, 5, factionColor, theme),
        _doctrineBar('Phase', d.phaseShips, 5, factionColor, theme),
        _doctrineBar('Aggression', d.aggression, 5, factionColor, theme),
        _doctrineBar('Ship Quality', d.shipQuality, 5, factionColor, theme),
        _doctrineBar(
          'Officer Quality',
          d.officerQuality,
          5,
          factionColor,
          theme,
        ),
        _doctrineBar('Ship Size', d.shipSize, 5, factionColor, theme),
        _doctrineBar('Fleet Size', d.numShips, 5, factionColor, theme),
      ],
    );
  }

  Widget _doctrineBar(
    String label,
    int value,
    int max,
    Color color,
    ThemeData theme,
  ) {
    return SizedBox(
      width: 200,
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: theme.textTheme.bodySmall),
          ),
          Expanded(
            child: Row(
              children: List.generate(max, (i) {
                return Expanded(
                  child: Container(
                    height: 12,
                    margin: .only(right: i < max - 1 ? 2 : 0),
                    decoration: BoxDecoration(
                      color: i < value
                          ? color.withValues(alpha: 0.8)
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$value',
            style: theme.textTheme.labelSmall?.copyWith(
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFleetSection(ThemeData theme, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        _BlueprintSection<Ship>(
          label: 'Known Ships',
          ids: faction.knownShipIds,
          attributionKey: 'knownShips.hulls',
          sectionAttributions: faction.sectionAttributions,
          itemAttributions: faction.itemAttributions,
          provider: shipListNotifierProvider,
          ref: ref,
          theme: theme,
          gameCoreDir: gameCoreDir,
          getName: (s) => s.name ?? s.id,
          getThumbnail: (s) =>
              s.spriteFile != null ? File(s.spriteFile!) : null,
          buildTooltip: (item, child) => _shipTooltip(ref, item, child),
          onTap: (context, ship) => _showShipDialog(context, ref, ship),
        ),
        _BlueprintSection<Weapon>(
          label: 'Known Weapons',
          ids: faction.knownWeaponIds,
          attributionKey: 'knownWeapons.weapons',
          sectionAttributions: faction.sectionAttributions,
          itemAttributions: faction.itemAttributions,
          provider: weaponListNotifierProvider,
          ref: ref,
          theme: theme,
          gameCoreDir: gameCoreDir,
          getName: (w) => w.name ?? w.id,
          getThumbnail: (w) {
            final sprite = w.turretSprite ?? w.hardpointSprite;
            if (sprite == null || gameCoreDir == null) return null;
            return File(p.join(gameCoreDir!.path, sprite));
          },
          buildTooltip: (item, child) =>
              WeaponCodexCard.tooltip(weapon: item, child: child),
          onTap: (context, weapon) => _showWeaponDialog(context, weapon),
        ),
        _BlueprintSection<Ship>(
          label: 'Known Fighters',
          ids: faction.knownFighterIds,
          attributionKey: 'knownFighters.fighters',
          sectionAttributions: faction.sectionAttributions,
          itemAttributions: faction.itemAttributions,
          provider: shipListNotifierProvider,
          ref: ref,
          theme: theme,
          gameCoreDir: gameCoreDir,
          getName: (s) => s.name ?? s.id,
          getThumbnail: (s) =>
              s.spriteFile != null ? File(s.spriteFile!) : null,
          buildTooltip: (item, child) => _shipTooltip(ref, item, child),
          onTap: (context, ship) => _showShipDialog(context, ref, ship),
        ),
        _BlueprintSection<Hullmod>(
          label: 'Known Hullmods',
          ids: faction.knownHullModIds,
          attributionKey: 'knownHullMods.hullMods',
          sectionAttributions: faction.sectionAttributions,
          itemAttributions: faction.itemAttributions,
          provider: hullmodListNotifierProvider,
          ref: ref,
          theme: theme,
          gameCoreDir: gameCoreDir,
          getName: (h) => h.name ?? h.id,
          getThumbnail: (h) {
            if (h.sprite == null || gameCoreDir == null) return null;
            return File(p.join(gameCoreDir!.path, h.sprite!));
          },
          buildTooltip: (item, child) =>
              HullmodCodexCard.tooltip(hullmod: item, child: child),
          onTap: (context, hullmod) => _showHullmodDialog(context, hullmod),
        ),
      ],
    );
  }

  void _showShipDialog(BuildContext context, WidgetRef ref, Ship ship) {
    final shipSystems = ref.read(shipSystemsStreamProvider).valueOrNull ?? [];
    final shipSystemsMap = {for (final s in shipSystems) s.id: s};
    final weapons = ref.read(weaponListNotifierProvider).valueOrNull ?? [];
    final weaponsMap = {for (final w in weapons) w.id: w};

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Padding(
            padding: .all(16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShipCodexCard.create(
                    ship: ship,
                    shipSystemsMap: shipSystemsMap,
                    weaponsMap: weaponsMap,
                    useAbbreviations: false,
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showWeaponDialog(BuildContext context, Weapon weapon) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: .all(16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  WeaponCodexCard.create(
                    weapon: weapon,
                    useAbbreviations: false,
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showHullmodDialog(BuildContext context, Hullmod hullmod) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: .all(16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HullmodCodexCard.create(hullmod: hullmod),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _shipTooltip(WidgetRef ref, Ship ship, Widget child) {
    final shipSystems = ref.watch(shipSystemsStreamProvider).valueOrNull ?? [];
    final shipSystemsMap = {for (final s in shipSystems) s.id: s};
    final weapons = ref.watch(weaponListNotifierProvider).valueOrNull ?? [];
    final weaponsMap = {for (final w in weapons) w.id: w};
    return ShipCodexCard.tooltip(
      ship: ship,
      shipSystemsMap: shipSystemsMap,
      weaponsMap: weaponsMap,
      child: child,
    );
  }

  Widget _buildPortraitsSection(ThemeData theme, WidgetRef ref) {
    final allPortraits = [...faction.malePortraits, ...faction.femalePortraits];
    final count = allPortraits.length;

    final searchDirs = <Directory>[];
    if (faction.sources.isNotEmpty) {
      for (final source in faction.sources.reversed) {
        final dir = source.modVariant is ModVariant
            ? (source.modVariant as ModVariant).modFolder
            : gameCoreDir;
        if (dir != null && !searchDirs.contains(dir)) searchDirs.add(dir);
      }
    } else {
      for (final mod in ref.read(AppState.mods)) {
        final variant = mod.findFirstEnabledOrHighestVersion;
        if (variant != null) searchDirs.add(variant.modFolder);
      }
    }
    if (gameCoreDir != null && !searchDirs.contains(gameCoreDir)) {
      searchDirs.add(gameCoreDir!);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${faction.malePortraits.length} male, '
          '${faction.femalePortraits.length} female',
          style: theme.textTheme.bodySmall,
        ),
        if (searchDirs.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: allPortraits.take(20).map((portraitPath) {
              File? file;
              for (final dir in searchDirs) {
                final candidate = File(p.join(dir.path, portraitPath));
                if (candidate.existsSync()) {
                  file = candidate;
                  break;
                }
              }
              return MovingTooltipWidget.image(
                path: file?.path ?? portraitPath,
                child: SizedBox(
                  width: 40,
                  height: 50,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: file != null
                        ? Image.file(file, fit: BoxFit.cover)
                        : const Icon(Icons.person, size: 20),
                  ),
                ),
              );
            }).toList(),
          ),
          if (count > 20)
            Padding(
              padding: .only(top: 4),
              child: Text(
                '+${count - 20} more',
                style: theme.textTheme.labelSmall,
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildBehaviorSection(ThemeData theme) {
    final interestingFlags = <String, dynamic>{};
    for (final entry in faction.customFlags.entries) {
      if (entry.value is bool || entry.value is num) {
        interestingFlags[entry.key] = entry.value;
      }
    }

    return Column(
      crossAxisAlignment: .start,
      spacing: 8,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: interestingFlags.entries.map((entry) {
            final isTrue = entry.value == true;
            final isFalse = entry.value == false;
            final label = _formatFlagName(entry.key);
            final display = isFalse
                ? label
                : entry.value is bool
                ? label
                : '$label: ${entry.value}';

            return Chip(
              label: Text(display),
              labelStyle: theme.textTheme.labelSmall,
              visualDensity: VisualDensity.compact,
              avatar: isFalse
                  ? Icon(Icons.close, size: 14, color: theme.colorScheme.error)
                  : isTrue
                  ? Icon(
                      Icons.check,
                      size: 14,
                      color: theme.colorScheme.primary,
                    )
                  : null,
            );
          }).toList(),
        ),
        if (faction.illegalCommodities.isNotEmpty)
          Padding(
            padding: .only(top: 4),
            child: Text(
              'Illegal commodities: ${faction.illegalCommodities.join(', ')}',
              style: theme.textTheme.bodySmall,
            ),
          ),
      ],
    );
  }

  Widget _buildSourceSection(ThemeData theme) {
    return Text(faction.sourceNames, style: theme.textTheme.bodySmall);
  }

  String _formatFlagName(String flag) {
    return flag.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (m) => '${m[1]} ${m[2]?.toLowerCase()}',
    );
  }
}

class _BlueprintSection<T> extends StatelessWidget {
  final String label;
  final List<String> ids;
  final String attributionKey;
  final Map<String, List<SourceContribution>> sectionAttributions;
  final Map<String, Map<String, String>> itemAttributions;
  final ProviderListenable<AsyncValue<List<T>>> provider;
  final WidgetRef ref;
  final ThemeData theme;
  final Directory? gameCoreDir;
  final String Function(T) getName;
  final File? Function(T) getThumbnail;
  final Widget Function(T item, Widget child)? buildTooltip;
  final void Function(BuildContext context, T item)? onTap;

  const _BlueprintSection({
    required this.label,
    required this.ids,
    required this.attributionKey,
    required this.sectionAttributions,
    required this.itemAttributions,
    required this.provider,
    required this.ref,
    required this.theme,
    required this.gameCoreDir,
    required this.getName,
    required this.getThumbnail,
    this.buildTooltip,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (ids.isEmpty) {
      return Padding(
        padding: .symmetric(vertical: 4),
        child: Text('$label: 0', style: theme.textTheme.bodySmall),
      );
    }

    final attribution = sectionAttributions[attributionKey];
    final hasMultipleSources = attribution != null && attribution.length > 1;

    return TriOSExpansionTile(
      childrenPadding: .only(left: 16, bottom: 8),
      dense: true,
      title: Text(
        '$label (${ids.length})',
        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
      ),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                children: hasMultipleSources
                    ? _buildGrouped(attribution)
                    : [
                        _BlueprintWrap<T>(
                          ids: ids,
                          provider: provider,
                          ref: ref,
                          theme: theme,
                          getName: getName,
                          getThumbnail: getThumbnail,
                          buildTooltip: buildTooltip,
                          onTap: onTap,
                        ),
                      ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildGrouped(List<SourceContribution> attribution) {
    final perItem = itemAttributions[attributionKey] ?? {};
    final sourceOrder = attribution.map((c) => c.source).toList();

    final groups = <String, List<String>>{};
    for (final id in ids) {
      final source = perItem[id] ?? sourceOrder.first;
      groups.putIfAbsent(source, () => []).add(id);
    }

    final orderedNames = <String>[
      for (final name in sourceOrder)
        if (groups.containsKey(name)) name,
      for (final name in groups.keys)
        if (!sourceOrder.contains(name)) name,
    ];

    return [
      for (final sourceName in orderedNames) ...[
        Padding(
          padding: .only(top: 4, bottom: 2),
          child: Text(
            sourceName,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        _BlueprintWrap<T>(
          ids: groups[sourceName]!,
          provider: provider,
          ref: ref,
          theme: theme,
          getName: getName,
          getThumbnail: getThumbnail,
          buildTooltip: buildTooltip,
          onTap: onTap,
        ),
      ],
    ];
  }
}

class _BlueprintWrap<T> extends StatelessWidget {
  final List<String> ids;
  final ProviderListenable<AsyncValue<List<T>>> provider;
  final WidgetRef ref;
  final ThemeData theme;
  final String Function(T) getName;
  final File? Function(T) getThumbnail;
  final Widget Function(T item, Widget child)? buildTooltip;
  final void Function(BuildContext context, T item)? onTap;

  const _BlueprintWrap({
    required this.ids,
    required this.provider,
    required this.ref,
    required this.theme,
    required this.getName,
    required this.getThumbnail,
    this.buildTooltip,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final allItems = ref.watch(provider).valueOrNull ?? [];
    final itemMap = <String, T>{};
    for (final item in allItems) {
      final id = (item as dynamic).id as String;
      itemMap[id] = item;
    }

    final resolved = <(String, T?)>[];
    for (final id in ids) {
      resolved.add((id, itemMap[id]));
    }
    resolved.sort((a, b) {
      final nameA = a.$2 != null ? getName(a.$2 as T) : a.$1;
      final nameB = b.$2 != null ? getName(b.$2 as T) : b.$1;
      return nameA.toLowerCase().compareTo(nameB.toLowerCase());
    });

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: resolved.map((entry) {
        final (id, item) = entry;
        final name = item != null ? getName(item) : id;
        File? thumb;
        if (item != null) {
          thumb = getThumbnail(item);
        }

        final avatarWidget = thumb != null && thumb.existsSync()
            ? Image.file(
                thumb,
                fit: BoxFit.contain,
                cacheWidth: 20,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.image_not_supported, size: 20),
              )
            : const Icon(Icons.image_not_supported, size: 20);

        Widget chip = DisplayChip(
          avatar: avatarWidget,
          label: name,
          avatarSize: 20,
          labelStyle: theme.textTheme.labelSmall,
        );

        if (item != null && onTap != null) {
          chip = MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTap!(context, item),
              child: IgnorePointer(child: chip),
            ),
          );
        }

        if (item != null && buildTooltip != null) {
          chip = buildTooltip!(item, chip);
        }

        return chip;
      }).toList(),
    );
  }
}
