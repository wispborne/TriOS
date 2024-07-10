import 'package:flutter/material.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/search.dart';
import 'package:trios/widgets/simple_data_row.dart';

import '../models/mod.dart';
import '../models/version.dart';

class DebugInfo extends StatelessWidget {
  final Mod mod;

  const DebugInfo({super.key, required this.mod});

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: Column(
        children: mod.modVariants
            .sortedByDescending<Version>(
                (variant) => variant.bestVersion ?? Version.zero())
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
                              "${variant.modInfo.id} ${variant.modInfo.version}",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.bold)),
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
                              value: variant.modsFolder.path),
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
                          Text("Version Checker",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          Text(variant.versionCheckerInfo.toString(),
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
