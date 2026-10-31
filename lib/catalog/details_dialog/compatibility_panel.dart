import 'package:collection/collection.dart';
import 'package:material_ui/material_ui.dart';
import 'package:trios/catalog/catalog_download_resolver.dart';
import 'package:trios/catalog/catalog_mod_card.dart';
import 'package:trios/catalog/catalog_requires.dart';
import 'package:trios/catalog/details_dialog/addons_tab.dart';
import 'package:trios/catalog/details_dialog/details_panel_section.dart';
import 'package:trios/catalog/models/catalog_extras.dart';
import 'package:trios/catalog/models/catalog_mod.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/moving_tooltip.dart';

/// One add / update / remove mid-game question, with the author's answer.
class SaveQuestion {
  final String label;
  final CatalogSaveAnswer answer;

  /// The author's own words behind [answer].
  final String? words;

  const SaveQuestion(this.label, this.answer, this.words);
}

/// The add / update / remove mid-game answers for [mod], leaving out any
/// question with no answer. From the extras record, or the AI answer when
/// there's no record.
List<SaveQuestion> saveQuestionsFor(CatalogMod mod) {
  const addLabel = 'Add mid-game?';
  const updateLabel = 'Update mid-game?';
  const removeLabel = 'Remove from game?';

  final extras = mod.extras;
  if (extras != null) {
    return [
      if (extras.canAdd case final answer?)
        SaveQuestion(addLabel, answer, extras.saveCompatibilityText),
      if (extras.canUpdate case final answer?)
        SaveQuestion(updateLabel, answer, extras.updateCompatibilityText),
      if (extras.canRemove case final answer?)
        SaveQuestion(removeLabel, answer, extras.removalCompatibilityText),
    ];
  }

  final llm = mod.llmMod?.extras;
  if (llm == null) return const [];
  final updateNote = llm.updateNotes?.firstWhereOrNull((n) => n.answer != null);
  return [
    if (_answerFrom(llm.canAdd) case final answer?)
      SaveQuestion(addLabel, answer, llm.saveCompatibility),
    if (_answerFrom(updateNote?.answer) case final answer?)
      SaveQuestion(updateLabel, answer, updateNote?.quote),
    if (_answerFrom(llm.canRemove) case final answer?)
      SaveQuestion(removeLabel, answer, llm.removalCompatibility),
  ];
}

CatalogSaveAnswer? _answerFrom(String? text) {
  if (text == null) return null;
  return CatalogSaveAnswer.values.asNameMap()[text.trim().toLowerCase()] ??
      CatalogSaveAnswer.unknown;
}

/// The catalog mod [need] points at: by its catalog id, or else by the one
/// catalog mod with that name. Null when there's no such mod.
CatalogMod? catalogModForNeed(
  CatalogNeed need,
  List<CatalogMod> allMods, {
  required Map<String, String> idsByNameKey,
}) {
  final id = need.id?.trim().isNotEmpty == true
      ? need.id!.trim()
      : idsByNameKey[requiresNameKey(need.name)];
  if (id == null) return null;
  return allMods.firstWhereOrNull((mod) => mod.entry.id == id);
}

/// The Compatibility panel: game version, required and optional mods, and the
/// add / update / remove mid-game answers.
class CompatibilityPanel extends StatelessWidget {
  final CatalogMod mod;

  /// Every catalog mod, for finding the required and optional mods.
  final List<CatalogMod> allMods;

  /// The forum thread's download rows, for installing a required mod.
  final List<DownloadGroup> downloadGroups;

  /// True when a mod with this name is installed.
  final bool Function(String name) isInstalledByName;

  /// Shows another catalog mod in the dialog.
  final void Function(CatalogMod mod) onOpenMod;
  final OnGroupDownload onDownload;

  const CompatibilityPanel({
    super.key,
    required this.mod,
    required this.allMods,
    required this.downloadGroups,
    required this.isInstalledByName,
    required this.onOpenMod,
    required this.onDownload,
  });

  /// True when the panel has anything to show.
  static bool hasContent(CatalogMod mod) =>
      (mod.entry.gameVersionReq?.isNotEmpty ?? false) ||
      mod.requiredMods.isNotEmpty ||
      mod.optionalMods.isNotEmpty ||
      saveQuestionsFor(mod).isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final idsByNameKey = catalogIdsByNameKey(allMods);
    final questions = saveQuestionsFor(mod);
    final gameVersion = mod.entry.gameVersionReq?.trim();

