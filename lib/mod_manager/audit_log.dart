import 'package:trios/utils/generic_settings_manager.dart';

import '../utils/generic_settings_notifier.dart';

class AuditLogPersistenceManager
    extends GenericAsyncSettingsManager<List<AuditEntry>> {
  /// Choose JSON format for simplicity in handling lists of objects.
  @override
  FileFormat get fileFormat => FileFormat.json;

  @override
  String get fileName => 'mod_audit_log.json';

  @override
  Map<String, dynamic> Function(List<AuditEntry>) get toMap =>
      (auditEntries) => {
            'auditLog': auditEntries
                .map((entry) => {
                      'smolId': entry.smolId,
                      'timestamp': entry.timestamp.toIso8601String(),
                      'action': entry.action.name,
                      'reason': entry.reason,
                    })
                .toList(),
          };

  @override
  List<AuditEntry> Function(Map<String, dynamic>) get fromMap =>
      (map) => (map['auditLog'] as List<dynamic>)
          .map((entry) => AuditEntry(
                entry['smolId'],
                DateTime.parse(entry['timestamp']),
                ModAction.values.byName(entry['action']),
                entry['reason'],
              ))
          .toList();
}

class AuditLog extends GenericSettingsAsyncNotifier<List<AuditEntry>> {
  static const maxAuditEntries = 100;

  @override
  List<AuditEntry> createDefaultState() => [];

  void addAuditEntry(String smolId, ModAction action,
      {required String reason}) {
    updateState((currentState) {
      final newEntry = AuditEntry(smolId, DateTime.now(), action, reason);
      final updatedState = [
        ...currentState,
        newEntry,
      ];

      // Keep only the last n entries
      if (updatedState.length > maxAuditEntries) {
        updatedState.removeRange(0, updatedState.length - maxAuditEntries);
      }

      return updatedState;
    });
  }

  @override
  GenericAsyncSettingsManager<List<AuditEntry>> createSettingsManager() =>
      AuditLogPersistenceManager();
}

class AuditEntry {
  final String smolId;
  final DateTime timestamp;
  final ModAction action;
  final String reason;

  AuditEntry(this.smolId, this.timestamp, this.action, this.reason);
}

enum ModAction {
  enable,
  disable,
  delete,
}
