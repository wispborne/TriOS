import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chatbot_engine.dart';
import 'chatbot_models.dart';
import 'intents/app_update_intent.dart';
import 'intents/app_version_intent.dart';
import 'intents/common_issues_intent.dart';
import 'intents/csv_export_intent.dart';
import 'intents/current_profile_intent.dart';
import 'intents/current_ram_info_intent.dart';
import 'intents/current_settings_intent.dart';
import 'intents/disabled_mods_intent.dart';
import 'intents/enabled_mods_intent.dart';
import 'intents/fallback_intent.dart';
import 'intents/find_mods_intent.dart';
import 'intents/game_folder_info_intent.dart';
import 'intents/game_running_intent.dart';
import 'intents/game_version_info_intent.dart';
import 'intents/help_intent.dart';
import 'intents/high_vram_mods_intent.dart';
import 'intents/hullmod_count_intent.dart';
import 'intents/ram_info_intent.dart';
import 'intents/launch_settings_intent.dart';
import 'intents/list_profiles_intent.dart';
import 'intents/log_errors_intent.dart';
import 'intents/log_location_intent.dart';
import 'intents/log_mod_list_intent.dart';
import 'intents/log_summary_intent.dart';
import 'intents/mod_audit_intent.dart';
import 'intents/mod_manager_features_intent.dart';
import 'intents/mod_changelog_intent.dart';
import 'intents/mod_compatibility_intent.dart';
import 'intents/mod_conflicts_intent.dart';
import 'intents/mod_count_intent.dart';
import 'intents/mod_dependencies_intent.dart';
import 'intents/mod_list_intent.dart';
import 'intents/mod_search_intent.dart';
import 'intents/mod_tips_intent.dart';
import 'intents/mod_updates_intent.dart';
import 'intents/mods_by_author_intent.dart';
import 'intents/mods_by_category_intent.dart';
import 'intents/navigate_to_page_intent.dart';
import 'intents/permission_issues_intent.dart';
import 'intents/portrait_stats_intent.dart';
import 'intents/profile_comparison_intent.dart';
import 'intents/ram_allocation_intent.dart';
import 'intents/ram_vs_vram_intent.dart';
import 'intents/recently_added_mods_intent.dart';
import 'intents/ship_count_intent.dart';
import 'intents/total_conversion_mods_intent.dart';
import 'intents/utility_mods_intent.dart';
import 'intents/viewer_stats_intent.dart';
import 'intents/vram_estimate_intent.dart';
import 'intents/weapon_count_intent.dart';

final chatbotControllerProvider =
    AutoDisposeNotifierProvider<ChatbotController, ConversationContext>(
      () => ChatbotController(),
    );

class ChatbotController extends AutoDisposeNotifier<ConversationContext> {
  static ConversationContext _persisted = const ConversationContext();

  late final ChatbotEngine _engine;

  @override
  ConversationContext build() {
    _engine = ChatbotEngine([
      // Register intents here. Order matters for tiebreaking.
      // Higher-priority intents should come first.

      // === Help / Navigation (highest priority) ===
      HelpIntent(),
      NavigateToPageIntent(),

      // === Static informational (no app state needed) ===
      RamVsVramIntent(),
      RamAllocationIntent(),
      CommonIssuesIntent(),
      PermissionIssuesIntent(ref),
      ModManagerFeaturesIntent(),
      CsvExportIntent(),
      FindModsIntent(), // Must be before ModSearchIntent for tiebreaking.

      // === App info ===
      AppVersionIntent(),
      AppUpdateIntent(ref),

      // === Settings-aware intents ===
      GameFolderInfoIntent(ref),
      CurrentSettingsIntent(ref),
      LaunchSettingsIntent(ref),
      GameRunningIntent(ref),

      // === RAM intents ===
      RamInfoIntent(ref),
      CurrentRamInfoIntent(ref),

      // === VRAM intents ===
      VramEstimateIntent(ref),
      HighVramModsIntent(ref),

      // === Profile intents ===
      CurrentProfileIntent(ref),
      ListProfilesIntent(ref),
      ProfileComparisonIntent(ref),

      // === Mod-aware intents (specific first, then general) ===
      ModSearchIntent(ref),
      ModsByAuthorIntent(ref),
      ModDependenciesIntent(ref),
      // ModlistRatingIntent(ref), // too cringe to use
      ModCompatibilityIntent(ref),
      ModConflictsIntent(ref),
      ModUpdatesIntent(ref),
      ModChangelogIntent(ref),
      ModAuditIntent(ref),
      RecentlyAddedModsIntent(ref),
      GameVersionInfoIntent(ref),
      UtilityModsIntent(ref),
      TotalConversionModsIntent(ref),
      ModsByCategoryIntent(ref),
      ModTipsIntent(ref),
      ModCountIntent(ref),
      EnabledModsIntent(ref),
      DisabledModsIntent(ref),
      ModListIntent(ref),

      // === Viewer / data intents ===
      ShipCountIntent(ref),
      WeaponCountIntent(ref),
      HullmodCountIntent(ref),
      ViewerStatsIntent(ref),
      PortraitStatsIntent(ref),

      // === Log-aware intents ===
      LogSummaryIntent(ref),
      LogErrorsIntent(ref),
      LogLocationIntent(ref),
      LogModListIntent(ref),

      // === Fallback (always last) ===
      FallbackIntent(),
    ]);

    return _persisted;
  }

  void sendMessage(String text) {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(
      text: text,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
    );

    final updatedHistory = [...state.history, userMessage];
    final contextForEngine = state.copyWith(history: updatedHistory);

    final response = _engine.process(text, contextForEngine);

    final botMessage = ChatMessage(
      text: response.text,
      sender: MessageSender.bot,
      timestamp: DateTime.now(),
    );

    final newMemory = {
      ...state.memory,
      if (response.memoryUpdates != null) ...response.memoryUpdates!,
    };

    state = state.copyWith(
      history: [...updatedHistory, botMessage],
      lastMatchedIntentId: _lastMatchedId(text, contextForEngine),
      turnCount: state.turnCount + 1,
      memory: newMemory,
    );
    _persisted = state;
  }

  String? _lastMatchedId(String input, ConversationContext context) {
    final normalized = input.toLowerCase().trim();
    String? bestId;
    double bestScore = -1;

    for (final intent in _engine.intents) {
      final score = intent.match(normalized, context);
      if (score > bestScore) {
        bestScore = score;
        bestId = intent.id;
      }
    }

    return bestScore >= ChatbotEngine.matchThreshold ? bestId : 'fallback';
  }

  void clear() {
    state = const ConversationContext();
    _persisted = state;
  }
}
