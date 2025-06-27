import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/portraits/portrait_model.dart';
import 'package:trios/trios/app_state.dart';

import '../models/mod_variant.dart';
import 'portrait_replacements_manager.dart';
import 'portrait_scanner.dart';

// Providers
final isLoadingPortraits = StateProvider<bool>((ref) => false);
final portraitReplacementsProvider = StateProvider<Map<String, String>>(
  (ref) => {},
);

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
  final replacementsManager = PortraitReplacementsManager();

  // Load existing replacements
  final replacements = await replacementsManager.loadReplacements();
  ref.read(portraitReplacementsProvider.notifier).state = replacements;

  // Scan and yield results progressively
  await for (final result in scanner.scanVariantsStream(variants)) {
    yield result;
  }

  ref.watch(isLoadingPortraits.notifier).state = false;
});

// Global manager instance
final portraitsManager = PortraitsManager();

/// Main portraits manager - coordinates scanning and replacements
class PortraitsManager {
  final _scanner = PortraitScanner();
  final _replacementsManager = PortraitReplacementsManager();

  Future<Map<ModVariant, List<Portrait>>> scanModFolders(
    List<ModVariant> variants,
  ) {
    return _scanner.scanVariants(variants);
  }

  Future<void> saveReplacement(String originalHash, String replacementPath) {
    return _replacementsManager.saveReplacement(originalHash, replacementPath);
  }

  Future<void> removeReplacement(String originalHash) {
    return _replacementsManager.removeReplacement(originalHash);
  }

  Future<String?> getReplacement(String portraitHash) {
    return _replacementsManager.getReplacement(portraitHash);
  }
}
