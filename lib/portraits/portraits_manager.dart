import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/portraits/portrait_model.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';

import '../models/mod_variant.dart';
import 'portrait_scanner.dart';

// Providers
final isLoadingPortraits = StateProvider<bool>((ref) => false);

final portraitsProvider = StreamProvider<Map<ModVariant?, List<Portrait>>>((
  ref,
) async* {
  // Detects when mods are added or removed, not enabled/disabled
  ref.watch(AppState.variantSmolIds);
  ref.watch(isLoadingPortraits.notifier).state = true;

  final variants = ref
      .read(AppState.mods)
      .map((mod) => mod.findFirstEnabledOrHighestVersion)
      .toList();

  final gameCoreFolder = ref.watch(appSettings.select((s) => s.gameCoreDir));

  if (gameCoreFolder == null) {
    ref.watch(isLoadingPortraits.notifier).state = false;
    return;
  }

  final scanner = PortraitScanner();

  // Scan and yield results progressively
  await for (final result in scanner.scanVariantsStream(
    variants + [null],
    gameCoreFolder,
  )) {
    yield result;
  }

  ref.watch(isLoadingPortraits.notifier).state = false;
});
