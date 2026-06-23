import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/faction_viewer/faction_manager.dart';
import 'package:trios/mod_profiles/save_reader.dart';
import 'package:trios/sector_map/finder/finder_engine.dart';
import 'package:trios/sector_map/models/sector.dart';
import 'package:trios/sector_map/sector_map_parser.dart';

/// Identifies a save's campaign file to parse. Records give value equality, so
/// this is a stable `family` key (re-parses only when the path/version change).
typedef SectorSource = ({String campaignXmlPath, String gameVersion});

extension SaveFileSectorSource on SaveFile {
  SectorSource get sectorSource => (
    campaignXmlPath: '${folder.path}${Platform.pathSeparator}campaign.xml',
    gameVersion: saveFileVersion ?? '',
  );
}

/// Parses a save's `campaign.xml` into a [Sector] on a background isolate.
/// The 10 MB read happens here; the heavy parse runs off the UI thread.
final sectorMapProvider = FutureProvider.family<Sector, SectorSource>((
  ref,
  source,
) async {
  final file = File(source.campaignXmlPath);
  if (!await file.exists()) {
    throw StateError('campaign.xml not found: ${source.campaignXmlPath}');
  }
  final xml = await file.readAsString();
  final version = source.gameVersion;
  final sector = await Isolate.run(
    () => parseCampaignXml(xml, gameVersion: version),
  );
  if (sector.systems.isEmpty) {
    throw StateError(
      'Parsed 0 systems from ${source.campaignXmlPath}. The save format may '
      'have changed (game version "$version") or this is not a sector save.',
    );
  }
  return sector;
});

/// A [FinderEngine] for the loaded sector, rebuilt only when the sector
/// changes. The engine precomputes per-system facts once; criteria-driven
/// `matchCount`/`filter` calls against it are cheap to run on every knob change.
final finderEngineProvider = Provider.family<FinderEngine?, SectorSource>((
  ref,
  source,
) {
  final sector = ref.watch(sectorMapProvider(source)).valueOrNull;
  return sector == null ? null : FinderEngine(sector);
});

/// Maps a faction id to its UI color, reusing faction_viewer's parsed factions.
/// Unknown ids fall back to [unknownFactionColor].
final factionColorsProvider = Provider<Map<String, Color>>((ref) {
  final factions = ref.watch(factionListNotifierProvider).valueOrNull ?? [];
  return {for (final f in factions) f.id: f.factionColor};
});

const Color unknownFactionColor = Color(0xFF9E9E9E); // grey

Color factionColorFor(Map<String, Color> colors, String factionId) =>
    colors[factionId] ?? unknownFactionColor;

/// Maps a faction id to its display name, for tooltips and the detail panel.
final factionNamesProvider = Provider<Map<String, String>>((ref) {
  final factions = ref.watch(factionListNotifierProvider).valueOrNull ?? [];
  return {for (final f in factions) f.id: f.displayNameBest};
});

/// Falls back to a title-cased id when the faction isn't found (e.g. modded).
String factionNameFor(Map<String, String> names, String factionId) =>
    names[factionId] ??
    factionId
        .split('_')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
