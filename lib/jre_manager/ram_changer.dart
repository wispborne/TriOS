import 'package:flutter/material.dart';
import 'package:flutter_color/flutter_color.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:trios/jre_manager/jre_manager_logic.dart';
import 'package:trios/thirdparty/dartx/iterable.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/extensions.dart';
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

  // TODO: Detect when vmparams files are out of sync and show a warning.

  @override
  Widget build(BuildContext context) {
    final jreManager = ref.watch(jreManagerProvider).valueOrNull;
    final activeJres = jreManager?.activeJres;
    final gamePath = ref.read(AppState.gameFolder).valueOrNull?.toDirectory();
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
              final activeJresByGb =
                  activeJres?.groupBy(
                    (jre) =>
                        double.tryParse(
                          jre.ramAmountInMb ?? "",
                        )?.div(mbPerGb.toDouble()) ??
                        0,
                  ) ??
                  {};

              return ConditionalWrap(
                condition: activeJres != null && activeJresByGb[ram] != null,
                wrapper: (child) {
                  final jres = activeJresByGb[ram]!;
                  final firstJre = jres.first;
                  final theme = Theme.of(context);
                  Color color;

                  if (jreManager
                          ?.hasMultipleActiveJresWithDifferentRamAmounts ??
                      false) {
                    final palette = PaletteGenerator.fromColors([
                      PaletteColor(firstJre.toString().toStableColor(), 20),
                      PaletteColor(
                        firstJre.vmParamsFileRelativePath.toStableColor(),
                        20,
                      ),
                    ]);
                    color =
                        (palette.lightVibrantColor?.color ??
                                palette.vibrantColor?.color ??
                                palette.darkVibrantColor?.color)
                            ?.mix(theme.colorScheme.primary, 0.5) ??
                        theme.colorScheme.primary;
                  } else {
                    color = theme.colorScheme.primary;
                  }
                  return MovingTooltipWidget.text(
                    message: jres.joinToString(
                      separator: "\n",
                      transform: (jre) =>
                          "${jre.ramAmountInMb} MB set in ${jre.vmParamsFileAbsolutePath.relativeTo(gamePath)}",
                    ),
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
                        .read(jreManagerProvider.notifier)
                        .changeRamAmount((ram * mbPerGb).toDouble());
                  },
                  child: Text("$ram GB"),
                ),
              );
            },
          );
  }

  Future<void> setWhetherVmParamsAreWritable(JreManagerState newState) async {
    vmParamsFilesThatCannotBeWritten.clear();
    isStandardVmparamsWritable =
        await newState.standardActiveJre?.canWriteToVmParamsFile() ?? false;
    if (!isStandardVmparamsWritable) {
      vmParamsFilesThatCannotBeWritten.add(
        newState.standardActiveJre?.vmParamsFileRelativePath ?? "",
      );
    }
    areAllCustomJresWritable = true;

    for (final customJre in newState.customInstalledJres) {
      // We only care if the vmparams file exists but can't be written to.
      // If it's missing entirely, then the JreEntry will be considered broken and unselectable.
      // This allows users to have random JRE/JDK folders in their game folder that they
      // don't plan to use, without breaking the RAM changer.
      if (customJre.vmParamsFileAbsolutePath.existsSync() &&
          !await customJre.canWriteToVmParamsFile()) {
        areAllCustomJresWritable = false;
        vmParamsFilesThatCannotBeWritten.add(
          customJre.vmParamsFileRelativePath,
        );
        break;
      }
    }

    // Async logic prior, might not be mounted anymore
    if (mounted) {
      setState(() {});
    }
  }
}
