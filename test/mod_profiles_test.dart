// import 'dart:io';
//
// import 'package:flutter_test/flutter_test.dart';
// import 'package:collection/collection.dart';
// import 'package:mockito/mockito.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:trios/mod_manager/models/mod.dart';
// import 'package:trios/mod_manager/models/mod_variant.dart';
// import 'package:trios/mod_profiles/mod_profiles_manager.dart';
// import 'package:trios/mod_profiles/models/mod_profile.dart';
// import 'package:trios/models/mod.dart';
// import 'package:trios/models/mod_info.dart';
// import 'package:trios/models/mod_variant.dart';
// import 'package:trios/models/version.dart';
// import 'package:trios/trios/app_state.dart';
// import 'package:trios/mod_manager/mod_profiles_manager.dart';
// import 'package:trios/mod_manager/models/mod_profile.dart';
// import 'package:trios/trios/settings/settings.dart';
//
// void main() {
//   group('ModProfileManagerNotifier - computeModProfileChanges', () {
//     late ProviderContainer container;
//     late ModProfileManagerNotifier modProfileManager;
//     late List<Mod> allMods;
//     late List<ModVariant> allModVariants;
//     late List<ModVariant> enabledModVariants;
//     late ModProfiles modProfiles;
//     late Settings appSettings;
//
//     setUp(() {
//       container = ProviderContainer();
//       modProfileManager = ModProfileManagerNotifier()..ref = container.read;
//
//       // Initialize mods, variants, and profiles
//       allModVariants = [
//         createModVariant('mod1', '1.0.0'),
//         createModVariant('mod1', '1.1.0'),
//         createModVariant('mod2', '2.0.0'),
//         createModVariant('mod3', '3.0.0'),
//       ];
//
//       allMods = [
//         createMod('mod1', [allModVariants[0], allModVariants[1]]),
//         createMod('mod2', [allModVariants[2]]),
//         createMod('mod3', [allModVariants[3]]),
//       ];
//
//       enabledModVariants = [allModVariants[0], allModVariants[2]];
//
//       modProfiles = ModProfiles(modProfiles: [
//         ModProfile(
//           id: 'profile1',
//           name: 'Profile 1',
//           enabledModVariants: [
//             ShallowModVariant.fromModVariant(allModVariants[1]), // mod1 v1.1.0
//             ShallowModVariant.fromModVariant(allModVariants[3]), // mod3 v3.0.0
//           ],
//           description: 'Profile 1 description',
//           sortOrder: 0,
//         ),
//       ]);
//
//       appSettings = Settings(activeModProfileId: null);
//
//       // Mock the necessary providers
//       container = ProviderContainer(
//         overrides: [
//           modProfilesProvider.overrideWithValue(
//               AsyncValue.data(modProfiles)),
//           AppState.mods.overrideWithValue(allMods),
//           AppState.modVariants.overrideWithValue(AsyncValue.data(allModVariants)),
//           AppState.enabledModVariants.overrideWithValue(enabledModVariants),
//           appSettingsProvider.overrideWithValue(appSettings),
//         ],
//       );
//
//       modProfileManager = container.read(modProfilesProvider.notifier);
//       modProfileManager.ref = container.read;
//       modProfileManager.state = AsyncValue.data(modProfiles);
//     });
//
//     test('should compute correct changes when swapping to a new profile', () {
//       final changes = modProfileManager.computeModProfileChanges('profile1');
//
//       expect(changes.length, 3);
//
//       final enableMod3 = changes.firstWhereOrNull(
//               (change) => change.mod?.id == 'mod3' && change.changeType == ModChangeType.enable);
//       expect(enableMod3, isNotNull);
//
//       final disableMod2 = changes.firstWhereOrNull(
//               (change) => change.mod?.id == 'mod2' && change.changeType == ModChangeType.disable);
//       expect(disableMod2, isNotNull);
//
//       final swapMod1 = changes.firstWhereOrNull(
//               (change) => change.mod?.id == 'mod1' && change.changeType == ModChangeType.swap);
//       expect(swapMod1, isNotNull);
//       expect(swapMod1?.fromVariant?.modInfo.version?.toString(), '1.0.0');
//       expect(swapMod1?.toVariant?.modInfo.version?.toString(), '1.1.0');
//     });
//
//     test('should compute no changes when activating the same profile', () {
//       // Set the active profile ID to 'profile1' to simulate it being active
//       appSettings = appSettings.copyWith(activeModProfileId: 'profile1');
//       container.updateOverrides([
//         appSettingsProvider.overrideWithValue(appSettings),
//       ]);
//
//       final changes = modProfileManager.computeModProfileChanges('profile1');
//
//       expect(changes.length, 0);
//     });
//
//     test('should handle enabling a mod not currently enabled', () {
//       // Modify profile to include a mod not currently enabled
//       final newVariant = createModVariant('mod4', '4.0.0');
//       allMods.add(createMod('mod4', [newVariant]));
//       allModVariants.add(newVariant);
//
//       modProfiles = ModProfiles(modProfiles: [
//         ModProfile(
//           id: 'profile2',
//           name: 'Profile 2',
//           enabledModVariants: [
//             ShallowModVariant.fromModVariant(newVariant),
//           ],
//         ),
//       ]);
//
//       modProfileManager.state = AsyncValue.data(modProfiles);
//
//       // Update providers
//       container.updateOverrides([
//         AppState.mods.overrideWithValue(allMods),
//         AppState.modVariants.overrideWithValue(AsyncValue.data(allModVariants)),
//         modProfilesProvider.overrideWithValue(AsyncValue.data(modProfiles)),
//       ]);
//
//       final changes = modProfileManager.computeModProfileChanges('profile2');
//
//       expect(changes.length, 1);
//
//       final enableMod4 = changes.firstWhereOrNull(
//               (change) => change.mod?.id == 'mod4' && change.changeType == ModChangeType.enable);
//       expect(enableMod4, isNotNull);
//     });
//
//     test('should handle disabling a mod not in the profile', () {
//       // Current enabled mods include mod2
//       // Profile does not include mod2
//
//       final changes = modProfileManager.computeModProfileChanges('profile1');
//
//       final disableMod2 = changes.firstWhereOrNull(
//               (change) => change.mod?.id == 'mod2' && change.changeType == ModChangeType.disable);
//       expect(disableMod2, isNotNull);
//     });
//
//     test('should handle no mods to change', () {
//       // Set enabled mods to match the profile
//       enabledModVariants = [allModVariants[1], allModVariants[3]]; // mod1 v1.1.0 and mod3 v3.0.0
//       container.updateOverrides([
//         AppState.enabledModVariants.overrideWithValue(enabledModVariants),
//       ]);
//
//       final changes = modProfileManager.computeModProfileChanges('profile1');
//
//       expect(changes.length, 0);
//     });
//   });
// }
//
// // Helper functions to create Mod and ModVariant instances
// Mod createMod(String id, List<ModVariant> variants) {
//   return Mod(
//     id: id,
//     isEnabledInGame: true,
//     modVariants: variants,
//   );
// }
//
// ModVariant createModVariant(String modId, String version) {
//   final modInfo = ModInfo(
//     id: modId,
//     name: 'Mod $modId',
//     version: Version.parse(version, sanitizeInput: false),
//   );
//   return ModVariant(
//     modInfo: modInfo,
//     versionCheckerInfo: null,
//     modFolder: Directory('/path/to/$modId/$version'),
//     hasNonBrickedModInfo: true,
//   );
// }
