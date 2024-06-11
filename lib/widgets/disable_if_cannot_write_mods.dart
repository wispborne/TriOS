import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/widgets/conditional_wrap.dart';
import 'package:trios/widgets/disable.dart';

import '../trios/app_state.dart';

class DisableIfCannotWriteMods extends ConsumerStatefulWidget {
  final Widget child;

  const DisableIfCannotWriteMods({super.key, required this.child});

  @override
  ConsumerState createState() => _DisableIfCannotWriteModsState();
}

class _DisableIfCannotWriteModsState
    extends ConsumerState<DisableIfCannotWriteMods> {
  @override
  Widget build(BuildContext context) {
    final canWriteMods = ref.watch(AppState.canWriteToModsFolder).value ?? true;

    return ConditionalWrap(
        condition: !canWriteMods,
        wrapper: (child) => Tooltip(
              message:
                  "Cannot modify mods folder.\nTry running ${Constants.appName} as administrator and make sure that mods/enabled_mods.json exists and can be modified.",
              child: Disable(isEnabled: false, child: child),
            ),
        child: widget.child);
  }
}
