import 'package:flutter/material.dart';
import 'package:trios/catalog/catalog_download_resolver.dart';
import 'package:trios/catalog/download_candidate_actions.dart';
import 'package:trios/catalog/models/forum_llm_data.dart';
import 'package:trios/catalog/widgets/mod_summary/mod_summary_data.dart';
import 'package:trios/catalog/widgets/mod_summary/mod_summary_widget.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/text_trios.dart';

/// Header for the details dialog. When [showSummary] is true it shows the full
/// [ModSummaryWidget] (image, author, dates, stats, summary, changelog, etc.);
/// when false it shows just the title. Either way it keeps the grouped per-mod
/// download rows and the open-in-browser / window actions.
class ForumPostHeader extends StatelessWidget {
  final ModSummaryData data;

  /// Whether to show the full mod summary. When false, only the title shows —
  /// the informational block is hidden per the user's setting.
  final bool showSummary;

  /// Flips the summary on/off. When null, the toggle button is hidden.
  final VoidCallback? onToggleSummary;

  /// Opens the topic in the operating system's default browser. Hidden when
  /// null.
  final VoidCallback? onOpenInSystemBrowser;

  /// Opens the topic in the app's built-in browser panel. Hidden when null
  /// (e.g. the built-in browser isn't available on this platform).
  final VoidCallback? onOpenInEmbeddedBrowser;
  final VoidCallback? onToggleFullScreen;
  final bool isFullScreen;
  final VoidCallback? onClose;

  /// The per-mod download rows, already built and ordered. Source-agnostic:
  /// the dialog fills this from LLM data when available, else from the post's
  /// scraped links or the scraped mod.
  final List<DownloadGroup> downloadGroups;

  /// Runs a download [candidate] for the mod named [modName].
  final void Function(DownloadCandidate candidate, String modName)? onDownload;

  const ForumPostHeader({
    super.key,
    required this.data,
    this.showSummary = true,
    this.onToggleSummary,
    this.onOpenInSystemBrowser,
    this.onOpenInEmbeddedBrowser,
    this.onToggleFullScreen,
    this.isFullScreen = false,
    this.onClose,
    this.downloadGroups = const [],
    this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer.withValues(alpha: 0.6),
        border: Border(bottom: BorderSide(color: theme.dividerColor, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Row(
            crossAxisAlignment: .start,
            spacing: 8,
            children: [
              Expanded(
                child: Builder(
                  builder: (context) {
                    final headerButtons = Row(
                      crossAxisAlignment: .start,
                      children: [
                        if (onToggleSummary != null)
                          MovingTooltipWidget.text(
                            message: showSummary
                                ? 'Hide the mod summary'
                                : 'Show the mod summary',
                            child: IconButton(
                              icon: Icon(
                                showSummary
                                    ? Icons.unfold_less
                                    : Icons.unfold_more,
                              ),
                              onPressed: onToggleSummary,
                            ),
                          ),
                        if (onOpenInEmbeddedBrowser != null)
                          Tooltip(
                            message: 'Open in the built-in browser',
                            child: IconButton(
                              icon: const Icon(Icons.web),
                              onPressed: onOpenInEmbeddedBrowser,
                            ),
                          ),
                        if (onOpenInSystemBrowser != null)
                          Tooltip(
                            message: 'Open in your web browser',
                            child: IconButton(
                              icon: const Icon(Icons.open_in_new),
                              onPressed: onOpenInSystemBrowser,
                            ),
                          ),
                        if (onToggleFullScreen != null)
                          Tooltip(
                            message: isFullScreen
                                ? 'Exit full screen'
                                : 'Full screen',
                            child: IconButton(
                              icon: Icon(
                                isFullScreen
                                    ? Icons.fullscreen_exit
                                    : Icons.fullscreen,
                              ),
                              onPressed: onToggleFullScreen,
                            ),
                          ),
                        if (onClose != null)
                          Tooltip(
                            message: 'Close',
                            child: IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: onClose,
                            ),
                          ),
                      ],
                    );

                    return Padding(
                      padding: const EdgeInsets.only(top: 8, right: 8),
                      child: showSummary
                          ? ModSummaryWidget(
                              data: data,
                              config: ModSummaryConfig.dialogHeader,
                              headerButtons: headerButtons,
                            )
                          : Row(
                              mainAxisAlignment: .spaceBetween,
                              children: [
                                TextTriOS(
                                  data.title.isNotEmpty ? data.title : '???',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                headerButtons,
                              ],
                            ),
                    );
                  },
                ),
              ),
            ],
          ),
          if (downloadGroups.isNotEmpty && onDownload != null)
            Padding(
              padding: const .only(top: 8),
              child: _DownloadSection(
                groups: downloadGroups,
                fallbackModName: data.title,
                onDownload: onDownload!,
              ),
            ),
        ],
      ),
    );
  }
}

