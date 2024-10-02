import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/jre_manager/jre_manager_logic.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/conditional_wrap.dart';

import '../themes/theme_manager.dart';
import '../trios/app_state.dart';
import '../trios/settings/settings.dart';
import '../utils/platform_paths.dart';
import '../widgets/fixed_height_grid_item.dart';

class RamChanger extends ConsumerStatefulWidget {
  const RamChanger({super.key});

  @override
  ConsumerState createState() => _RamChangerState();
}

class _RamChangerState extends ConsumerState<RamChanger> {
  @override
  Widget build(BuildContext context) {
    final currentRamInMb = ref.watch(currentRamAmountInMb);
    final gamePath =
        ref.read(appSettings.select((value) => value.gameDir))?.toDirectory();
    if (gamePath == null) {
      return const SizedBox();
    }
    var vmparamsFile = getVmparamsFile(gamePath);

    final vmParamsWritable =
        ref.watch(AppState.isVmParamsFileWritable).valueOrNull;
    var isJre23VmparamsWritable =
        ref.watch(AppState.isJre23VmparamsFileWritable).valueOrNull;
    final jre23Vmparams = getJre23VmparamsFile(gamePath);

    var ramChoices = [1.5, 2, 3, 4, 6, 8, 10, 11, 16];
    return (vmParamsWritable == false ||
            (jre23Vmparams.existsSync() && isJre23VmparamsWritable == false))
        ? Text(
            "Cannot write to vmparams file:\n${vmParamsWritable == false ? vmparamsFile.path : jre23Vmparams.path}."
            "\n\nTry running ${Constants.appName} as an administrator.")
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
                    changeRamAmount(ref, (ram * mbPerGb).toDouble());
                  },
                  child: Text("$ram GB"),
                ),
              );
            });
  }
}
