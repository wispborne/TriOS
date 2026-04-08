import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:trios/mod_records/mod_record.dart';
import 'package:trios/mod_records/mod_record_source.dart';
import 'package:trios/mod_records/mod_records_store.dart';
import 'package:trios/widgets/inline_edit_text.dart';
import 'package:trios/widgets/simple_data_row.dart';
import 'package:trios/widgets/trios_expansion_tile.dart';

/// Shows the mod sources dialog for the given mod.
void showModRecordSourcesDialog(
  BuildContext context,
  String recordKey,
  String displayName,
) {
  showDialog(
    context: context,
    builder: (context) =>
        ModRecordSourcesDialog(recordKey: recordKey, displayName: displayName),
  );
}

class ModRecordSourcesDialog extends ConsumerStatefulWidget {
  final String recordKey;
  final String displayName;

  const ModRecordSourcesDialog({
    super.key,
    required this.recordKey,
    required this.displayName,
  });

  @override
  ConsumerState<ModRecordSourcesDialog> createState() =>
      _ModRecordSourcesDialogState();
}

class _ModRecordSourcesDialogState
    extends ConsumerState<ModRecordSourcesDialog> {
  bool _isDirty = false;
  bool _controllersInitialized = false;

  // Version Checker editable controllers
  final _vcForumThreadId = TextEditingController();
  final _vcNexusModsId = TextEditingController();
  final _vcDirectDownloadUrl = TextEditingController();
  final _vcChangelogUrl = TextEditingController();
  final _vcMasterVersionFileUrl = TextEditingController();

  // Catalog editable controllers
  final _catForumUrl = TextEditingController();
  final _catNexusUrl = TextEditingController();
  final _catDiscordUrl = TextEditingController();
  final _catDirectDownloadUrl = TextEditingController();
  final _catDownloadPageUrl = TextEditingController();
  final _catForumThreadId = TextEditingController();
  final _catNexusModsId = TextEditingController();

  void _initControllersIfNeeded(ModRecord record) {
    if (_controllersInitialized) return;
    _controllersInitialized = true;
    _initControllers(record);
  }

  void _initControllers(ModRecord record) {
    final vc = record.versionChecker;
    _vcForumThreadId.text = vc?.forumThreadId ?? '';
    _vcNexusModsId.text = vc?.nexusModsId ?? '';
    _vcDirectDownloadUrl.text = vc?.directDownloadUrl ?? '';
    _vcChangelogUrl.text = vc?.changelogUrl ?? '';
    _vcMasterVersionFileUrl.text = vc?.masterVersionFileUrl ?? '';

    final cat = record.catalog;
    _catForumUrl.text = cat?.forumUrl ?? '';
    _catNexusUrl.text = cat?.nexusUrl ?? '';
    _catDiscordUrl.text = cat?.discordUrl ?? '';
    _catDirectDownloadUrl.text = cat?.directDownloadUrl ?? '';
    _catDownloadPageUrl.text = cat?.downloadPageUrl ?? '';
    _catForumThreadId.text = cat?.forumThreadId ?? '';
    _catNexusModsId.text = cat?.nexusModsId ?? '';
  }

  @override
  void dispose() {
    _vcForumThreadId.dispose();
    _vcNexusModsId.dispose();
    _vcDirectDownloadUrl.dispose();
    _vcChangelogUrl.dispose();
    _vcMasterVersionFileUrl.dispose();
    _catForumUrl.dispose();
    _catNexusUrl.dispose();
    _catDiscordUrl.dispose();
    _catDirectDownloadUrl.dispose();
    _catDownloadPageUrl.dispose();
    _catForumThreadId.dispose();
    _catNexusModsId.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  void _onSave() {
    final currentRecord = ref
        .read(modRecordsStore)
        .valueOrNull
        ?.records[widget.recordKey];
    if (currentRecord == null) return;

    final updatedOverrides = Map<String, ModRecordSource>.of(
      currentRecord.userOverrides,
    );

    // Build a VersionCheckerSource override with only user-changed fields.
    // null means "no override, use auto-populated value".
    final autoVc =
        currentRecord.sources['versionChecker'] as VersionCheckerSource?;
    final vcOverride = VersionCheckerSource(
      forumThreadId: _diffField(_vcForumThreadId, autoVc?.forumThreadId),
      nexusModsId: _diffField(_vcNexusModsId, autoVc?.nexusModsId),
      directDownloadUrl: _diffField(
        _vcDirectDownloadUrl,
        autoVc?.directDownloadUrl,
      ),
      changelogUrl: _diffField(_vcChangelogUrl, autoVc?.changelogUrl),
      masterVersionFileUrl: _diffField(
        _vcMasterVersionFileUrl,
        autoVc?.masterVersionFileUrl,
      ),
    );
    if (_hasAnyField(vcOverride)) {
      updatedOverrides['versionChecker'] = vcOverride;
    } else {
      updatedOverrides.remove('versionChecker');
    }

    // Build a CatalogSource override with only user-changed fields.
    final autoCat = currentRecord.sources['catalog'] as CatalogSource?;
    final catOverride = CatalogSource(
      forumUrl: _diffField(_catForumUrl, autoCat?.forumUrl),
      nexusUrl: _diffField(_catNexusUrl, autoCat?.nexusUrl),
      discordUrl: _diffField(_catDiscordUrl, autoCat?.discordUrl),
      directDownloadUrl: _diffField(
        _catDirectDownloadUrl,
        autoCat?.directDownloadUrl,
      ),
      downloadPageUrl: _diffField(
        _catDownloadPageUrl,
        autoCat?.downloadPageUrl,
      ),
      forumThreadId: _diffField(_catForumThreadId, autoCat?.forumThreadId),
      nexusModsId: _diffField(_catNexusModsId, autoCat?.nexusModsId),
    );
    if (_hasAnyField(catOverride)) {
      updatedOverrides['catalog'] = catOverride;
    } else {
      updatedOverrides.remove('catalog');
    }

    ref
        .read(modRecordsStore.notifier)
        .updateRecord(
          widget.recordKey,
          (_) => currentRecord.copyWith(userOverrides: updatedOverrides),
        );
    Navigator.of(context).pop();
  }

  /// Returns the controller's trimmed value if it differs from the
  /// auto-populated [autoValue], or null if unchanged (meaning no override).
  String? _diffField(TextEditingController controller, String? autoValue) {
    final userVal = controller.text.trim().nullIfEmpty;
    final autoVal = autoValue?.trim().nullIfEmpty;
    return userVal != autoVal ? userVal : null;
  }

  /// Returns true if any non-lastSeen field in the source is non-null.
  bool _hasAnyField(ModRecordSource source) => switch (source) {
    VersionCheckerSource s =>
      s.forumThreadId != null ||
          s.nexusModsId != null ||
          s.directDownloadUrl != null ||
          s.changelogUrl != null ||
          s.masterVersionFileUrl != null,
    CatalogSource s =>
      s.name != null ||
          s.authors != null ||
          s.forumUrl != null ||
          s.nexusUrl != null ||
          s.discordUrl != null ||
          s.directDownloadUrl != null ||
          s.downloadPageUrl != null ||
          s.forumThreadId != null ||
          s.nexusModsId != null ||
          s.categories != null,
    InstalledSource s =>
      s.name != null ||
          s.author != null ||
          s.installPath != null ||
          s.version != null,
    DownloadHistorySource s =>
      s.lastDownloadedFrom != null || s.lastDownloadedAt != null,
  };

  @override
  Widget build(BuildContext context) {
    final record = ref
        .watch(modRecordsStore)
        .valueOrNull
        ?.records[widget.recordKey];
    final theme = Theme.of(context);
    final dateFmt = DateFormat.yMd().add_jm();

    if (record != null) {
      _initControllersIfNeeded(record);
    }

    return AlertDialog(
      title: Text("Mod Sources: ${widget.displayName}"),
      backgroundColor: theme.colorScheme.surface,
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          child: record == null
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "No source record exists for this mod yet.\n"
                    "Records are created automatically when TriOS processes installed mods.",
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: [
                    // Identity card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 4,
                          children: [
                            Text("Identity", style: theme.textTheme.titleSmall),
                            SimpleDataRow(
                              label: "Record Key: ",
                              value: record.recordKey,
                            ),
                            SimpleDataRow(
                              label: "Mod ID: ",
                              value: record.modId ?? "(none)",
                            ),
                            SimpleDataRow(
                              label: "Names: ",
                              value: record.allNames.isNotEmpty
                                  ? record.allNames.join(", ")
                                  : "(none)",
                            ),
                            SimpleDataRow(
                              label: "Authors: ",
                              value: record.allAuthors.isNotEmpty
                                  ? record.allAuthors.join(", ")
                                  : "(none)",
                            ),
                            if (record.firstSeen != null)
                              SimpleDataRow(
                                label: "First Seen: ",
                                value: dateFmt.format(record.firstSeen!),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Installed source
                    _buildInstalledSection(record, dateFmt),

                    // Version Checker source
                    _buildVersionCheckerSection(record, dateFmt),

                    // Catalog source
                    _buildCatalogSection(record, dateFmt),

                    // Download History source
                    _buildDownloadHistorySection(record, dateFmt),
                  ],
                ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Cancel"),
        ),
        if (record != null)
          TextButton(
            onPressed: _isDirty ? _onSave : null,
            child: const Text("Save"),
          ),
      ],
    );
  }

  Widget _buildInstalledSection(ModRecord record, DateFormat dateFmt) {
    final source = record.installed;
    return TriOSExpansionTile(
      title: Text("Installed"),
      leading: const Icon(Icons.folder, size: 20),
      initiallyExpanded: source != null,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: source == null
                ? [
                    Text(
                      "(not installed)",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ]
                : [
                    SimpleDataRow(
                      label: "Name: ",
                      value: source.name ?? "(unknown)",
                    ),
                    SimpleDataRow(
                      label: "Author: ",
                      value: source.author ?? "(unknown)",
                    ),
                    SimpleDataRow(
                      label: "Path: ",
                      value: source.installPath ?? "(unknown)",
                    ),
                    SimpleDataRow(
                      label: "Version: ",
                      value: source.version ?? "(unknown)",
                    ),
                    if (source.lastSeen != null)
                      SimpleDataRow(
                        label: "Last Seen: ",
                        value: dateFmt.format(source.lastSeen!),
                      ),
                  ],
          ),
        ),
      ],
    );
  }

  Widget _buildVersionCheckerSection(ModRecord record, DateFormat dateFmt) {
    final source = record.versionChecker;
    return TriOSExpansionTile(
      title: Text("Version Checker"),
      leading: const Icon(Icons.update, size: 20),
      initiallyExpanded: source != null,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              if (source == null)
                Text(
                  "(no version checker data — fill in fields to create)",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              InlineEditText(
                label: "Forum Thread ID: ",
                controller: _vcForumThreadId,
                onChanged: _markDirty,
              ),
              InlineEditText(
                label: "Nexus Mods ID: ",
                controller: _vcNexusModsId,
                onChanged: _markDirty,
              ),
              InlineEditText(
                label: "Direct Download URL: ",
                controller: _vcDirectDownloadUrl,
                onChanged: _markDirty,
              ),
              InlineEditText(
                label: "Changelog URL: ",
                controller: _vcChangelogUrl,
                onChanged: _markDirty,
              ),
              InlineEditText(
                label: "Master Version File URL: ",
                controller: _vcMasterVersionFileUrl,
                onChanged: _markDirty,
              ),
              if (source?.lastSeen != null)
                SimpleDataRow(
                  label: "Last Seen: ",
                  value: dateFmt.format(source!.lastSeen!),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCatalogSection(ModRecord record, DateFormat dateFmt) {
    final source = record.catalog;
    return TriOSExpansionTile(
      title: Text("Catalog"),
      leading: const Icon(Icons.library_books, size: 20),
      initiallyExpanded: source != null,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              if (source == null)
                Text(
                  "(not found in catalog — fill in fields to create)",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              if (source?.name != null)
                SimpleDataRow(label: "Catalog Name: ", value: source!.name!),
              InlineEditText(
                label: "Forum URL: ",
                controller: _catForumUrl,
                onChanged: _markDirty,
              ),
              InlineEditText(
                label: "Nexus URL: ",
                controller: _catNexusUrl,
                onChanged: _markDirty,
              ),
              InlineEditText(
                label: "Discord URL: ",
                controller: _catDiscordUrl,
                onChanged: _markDirty,
              ),
              InlineEditText(
                label: "Direct Download URL: ",
                controller: _catDirectDownloadUrl,
                onChanged: _markDirty,
              ),
              InlineEditText(
                label: "Download Page URL: ",
                controller: _catDownloadPageUrl,
                onChanged: _markDirty,
              ),
              InlineEditText(
                label: "Forum Thread ID: ",
                controller: _catForumThreadId,
                onChanged: _markDirty,
              ),
              InlineEditText(
                label: "Nexus Mods ID: ",
                controller: _catNexusModsId,
                onChanged: _markDirty,
              ),
              if (source?.categories != null && source!.categories!.isNotEmpty)
                SimpleDataRow(
                  label: "Categories: ",
                  value: source.categories!.join(", "),
                ),
              if (source?.lastSeen != null)
                SimpleDataRow(
                  label: "Last Seen: ",
                  value: dateFmt.format(source!.lastSeen!),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadHistorySection(ModRecord record, DateFormat dateFmt) {
    final source = record.downloadHistory;
    return TriOSExpansionTile(
      title: Text("Download History"),
      leading: const Icon(Icons.download, size: 20),
      initiallyExpanded: source != null,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: source == null
                ? [
                    Text(
                      "(no downloads recorded)",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ]
                : [
                    SimpleDataRow(
                      label: "Downloaded From: ",
                      value: source.lastDownloadedFrom ?? "(unknown)",
                    ),
                    if (source.lastDownloadedAt != null)
                      SimpleDataRow(
                        label: "Downloaded At: ",
                        value: dateFmt.format(source.lastDownloadedAt!),
                      ),
                    if (source.lastSeen != null)
                      SimpleDataRow(
                        label: "Last Seen: ",
                        value: dateFmt.format(source.lastSeen!),
                      ),
                  ],
          ),
        ),
      ],
    );
  }
}

extension _NullIfEmpty on String {
  String? get nullIfEmpty => trim().isEmpty ? null : trim();
}
