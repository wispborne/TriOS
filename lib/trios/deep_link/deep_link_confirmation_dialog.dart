import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/deep_link/deep_link_parser.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/widgets/checkbox_with_label.dart';
import 'package:trios/widgets/disable.dart';

/// Information about a resolved mod entry for display in the dialog.
class ResolvedModEntry {
  final DeepLinkModEntry entry;

  /// Mod name from .version file, or null if direct download / fetch failed.
  final String? modName;

  /// Mod version string from .version file.
  final String? modVersion;

  /// The actual download URL (may differ from entry.url for .version files).
  final Uri downloadUrl;

  /// Whether this mod is already installed (and version is >= remote).
  final bool alreadyInstalled;

  /// Error message if .version file fetch failed.
  final String? error;

  const ResolvedModEntry({
    required this.entry,
    this.modName,
    this.modVersion,
    required this.downloadUrl,
    this.alreadyInstalled = false,
    this.error,
  });

  String get displayName => modName ?? _nameFromUrl(entry.url);

  String get displayDetail {
    // Already-installed wins over a download error: if we already have it, the
    // missing/invalid download link doesn't matter.
    if (alreadyInstalled) return 'Already installed';
    if (error != null) return error!;
    // Version is shown on its own labeled line; here just show the actual
    // download host (where bytes come from), which for a .version link differs
    // from the .version file's own host.
    return downloadUrl.host;
  }

  /// Falls back to the URL's filename (sans extension) when the mod name isn't
  /// known — e.g. "RandomAssortmentOfThings" from ".../RandomAssortmentOfThings.version",
  /// which is far more recognizable than the bare host.
  static String _nameFromUrl(Uri url) {
    // posix semantics: URL paths are '/'-separated regardless of host OS.
    final name = p.posix.basenameWithoutExtension(url.path);
    return name.isEmpty ? url.host : name;
  }
}

/// Live contents of the confirmation dialog. The dialog rebuilds when this
/// changes, so links clicked while it's open merge into the same dialog.
class DeepLinkConfirmData {
  final List<ResolvedModEntry> mods;
  final List<ResolvedModEntry> dependencies;

  const DeepLinkConfirmData({required this.mods, required this.dependencies});
}

/// Shows the deep link confirmation dialog, driven by [data] so it updates live
/// as more links are added to the same install.
///
/// Returns the entries the user chose to install, or `null` if cancelled.
Future<List<ResolvedModEntry>?> showDeepLinkConfirmationDialog(
  BuildContext context, {
  required ValueListenable<DeepLinkConfirmData> data,
  required Ref ref,
}) {
  return showDialog<List<ResolvedModEntry>>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _DeepLinkConfirmationDialog(data: data, ref: ref),
  );
}

class _DeepLinkConfirmationDialog extends StatefulWidget {
  final ValueListenable<DeepLinkConfirmData> data;
  final Ref ref;

  const _DeepLinkConfirmationDialog({required this.data, required this.ref});

  @override
  State<_DeepLinkConfirmationDialog> createState() =>
      _DeepLinkConfirmationDialogState();
}

