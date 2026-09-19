import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:trios/modpacks/full_page/modpack_item_row_data.dart';
import 'package:trios/modpacks/installation/modpack_installation.dart';
import 'package:trios/modpacks/models/modpack_definition.dart';
import 'package:trios/modpacks/models/modpack_library_entry.dart';
import 'package:trios/modpacks/modpack_format.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/relative_timestamp.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/snackbar.dart';

const _jsonEncoder = JsonEncoder.withIndent('  ');

/// Shows pack diagnostics, unknown fields, and the serialized pack data.
void showModpackDebugDialog(
  BuildContext context, {
  required ModpackLibraryEntry entry,
  required bool isPreview,
  required List<ModpackItemRowData> rows,
  ModpackInstallRun? run,
  Map<String, ModpackItemInstallResult> installResults = const {},
}) {
  final definition = entry.definition;
  final rowsById = {for (final row in rows) row.key: row};

  _FactAction? openMod(String modId) {
    final row = rowsById[modId];
    if (row == null) return null;
    return _FactAction(
      icon: Icons.open_in_new,
      tooltip: 'Show debug info for this mod',
      onPressed: () => showModpackItemDebugDialog(
        context,
        entry: entry,
        row: row,
        installResult: installResults[modId],
      ),
    );
  }

  final check = entry.updateCheck;
  final checkFailedLast =
      check?.error != null &&
      (check!.succeededAt == null ||
          (check.failedAt?.isAfter(check.succeededAt!) ?? false));
  final failures = entry.itemFailures.values.toList()
    ..sort((a, b) => a.modId.compareTo(b.modId));
  final itemsWithUnknownFields = [
    for (final item in definition.items)
      if (_unknownKeys(item).isNotEmpty) item,
  ];
  final unknownCount =
      definition.unknownFields.length +
      itemsWithUnknownFields.fold<int>(
        0,
        (sum, i) => sum + _unknownKeys(i).length,
      );

  showDialog(
    context: context,
    builder: (context) => _DebugDialog(
      title: definition.name,
      subtitle:
          'Modpack · v${definition.version} · format ${definition.formatVersion}'
          ' · ${isPreview ? 'preview, not in library' : 'in library'}',
      statuses: [
        if (run != null && !run.complete)
          const _Status(
            .info,
            Icons.downloading,
            'Installing',
            target: 'This computer',
          ),
        if (entry.onlineVersionAvailable != null)
          _Status(
            .info,
            Icons.upgrade,
            'v${entry.onlineVersionAvailable} available',
            target: 'Update check',
          ),
        if (checkFailedLast)
          const _Status(
            .error,
            Icons.cloud_off,
            'Update check failed',
            target: 'Update check',
          ),
        if (failures.isNotEmpty)
          _Status(
            .error,
            Icons.error_outline,
            _plural(failures.length, 'failed install'),
            target: 'Failed installs',
          ),
        if (unknownCount > 0)
          _Status(
            .warning,
            Icons.help_outline,
            _plural(unknownCount, 'unrecognized field'),
            target: definition.unknownFields.isNotEmpty
                ? 'Unrecognized pack fields'
                : 'Mods with unrecognized fields',
          ),
      ],
      jsonLabel: 'Pack file',
      json: encodeModpackDefinitionFileJson(definition),
      sections: [
        if (failures.isNotEmpty)
          _Section('Failed installs', [
            for (final failure in failures)
              _Fact(
                failure.modId,
                failure.message,
                tone: .error,
                tooltip:
                    'Failed ${failure.failedAt.relativeTimestamp()}\n'
                    'Source: ${failure.sourceFingerprint}',
                action: openMod(failure.modId),
              ),
          ]),
        _Section('Pack', [
          _Fact('ID', definition.id, copyable: true, monospace: true),
          _Fact('Mods', '${definition.items.length}'),
          _Fact('Update URL', definition.updateUrl, copyable: true),
        ]),
        _Section('This computer', [
          _Fact.time('Saved', entry.savedAt, ifMissing: 'Never'),
          _Fact(
            'Last export',
            entry.lastExportPath,
            ifMissing: 'Never',
            copyable: true,
          ),
          _Fact('Install run', _runSummary(run)),
        ]),
        if (definition.updateUrl != null)
          _Section('Update check', [
            if (check == null)
              const _Fact('Status', null, ifMissing: 'Never checked')
            else ...[
              _Fact.time('Last success', check.succeededAt, ifMissing: 'Never'),
              _Fact(
                'Online version',
                check.onlineDefinition?.version.toString(),
                ifMissing: 'Unknown',
              ),
              if (check.error != null) ...[
                _Fact.time('Last failure', check.failedAt),
                _Fact('Error', check.error, tone: .error),
              ],
            ],
          ]),
        if (definition.unknownFields.isNotEmpty)
          _Section('Unrecognized pack fields', [
            for (final field in definition.unknownFields.entries)
              _Fact(field.key, jsonEncode(field.value), monospace: true),
          ]),
        if (itemsWithUnknownFields.isNotEmpty)
          _Section('Mods with unrecognized fields', [
            for (final item in itemsWithUnknownFields)
              _Fact(
                item.modId,
                _unknownKeys(item).join(', '),
                monospace: true,
                action: openMod(item.modId),
              ),
          ]),
      ],
    ),
  );
}

