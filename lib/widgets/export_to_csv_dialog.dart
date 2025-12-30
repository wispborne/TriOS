import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trios/thirdparty/dartx/string.dart';

enum _ExportOption {
  allData('All Data'),
  gridData('Grid Data');

  const _ExportOption(this.label);

  final String label;
}

/// Shows a dialog allowing the user to export data to a CSV file or copy it to the clipboard.
///
/// [nameOfThingBeingExported] is the name of the thing being exported, e.g. 'weapon' or 'ship'.
/// [getGridCsvString] is a function that returns the CSV string for the grid data.
/// [getAllDataCsvString] is an optional function that returns the CSV string for all data.
Future<void> showExportOrCopyDialog(
  BuildContext context,
  String nameOfThingBeingExported,
  String Function() getGridCsvString,
  String Function()? getAllDataCsvString,
) async {
  _ExportOption? selectedOption;

  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      final options = <_ExportOption>[
        if (getAllDataCsvString != null) _ExportOption.allData,
        _ExportOption.gridData,
      ];
      selectedOption ??= options.first;

      String getCsv(_ExportOption userOption) =>
          userOption == _ExportOption.allData
          ? getAllDataCsvString!()
          : getGridCsvString();

      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 420, maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.exit_to_app, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Export ${nameOfThingBeingExported.capitalize()} Data',
                          style: Theme.of(ctx).textTheme.titleLarge,
                        ),
                        const Spacer(),
                      ],
                    ),
                    if (getAllDataCsvString != null) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: options.map((option) {
                          return Padding(
                            padding: const .symmetric(horizontal: 4.0),
                            child: SizedBox(
                              width: 200,
                              child: RadioListTile<_ExportOption>(
                                dense: true,
                                value: option,
                                groupValue: selectedOption!,
                                title: Column(
                                  crossAxisAlignment: .start,
                                  children: [
                                    Text(
                                      option.label,
                                      style: Theme.of(ctx).textTheme.bodyMedium,
                                    ),
                                    Text(switch (option) {
                                      _ExportOption.allData =>
                                        'All loaded $nameOfThingBeingExported data and fields.',
                                      _ExportOption.gridData =>
                                        'Only the $nameOfThingBeingExported data and fields visible in the grid.',
                                    }, style: Theme.of(ctx).textTheme.labelMedium),
                                  ],
                                ),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => selectedOption = value);
                                  }
                                },
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(220, 64),
                            ),
                            icon: const Icon(Icons.copy_all),
                            label: const Text('Copy to Clipboard'),
                            onPressed: () async {
                              await Clipboard.setData(
                                ClipboardData(text: getCsv(selectedOption!)),
                              );
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                    content: Text('Copied to clipboard!'),
                                  ),
                                );
                              }
                            },
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(220, 64),
                            ),
                            icon: const Icon(Icons.save_alt),
                            label: const Text('Save to File'),
                            onPressed: () async {
                              final path = await _pickSaveLocation(ctx);
                              if (path == null) return;
                              final file = File(path);
                              await file.writeAsString(getCsv(selectedOption!));
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(content: Text('Saved: $path')),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Spacer(),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

Future<String?> _pickSaveLocation(BuildContext context) async {
  // Prefer a desktop-like save dialog if available via file_picker.
  try {
    // Uses `file_picker` save dialog; falls back to temp file if unsupported.
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Weapons CSV',
      fileName: 'weapons_export.csv',
      type: FileType.custom,
      allowedExtensions: ['csv'],
      lockParentWindow: true,
    );
    if (result != null && !result.toLowerCase().endsWith('.csv')) {
      return '$result.csv';
    }
    return result;
  } catch (_) {
    // Fallback: write to temp and inform user
    final temp = File('${Directory.systemTemp.path}/weapons_export.csv');
    await temp.writeAsString(''); // touch file to ensure existence hint
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Save dialog unavailable. Example file at: ${temp.path}',
          ),
        ),
      );
    }
    return temp.path;
  }
}