class _DeepLinkConfirmationDialogState
    extends State<_DeepLinkConfirmationDialog> {
  bool _dontAskAgain = false;

  /// Selected entries, by stable key (the source URL).
  final Set<String> _selected = {};

  /// Entries the default-selection rule has already been applied to, so links
  /// merged in later get pre-selected once without overriding the user's picks.
  final Set<String> _defaultsApplied = {};

  @override
  void initState() {
    super.initState();
    _applyDefaultSelection();
    widget.data.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    widget.data.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() => setState(_applyDefaultSelection);

  /// Pre-select installable entries that aren't already present (same mod id +
  /// version). Errored and already-installed entries start unchecked.
  void _applyDefaultSelection() {
    final data = widget.data.value;
    for (final e in [...data.mods, ...data.dependencies]) {
      final key = _keyOf(e);
      if (_defaultsApplied.add(key) && e.error == null && !e.alreadyInstalled) {
        _selected.add(key);
      }
    }
  }

  String _keyOf(ResolvedModEntry e) => e.entry.url.toString();

  void _toggle(String key, bool selected) {
    setState(() {
      if (selected) {
        _selected.add(key);
      } else {
        _selected.remove(key);
      }
    });
  }

  @override
  Widget build(BuildContext context) =>
      _buildDialog(context, widget.data.value);

  Widget _buildDialog(BuildContext context, DeepLinkConfirmData data) {
    final theme = Theme.of(context);
    // Group by role: main mods first, then dependencies. Within each role,
    // sort by status: to-install, then couldn't-load, then already-installed.
    // Dependencies that are also main mods were already dropped upstream
    // (deduped by URL in the handler).
    List<ResolvedModEntry> byStatus(List<ResolvedModEntry> list) => [
      ...list.where((e) => !e.alreadyInstalled && e.error == null),
      ...list.where((e) => !e.alreadyInstalled && e.error != null),
      ...list.where((e) => e.alreadyInstalled),
    ];
    final mainMods = byStatus(data.mods);
    final deps = byStatus(data.dependencies);

    final allEntries = [...data.mods, ...data.dependencies];
    final installCount = allEntries
        .where((e) => !e.alreadyInstalled && e.error == null)
        .length;
    final selectedCount = _selected.length;

    return AlertDialog(
      title: Text(
        installCount > 1 ? 'Install Mods from Link' : 'Install Mod from Link',
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 400, maxWidth: 620),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main mods first.
                    ...mainMods.map(
                      (mod) => _buildModTile(context, entry: mod, isMain: true),
                    ),
                    // Then dependencies (already excludes any that are main mods).
                    if (deps.isNotEmpty) ...[
                      _sectionHeader(
                        'Dependencies (${deps.length})',
                        theme.textTheme.titleSmall,
                      ),
                      ...deps.map(
                        (dep) =>
                            _buildModTile(context, entry: dep, isMain: false),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Divider(),
            CheckboxWithLabel(
              value: _dontAskAgain,
              onChanged: (value) =>
                  setState(() => _dontAskAgain = value ?? false),
              label: "Always install new mods without confirming",
              labelStyle: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: selectedCount == 0
              ? null
              : () {
                  if (_dontAskAgain) {
                    widget.ref
                        .read(appSettings.notifier)
                        .update(
                          (s) => s.copyWith(deepLinkSkipConfirmation: true),
                        );
                  }
                  final selectedEntries = allEntries
                      .where((e) => _selected.contains(_keyOf(e)))
                      .toList();
                  Navigator.of(context).pop(selectedEntries);
                },
          icon: const Icon(Icons.download),
          label: Text(
            selectedCount == 0
                ? 'No mods selected'
                : 'Download & Install ($selectedCount)',
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String text, TextStyle? style) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4, left: 4),
      child: Text(text, style: style),
    );
  }

  Widget _buildModTile(
    BuildContext context, {
    required ResolvedModEntry entry,
    required bool isMain,
  }) {
    final theme = Theme.of(context);
    // Errored entries can't be installed, so they aren't selectable.
    final selectable = entry.error == null;
    final key = _keyOf(entry);
    final isSelected = selectable && _selected.contains(key);

    return Card.outlined(
      margin: const EdgeInsets.only(bottom: 6),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isSelected
              ? theme.colorScheme.primary.withAlpha(200)
              : theme.colorScheme.outline.withValues(alpha: 0.25),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: selectable
          ? Disable(
              isEnabled: selectable,
              child: CheckboxListTile(
                value: isSelected,
                onChanged: (value) => _toggle(key, value ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: const EdgeInsets.only(left: 4, right: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                // The provenance lines are SelectableText, which would otherwise
                // swallow taps (the tile flashes but doesn't toggle). Route a tap
                // on them to the same toggle; drag-to-select still works.
                title: _modContent(
                  context,
                  entry,
                  isMain: isMain,
                  onTap: () => _toggle(key, !isSelected),
                ),
              ),
            )
          : ListTile(
              contentPadding: const EdgeInsets.fromLTRB(16, 6, 12, 6),
              // This branch is only reached for errored entries (selectable ==
              // entry.error == null), so the icon always signals a problem —
              // even for an already-installed mod whose link can't be used.
              leading: Icon(
                Icons.error_outline,
                color: theme.colorScheme.error,
              ),
              title: _modContent(context, entry, isMain: isMain),
            ),
    );
  }

  /// Shared tile body: name, status/detail, and provenance URL lines.
  Widget _modContent(
    BuildContext context,
    ResolvedModEntry entry, {
    required bool isMain,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    // Already-installed takes precedence, so don't style it as an error.
    final hasError = entry.error != null && !entry.alreadyInstalled;

    final isVersionFile = entry.entry.source == DeepLinkModSource.versionFile;
    final sourceUrl = entry.entry.url.toString();
    final resolvedUrl = entry.downloadUrl.toString();
    final showResolved = isVersionFile && resolvedUrl != sourceUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 2,
      children: [
        Text(
          entry.displayName,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isMain ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          entry.displayDetail,
          style: theme.textTheme.bodySmall?.copyWith(
            color: hasError
                ? theme.colorScheme.error
                : theme.colorScheme.onSurface.withValues(alpha: 0.6),
            fontStyle: FontStyle.italic,
          ),
        ),
        // If a mod is already installed but its link couldn't be downloaded,
        // displayDetail shows "Already installed" — surface the reason here so
        // the user understands why it has no checkbox (rather than nothing).
        if (entry.alreadyInstalled && entry.error != null)
          Text(
            entry.error!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        if (entry.entry.modId != null)
          _urlLine(theme, Icons.tag, '${entry.entry.modId}', onTap: onTap),
        // A dependency's link version is a minimum requirement — label it as such.
        // The main mod (and version-less deps) show a bare resolved version.
        if (!isMain && entry.entry.modVersion != null)
          _urlLine(
            theme,
            Icons.numbers,
            'Requires ≥ ${entry.entry.modVersion}',
            onTap: onTap,
          )
        else if (entry.modVersion != null)
          _urlLine(theme, Icons.numbers, '${entry.modVersion}', onTap: onTap),
        _urlLine(
          theme,
          isVersionFile ? Icons.description_outlined : Icons.download,
          sourceUrl,
          onTap: onTap,
        ),
        if (showResolved)
          _urlLine(theme, Icons.download, resolvedUrl, onTap: onTap),
      ],
    );
  }

  /// A small, selectable provenance line (icon + URL) so the user can read or
  /// copy exactly which link / version-checker file was used, for debugging.
  Widget _urlLine(
    ThemeData theme,
    IconData icon,
    String url, {
    VoidCallback? onTap,
  }) {
    final color = theme.colorScheme.onSurface.withValues(alpha: 0.5);
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2, right: 6),
            child: Icon(icon, size: 13, color: color),
          ),
          Expanded(
            child: SelectableText(
              url,
              onTap: onTap,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
