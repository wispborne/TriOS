import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/portraits/portrait_model.dart';
import 'package:trios/trios/app_state.dart';

import '../models/mod_variant.dart';
import 'portrait_scanner.dart';

// Providers
final isLoadingPortraits = StateProvider<bool>((ref) => false);

final portraitsProvider = StreamProvider<Map<ModVariant, List<Portrait>>>((
  ref,
) async* {
  ref.watch(isLoadingPortraits.notifier).state = true;

  final variants = ref
      .watch(AppState.mods)
      .map((mod) => mod.findFirstEnabledOrHighestVersion)
      .nonNulls
      .toList();

  final scanner = PortraitScanner();

  // Scan and yield results progressively
  await for (final result in scanner.scanVariantsStream(variants)) {
    yield result;
  }

  ref.watch(isLoadingPortraits.notifier).state = false;
});
