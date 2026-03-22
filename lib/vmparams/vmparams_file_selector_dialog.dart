import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/vmparams/vmparams_manager.dart';
import 'package:trios/widgets/trios_expansion_tile.dart';

class VmparamsFileSelectorDialog extends ConsumerStatefulWidget {
  const VmparamsFileSelectorDialog({super.key});

  @override
  ConsumerState<VmparamsFileSelectorDialog> createState() =>
      _VmparamsFileSelectorDialogState();
}

class _VmparamsFileSelectorDialogState
    extends ConsumerState<VmparamsFileSelectorDialog> {
  late Set<String> _selectedPaths;
  bool _isScanning = false;
  List<File>? _detectedFiles;

  @override
  void initState() {
    super.initState();
    _selectedPaths = {};
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final vmState = ref.read(vmparamsManagerProvider).value;
    if (vmState != null && _selectedPaths.isEmpty) {
      final gameDir = ref.read(AppState.gameFolder).value;
      if (gameDir != null) {
        _selectedPaths = vmState.selectedVmparamsFiles
            .map((f) => _relativePath(f, gameDir))
            .toSet();
      }
      _detectedFiles = vmState.detectedVmparamsFiles;
    }
  }

  String _relativePath(File file, Directory gameDir) {
    return p.relative(
      p.normalize(file.absolute.path),
      from: p.normalize(gameDir.absolute.path),
    );
  }

  Future<void> _rescan() async {
    final gameDir = ref.read(AppState.gameFolder).value;
    if (gameDir == null) return;

    setState(() => _isScanning = true);
    final files = await scanForVmparamsFiles(gameDir);
    setState(() {
      _detectedFiles = files;
      _isScanning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameDir = ref.watch(AppState.gameFolder).value;
    final vmState = ref.watch(vmparamsManagerProvider).value;
    final files = _detectedFiles ?? vmState?.detectedVmparamsFiles ?? [];
    final fileRamAmounts = vmState?.fileRamAmounts ?? {};
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text("vmparams Files"),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              "Select which files TriOS should use for reading and writing RAM allocation.",
              style: theme.textTheme.bodyMedium,
            ),
            Padding(
              padding: const .only(top: 4),
              child: TriOSExpansionTile(
                title: Text("More information"),
                dense: true,
                leading: const Icon(Icons.info),
                childrenPadding: .all(8),
                children: [
                  SelectableText(
                    "Different game launchers use different configuration files."
                    "\n\nFor example, if you launch the game using Fast Rendering, it will use the amount of RAM specified in the `starsector-core/fr.vmparams` file (as of March 2026)."
                    "\n\n${Constants.appName} scanned your game folder for files containing a pattern for Java RAM allocation arguments `(?<=xmx).*?(?=\\s)`."
                    "\n\nFor each of these files checked below, when you pick a RAM value, it will surgically modify just the RAM allocation part of those files without changing the rest of the file.",
                    style: theme.textTheme.labelLarge,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_isScanning)
              const Center(child: CircularProgressIndicator())
            else if (files.isEmpty)
              const Text("No vmparams-type files found in the game directory.")
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    final file = files[index];
                    final relativePath = gameDir != null
                        ? _relativePath(file, gameDir)
                        : file.path;
                    final ram = fileRamAmounts[file];
                    final isSelected = _selectedPaths.contains(relativePath);

                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            _selectedPaths.add(relativePath);
                          } else {
                            _selectedPaths.remove(relativePath);
                          }
                        });
                      },
                      title: Text(
                        relativePath,
                        style: theme.textTheme.bodyMedium,
                      ),
                      subtitle: Text(
                        ram != null ? "$ram MB" : "RAM not detected",
                        style: theme.textTheme.bodySmall,
                      ),
                      dense: true,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        Row(
          children: [
            TextButton.icon(
              onPressed: _isScanning ? null : _rescan,
              icon: const Icon(Icons.refresh),
              label: const Text("Rescan"),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () {
                ref
                    .read(vmparamsManagerProvider.notifier)
                    .setSelectedFiles(_selectedPaths.toList());
                Navigator.of(context).pop();
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ],
    );
  }
}
