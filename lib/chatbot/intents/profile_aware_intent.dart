import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/mod_profiles/mod_profiles_manager.dart';
import 'package:trios/mod_profiles/models/mod_profile.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';

/// Mixin for intents that need access to mod profile data.
mixin ProfileAwareIntent {
  Ref get ref;

  ModProfiles? get modProfiles =>
      ref.read(modProfilesProvider).valueOrNull;

  ModProfile? get currentProfile {
    final profiles = modProfiles;
    if (profiles == null) return null;
    final activeId = ref.read(appSettings).activeModProfileId;
    if (activeId == null) return null;
    return profiles.modProfiles
        .where((p) => p.id == activeId)
        .firstOrNull;
  }

  static const noProfileDataMessage =
      "No mod profile data available yet.";
}
