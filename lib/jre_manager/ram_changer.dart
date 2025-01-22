import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/jre_manager/jre_manager_logic.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/conditional_wrap.dart';

import '../themes/theme_manager.dart';
import '../widgets/fixed_height_grid_item.dart';

class RamChanger extends ConsumerStatefulWidget {
  const RamChanger({super.key});

  @override
  ConsumerState createState() => _RamChangerState();
}

class _RamChangerState extends ConsumerState<RamChanger> {
  bool isStandardVmparamsWritable = false;
  bool areAllCustomJresWritable = false;
  final List<String> vmParamsFilesThatCannotBeWritten = [];

  @override
  void initState() {
    super.initState();
    final jreManager = ref.read(jreManagerProvider).valueOrNull;
    if (jreManager != null) {
      setWhetherVmParamsAreWritable(jreManager);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentRamInMb = ref.watch(currentRamAmountInMb);
    final gamePath =
        ref.read(appSettings.select((value) => value.gameDir))?.toDirectory();
    if (gamePath == null) {
      return const SizedBox();
    }

    ref.listen(jreManagerProvider, (prev, next) async {
      final newState = next.valueOrNull;
      if (newState != null && prev?.valueOrNull != newState) {
        await setWhetherVmParamsAreWritable(newState);
      }
    });

    final ramChoices = [1.5, 2, 3, 4, 6, 8, 10, 11, 16];
    return (isStandardVmparamsWritable == false ||
            areAllCustomJresWritable == false)
        ? Text(
            "Cannot write to vmparams file:\n${vmParamsFilesThatCannotBeWritten.join("\n")}."
            "\n\nMake sure it exists or try running ${Constants.appName} as an administrator.",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ThemeManager.vanillaWarningColor,
                ),
          )
        : GridView.builder(
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
              return ConditionalWrap(
                condition: currentRamInMb.value != null &&
                    ramChoices.findClosest(
                            double.tryParse(currentRamInMb.value!)
                                    ?.div(mbPerGb.toDouble()) ??
                                0) ==
                        ram,
                wrapper: (child) => Container(
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(ThemeManager.cornerRadius),
                    border: Border.all(
                      width: 2,
                      color: Theme.of(context).colorScheme.primaryFixedDim,
                    ),
                  ),
                  child: child,
                ),
                child: ElevatedButton(
                  onPressed: () {
                    ref
                        .read(jreManagerProvider.notifier)
                        .changeRamAmount((ram * mbPerGb).toDouble());
                  },
                  child: Text("$ram GB"),
                ),
              );
            });
  }

  Future<void> setWhetherVmParamsAreWritable(JreManagerState newState) async {
    vmParamsFilesThatCannotBeWritten.clear();
    isStandardVmparamsWritable =
        await newState.standardActiveJre?.canWriteToVmParamsFile() ?? false;
    if (!isStandardVmparamsWritable) {
      vmParamsFilesThatCannotBeWritten
          .add(newState.standardActiveJre?.vmParamsFileRelativePath ?? "");
    }
    areAllCustomJresWritable = true;

    for (final customJre in newState.customInstalledJres) {
      if (!await customJre.canWriteToVmParamsFile()) {
        areAllCustomJresWritable = false;
        vmParamsFilesThatCannotBeWritten
            .add(customJre.vmParamsFileRelativePath);
        break;
      }
    }

    // Async logic prior, might not be mounted anymore
    if (mounted) {
      setState(() {});
    }
  }
}
