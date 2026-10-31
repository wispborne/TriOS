import 'package:material_ui/material_ui.dart';
import 'package:trios/catalog/catalog_download_resolver.dart';
import 'package:trios/catalog/details_dialog/details_panel_section.dart';
import 'package:trios/catalog/download_candidate_actions.dart';
import 'package:trios/catalog/models/forum_llm_data.dart';
import 'package:trios/trios/download_manager/download_target.dart';
import 'package:trios/widgets/mod_download/mod_download_button.dart';
import 'package:trios/widgets/moving_tooltip.dart';

/// Runs [candidate], a download for the mod named [modName].
typedef OnGroupDownload = void Function(
  DownloadCandidate candidate,
  String modName,
);

/// The download rows for the other mods in the forum thread: every row except
/// the one for the mod the dialog is about, and except the unnamed row built
/// from the post's own links.
List<DownloadGroup> threadModRows(List<DownloadGroup> groups) => [
  for (final group in groups)
    if (!group.isDialogMod && group.modName != null) group,
];

/// The Add-ons tab: the other mods in the same forum thread, each with its
/// own download button. Rows that look like another version of the dialog's
/// mod are listed apart.
class AddonsTab extends StatelessWidget {
  /// From [threadModRows].
  final List<DownloadGroup> rows;

  /// The name of the mod the dialog is about.
  final String dialogModName;
  final OnGroupDownload onDownload;

  const AddonsTab({
    super.key,
    required this.rows,
    required this.dialogModName,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    bool isOtherVersion(DownloadGroup group) =>
        modNamesMatch(group.rawModName ?? group.modName!, dialogModName);
    final otherVersions = rows.where(isOtherVersion).toList();
    final addons = rows.where((row) => !isOtherVersion(row)).toList();

    Widget rowList(List<DownloadGroup> groups) => Column(
      crossAxisAlignment: .stretch,
      spacing: 8,
      children: [
        for (final group in groups)
          DownloadGroupRow(group: group, onDownload: onDownload),
      ],
    );

    return Column(
      crossAxisAlignment: .stretch,
      spacing: 16,
      children: [
        if (addons.isNotEmpty)
          ContentSection(
            icon: Icons.extension,
            title: 'Add-ons in the same thread',
            child: rowList(addons),
          ),
        if (otherVersions.isNotEmpty)
          ContentSection(
            icon: Icons.layers,
            title: 'Other versions of this mod',
            child: rowList(otherVersions),
          ),
      ],
    );
  }
}

/// One mod's download row: its download button, its name and its role tag.
class DownloadGroupRow extends StatelessWidget {
  final DownloadGroup group;
  final OnGroupDownload onDownload;

  const DownloadGroupRow({
    super.key,
    required this.group,
    required this.onDownload,
  });

  /// The pill beside a row's name. "required" wins over the role: someone
  /// reading an add-on's dialog needs to know the base mod is not optional.
  static String? _roleLabel(DownloadGroup group) {
    if (group.requiredByDialogMod) return 'required';
    return switch (group.role) {
      LlmModRole.addon => 'add-on',
      LlmModRole.separate => 'separate mod',
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = group.modName ?? '';
    final roleLabel = _roleLabel(group);
    return Row(
      spacing: 8,
      children: [
        // The download and the mod record use the source's own wording; only
        // the text on the row is cleaned up.
        DownloadSplitButton(
          candidates: group.candidates,
          modName: group.rawModName ?? name,
          onDownload: onDownload,
        ),
        Flexible(
          child: Text(
            name,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (roleLabel != null) _RoleTag(label: roleLabel),
      ],
    );
  }
}

/// Small pill next to an add-on / separate mod's name.
class _RoleTag extends StatelessWidget {
  final String label;

  const _RoleTag({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const .symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

/// A mod's download button: one click runs the best candidate; the ▾ menu
/// lists every candidate (with its host) when there's more than one.
class DownloadSplitButton extends StatelessWidget {
  final List<DownloadCandidate> candidates;
  final String modName;
  final OnGroupDownload onDownload;

  const DownloadSplitButton({
    super.key,
    required this.candidates,
    required this.modName,
    required this.onDownload,
  });

  static String _tooltip(DownloadCandidate candidate) {
    final subtitle = downloadCandidateSubtitle(candidate);
    return [
      candidate.label,
      candidate.url,
      if (subtitle.isNotEmpty) subtitle,
    ].join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = primaryCandidate(candidates);
    final mainCandidate = primary ?? candidates.first;
    // No one-click candidate: the best we can do is open the download page.
    final label = primary != null ? 'Install' : 'Open download page';

    // This row's downloads are named after its mod, whichever candidate the
    // user ends up picking.
    final target = DownloadTarget(
      url: mainCandidate.url,
      catalogName: modName,
      displayName: modName,
    );

    final button = ModDownloadButton(
      target: target,
      variant: ModDownloadButtonVariant.elevated,
      icon: downloadCandidateIconWidget(mainCandidate),
      label: Text(label, style: theme.textTheme.labelMedium),
      style: ElevatedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      spinnerSize: 20,
      // Opening a download page isn't a download, so it never spins.
      markPendingOnPress: primary != null,
      tooltip: _tooltip(mainCandidate),
      onPressed: () => onDownload(mainCandidate, modName),
    );

    if (candidates.length < 2) return button;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        button,
        OtherDownloadOptionsButton(
          candidates: candidates,
          target: target,
          onSelected: (candidate) => onDownload(candidate, modName),
        ),
      ],
    );
  }
}

/// The ▾ button that lists every download for a mod.
class OtherDownloadOptionsButton extends StatelessWidget {
  final List<DownloadCandidate> candidates;

  /// The download button this menu belongs to, so it shows the progress.
  final DownloadTarget target;
  final void Function(DownloadCandidate candidate) onSelected;

  /// Draws a square outlined button that matches a tall button beside it,
  /// instead of a bare icon.
  final bool outlined;

  const OtherDownloadOptionsButton({
    super.key,
    required this.candidates,
    required this.target,
    required this.onSelected,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      menuChildren: [
        for (final candidate in candidates)
          DownloadCandidateMenuItem(
            candidate: candidate,
            target: target,
            onSelected: () => onSelected(candidate),
          ),
      ],
      builder: (context, controller, _) {
        void toggle() =>
            controller.isOpen ? controller.close() : controller.open();
        return MovingTooltipWidget.text(
          message: 'Other download options',
          child: outlined
              ? SizedBox(
                  width: 40,
                  height: 40,
                  child: OutlinedButton(
                    onPressed: toggle,
                    // Grey, the same as the toolbar items on other pages.
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: const Icon(Icons.arrow_drop_down),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.arrow_drop_down),
                  visualDensity: VisualDensity.compact,
                  onPressed: toggle,
                ),
        );
      },
    );
  }
}
