import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid.dart';
import 'package:trios/mod_manager/mod_summary_panel.dart';
import 'package:trios/trios/app_state.dart';

import '../models/mod.dart';

class Smol4 extends ConsumerStatefulWidget {
  const Smol4({super.key});

  @override
  ConsumerState createState() => _Smol4State();
}

class _Smol4State extends ConsumerState<Smol4> {
  Mod? selectedMod;

  @override
  Widget build(BuildContext context) {
    final allMods = ref.watch(AppState.mods);

    return Stack(
      children: [
        WispGrid(
            mods: allMods,
            onModRowSelected: (mod) {
              setState(() {
                if (selectedMod == mod) {
                  selectedMod = null;
                } else {
                  selectedMod = mod;
                }
              });
            }),
        if (selectedMod != null)
          Align(
            alignment: Alignment.topRight,
            child: SizedBox(
              width: 400,
              child: ModSummaryPanel(
                selectedMod,
                () {
                  setState(() {
                    selectedMod = null;
                  });
                },
              ),
            ),
          ),
      ],
    );
  }
}
