import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid.dart';
import 'package:trios/trios/app_state.dart';

class Smol4 extends ConsumerStatefulWidget {
  const Smol4({super.key});

  @override
  ConsumerState createState() => _Smol4State();
}

class _Smol4State extends ConsumerState<Smol4> {
  @override
  Widget build(BuildContext context) {
    final allMods = ref.watch(AppState.mods);

    return WispGrid(mods: allMods);
  }
}