/// Shows developer details about one mod in a pack.
void showModpackItemDebugDialog(
  BuildContext context, {
  required ModpackLibraryEntry entry,
  required ModpackItemRowData row,
  ModpackItemInstallResult? installResult,
}) {
  final item = row.item;
  final variant = row.installedVariant;
  final failure = entry.itemFailures[item.modId];
  final catalogUnknown = item.catalog?.unknownFields ?? const {};
  final unknownCount = _unknownKeys(item).length;
  final items = canonicalModpackMap(entry.definition)['items'] as List;

  showDialog(
    context: context,
    builder: (context) => _DebugDialog(
      title: row.displayName,
      subtitle:
          'Mod ${row.packOrder + 1} of ${entry.definition.items.length}'
          ' in ${entry.definition.name}',
      statuses: [
        if (variant != null)
          const _Status(
            .success,
            Icons.check_circle_outline,
            'Installed',
            target: 'This computer',
          )
        else
          const _Status(
            .neutral,
            Icons.remove_circle_outline,
            'Not installed',
            target: 'This computer',
          ),
        switch (item.sourceType) {
          .versionFile => const _Status(
            .info,
            Icons.sync,
            'Version Checker',
            target: 'Source',
          ),
          .directDownload => const _Status(
            .warning,
            Icons.push_pin_outlined,
            'Fixed download',
            target: 'Source',
          ),
        },
        if (failure != null || installResult?.status == .failed)
          _Status(
            .error,
            Icons.error_outline,
            'Install failed',
            target: failure != null ? 'Last failure' : 'This computer',
          ),
        if (unknownCount > 0)
          _Status(
            .warning,
            Icons.help_outline,
            _plural(unknownCount, 'unrecognized field'),
            target: 'Unrecognized fields',
          ),
      ],
      jsonLabel: 'Entry in pack file',
      json: _jsonEncoder.convert(items[row.packOrder]),
      sections: [
        if (failure != null)
          _Section('Last failure', [
            _Fact('Message', failure.message, tone: .error),
            _Fact.time('When', failure.failedAt),
            _Fact(
              'Source used',
              failure.sourceFingerprint,
              monospace: true,
              tooltip: 'Changing this mod\'s source clears the saved failure.',
            ),
          ]),
        _Section('Source', [
          _Fact('Mod ID', item.modId, copyable: true, monospace: true),
          _Fact('URL', item.url, copyable: true),
          _Fact('Pack version', row.recordedVersion),
          _Fact('Catalog clues', row.catalogRecoveryText, ifMissing: 'None'),
        ]),
        _Section('This computer', [
          _Fact(
            'Installed',
            variant?.smolId,
            ifMissing: 'Not installed',
            monospace: true,
          ),
          if (variant != null)
            _Fact(
              'Folder',
              variant.modFolder.path,
              copyable: true,
              action: _FactAction(
                icon: Icons.folder_open,
                tooltip: 'Open folder',
                onPressed: variant.modFolder.openInExplorer,
              ),
            ),
          _Fact(
            'Install run',
            installResult == null
                ? null
                : '${installResult.status.name} · ${installResult.text}',
            ifMissing: 'Not in a run',
            tone: installResult?.status == .failed ? .error : .normal,
          ),
        ]),
        if (unknownCount > 0)
          _Section('Unrecognized fields', [
            for (final field in item.unknownFields.entries)
              _Fact(field.key, jsonEncode(field.value), monospace: true),
            for (final field in catalogUnknown.entries)
              _Fact(
                'catalog.${field.key}',
                jsonEncode(field.value),
                monospace: true,
              ),
          ]),
      ],
    ),
  );
}

