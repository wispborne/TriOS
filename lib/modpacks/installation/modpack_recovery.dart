import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:trios/catalog/catalog_download_resolver.dart';
import 'package:trios/catalog/catalog_manager.dart';
import 'package:trios/catalog/models/catalog_mod.dart';
import 'package:trios/catalog/models/mod_repo_entry.dart';
import 'package:trios/modpacks/models/modpack_definition.dart';
import 'package:trios/trios/download_manager/download_manager.dart';
import 'package:trios/utils/catalog_search.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';

import 'modpack_installation.dart';

/// Saved catalog clues outrank exact item names, which outrank likely names.
/// Ranking never authorizes a download, even for an exact match.
int? modpackRecoveryRank(ModpackItem item, ModRepoEntry entry) {
  final clue = item.catalog;
  final urls = entry.getUrls();
  if ((clue?.name != null &&
          clue!.name!.toLowerCase() == entry.name.toLowerCase()) ||
      (clue?.forumTopicId != null &&
          clue!.forumTopicId == extractForumThreadId(urls[ModUrlType.Forum])) ||
      (clue?.nexusModsId != null &&
          clue!.nexusModsId == extractNexusModId(urls[ModUrlType.NexusMods]))) {
    return 0;
  }
  final name = (item.name ?? item.modId).trim().toLowerCase();
  final candidate = entry.name.trim().toLowerCase();
  if (name == candidate) return 1;
  final words = name
      .split(RegExp(r'[^a-z0-9]+'))
      .where((w) => w.length > 2)
      .toSet();
  final other = candidate.split(RegExp(r'[^a-z0-9]+')).toSet();
  if (candidate.contains(name) ||
      name.contains(candidate) ||
      words.intersection(other).isNotEmpty) {
    return 2;
  }
  return null;
}

class _Recovery {
  final ModRepoEntry entry;
  final DownloadCandidate candidate;
  final int rank;
  const _Recovery(this.entry, this.candidate, this.rank);
}

Future<ModpackInstallChoice?> chooseModpackRecovery(
  BuildContext context,
  WidgetRef ref,
  ModpackInstallChoice original,
) async {
  final manager = ref.read(modpackInstallationProvider.notifier);
  await ref
      .read(browseModsNotifierProvider.future)
      .timeout(const Duration(seconds: 30));
  final catalog = ref.read(catalogModsProvider);
  final choices =
      <_Recovery>[
        for (final mod in catalog)
          if (modpackRecoveryRank(original.row.item, mod.entry)
              case final int rank)
            for (final candidate in resolveDownloadCandidates(
              mod.entry,
              ref.read(appSettings).enableAiFeatures ? mod.llmMod : null,
            ))
              if (candidate.isOneClick &&
                  candidate.kind != DownloadCandidateKind.triosDeepLink)
                _Recovery(mod.entry, candidate, rank),
      ]..sort(
        (a, b) => a.rank != b.rank
            ? a.rank.compareTo(b.rank)
            : a.entry.name.compareTo(b.entry.name),
      );
  if (!context.mounted) return null;
  final chosen = await showDialog<_Recovery>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text(
        'Original source failed — install from Catalog instead',
      ),
      content: SizedBox(
        width: 720,
        height: 400,
        child: choices.isEmpty
            ? const Text(
                'No downloadable matches found. Repair the source in the modpack editor or install the mod manually.',
              )
            : ListView(
                children: [
                  const Text(
                    'Choose a source to use for this installation. The archive must still contain the declared mod ID. The saved modpack will keep its original source.',
                  ),
                  for (final choice in choices)
                    MovingTooltipWidget.text(
                      message: choice.candidate.url,
                      child: ListTile(
                        title: Text(choice.entry.name),
                        subtitle: Text(
                          '${switch (choice.rank) {
                            0 => 'Saved catalog clue',
                            1 => 'Exact name',
                            _ => 'Likely match — check carefully',
                          }} · ${choice.candidate.label}\n${choice.candidate.url}',
                        ),
                        onTap: () => Navigator.pop(context, choice),
                      ),
                    ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    ),
  );
  if (chosen == null) return null;
  final url = await manager.resolveSource(
    original.row.item.copyWith(
      url: chosen.candidate.url,
      sourceType: ModpackItemSourceType.directDownload,
    ),
  );
  return ModpackInstallChoice(
    original.row,
    downloadUrl: url,
    recoverySource: DownloadSourceHint.fromModRepoEntry(chosen.entry),
  );
}
