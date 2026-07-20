import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/faction_viewer/models/faction.dart';
import 'package:trios/faction_viewer/spawn_weights/spawn_weight_calculator.dart';
import 'package:trios/faction_viewer/spawn_weights/vanilla_share_bar.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/text_trios.dart';

class FactionCard extends ConsumerWidget {
  final Faction faction;
  final Directory? gameCoreDir;
  final VoidCallback onTap;

  /// Leave weights added by mods that aren't enabled out of the spawn share.
  final bool onlyEnabledMods;

  const FactionCard({
    super.key,
    required this.faction,
    required this.gameCoreDir,
    required this.onTap,
    this.onlyEnabledMods = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final factionColor = faction.factionColor;
    final theme = Theme.of(context);
    final spawnReady = ref.watch(spawnWeightsReadyProvider(onlyEnabledMods));
    final summary =
        ref.watch(
          factionSpawnSummariesProvider(onlyEnabledMods),
        )[faction.mergeKey] ??
        FactionSpawnSummary.empty;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            // Faction color accent bar at top.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(height: 4, color: factionColor),
            ),
            Padding(
              padding: .fromLTRB(12, 12, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildLogo(gameCoreDir),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              faction.displayName,
                              style: theme.textTheme.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (faction.shipNamePrefix != null)
                              Text(
                                faction.shipNamePrefix!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (faction.doctrine != null) ...[
                    const SizedBox(height: 4),
                    _buildDoctrineRow(theme),
                    const SizedBox(height: 4),
                  ],
                  const Spacer(),
                  _buildStatsRow(theme),
                  Padding(
                    padding: .only(top: 4),
                    child: Row(
                      crossAxisAlignment: .center,
                      spacing: 4,
                      children: [
                        MovingTooltipWidget.text(
                          message:
                              "How much of the fleet weight is contributed by vanilla/mods",
                          child: Text(
                            "Fleet Wgts:",
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Expanded(
                          child: spawnReady
                              ? Padding(
                                  padding: const .only(top: 1),
                                  child: VanillaShareBar(
                                    summary: summary,
                                    factionColor: factionColor,
                                    factionName: faction.displayName,
                                  ),
                                )
                              : Text(
                                  'Calculating fleet weights…',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: .only(top: 4),
                    child: MovingTooltipWidget.text(
                      message: faction.attributionTooltip,
                      child: TextTriOS(
                        _sourceLine(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        tooltipMaxWidth: 300,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// One-line source summary: who added the faction, plus how many other
  /// mods change it. Full breakdown lives in the tooltip.
  String _sourceLine() {
    final adder = faction.addedBy;
    if (adder == null) {
      return faction.sources.isEmpty ? '' : 'Patch only';
    }
    final modCount = faction.modifiedBy.length;
    if (modCount == 0) return adder.name;
    return '${adder.name} +$modCount ${modCount == 1 ? 'mod' : 'mods'}';
  }

  Widget _buildLogo(Directory? gameCoreDir) {
    final logoFile = faction.resolveImageFile(faction.logo, gameCoreDir);
    if (logoFile == null) {
      return const SizedBox(
        width: 40,
        height: 40,
        child: Icon(Icons.flag, size: 24),
      );
    }
    return _logoImage(logoFile);
  }

  Widget _logoImage(File file) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Image.file(
        file,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const Icon(Icons.flag, size: 24),
      ),
    );
  }

  Widget _buildDoctrineRow(ThemeData theme) {
    final d = faction.doctrine!;
    final factionColor = faction.factionColor;
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        _doctrineStat('War', 'Warships', d.warships, factionColor, theme),
        _doctrineStat('Carr', 'Carriers', d.carriers, factionColor, theme),
        _doctrineStat('Phse', 'Phase Ships', d.phaseShips, factionColor, theme),
        _doctrineStat(
          'OffQ',
          'Officer Quality',
          d.officerQuality,
          factionColor,
          theme,
        ),
        _doctrineStat(
          'ShpQ',
          'Ship Quality',
          d.shipQuality,
          factionColor,
          theme,
        ),
        _doctrineStat('Fleet', 'Fleet Size', d.numShips, factionColor, theme),
        _doctrineStat('Shp#', 'Ship Size', d.shipSize, factionColor, theme),
        _doctrineStat('Aggr', 'Aggression', d.aggression, factionColor, theme),
      ],
    );
  }

  Widget _doctrineStat(
    String label,
    String tooltip,
    int value,
    Color factionColor,
    ThemeData theme,
  ) {
    return MovingTooltipWidget.text(
      message: '$tooltip: $value/5\nNote: May be changed by mods.',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: .start,
        children: [
          _buildPips(value, 5, factionColor, theme),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPips(int value, int max, Color color, ThemeData theme) {
    const gap = 1.0;
    final filledColor = color.withValues(alpha: 0.9);
    final emptyColor = theme.colorScheme.onSurface.withValues(alpha: 0.15);

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: gap,
      children: List.generate(max, (i) {
        return Container(
          width: 3,
          height: 4,
          decoration: BoxDecoration(
            color: i < value ? filledColor.withAlpha(200) : emptyColor,
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }

  Widget _buildStatsRow(ThemeData theme) {
    return Wrap(
      spacing: 12,
      alignment: WrapAlignment.start,
      children: [
        _stat('Ships', faction.knownShipIds.length, theme),
        _stat('Wpns', faction.knownWeaponIds.length, theme),
        _stat('Mods', faction.knownHullModIds.length, theme),
      ],
    );
  }

  Widget _stat(String label, int value, ThemeData theme) {
    return Text(
      '$label: $value',
      style: theme.textTheme.labelSmall?.copyWith(
        fontFeatures: [const FontFeature.tabularFigures()],
      ),
    );
  }
}
