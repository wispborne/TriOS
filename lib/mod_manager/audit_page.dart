import 'dart:io';

import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/thirdparty/dartx/list.dart';
import 'package:trios/thirdparty/dartx/map.dart';
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
    final auditLog =
        groupByTime(ref.watch(AppState.modAudit).reversed.toList());
    final dateFormat = DateFormat.yMMMMd(Intl.getCurrentLocale()).add_jms();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mod Audit Log'),
      ),
      body: ListView.separated(
        itemCount: auditLog.flatten().length,
        itemBuilder: (context, index) {
          final entry = auditLog.flatten()[index];
          final variant = modVariantsBySmolId[entry.smolId];
          final actionWord =
              "${entry.action.name.replaceFirstMapped(RegExp(r'^.'), (match) => match.group(0)!.toUpperCase())}d";
          return SelectionArea(
            child: ListTile(
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
                  "$actionWord ${dateFormat.format(entry.timestamp)}"),
              subtitleTextStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color:
                        Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
            ),
          );
        },
        separatorBuilder: (BuildContext context, int index) {
          if (auditLog
              .map((group) => group.length - 1)
              .toList()
              .contains(index)) {
            return SizedBox(
              height: 2,
              child: Container(
                color: Colors.black,
              ),
            );
          } else {
            return Container();
          }
        },
      ),
    );
  }

  List<List<AuditEntry>> groupByTime(List<AuditEntry> entries) {
    List<List<AuditEntry>> ret = [];
    AuditEntry? prev;

    for (final entry in entries) {
      if (prev == null) {
        ret.add([entry]);
      } else {
        var pauseBetweenGroupsInSeconds = 3;
        if (entry.timestamp.difference(prev.timestamp).abs().inSeconds <= pauseBetweenGroupsInSeconds) {
          ret.last.add(entry);
        } else {
          ret.add([entry]);
        }
      }

      prev = entry;
    }

    return ret;
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
