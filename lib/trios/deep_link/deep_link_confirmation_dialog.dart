import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/trios/deep_link/deep_link_parser.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';

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

  String get displayName =>
      modName ?? entry.url.host;

  String get displayDetail {
    if (error != null) return 'Error: $error';
    if (alreadyInstalled) return 'Already installed';
    final parts = <String>[];
    if (modVersion != null) parts.add('v$modVersion');
    parts.add(entry.url.host);
    return parts.join(' · ');
  }
}

/// Shows the deep link confirmation dialog.
///
/// Returns `true` if user confirmed, `false` if cancelled.
Future<bool> showDeepLinkConfirmationDialog(
  BuildContext context, {
  required ResolvedModEntry mainMod,
  required List<ResolvedModEntry> dependencies,
  required WidgetRef ref,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _DeepLinkConfirmationDialog(
      mainMod: mainMod,
      dependencies: dependencies,
      ref: ref,
    ),
  );
  return result ?? false;
}

class _DeepLinkConfirmationDialog extends StatefulWidget {
  final ResolvedModEntry mainMod;
  final List<ResolvedModEntry> dependencies;
  final WidgetRef ref;

  const _DeepLinkConfirmationDialog({
    required this.mainMod,
    required this.dependencies,
    required this.ref,
  });

  @override
  State<_DeepLinkConfirmationDialog> createState() =>
      _DeepLinkConfirmationDialogState();
}

class _DeepLinkConfirmationDialogState
    extends State<_DeepLinkConfirmationDialog> {
  bool _dontAskAgain = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final depsToInstall =
        widget.dependencies.where((d) => !d.alreadyInstalled).toList();
    final depsAlreadyInstalled =
        widget.dependencies.where((d) => d.alreadyInstalled).toList();

    return AlertDialog(
      title: const Text('Install Mod from Link'),
      content: SizedBox(
        width: 450,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('A link is requesting to install a mod:', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            // Main mod
            _buildModTile(
              context,
              entry: widget.mainMod,
              isMain: true,
            ),
            // Dependencies to install
            if (depsToInstall.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Dependencies (${depsToInstall.length})',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              ...depsToInstall.map(
                (dep) => _buildModTile(context, entry: dep, isMain: false),
              ),
            ],
            // Already installed deps
            if (depsAlreadyInstalled.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Already installed (${depsAlreadyInstalled.length})',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 8),
              ...depsAlreadyInstalled.map(
                (dep) => _buildModTile(context, entry: dep, isMain: false),
              ),
            ],
            const SizedBox(height: 16),
            // Don't ask again checkbox
            Row(
              children: [
                Checkbox(
                  value: _dontAskAgain,
                  onChanged: (value) =>
                      setState(() => _dontAskAgain = value ?? false),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    "Don't ask again for deep links",
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () {
            if (_dontAskAgain) {
              widget.ref.read(appSettings.notifier).update(
                (s) => s.copyWith(deepLinkSkipConfirmation: true),
              );
            }
            Navigator.of(context).pop(true);
          },
          icon: const Icon(Icons.download),
          label: const Text('Download & Install'),
        ),
      ],
    );
  }

  Widget _buildModTile(
    BuildContext context, {
    required ResolvedModEntry entry,
    required bool isMain,
  }) {
    final theme = Theme.of(context);
    final hasError = entry.error != null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            entry.alreadyInstalled
                ? Icons.check_circle
                : hasError
                    ? Icons.error
                    : isMain
                        ? Icons.extension
                        : Icons.subdirectory_arrow_right,
            size: 20,
            color: entry.alreadyInstalled
                ? theme.colorScheme.primary
                : hasError
                    ? theme.colorScheme.error
                    : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.displayName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isMain ? FontWeight.bold : FontWeight.normal,
                    decoration:
                        entry.alreadyInstalled ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(
                  entry.displayDetail,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: hasError
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
