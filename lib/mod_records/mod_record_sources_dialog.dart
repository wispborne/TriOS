import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:trios/mod_records/mod_record.dart';
import 'package:trios/mod_records/mod_record_source.dart';
import 'package:trios/mod_records/mod_records_store.dart';
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
    builder: (context) => ModRecordSourcesDialog(
      recordKey: recordKey,
      displayName: displayName,
    ),
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

  @override
  void initState() {
    super.initState();
    final record = ref
        .read(modRecordsStore)
        .valueOrNull
        ?.records[widget.recordKey];
    if (record != null) {
      _initControllers(record);
    }
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

    final updatedSources = Map<String, ModRecordSource>.of(
      currentRecord.sources,
    );

    // Update or create VersionCheckerSource.
    final hasVcData = [
      _vcForumThreadId,
      _vcNexusModsId,
      _vcDirectDownloadUrl,
      _vcChangelogUrl,
      _vcMasterVersionFileUrl,
    ].any((c) => c.text.trim().isNotEmpty);

    if (hasVcData) {
      final existing = currentRecord.versionChecker;
      updatedSources['versionChecker'] = VersionCheckerSource(
        forumThreadId: _vcForumThreadId.text.trim().nullIfEmpty,
        nexusModsId: _vcNexusModsId.text.trim().nullIfEmpty,
        directDownloadUrl: _vcDirectDownloadUrl.text.trim().nullIfEmpty,
        changelogUrl: _vcChangelogUrl.text.trim().nullIfEmpty,
        masterVersionFileUrl:
            _vcMasterVersionFileUrl.text.trim().nullIfEmpty,
        lastSeen: existing?.lastSeen,
      );
    } else {
      updatedSources.remove('versionChecker');
    }

    // Update or create CatalogSource.
    final existingCat = currentRecord.catalog;
    final hasCatEdits = [
      _catForumUrl,
      _catNexusUrl,
      _catDiscordUrl,
      _catDirectDownloadUrl,
      _catDownloadPageUrl,
      _catForumThreadId,
      _catNexusModsId,
    ].any((c) => c.text.trim().isNotEmpty);

    if (hasCatEdits || existingCat != null) {
      updatedSources['catalog'] = CatalogSource(
        catalogName: existingCat?.catalogName,
        forumUrl: _catForumUrl.text.trim().nullIfEmpty,
        nexusUrl: _catNexusUrl.text.trim().nullIfEmpty,
        discordUrl: _catDiscordUrl.text.trim().nullIfEmpty,
        directDownloadUrl: _catDirectDownloadUrl.text.trim().nullIfEmpty,
        downloadPageUrl: _catDownloadPageUrl.text.trim().nullIfEmpty,
        forumThreadId: _catForumThreadId.text.trim().nullIfEmpty,
        nexusModsId: _catNexusModsId.text.trim().nullIfEmpty,
        categories: existingCat?.categories,
        lastSeen: existingCat?.lastSeen,
      );
    }

    ref.read(modRecordsStore.notifier).updateRecord(
      widget.recordKey,
      (_) => currentRecord.copyWith(sources: updatedSources),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final record = ref
        .watch(modRecordsStore)
        .valueOrNull
        ?.records[widget.recordKey];
    final theme = Theme.of(context);
    final dateFmt = DateFormat.yMd().add_jm();

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
                            Text(
                              "Identity",
                              style: theme.textTheme.titleSmall,
                            ),
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
                              value: record.names.isNotEmpty
                                  ? record.names.join(", ")
                                  : "(none)",
                            ),
                            SimpleDataRow(
                              label: "Authors: ",
                              value: record.authors.isNotEmpty
                                  ? record.authors.join(", ")
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
              _editField("Forum Thread ID", _vcForumThreadId),
              _editField("Nexus Mods ID", _vcNexusModsId),
              _editField("Direct Download URL", _vcDirectDownloadUrl),
              _editField("Changelog URL", _vcChangelogUrl),
              _editField("Master Version File URL", _vcMasterVersionFileUrl),
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
              if (source?.catalogName != null)
                SimpleDataRow(
                  label: "Catalog Name: ",
                  value: source!.catalogName!,
                ),
              _editField("Forum URL", _catForumUrl),
              _editField("Nexus URL", _catNexusUrl),
              _editField("Discord URL", _catDiscordUrl),
              _editField("Direct Download URL", _catDirectDownloadUrl),
              _editField("Download Page URL", _catDownloadPageUrl),
              _editField("Forum Thread ID", _catForumThreadId),
              _editField("Nexus Mods ID", _catNexusModsId),
              if (source?.categories != null &&
                  source!.categories!.isNotEmpty)
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

  Widget _editField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
      style: Theme.of(context).textTheme.bodySmall,
      onChanged: (_) => _markDirty(),
    );
  }
}

extension _NullIfEmpty on String {
  String? get nullIfEmpty => trim().isEmpty ? null : trim();
}
