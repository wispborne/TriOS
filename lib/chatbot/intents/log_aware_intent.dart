import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/chipper/chipper_state.dart';

/// Mixin for intents that need access to the parsed log file.
mixin LogAwareIntent {
  Ref get ref;

  LogChips? get logChips => ref.read(ChipperState.logRawContents).valueOrNull;

  bool get isLogLoaded => logChips != null;

  static const noLogMessage =
      "No log file has been loaded yet. Make sure your game folder is "
      "configured in Settings.";
}
