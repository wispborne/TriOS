import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/mod_manager/version_checker.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/mod_metadata.dart';

import '../chatbot_models.dart';

/// Mixin for intents that need access to mod data via Riverpod providers.
mixin ModAwareIntent {
  Ref get ref;

  List<Mod> get mods => ref.read(AppState.mods);

  List<ModVariant> get enabledModVariants =>
      ref.read(AppState.enabledModVariants);

  Map<SmolId, DependencyCheck> get modCompatibility =>
      ref.read(AppState.modCompatibility);

  VersionCheckerState? get versionCheckResults =>
      ref.read(AppState.versionCheckResults).valueOrNull;

  String? get starsectorVersion =>
      ref.read(AppState.starsectorVersion).valueOrNull;

  ModsMetadata? get modsMetadata =>
      ref.read(AppState.modsMetadata).valueOrNull;

  bool get isModDataLoaded => mods.isNotEmpty;

  static const noModDataMessage =
      "No mod data available yet. Make sure your game folder is "
      "configured in Settings.";

  /// Standard keyword-based scoring used by all mod intents.
  static double scoreInput(
    String input,
    List<String> phrases,
    Map<String, double> primaryKeywords,
    Map<String, double> secondaryKeywords, {
    double contextBonus = 0.0,
  }) {
    for (final phrase in phrases) {
      if (input.contains(phrase)) return 0.85;
    }

    var score = 0.0;
    for (final entry in primaryKeywords.entries) {
      if (input.contains(entry.key)) score += entry.value;
    }
    for (final entry in secondaryKeywords.entries) {
      if (input.contains(entry.key)) score += entry.value;
    }

    score += contextBonus;
    return score.clamp(0.0, 0.95);
  }

  /// Guard that returns a "no data" response if mods aren't loaded.
  ChatResponse? guardModData() {
    if (!isModDataLoaded) {
      return const ChatResponse(text: ModAwareIntent.noModDataMessage);
    }
    return null;
  }
}
