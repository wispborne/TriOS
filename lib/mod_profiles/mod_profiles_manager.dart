import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:uuid/uuid.dart';

import 'models/mod_profile.dart';

/// Uses shared preferences to store mod profiles
class ModProfilesSettings {
  static const modProfilesKey = 'modProfiles';

  static List<ModProfile>? _loadFromDisk() {
    try {
      final json = sharedPrefs.getString(modProfilesKey);
      return json == null
          ? null
          : (jsonDecode(json) as List)
              .map((e) => ModProfile.fromJson(e))
              .toList();
    } catch (e) {
      Fimber.e('Failed to load mod profiles from shared prefs', ex: e);
      return null;
    }
  }

  static Future<void> _saveToDisk(List<ModProfile> profiles) async {
    await sharedPrefs.setString(modProfilesKey, jsonEncode(profiles));
  }
}

final modProfilesProvider =
    AsyncNotifierProvider<ModProfileManagerNotifier, ModProfiles>(
        ModProfileManagerNotifier.new);

class ModProfileManagerNotifier extends AsyncNotifier<ModProfiles> {
  static ModProfile defaultModProfile = ModProfile(
    id: const Uuid().v4(),
    name: 'default',
    description: 'Default profile',
    sortOrder: 0,
    enabledModVariants: [],
    dateCreated: DateTime.timestamp(),
    dateModified: DateTime.timestamp(),
  );
  static ModProfiles defaultModProfiles =
      ModProfiles(modProfiles: [defaultModProfile]);

  @override
  Future<ModProfiles> build() async {
    updateFromModList();
    return state.valueOrNull ??
        ModProfiles(
            modProfiles:
                ModProfilesSettings._loadFromDisk() ?? [defaultModProfile]);
  }

  ModProfile getCurrentModProfile() {
    final currentProfileId =
        ref.watch(appSettings.select((s) => s.activeModProfileId));
    return state.valueOrNull?.modProfiles
            .firstWhereOrNull((profile) => profile.id == currentProfileId) ??
        defaultModProfile;
  }

  void updateFromModList() {
    final mods = ref.watch(AppState.mods);
    // final enabledModIds = ref.watch(AppState.enabledModIds).valueOrNull;
    final enabledModVariants = mods
        .map((mod) => mod.findFirstEnabled)
        .whereNotNull()
        .map((variant) => ShallowModVariant.fromModVariant(variant))
        .toList();
    Fimber.d("Updating mod profile with ${enabledModVariants.length} mods");
    updateModProfile(getCurrentModProfile()
        .copyWith(enabledModVariants: enabledModVariants ?? []));
  }

  void createModProfile(
    String name, {
    String description = '',
    int? sortOrder,
    List<ShallowModVariant> enabledModVariants = const [],
  }) {
    final newModProfile = ModProfile(
      id: const Uuid().v4(),
      name: name,
      description: description,
      sortOrder: sortOrder ??
          (state.valueOrNull?.modProfiles.map((e) => e.sortOrder).maxOrNull ??
                  0) +
              1,
      enabledModVariants: enabledModVariants,
      dateCreated: DateTime.now(),
      dateModified: DateTime.now(),
    );
    state = AsyncData(state.valueOrNull?.copyWith(
            modProfiles: [...?state.valueOrNull?.modProfiles, newModProfile]) ??
        ModProfiles(modProfiles: [newModProfile]));
    if (state.valueOrNull != null &&
        state.valueOrNull!.modProfiles.isNotEmpty) {
      ModProfilesSettings._saveToDisk(state.value!.modProfiles);
    }
  }

  void updateModProfile(ModProfile updatedProfile) {
    final startingState = state.valueOrNull ?? defaultModProfiles;

    // if (startingState.modProfiles.none((profile) => profile.id == updatedProfile.id)) {
    //   createModProfile();
    //   return;
    // }

    final newModProfiles = startingState.modProfiles
        .orEmpty()
        .map((profile) =>
            profile.id == updatedProfile.id ? updatedProfile : profile)
        .toList();

    state = AsyncData(startingState.copyWith(modProfiles: newModProfiles));
    ModProfilesSettings._saveToDisk(newModProfiles);
  }

  void removeModProfile(String modProfileId) {
    if (!state.hasValue || state.valueOrNull?.modProfiles.isEmpty == true) {
      return;
    }

    final newModProfiles = state.value!.modProfiles
        .orEmpty()
        .where((profile) => profile.id != modProfileId)
        .toList();
    state = AsyncData(state.value!.copyWith(modProfiles: newModProfiles));
    ModProfilesSettings._saveToDisk(newModProfiles);
  }
}