List<String> _unknownKeys(ModpackItem item) => [
  ...item.unknownFields.keys,
  ...?item.catalog?.unknownFields.keys.map((key) => 'catalog.$key'),
];

String _plural(int count, String noun) =>
    '$count $noun${count == 1 ? '' : 's'}';

String _runSummary(ModpackInstallRun? run) {
  if (run == null) return 'Not running';
  final counts = <ModpackItemInstallStatus, int>{};
  for (final result in run.results.values) {
    counts[result.status] = (counts[result.status] ?? 0) + 1;
  }
  final parts = [
    for (final status in ModpackItemInstallStatus.values)
      if (counts[status] != null) '${counts[status]} ${status.name}',
  ];
  return [run.complete ? 'Finished' : 'Running', ...parts].join(' · ');
}

enum _Tone { normal, neutral, info, success, warning, error }

Color _toneColor(ThemeData theme, _Tone tone) => switch (tone) {
  .normal => theme.colorScheme.onSurface,
  .neutral => theme.colorScheme.onSurfaceVariant,
  .info => theme.colorScheme.primary,
  .success => theme.triosExtensions.success,
  .warning => theme.triosExtensions.warning,
  .error => theme.colorScheme.error,
};

class _Status {
  final _Tone tone;
  final IconData icon;
  final String label;

  /// Title of the section that explains this status. Clicking the chip
  /// scrolls to it.
  final String? target;

  const _Status(this.tone, this.icon, this.label, {this.target});
}

class _DebugDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<_Status> statuses;
  final List<_Section> sections;
  final String jsonLabel;
  final String json;

  const _DebugDialog({
    required this.title,
    required this.subtitle,
    required this.statuses,
    required this.sections,
    required this.jsonLabel,
    required this.json,
  });

  @override
  State<_DebugDialog> createState() => _DebugDialogState();
}

class _DebugDialogState extends State<_DebugDialog> {
  final _sectionKeys = <String, GlobalKey>{};
  String? _highlighted;
  Timer? _highlightTimer;

  @override
  void dispose() {
    _highlightTimer?.cancel();
    super.dispose();
  }

