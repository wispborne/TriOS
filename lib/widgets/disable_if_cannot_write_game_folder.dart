import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/widgets/conditional_wrap.dart';
import 'package:trios/widgets/disable.dart';

import '../trios/app_state.dart';

class DisableIfCannotWriteGameFolder extends ConsumerStatefulWidget {
  final Widget child;

  const DisableIfCannotWriteGameFolder({super.key, required this.child});

  @override
  ConsumerState createState() => _DisableIfCannotWriteGameFolderState();
}

class _DisableIfCannotWriteGameFolderState
    extends ConsumerState<DisableIfCannotWriteGameFolder> {
  @override
  Widget build(BuildContext context) {
    final canWrite = ref.watch(AppState.canWriteToModsFolder).value ?? true;
    return ConditionalWrap(
      condition: !canWrite,
      wrapper:
          (child) => Tooltip(
            message:
                "Cannot modify game folder and/or vmparams.\nTry running ${Constants.appName} as administrator.",
            child: Disable(isEnabled: false, child: child),
          ),
      child: widget.child,
    );
  }
}