/// The Downloads section: one row per mod in the topic. The topic's main mod
/// (and the unnamed scraped fallback) render first; add-ons and separate mods
/// follow under an "Also in this thread" heading.
class _DownloadSection extends StatelessWidget {
  final List<DownloadGroup> groups;
  final String fallbackModName;
  final void Function(DownloadCandidate candidate, String modName) onDownload;

  const _DownloadSection({
    required this.groups,
    required this.fallbackModName,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headingStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurface.withAlpha(200),
      fontStyle: .italic,
    );

    final mainGroups = groups
        .where((g) => g.modName == null || g.role == LlmModRole.main)
        .toList();
    final otherGroups = groups
        .where((g) => g.modName != null && g.role != LlmModRole.main)
        .toList();

    return Column(
      crossAxisAlignment: .start,
      spacing: 6,
      children: [
        Text('Downloads', style: headingStyle),
        for (final group in mainGroups)
          _DownloadRow(
            group: group,
            fallbackModName: fallbackModName,
            onDownload: onDownload,
          ),
        if (otherGroups.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text('Also in this thread', style: headingStyle),
          for (final group in otherGroups)
            _DownloadRow(
              group: group,
              fallbackModName: fallbackModName,
              onDownload: onDownload,
            ),
        ],
      ],
    );
  }
}

class _DownloadRow extends StatelessWidget {
  final DownloadGroup group;
  final String fallbackModName;
  final void Function(DownloadCandidate candidate, String modName) onDownload;

  const _DownloadRow({
    required this.group,
    required this.fallbackModName,
    required this.onDownload,
  });

  static String? _roleLabel(LlmModRole role) => switch (role) {
    LlmModRole.addon => 'add-on',
    LlmModRole.separate => 'separate mod',
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final button = _DownloadSplitButton(
      candidates: group.candidates,
      modName: group.modName ?? fallbackModName,
      onDownload: onDownload,
    );

    // The unnamed scraped fallback has no name to show — just the button.
    if (group.modName == null) {
      return Align(alignment: Alignment.centerLeft, child: button);
    }

    final roleLabel = _roleLabel(group.role);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 6,
              children: [
                Flexible(
                  child: Text(
                    group.modName!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (roleLabel != null) _RoleTag(label: roleLabel),
              ],
            ),
            _DependencyLine(group: group),
          ],
        ),
        const SizedBox(width: 8),
        button,
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
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

/// The line under the main mod's row: "Install incl. dependencies" when a
/// TriOS deep link handles them, otherwise "Also needs: A ✓, B".
class _DependencyLine extends StatelessWidget {
  final DownloadGroup group;

  const _DependencyLine({required this.group});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelSmall?.copyWith(
      color: theme.textTheme.labelSmall?.color?.withValues(alpha: 0.7),
    );

    if (group.installsDependencies) {
      return Text('Install incl. dependencies', style: style);
    }
    if (group.dependencies.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('Also needs:', style: style),
        for (final dep in group.dependencies)
          MovingTooltipWidget.text(
            message: dep.installed ? 'Already installed' : 'Not installed',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 2,
              children: [
                Text(dep.name, style: style),
                if (dep.installed)
                  Icon(
                    Icons.check,
                    size: 12,
                    color: theme.statusColors.success,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A mod's download button: one click runs the best candidate; the ▾ menu
/// lists every candidate (with its host) when there's more than one.
class _DownloadSplitButton extends StatelessWidget {
  final List<DownloadCandidate> candidates;
  final String modName;
  final void Function(DownloadCandidate candidate, String modName) onDownload;

  const _DownloadSplitButton({
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
    final hasMenu = candidates.length > 1;

    final button = ElevatedButton.icon(
      icon: Icon(downloadCandidateIcon(mainCandidate), size: 16),
      label: Text(label, style: theme.textTheme.labelMedium),
      style: ElevatedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: () => onDownload(mainCandidate, modName),
    );

    if (!hasMenu) {
      return MovingTooltipWidget.text(
        message: _tooltip(mainCandidate),
        child: button,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MovingTooltipWidget.text(
          message: _tooltip(mainCandidate),
          child: button,
        ),
        MenuAnchor(
          menuChildren: [
            for (final candidate in candidates) _menuItem(context, candidate),
          ],
          builder: (context, controller, _) => MovingTooltipWidget.text(
            message: 'Other download options',
            child: IconButton(
              icon: const Icon(Icons.arrow_drop_down),
              visualDensity: VisualDensity.compact,
              onPressed: () =>
                  controller.isOpen ? controller.close() : controller.open(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _menuItem(BuildContext context, DownloadCandidate candidate) {
    final theme = Theme.of(context);
    final subtitle = downloadCandidateSubtitle(candidate);
    return MenuItemButton(
      leadingIcon: Icon(downloadCandidateIcon(candidate), size: 16),
      onPressed: () => onDownload(candidate, modName),
      child: MovingTooltipWidget.text(
        message: candidate.url,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(candidate.label),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