  void _showSection(String title) {
    final sectionContext = _sectionKeys[title]?.currentContext;
    if (sectionContext == null) return;
    Scrollable.ensureVisible(
      sectionContext,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _highlighted = title);
    _highlightTimer?.cancel();
    _highlightTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _highlighted = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = widget.title;
    final subtitle = widget.subtitle;
    final statuses = widget.statuses;
    for (final section in widget.sections) {
      _sectionKeys.putIfAbsent(section.title, GlobalKey.new);
    }

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 760),
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .stretch,
          children: [
            Padding(
              padding: const .fromLTRB(24, 16, 8, 16),
              child: Row(
                crossAxisAlignment: .start,
                spacing: 16,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: .start,
                      spacing: 8,
                      children: [
                        Column(
                          crossAxisAlignment: .start,
                          children: [
                            Text(
                              'DEBUG INFO',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                letterSpacing: 1.2,
                              ),
                            ),
                            SelectableText(
                              title,
                              style: theme.textTheme.titleLarge,
                            ),
                            Text(
                              subtitle,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        if (statuses.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final status in statuses)
                                _StatusChip(
                                  status,
                                  onTap: _sectionKeys.containsKey(status.target)
                                      ? () => _showSection(status.target!)
                                      : null,
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  MovingTooltipWidget.text(
                    message: 'Close',
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const .fromLTRB(24, 16, 24, 24),
                child: Column(
                  crossAxisAlignment: .stretch,
                  spacing: 24,
                  children: [
                    for (final section in widget.sections)
                      _Section(
                        section.title,
                        section.facts,
                        key: _sectionKeys[section.title],
                        highlighted: _highlighted == section.title,
                      ),
                    _JsonPanel(label: widget.jsonLabel, json: widget.json),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final _Status status;
  final VoidCallback? onTap;

  const _StatusChip(this.status, {this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _toneColor(theme, status.tone);
    final borderRadius = BorderRadius.circular(16);

    final chip = Material(
      color: color.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: BorderSide(color: color.withValues(alpha: 0.4)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        hoverColor: color.withValues(alpha: 0.12),
        child: Padding(
          padding: .only(
            left: 8,
            right: onTap == null ? 8 : 4,
            top: 4,
            bottom: 4,
          ),
          child: Row(
            mainAxisSize: .min,
            spacing: 4,
            children: [
              Icon(status.icon, size: 14, color: color),
              Text(
                status.label,
                style: theme.textTheme.labelSmall?.copyWith(color: color),
              ),
              if (onTap != null)
                Icon(Icons.chevron_right, size: 14, color: color),
            ],
          ),
        ),
      ),
    );

    if (onTap == null) return chip;
    return MovingTooltipWidget.text(message: 'Show details', child: chip);
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<_Fact> facts;
  final bool highlighted;

  const _Section(this.title, this.facts, {super.key, this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: .stretch,
      spacing: 8,
      children: [
        Text(
          title.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const .symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: highlighted
                  ? theme.colorScheme.primary
                  : theme.colorScheme.primary.withValues(alpha: 0),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: .stretch,
            children: [
              for (var i = 0; i < facts.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.3,
                    ),
                  ),
                facts[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FactAction {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _FactAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });
}

/// One label and value. A missing value shows [ifMissing] in a muted style.
class _Fact extends StatelessWidget {
  final String label;
  final String? value;
  final String ifMissing;
  final bool copyable;
  final bool monospace;
  final _Tone tone;
  final String? tooltip;
  final _FactAction? action;

  const _Fact(
    this.label,
    this.value, {
    this.ifMissing = 'Not set',
    this.copyable = false,
    this.monospace = false,
    this.tone = .normal,
    this.tooltip,
    this.action,
  });

  /// Shows a time as "5 minutes ago", with the exact time on hover.
  _Fact.time(this.label, DateTime? time, {this.ifMissing = 'Not set'})
    : value = time?.relativeTimestamp(),
      tooltip = time?.toLocal().toString(),
      copyable = false,
      monospace = false,
      tone = .normal,
      action = null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.textTheme.bodySmall;
    final text = value;
    final isMissing = text == null || text.isEmpty;

    final valueStyle = isMissing
        ? base?.copyWith(color: theme.colorScheme.onSurfaceVariant)
        : (monospace
                  ? GoogleFonts.robotoMono(textStyle: base, fontSize: 12)
                  : base)
              ?.copyWith(color: _toneColor(theme, tone));

    Widget valueWidget = SelectableText(
      isMissing ? ifMissing : text,
      style: valueStyle,
    );
    if (tooltip != null) {
      valueWidget = MovingTooltipWidget.text(
        message: tooltip,
        child: valueWidget,
      );
    }

    return Padding(
      padding: const .symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: .start,
        spacing: 16,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: base?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              overflow: .ellipsis,
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: .start,
              spacing: 4,
              children: [
                Flexible(child: valueWidget),
                if (copyable && !isMissing)
                  _InlineIconButton(
                    icon: Icons.copy,
                    tooltip: 'Copy ${label.toLowerCase()}',
                    onPressed: () => _copy(context, text, label),
                  ),
                if (action != null)
                  _InlineIconButton(
                    icon: action!.icon,
                    tooltip: action!.tooltip,
                    onPressed: action!.onPressed,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JsonPanel extends StatefulWidget {
  final String label;
  final String json;

  const _JsonPanel({required this.label, required this.json});

  @override
  State<_JsonPanel> createState() => _JsonPanelState();
}

class _JsonPanelState extends State<_JsonPanel> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const .only(left: 8, right: 8),
              child: SizedBox(
                height: 40,
                child: Row(
                  spacing: 8,
                  children: [
                    AnimatedRotation(
                      turns: _expanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 150),
                      child: Icon(Icons.chevron_right, size: 20, color: muted),
                    ),
                    Icon(Icons.data_object, size: 16, color: muted),
                    Expanded(
                      child: Text(
                        widget.label,
                        style: theme.textTheme.labelLarge,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          _copy(context, widget.json, widget.label),
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy'),
                      style: TextButton.styleFrom(
                        foregroundColor: muted,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_expanded)
            Container(
              padding: const .all(16),
              color: Colors.black.withValues(alpha: 0.2),
              child: SelectableText(
                widget.json,
                style: GoogleFonts.robotoMono(fontSize: 12, height: 1.5),
              ),
            ),
        ],
      ),
    );
  }
}

class _InlineIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _InlineIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => MovingTooltipWidget.text(
    message: tooltip,
    child: InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const .all(2),
        child: Icon(
          icon,
          size: 14,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ),
  );
}

void _copy(BuildContext context, String text, String label) {
  Clipboard.setData(ClipboardData(text: text));
  showSnackBar(context: context, content: Text('$label copied.'));
}
