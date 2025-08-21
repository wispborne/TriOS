import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class GamePathsSetupController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}
}

class GamePathsSetupState {

}

final pathSetupViewModel =
    AsyncNotifierProvider<GamePathsSetupController, void>(
      GamePathsSetupController.new,
    );
