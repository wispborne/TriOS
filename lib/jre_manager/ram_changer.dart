import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/jre_manager/jre_manager_logic.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/conditional_wrap.dart';

import '../themes/theme_manager.dart';
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
    final vmParamsWritable = (vmparamsFile.isWritable());
    final jre23Vmparams = getJre23VmparamsFile(gamePath);

    var ramChoices = [1.5, 2, 3, 4, 6, 8, 10, 11, 16];
    var isJre23VmparamsWritable =
        (ref.watch(appSettings.select((s) => s.useJre23)) ?? false
            ? jre23Vmparams.isWritable()
            : Future.value(true));
    return FutureBuilder(
        future: Future.wait([vmParamsWritable, isJre23VmparamsWritable]),
        builder: (context, builder) {
          return builder.data
                      ?.none((isFileWritable) => isFileWritable == false) ==
                  false
              ? Text(
                  "Cannot write to vmparams file:\n${builder.data?.firstOrNull == false ? vmparamsFile.path : jre23Vmparams.path}.\n\nTry running ${Constants.appName} as an administrator.")
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
                                  double.parse(currentRamInMb.value!) /
                                      mbPerGb) ==
                              ram,
                      wrapper: (child) => Container(
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(ThemeManager.cornerRadius),
                          border: Border.all(
                            width: 2,
                            color:
                                Theme.of(context).colorScheme.primaryFixedDim,
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
        });
  }
}
