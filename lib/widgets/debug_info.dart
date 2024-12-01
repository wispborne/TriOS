import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/search.dart';
import 'package:trios/widgets/simple_data_row.dart';

import '../models/mod.dart';

class DebugInfo extends ConsumerWidget {
  final Mod mod;

  const DebugInfo({super.key, required this.mod});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vcResultsCache = (ref.watch(AppState.versionCheckResults).valueOrNull)
            ?.versionCheckResultsBySmolId ??
        {};

    return SelectionArea(
      child: Column(
        children: mod.modVariants
            .sortedByDescending<ModVariant>((variant) => variant)
            .map(
              (variant) => Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              "${variant.modInfo.nameOrId} ${variant.modInfo.version}",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20)),
                          SimpleDataRow(
                              label: "id: ", value: variant.modInfo.id),
                          SimpleDataRow(
                            label: "Version: ",
                            value:
                                '${variant.modInfo.version} • Version Checker: ${variant.versionCheckerInfo?.modVersion}',
                          ),
                          SimpleDataRow(
                              label: "Internal id: ", value: variant.smolId),
                          SimpleDataRow(
                              label: "Mod Folder: ",
                              value: variant.modFolder.path),
                          SimpleDataRow(
                              label: "Icon: ",
                              value: variant.iconFilePath ?? ""),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("mod_info.json",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          Text(variant.modInfo.toString(),
                              style: Theme.of(context).textTheme.labelLarge),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Version Checker - Local",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          Text(
                              variant.versionCheckerInfo?.toString() ??
                                  "(none)",
                              style: Theme.of(context).textTheme.labelLarge),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Version Checker - Remote (cached lookup)",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          Text(
                              vcResultsCache[variant.smolId]?.toString() ??
                                  "(none)",
                              style: Theme.of(context).textTheme.labelLarge),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Search Tags",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          Text(
                              getModVariantSearchTags(variant).joinToString(
                                  transform: (it) =>
                                      "${it.term} (-${it.scorePenalty.toStringAsFixed(0)})"),
                              style: Theme.of(context).textTheme.labelLarge),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

showDebugViewDialog(BuildContext context, Mod mod) {
  showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("${mod.findHighestVersion?.modInfo.name}"),
          content: SingleChildScrollView(child: DebugInfo(mod: mod)),
          backgroundColor: Theme.of(context).colorScheme.surface,
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("Close")),
          ],
        );
      });
}
