import 'dart:io';

import 'package:dartx/dartx.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants.dart';

class ModAuditNotifier extends StateNotifier<List<AuditEntry>> {
  ModAuditNotifier() : super([]);

  void addAuditEntry(String smolId, ModAction action) {
    state = [
      ...state,
      AuditEntry(smolId, DateTime.now(), action),
    ];
  }
}

class AuditPage extends ConsumerStatefulWidget {
  const AuditPage({super.key});

  @override
  ConsumerState createState() => _AuditPageState();
}

class _AuditPageState extends ConsumerState<AuditPage> {
  @override
  Widget build(BuildContext context) {
    final modVariantsBySmolId = (ref
                .watch(AppState.modVariants)
                .valueOrNull
                ?.groupBy((ModVariant variant) => variant.smolId) ??
            {})
        .map((key, value) => MapEntry(key, value.first))
        .cast<String, ModVariant>()
        .toMap();
    var auditLog = ref.watch(AppState.modAudit).reversed.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mod Audit Log'),
      ),
      body: ListView.builder(
        itemCount: auditLog.length,
        itemBuilder: (context, index) {
          final entry = auditLog[index];
          final variant = modVariantsBySmolId[entry.smolId];
          final actionWord =
              "${entry.action.name.replaceFirstMapped(RegExp(r'^.'), (match) => match.group(0)!.toUpperCase())}d";
          return ListTile(
            dense: true,
            leading: Icon(
              switch (entry.action) {
                ModAction.enable => Icons.check,
                ModAction.disable => Icons.close,
                ModAction.delete => Icons.delete,
              },
            ),
            title: Row(
              children: [
                if (variant?.iconFilePath != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Image.file(
                      File(variant!.iconFilePath!),
                      width: 24,
                      height: 24,
                    ),
                  ),
                Text(variant != null
                    ? "${variant.modInfo.nameOrId} ${variant.modInfo.version}"
                    : entry.smolId),
              ],
            ),
            subtitle: Text(
                "$actionWord ${Constants.dateTimeFormat.format(entry.timestamp)}"),
            subtitleTextStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
          );
        },
      ),
    );
  }
}

class AuditEntry {
  final String smolId;
  final DateTime timestamp;
  final ModAction action;

  AuditEntry(this.smolId, this.timestamp, this.action);
}

enum ModAction {
  enable,
  disable,
  delete,
}
