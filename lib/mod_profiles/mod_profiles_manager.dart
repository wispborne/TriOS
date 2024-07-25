// import 'dart:async';
// import 'dart:io';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:uuid/uuid.dart';
//
// import 'models/mod_profile.dart';
//
// class UserManager {
//   static  ModProfile defaultModProfile = ModProfile(
//     id: const Uuid().v4(),
//     name: 'default',
//     description: 'Default profile',
//     sortOrder: 0,
//     enabledModVariants: [],
//     dateCreated: DateTime.timestamp(),
//     dateModified:DateTime.timestamp(),
//   );
//
//   final activeProfileProvider = StateNotifierProvider<ActiveProfileNotifier, UserProfile>((ref) {
//     final appConfig = ref.read(appConfigProvider);
//     return ActiveProfileNotifier(appConfig);
//   });
//
//   void updateUserProfile(UserProfile Function(UserProfile) mutator) {
//     ref.read(activeProfileProvider.notifier).updateUserProfile(mutator);
//   }
//
//   void createModProfile(String name, {String description = '', int? sortOrder, List<ShallowModVariant> enabledModVariants = const []}) {
//     ref.read(activeProfileProvider.notifier).createModProfile(name, description: description, sortOrder: sortOrder, enabledModVariants: enabledModVariants);
//   }
//
//   void removeModProfile(String modProfileId) {
//     ref.read(activeProfileProvider.notifier).removeModProfile(modProfileId);
//   }
//
//   void setModFavorited(String modId, bool newFavoriteValue) {
//     ref.read(activeProfileProvider.notifier).setModFavorited(modId, newFavoriteValue);
//   }
//
//   void reloadUser() {
//     ref.read(appConfigProvider).reload();
//   }
// }
//
// class ActiveProfileNotifier extends StateNotifier<UserProfile> {
//   final AppConfig appConfig;
//
//   ActiveProfileNotifier(this.appConfig) : super(UserManager.defaultProfile) {
//     _init();
//   }
//
//   Future<void> _init() async {
//     final profile = await appConfig.getUserProfile() ?? UserManager.defaultProfile;
//     state = UserManager.defaultProfile.merge(preferredObj: profile);
//     appConfig.userProfile = state;
//   }
//
//   void updateUserProfile(UserProfile Function(UserProfile) mutator) {
//     state = mutator(state);
//     appConfig.userProfile = state;
//   }
//
//   void createModProfile(String name, {String description = '', int? sortOrder, List<ShallowModVariant> enabledModVariants = const []}) {
//     final newModProfile = ModProfile(
//       id: Uuid().v4(),
//       name: name,
//       description: description,
//       sortOrder: sortOrder ?? (state.modProfiles.map((e) => e.sortOrder).maxOrNull ?? 0) + 1,
//       enabledModVariants: enabledModVariants,
//       dateCreated: tz.TZDateTime.now(tz.local),
//       dateModified: tz.TZDateTime.now(tz.local),
//     );
//     state = state.copyWith(modProfiles: [...state.modProfiles, newModProfile]);
//     appConfig.userProfile = state;
//   }
//
//   void removeModProfile(String modProfileId) {
//     final newModProfiles = state.modProfiles.where((profile) => profile.id != modProfileId).toList();
//     state = state.copyWith(modProfiles: newModProfiles);
//     appConfig.userProfile = state;
//   }
//
//   void setModFavorited(String modId, bool newFavoriteValue) {
//     final newFavorites = newFavoriteValue
//         ? (state.favoriteMods + [modId]).toSet().toList()
//         : state.favoriteMods.where((id) => id != modId).toList();
//     state = state.copyWith(favoriteMods: newFavorites);
//     appConfig.userProfile = state;
//   }
// }
