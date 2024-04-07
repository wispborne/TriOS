import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/jre_manager/jre_manager_logic.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/conditional_wrap.dart';

import '../trios/trios_theme.dart';
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

    var ramChoices = [1.5, 2, 3, 4, 6, 8, 10, 11, 16];
    return GridView.builder(
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
                        double.parse(currentRamInMb.value!) / mbPerGb) ==
                    ram,
            wrapper: (child) => Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(TriOSTheme.cornerRadius),
                border: Border.all(
                  width: 2,
                  color: Theme.of(context).colorScheme.primary,
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