    Widget tags(List<CatalogNeed> needs, {required bool offerInstall}) => Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (final need in needs)
          _NeedTag(
            need: need,
            catalogMod: catalogModForNeed(
              need,
              allMods,
              idsByNameKey: idsByNameKey,
            ),
            isInstalledByName: isInstalledByName,
            downloadGroup: offerInstall
                ? downloadGroups.firstWhereOrNull(
                    (g) =>
                        g.candidates.isNotEmpty &&
                        g.modName != null &&
                        modNamesMatch(g.rawModName ?? g.modName!, need.name),
                  )
                : null,
            onOpenMod: onOpenMod,
            onDownload: onDownload,
          ),
      ],
    );

    return SidePanelSection(
      title: 'Compatibility',
      children: [
        if (gameVersion != null && gameVersion.isNotEmpty)
          SidePanelRow(
            label: 'Game version',
            value: CatalogGameVersionBadge(mod: mod.entry),
          ),
        if (mod.requiredMods.isNotEmpty)
          Column(
            crossAxisAlignment: .start,
            spacing: 8,
            children: [
              const SidePanelLabel('Requires'),
              tags(mod.requiredMods, offerInstall: true),
            ],
          ),
        if (mod.optionalMods.isNotEmpty)
          Column(
            crossAxisAlignment: .start,
            spacing: 8,
            children: [
              const SidePanelLabel('Optional'),
              tags(mod.optionalMods, offerInstall: false),
            ],
          ),
        for (final question in questions) _SaveQuestionRow(question: question),
      ],
    );
  }
}

/// A required or optional mod. Clicking it shows that mod when it's in the
/// catalog. It's faded when it isn't. An installed mod gets a check mark.
class _NeedTag extends StatelessWidget {
  final CatalogNeed need;
  final CatalogMod? catalogMod;
  final bool Function(String name) isInstalledByName;

  /// A download row for this mod in the forum thread, when there is one.
  final DownloadGroup? downloadGroup;
  final void Function(CatalogMod mod) onOpenMod;
  final OnGroupDownload onDownload;

  const _NeedTag({
    required this.need,
    required this.catalogMod,
    required this.isInstalledByName,
    required this.downloadGroup,
    required this.onOpenMod,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final target = catalogMod;
    final name = target?.title ?? cleanModDisplayName(need.name);
    final installed = target?.installedMod != null || isInstalledByName(name);
    final group = downloadGroup;
    final via = need.via?.trim();

    Widget? trailing;
    if (installed) {
      trailing = Icon(Icons.check, size: 14, color: theme.statusColors.success);
    } else if (group != null) {
      trailing = MovingTooltipWidget.text(
        message: 'Install',
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: () => onDownload(
            primaryCandidate(group.candidates) ?? group.candidates.first,
            group.rawModName ?? group.modName!,
          ),
          child: Icon(
            Icons.download,
            size: 16,
            color: theme.colorScheme.primary,
          ),
        ),
      );
    }

    return DetailsTag(
      label: name,
      faded: target == null,
      onTap: target == null ? null : () => onOpenMod(target),
      tooltip: [
        installed ? 'Already installed' : 'Not installed',
        if (via != null && via.isNotEmpty) 'Required by $via.',
      ].join('\n'),
      trailing: trailing,
    );
  }
}

class _SaveQuestionRow extends StatelessWidget {
  final SaveQuestion question;

  const _SaveQuestionRow({required this.question});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = switch (question.answer) {
      CatalogSaveAnswer.yes => 'Yes',
      CatalogSaveAnswer.no => 'No',
      CatalogSaveAnswer.depends => 'Maybe',
      CatalogSaveAnswer.unknown => 'Unknown',
    };
    final color = switch (question.answer) {
      CatalogSaveAnswer.yes => theme.statusColors.success,
      CatalogSaveAnswer.no => theme.colorScheme.error,
      CatalogSaveAnswer.depends => theme.statusColors.warning,
      CatalogSaveAnswer.unknown => null,
    };
    final words = question.words?.trim();

    return Column(
      crossAxisAlignment: .stretch,
      spacing: 4,
      children: [
        SidePanelRow(
          label: question.label,
          strongLabel: true,
          value: DetailsTag(
            label: label,
            color: color,
            faded: question.answer == CatalogSaveAnswer.unknown,
          ),
        ),
        if (words != null && words.isNotEmpty)
          Text(
            '“$words”',
            style: theme.textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
              color: detailsMutedColor(theme),
            ),
          ),
      ],
    );
  }
}
