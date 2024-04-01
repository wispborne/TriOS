import 'package:flutter/material.dart';

class ModEntry {
  static final RegExp regex =
      RegExp(".*-    +(?<name>.*) +\\[id: (?<id>.*?)\\] \\[version +(?<version>.*?)\\].*\\(from .*");

  final String? modName;
  final String? modId;
  final String? modVersion;

  ModEntry(this.modName, this.modId, this.modVersion);

  static ModEntry tryCreate(String line) {
    final parsed = regex.firstMatch(line);

    return ModEntry(parsed?.namedGroup("name"), parsed?.namedGroup("id"), parsed?.namedGroup("version"));
  }

  Widget createWidget(BuildContext context) {
    return ModEntryWidget(modEntry: this);
  }

  @override
  String toString() {
    return "ModEntry{modName: $modName, modId: $modId, modVersion: $modVersion}";
  }
}

class ModEntryWidget extends StatelessWidget {
  final ModEntry modEntry;

  const ModEntryWidget({super.key, required this.modEntry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
        padding: const EdgeInsets.only(bottom: 1),
        child: Text.rich(TextSpan(children: [
          TextSpan(text: modEntry.modName, style: TextStyle(color: theme.colorScheme.secondary.withAlpha(240))),
          ...(modEntry.modVersion == null
              ? [const TextSpan()]
              : [
                  TextSpan(text: " • ", style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(100))),
                  TextSpan(
                      text: "${modEntry.modVersion}",
                      style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(240)))
                ]),
          ...(modEntry.modId == null
              ? [const TextSpan()]
              : [
                  TextSpan(text: " • ", style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(100))),
                  TextSpan(
                      text: "${modEntry.modId}",
                      style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(180), fontFamily: 'RobotoMono'))
                ]),
        ])));
  }
}
