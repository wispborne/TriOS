import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_color/flutter_color.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/vmparams/vmparams_manager.dart';
import 'package:trios/widgets/conditional_wrap.dart';
import 'package:trios/widgets/moving_tooltip.dart';

import '../themes/theme_manager.dart';
import '../widgets/fixed_height_grid_item.dart';

class RamChanger extends ConsumerStatefulWidget {
  const RamChanger({super.key});

  @override
  ConsumerState createState() => _RamChangerState();
}

class _RamChangerState extends ConsumerState<RamChanger> {
  bool areVmparamsWritable = true;
  final List<String> vmParamsFilesThatCannotBeWritten = [];
  final TextEditingController _customRamController = TextEditingController();
  double? _lastKnownRamMb;
  bool _lastKnownHasMultiple = false;

  @override
  void dispose() {
    _customRamController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final vmState = ref.read(vmparamsManagerProvider).value;
    if (vmState != null) {
      _checkWritability(vmState.selectedVmparamsFiles);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vmState = ref.watch(vmparamsManagerProvider).value;
    final selectedFiles = vmState?.selectedVmparamsFiles ?? [];
    final gamePath = ref.read(AppState.gameFolder).value?.toDirectory();
    if (gamePath == null) {
      return const SizedBox();
    }

    ref.listen(vmparamsManagerProvider, (prev, next) async {
      final newState = next.value;
      if (newState != null && prev?.value != newState) {
        await _checkWritability(newState.selectedVmparamsFiles);
      }
    });

    final theme = Theme.of(context);
    final ramChoices = [1.5, 2, 3, 4, 6, 8, 10, 11, 16];
    final hasMultiple = vmState?.hasMultipleFilesWithDifferentRam ?? false;
    final currentRamMb = double.tryParse(
      vmState?.currentRamAmountInMb ?? "",
    );
    final ramChoicesInMb = ramChoices.map((gb) => gb * mbPerGb).toSet();
    final isCustomRam =
        !hasMultiple &&
        currentRamMb != null &&
        !ramChoicesInMb.contains(currentRamMb);

    if (currentRamMb != _lastKnownRamMb ||
        hasMultiple != _lastKnownHasMultiple) {
      _lastKnownRamMb = currentRamMb;
      _lastKnownHasMultiple = hasMultiple;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (isCustomRam) {
          _customRamController.text = currentRamMb.toStringAsFixed(0);
        } else {
          _customRamController.clear();
        }
      });
    }

    if (!areVmparamsWritable) {
      return Text(
        "Cannot write to vmparams file:\n${vmParamsFilesThatCannotBeWritten.join("\n")}."
        "\n\nMake sure it exists or try running ${Constants.appName} as an administrator.",
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: ThemeManager.vanillaWarningColor,
        ),
      );
    }

    return Column(
      spacing: 8,
      children: [
        GridView.builder(
          shrinkWrap: true,
          itemCount: ramChoices.length,
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCountAndFixedHeight(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                height: 25,
              ),
          itemBuilder: (context, index) {
            final ram = ramChoices[index];
            final ramInMb = ram * mbPerGb;

            // Find which selected files have this RAM amount.
            final filesWithThisRam = selectedFiles.where((f) {
              final fileRam = vmState?.fileRamAmounts[f];
              return fileRam != null &&
                  double.tryParse(fileRam) == ramInMb;
            }).toList();

            return ConditionalWrap(
              condition: filesWithThisRam.isNotEmpty,
              wrapper: (child) {
                final color = hasMultiple
                    ? theme.colorScheme.secondary
                    : theme.colorScheme.primary;
                return MovingTooltipWidget.text(
                  message: filesWithThisRam
                      .map((f) =>
                          "${vmState?.fileRamAmounts[f]} MB set in ${p.relative(f.path, from: gamePath.path)}")
                      .join("\n"),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        ThemeManager.cornerRadius,
                      ),
                      border: Border.all(width: 2, color: color),
                    ),
                    child: child,
                  ),
                );
              },
              child: ElevatedButton(
                onPressed: () {
                  ref
                      .read(vmparamsManagerProvider.notifier)
                      .changeRamAmount(ramInMb.toDouble());
                },
                child: Text("$ram GB"),
              ),
            );
          },
        ),
        Card(
          color: theme.cardColor.darker(1),
          shape: isCustomRam
              ? RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    ThemeManager.cornerRadius,
                  ),
                  side: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                )
              : null,
          child: Padding(
            padding:
                const EdgeInsets.only(left: 8, top: 8, right: 8, bottom: 12),
            child: Column(
              spacing: 4,
              children: [
                Text(
                  "or set a custom RAM assignment",
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 8,
                  children: [
                    SizedBox(
                      width: 8 * 11,
                      child: TextField(
                        controller: _customRamController,
                        decoration: InputDecoration(
                          suffixText: "MB",
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 4),
                        ),
                        keyboardType: TextInputType.number,
                        onSubmitted: (_) => _applyCustomRam(),
                      ),
                    ),
                    SizedBox(
                      height: 24,
                      child: ElevatedButton(
                        onPressed: _applyCustomRam,
                        child: const Text("Apply"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _applyCustomRam() {
    final mb = double.tryParse(_customRamController.text);
    if (mb != null && mb > 0) {
      ref.read(vmparamsManagerProvider.notifier).changeRamAmount(mb);
    }
  }

  Future<void> _checkWritability(List<File> selectedFiles) async {
    vmParamsFilesThatCannotBeWritten.clear();
    areVmparamsWritable = true;

    for (final file in selectedFiles) {
      if (file.existsSync() && await file.isNotWritable()) {
        areVmparamsWritable = false;
        vmParamsFilesThatCannotBeWritten.add(file.path);
      }
    }

    if (mounted) {
      setState(() {});
    }
  }
}
