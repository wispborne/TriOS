import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuditPage extends ConsumerStatefulWidget {
  const AuditPage({super.key});

  @override
  ConsumerState createState() => _AuditPageState();
}

class _AuditPageState extends ConsumerState<AuditPage> {
  @override
  Widget build(BuildContext context) {
    return Container();
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