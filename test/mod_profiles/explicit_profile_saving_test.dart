import 'dart:async';
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:trios/mod_profiles/mod_profile_card.dart';
import 'package:trios/mod_profiles/mod_profiles_manager.dart';
import 'package:trios/mod_profiles/models/mod_profile.dart';
import 'package:trios/models/enabled_mods.dart';
import 'package:trios/models/mod_info.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/models/version.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/data_cache/enabled_mods.dart';
import 'package:trios/trios/mod_variants.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/generic_settings_manager.dart';

import '../riverpod_test_helpers.dart';

void main() {
  final v100 = Version.parse("1.0.0", sanitizeInput: true);
  final v200 = Version.parse("2.0.0", sanitizeInput: true);

  // Keep tests off the real settings file.
  setUpAll(() {
    Constants.configDataFolderPath = Directory.systemTemp.createTempSync(
      'profile_saving_config',
    );
  });

  ModVariant makeVariant(
    String modId,
    Version version, {
    bool hasNonBrickedModInfo = true,
  }) => ModVariant(
    modInfo: ModInfo(id: modId, version: version),
    versionCheckerInfo: null,
    modFolder: Directory(''),
    hasNonBrickedModInfo: hasNonBrickedModInfo,
    gameCoreFolder: Directory(''),
  );

  group('doesLoadoutMatchProfile', () {
    test('exact match', () {
      final variant = makeVariant('modA', v100);
      final profile = makeProfile('p', [
        ShallowModVariant.fromModVariant(variant),
      ]);

      expect(
        ModProfileManagerNotifier.doesLoadoutMatchProfile(profile, [variant]),
        isTrue,
      );
    });

    test('order and display data do not matter', () {
      final a = makeVariant('modA', v100);
      final b = makeVariant('modB', v200);
      // Saved with a different name and no version, but the same variant ids.
      final profile = makeProfile('p', [
        ShallowModVariant(
          modId: 'modB',
          modName: 'A Different Saved Name',
          smolVariantId: b.smolId,
        ),
        ShallowModVariant(modId: 'modA', smolVariantId: a.smolId),
      ]);

      expect(
        ModProfileManagerNotifier.doesLoadoutMatchProfile(profile, [a, b]),
        isTrue,
      );
    });

    test('an extra enabled mod counts as modified', () {
      final a = makeVariant('modA', v100);
      final b = makeVariant('modB', v100);
      final profile = makeProfile('p', [ShallowModVariant.fromModVariant(a)]);

      expect(
        ModProfileManagerNotifier.doesLoadoutMatchProfile(profile, [a, b]),
        isFalse,
      );
    });

    test('a member that is not enabled counts as modified', () {
      final a = makeVariant('modA', v100);
      final b = makeVariant('modB', v100);
      final profile = makeProfile('p', [
        ShallowModVariant.fromModVariant(a),
        ShallowModVariant.fromModVariant(b),
      ]);

      expect(
        ModProfileManagerNotifier.doesLoadoutMatchProfile(profile, [a]),
        isFalse,
      );
    });

    test('a different version of the same mod counts as modified', () {
      final old = makeVariant('modA', v100);
      final newer = makeVariant('modA', v200);
      final profile = makeProfile('p', [ShallowModVariant.fromModVariant(old)]);

      expect(
        ModProfileManagerNotifier.doesLoadoutMatchProfile(profile, [newer]),
        isFalse,
      );
    });

    test('an empty profile matches an empty loadout', () {
      expect(
        ModProfileManagerNotifier.doesLoadoutMatchProfile(
          makeProfile('p', []),
          [],
        ),
        isTrue,
      );
    });
  });

  group('profile tracking', () {
    late ProviderContainer container;
    late _TestEnabledModsNotifier enabledModsNotifier;

    Future<ProviderContainer> makeContainer({
      required List<ModVariant> variants,
      required Set<String> enabledModIds,
      required List<ModProfile> profiles,
      String? trackedProfileId,
      bool modsHaveLoaded = true,
      bool enabledModsHaveLoaded = true,
    }) async {
      final built = createProfileTestContainer(
        variants: variants,
        enabledModIds: enabledModIds,
        profiles: profiles,
        trackedProfileId: trackedProfileId,
        modsHaveLoaded: modsHaveLoaded,
        enabledModsHaveLoaded: enabledModsHaveLoaded,
      );
      await Future.delayed(const Duration(milliseconds: 50));

      enabledModsNotifier = built.read(
        AppState.enabledModsFile.notifier,
      ) as _TestEnabledModsNotifier;
      return built;
    }

    test('waits for the mods folder scan before comparing', () async {
      final a = makeVariant('modA', v100);
      container = await makeContainer(
        variants: [a],
        enabledModIds: {'modA'},
        profiles: [
          makeProfile('p1', [ShallowModVariant.fromModVariant(a)]),
        ],
        trackedProfileId: 'p1',
        modsHaveLoaded: false,
      );

      final status = container.read(trackedProfileStatusProvider);
      expect(status.isLoading, isTrue);
      expect(status.profile, isNull);
    });

    test('waits for the enabled-mods file before comparing', () async {
      final a = makeVariant('modA', v100);
      container = await makeContainer(
        variants: [a],
        enabledModIds: {'modA'},
        profiles: [
          makeProfile('p1', [ShallowModVariant.fromModVariant(a)]),
        ],
        trackedProfileId: 'p1',
        enabledModsHaveLoaded: false,
      );

      expect(container.read(trackedProfileStatusProvider).isLoading, isTrue);
    });

    test(
      'a stored id that names no profile means nothing is tracked',
      () async {
        final a = makeVariant('modA', v100);
        container = await makeContainer(
          variants: [a],
          enabledModIds: {'modA'},
          profiles: [
            makeProfile('p1', [ShallowModVariant.fromModVariant(a)]),
          ],
          trackedProfileId: 'a-profile-that-was-deleted',
        );

        final status = container.read(trackedProfileStatusProvider);
        expect(status.isLoading, isFalse);
        expect(status.isTracking, isFalse);
        expect(status.isModified, isFalse);
      },
    );

    test('a matching loadout is not modified', () async {
      final a = makeVariant('modA', v100);
      container = await makeContainer(
        variants: [a],
        enabledModIds: {'modA'},
        profiles: [
          makeProfile('p1', [ShallowModVariant.fromModVariant(a)]),
        ],
        trackedProfileId: 'p1',
      );

      final status = container.read(trackedProfileStatusProvider);
      expect(status.isTracking, isTrue);
      expect(status.isModified, isFalse);
    });

    test(
      'enabling another mod shows Modified and leaves the profile alone',
      () async {
        final a = makeVariant('modA', v100);
        final b = makeVariant('modB', v100);
        container = await makeContainer(
          variants: [a, b],
          enabledModIds: {'modA'},
          profiles: [
            makeProfile('p1', [ShallowModVariant.fromModVariant(a)]),
          ],
          trackedProfileId: 'p1',
        );
        expect(
          container.read(trackedProfileStatusProvider).isModified,
          isFalse,
        );

        enabledModsNotifier.setEnabledMods({'modA', 'modB'});
        await Future.delayed(const Duration(milliseconds: 50));

        final status = container.read(trackedProfileStatusProvider);
        expect(status.isModified, isTrue);
        expect(
          status.profile!.enabledModVariants.map((m) => m.modId).toList(),
          ['modA'],
        );
      },
    );

    test('Save changes writes the current loadout to the profile', () async {
      final a = makeVariant('modA', v100);
      final b = makeVariant('modB', v100);
      container = await makeContainer(
        variants: [a, b],
        enabledModIds: {'modA', 'modB'},
        profiles: [
          makeProfile('p1', [ShallowModVariant.fromModVariant(a)]),
        ],
        trackedProfileId: 'p1',
      );
      expect(container.read(trackedProfileStatusProvider).isModified, isTrue);

      final saved = await container
          .read(modProfilesProvider.notifier)
          .saveCurrentModListToProfile('p1');

      expect(saved, isTrue);
      final status = container.read(trackedProfileStatusProvider);
      expect(status.isModified, isFalse);
      expect(status.profile!.enabledModVariants.map((m) => m.modId).toSet(), {
        'modA',
        'modB',
      });
      expect(status.profile!.dateModified, isNot(DateTime(2020)));
    });

    test('Save changes reports failure for a profile that is gone', () async {
      final a = makeVariant('modA', v100);
      container = await makeContainer(
        variants: [a],
        enabledModIds: {'modA'},
        profiles: [
          makeProfile('p1', [ShallowModVariant.fromModVariant(a)]),
        ],
        trackedProfileId: 'p1',
      );

      final saved = await container
          .read(modProfilesProvider.notifier)
          .saveCurrentModListToProfile('not-a-profile');

      expect(saved, isFalse);
      expect(
        container
            .read(trackedProfileStatusProvider)
            .profile!
            .enabledModVariants
            .map((m) => m.modId)
            .toList(),
        ['modA'],
      );
    });

    test(
      'Deactivating clears tracking and leaves enabled mods alone',
      () async {
        final a = makeVariant('modA', v100);
        final b = makeVariant('modB', v100);
        container = await makeContainer(
          variants: [a, b],
          enabledModIds: {'modA', 'modB'},
          profiles: [
            makeProfile('p1', [ShallowModVariant.fromModVariant(a)]),
          ],
          trackedProfileId: 'p1',
        );

        await container.read(modProfilesProvider.notifier).stopUsingProfile();

        expect(container.read(appSettings).activeModProfileId, isNull);
        expect(
          container.read(trackedProfileStatusProvider).isTracking,
          isFalse,
        );
        expect(
          container
              .read(AppState.enabledModVariants)
              .map((v) => v.modInfo.id)
              .toSet(),
          {'modA', 'modB'},
        );
        expect(
          container
              .read(modProfilesProvider)
              .value!
              .modProfiles
              .single
              .enabledModVariants
              .map((m) => m.modId)
              .toList(),
          ['modA'],
        );
      },
    );

    test('toggling mods never rewrites the tracked profile', () async {
      final a = makeVariant('modA', v100);
      final b = makeVariant('modB', v100);
      final c = makeVariant('modC', v100);
      container = await makeContainer(
        variants: [a, b, c],
        enabledModIds: {'modA'},
        profiles: [
          makeProfile('p1', [ShallowModVariant.fromModVariant(a)]),
        ],
        trackedProfileId: 'p1',
      );

      final before = container
          .read(modProfilesProvider)
          .value!
          .modProfiles
          .single;

      // One mod at a time, then several at once.
      enabledModsNotifier.setEnabledMods({'modA', 'modB'});
      await Future.delayed(const Duration(milliseconds: 20));
      enabledModsNotifier.setEnabledMods({'modB', 'modC'});
      await Future.delayed(const Duration(milliseconds: 20));
      enabledModsNotifier.setEnabledMods({});
      await Future.delayed(const Duration(milliseconds: 50));

      final after = container
          .read(modProfilesProvider)
          .value!
          .modProfiles
          .single;
      expect(
        after.enabledModVariants.map((m) => m.smolVariantId).toList(),
        before.enabledModVariants.map((m) => m.smolVariantId).toList(),
      );
      expect(after.dateModified, before.dateModified);
      expect(container.read(trackedProfileStatusProvider).isModified, isTrue);
    });
  });

  group('Deactivate dialog', () {
    Future<ProviderContainer> pumpStopHarness(
      WidgetTester tester, {
      required Set<String> enabledModIds,
      required List<ShallowModVariant> profileMembers,
      required List<ModVariant> variants,
    }) async {
      final container = createProfileTestContainer(
        variants: variants,
        enabledModIds: enabledModIds,
        profiles: [makeProfile('p1', profileMembers, name: 'Vanilla+')],
        trackedProfileId: 'p1',
      );
      await tester.pump();
      await tester.pump();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) => TextButton(
                  onPressed: () => ref
                      .read(modProfilesProvider.notifier)
                      .showStopUsingProfileDialog(context),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets('an unchanged profile stops without asking', (tester) async {
      final a = makeVariant('modA', v100);
      final container = await pumpStopHarness(
        tester,
        enabledModIds: {'modA'},
        profileMembers: [ShallowModVariant.fromModVariant(a)],
        variants: [a],
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Save and deactivate'), findsNothing);
      expect(container.read(appSettings).activeModProfileId, isNull);
    });

    testWidgets('a modified loadout offers save, stop, and cancel', (
      tester,
    ) async {
      final a = makeVariant('modA', v100);
      final b = makeVariant('modB', v100);
      await pumpStopHarness(
        tester,
        enabledModIds: {'modA', 'modB'},
        profileMembers: [ShallowModVariant.fromModVariant(a)],
        variants: [a, b],
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Save and deactivate'), findsOneWidget);
      expect(find.text('Deactivate without saving'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('Cancel changes nothing', (tester) async {
      final a = makeVariant('modA', v100);
      final b = makeVariant('modB', v100);
      final container = await pumpStopHarness(
        tester,
        enabledModIds: {'modA', 'modB'},
        profileMembers: [ShallowModVariant.fromModVariant(a)],
        variants: [a, b],
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(container.read(appSettings).activeModProfileId, 'p1');
      expect(
        container
            .read(modProfilesProvider)
            .value!
            .modProfiles
            .single
            .enabledModVariants
            .map((m) => m.modId)
            .toList(),
        ['modA'],
      );
    });

    testWidgets('Stop without saving leaves the profile as it was', (
      tester,
    ) async {
      final a = makeVariant('modA', v100);
      final b = makeVariant('modB', v100);
      final container = await pumpStopHarness(
        tester,
        enabledModIds: {'modA', 'modB'},
        profileMembers: [ShallowModVariant.fromModVariant(a)],
        variants: [a, b],
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Deactivate without saving'));
      await tester.pumpAndSettle();

      expect(container.read(appSettings).activeModProfileId, isNull);
      expect(
        container
            .read(modProfilesProvider)
            .value!
            .modProfiles
            .single
            .enabledModVariants
            .map((m) => m.modId)
            .toList(),
        ['modA'],
      );
      expect(
        container
            .read(AppState.enabledModVariants)
            .map((v) => v.modInfo.id)
            .toSet(),
        {'modA', 'modB'},
      );
    });

    testWidgets('Save and deactivate saves first', (tester) async {
      final a = makeVariant('modA', v100);
      final b = makeVariant('modB', v100);
      final container = await pumpStopHarness(
        tester,
        enabledModIds: {'modA', 'modB'},
        profileMembers: [ShallowModVariant.fromModVariant(a)],
        variants: [a, b],
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save and deactivate'));
      await tester.pumpAndSettle();

      expect(container.read(appSettings).activeModProfileId, isNull);
      expect(
        container
            .read(modProfilesProvider)
            .value!
            .modProfiles
            .single
            .enabledModVariants
            .map((m) => m.modId)
            .toSet(),
        {'modA', 'modB'},
      );
    });
  });

  group('Tracked profile card layout', () {
    Future<void> pumpCard(
      WidgetTester tester, {
      required Set<String> enabledModIds,
      required List<ShallowModVariant> profileMembers,
      required List<ModVariant> variants,
      required double width,
    }) async {
      final container = createProfileTestContainer(
        variants: variants,
        enabledModIds: enabledModIds,
        profiles: [
          makeProfile('p1', profileMembers, name: 'Hello 1.0'),
          makeProfile('p2', const [], name: 'Another'),
        ],
        trackedProfileId: 'p1',
        additionalOverrides: [
          AppState.gameCoreFolder.overrideWith((ref) async => null),
          AppState.isGameRunning.overrideWith((ref) async => false),
        ],
      );
      await tester.pump();
      await tester.pump();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: width,
                  child: ModProfileCard(
                    minHeight: 120,
                    profile: container
                        .read(modProfilesProvider)
                        .value!
                        .modProfiles
                        .first,
                    modProfiles: container
                        .read(modProfilesProvider)
                        .value!
                        .modProfiles,
                    save: null,
                    saves: null,
                    isInitiallyExpanded: false,
                    cardPadding: 8,
                    actualAxisSpacing: 8,
                    axisSpacingForHeightHack: 8,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('a modified tracked card fits the narrowest grid column', (
      tester,
    ) async {
      final a = makeVariant('modA', v100);
      final b = makeVariant('modB', v100);

      await pumpCard(
        tester,
        enabledModIds: {'modA', 'modB'},
        profileMembers: [ShallowModVariant.fromModVariant(a)],
        variants: [a, b],
        width: 340,
      );

      expect(find.text('Modified'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(find.byIcon(Icons.undo), findsOneWidget);
      expect(find.text('Deactivate'), findsOneWidget);
    });

    testWidgets('an unchanged tracked card shows only Deactivate', (
      tester,
    ) async {
      final a = makeVariant('modA', v100);

      await pumpCard(
        tester,
        enabledModIds: {'modA'},
        profileMembers: [ShallowModVariant.fromModVariant(a)],
        variants: [a],
        width: 340,
      );

      expect(find.text('Modified'), findsNothing);
      expect(find.text('Save'), findsNothing);
      expect(find.byIcon(Icons.undo), findsNothing);
      expect(find.text('Deactivate'), findsOneWidget);
    });
  });

  group('Profile switch dialog', () {
    Future<ProviderContainer> pumpSwitchHarness(
      WidgetTester tester, {
      required Set<String> enabledModIds,
      required List<ModVariant> variants,
      required List<ModProfile> profiles,
      required String trackedProfileId,
      required String targetProfileId,
    }) async {
      final container = createProfileTestContainer(
        variants: variants,
        enabledModIds: enabledModIds,
        profiles: profiles,
        trackedProfileId: trackedProfileId,
      );
      await tester.pump();
      await tester.pump();

      ModProfile profileById(WidgetRef ref, String id) => ref
          .read(modProfilesProvider)
          .value!
          .modProfiles
          .firstWhere((p) => p.id == id);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) => Column(
                  children: [
                    TextButton(
                      onPressed: () => ref
                          .read(modProfilesProvider.notifier)
                          .showActivateDialog(
                            profileById(ref, targetProfileId),
                            context,
                          ),
                      child: const Text('switch'),
                    ),
                    TextButton(
                      onPressed: () => ref
                          .read(modProfilesProvider.notifier)
                          .showActivateDialog(
                            profileById(ref, trackedProfileId),
                            context,
                          ),
                      child: const Text('pick tracked'),
                    ),
                    TextButton(
                      onPressed: () => ref
                          .read(modProfilesProvider.notifier)
                          .showRevertDialog(
                            profileById(ref, trackedProfileId),
                            context,
                          ),
                      child: const Text('revert'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets('an unchanged loadout gets one plain confirmation', (
      tester,
    ) async {
      final a = makeVariant('modA', v100);
      final b = makeVariant('modB', v100);
      await pumpSwitchHarness(
        tester,
        enabledModIds: {'modA'},
        variants: [a, b],
        profiles: [
          makeProfile('p1', [ShallowModVariant.fromModVariant(a)], name: 'One'),
          makeProfile('p2', [ShallowModVariant.fromModVariant(b)], name: 'Two'),
        ],
        trackedProfileId: 'p1',
        targetProfileId: 'p2',
      );

      await tester.tap(find.text('switch'));
      await tester.pumpAndSettle();

      expect(find.text("Activate 'Two'?"), findsOneWidget);
      expect(find.text('Activate'), findsOneWidget);
      expect(find.text('Save and activate'), findsNothing);
      expect(find.text('Activate without saving'), findsNothing);
    });

    testWidgets('a modified loadout gets one combined confirmation', (
      tester,
    ) async {
      final a = makeVariant('modA', v100);
      final b = makeVariant('modB', v100);
      await pumpSwitchHarness(
        tester,
        enabledModIds: {'modA', 'modB'},
        variants: [a, b],
        profiles: [
          makeProfile('p1', [ShallowModVariant.fromModVariant(a)], name: 'One'),
          makeProfile('p2', [ShallowModVariant.fromModVariant(b)], name: 'Two'),
        ],
        trackedProfileId: 'p1',
        targetProfileId: 'p2',
      );

      await tester.tap(find.text('switch'));
      await tester.pumpAndSettle();

      // One dialog, holding both the unsaved-changes choice and the changes
      // the target profile would make.
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Save and activate'), findsOneWidget);
      expect(find.text('Activate without saving'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.textContaining('no longer match'), findsOneWidget);
      expect(find.textContaining('Disabling mod'), findsNothing);
    });

    testWidgets('cancelling the combined confirmation saves nothing', (
      tester,
    ) async {
      final a = makeVariant('modA', v100);
      final b = makeVariant('modB', v100);
      final container = await pumpSwitchHarness(
        tester,
        enabledModIds: {'modA', 'modB'},
        variants: [a, b],
        profiles: [
          makeProfile('p1', [ShallowModVariant.fromModVariant(a)], name: 'One'),
          makeProfile('p2', [ShallowModVariant.fromModVariant(b)], name: 'Two'),
        ],
        trackedProfileId: 'p1',
        targetProfileId: 'p2',
      );

      await tester.tap(find.text('switch'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(container.read(appSettings).activeModProfileId, 'p1');
      expect(
        container
            .read(modProfilesProvider)
            .value!
            .modProfiles
            .firstWhere((p) => p.id == 'p1')
            .enabledModVariants
            .map((m) => m.modId)
            .toList(),
        ['modA'],
      );
    });

    testWidgets('a failed save stops the switch', (tester) async {
      final a = makeVariant('modA', v100);
      final b = makeVariant('modB', v100);
      final container = await pumpSwitchHarness(
        tester,
        enabledModIds: {'modA', 'modB'},
        variants: [a, b],
        profiles: [
          makeProfile('p1', [ShallowModVariant.fromModVariant(a)], name: 'One'),
          makeProfile('p2', [ShallowModVariant.fromModVariant(b)], name: 'Two'),
        ],
        trackedProfileId: 'p1',
        targetProfileId: 'p2',
      );

      await tester.tap(find.text('switch'));
      await tester.pumpAndSettle();

      // Make the save fail by removing the profile it would write to.
      container.read(modProfilesProvider.notifier).removeModProfile('p1');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save and activate'));
      await tester.pumpAndSettle();

      // The target profile was not applied.
      expect(container.read(appSettings).activeModProfileId, 'p1');
    });

    testWidgets('picking the profile already in use does nothing', (
      tester,
    ) async {
      final a = makeVariant('modA', v100);
      final b = makeVariant('modB', v100);
      await pumpSwitchHarness(
        tester,
        enabledModIds: {'modA', 'modB'},
        variants: [a, b],
        profiles: [
          makeProfile('p1', [ShallowModVariant.fromModVariant(a)], name: 'One'),
          makeProfile('p2', [ShallowModVariant.fromModVariant(b)], name: 'Two'),
        ],
        trackedProfileId: 'p1',
        targetProfileId: 'p2',
      );

      await tester.tap(find.text('pick tracked'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('Revert reapplies the profile already in use', (tester) async {
      final a = makeVariant('modA', v100);
      final b = makeVariant('modB', v100);
      await pumpSwitchHarness(
        tester,
        enabledModIds: {'modA', 'modB'},
        variants: [a, b],
        profiles: [
          makeProfile('p1', [ShallowModVariant.fromModVariant(a)], name: 'One'),
          makeProfile('p2', [ShallowModVariant.fromModVariant(b)], name: 'Two'),
        ],
        trackedProfileId: 'p1',
        targetProfileId: 'p2',
      );

      await tester.tap(find.text('revert'));
      await tester.pumpAndSettle();

      expect(find.text("Revert to 'One'?"), findsOneWidget);
      expect(find.text('Revert'), findsOneWidget);
      // Reverting is not a switch, so it never offers to save first.
      expect(find.text('Save and activate'), findsNothing);
    });

    testWidgets('missing profile members are not discarded from the profile', (
      tester,
    ) async {
      final a = makeVariant('modA', v100);
      await pumpSwitchHarness(
        tester,
        enabledModIds: {'modA'},
        variants: [a],
        profiles: [
          makeProfile('p1', [ShallowModVariant.fromModVariant(a)], name: 'One'),
          makeProfile('p2', [
            ShallowModVariant(
              modId: 'notInstalled',
              smolVariantId: 'notInstalled-100',
              version: v100,
            ),
          ], name: 'Two'),
        ],
        trackedProfileId: 'p1',
        targetProfileId: 'p2',
      );

      await tester.tap(find.text('switch'));
      await tester.pumpAndSettle();

      expect(find.textContaining('They are still'), findsOneWidget);
      expect(find.textContaining('discarded'), findsNothing);
    });
  });
}

ProviderContainer createProfileTestContainer({
  required List<ModVariant> variants,
  required Set<String> enabledModIds,
  required List<ModProfile> profiles,
  String? trackedProfileId,
  bool modsHaveLoaded = true,
  bool enabledModsHaveLoaded = true,
  List<Override> additionalOverrides = const [],
}) {
  final container = createTestContainer(
    overrides: [
      AppState.modVariants.overrideWith(
        () => _TestModVariantsNotifier(variants, hasScanned: modsHaveLoaded),
      ),
      AppState.enabledModsFile.overrideWith(
        () => _TestEnabledModsNotifier(
          enabledModIds,
          neverFinishesLoading: !enabledModsHaveLoaded,
        ),
      ),
      appSettings.overrideWith(
        () => _TestAppSettingNotifier(
          Settings(activeModProfileId: trackedProfileId),
        ),
      ),
      modProfilesProvider.overrideWith(
        () => _TestModProfileManagerNotifier(profiles),
      ),
      ...additionalOverrides,
    ],
  );
  addTearDown(container.dispose);

  // Keep the lazy providers alive for the test.
  container.listen(AppState.modVariants, (_, _) {});
  container.listen(AppState.enabledModsFile, (_, _) {});
  container.listen(modProfilesProvider, (_, _) {});
  container.listen(trackedProfileStatusProvider, (_, _) {});
  return container;
}

ModProfile makeProfile(
  String id,
  List<ShallowModVariant> members, {
  String name = 'Profile',
}) => ModProfile(
  id: id,
  name: name,
  description: '',
  sortOrder: 0,
  enabledModVariants: members,
  dateCreated: DateTime(2020),
  dateModified: DateTime(2020),
);

/// Mod variants without touching the mods folder.
class _TestModVariantsNotifier extends ModVariantsNotifier {
  _TestModVariantsNotifier(this._variants, {required this.hasScanned});

  final List<ModVariant> _variants;
  final bool hasScanned;

  @override
  Future<List<ModVariant>> build() async {
    hasScannedModsFolder = hasScanned;
    return _variants;
  }
}

/// `enabled_mods.json` without a file behind it.
class _TestEnabledModsNotifier extends EnabledModsNotifier {
  _TestEnabledModsNotifier(this._modIds, {this.neverFinishesLoading = false});

  final Set<String> _modIds;

  /// Stands in for the file not having been read yet.
  final bool neverFinishesLoading;

  @override
  Future<EnabledMods> build() async {
    if (neverFinishesLoading) return Completer<EnabledMods>().future;
    return EnabledMods(_modIds);
  }

  void setEnabledMods(Set<String> modIds) {
    state = AsyncData(EnabledMods(modIds));
  }
}

/// Settings held in memory, so tests never write the real settings file.
class _TestAppSettingNotifier extends AppSettingNotifier {
  _TestAppSettingNotifier(this._initial);

  final Settings _initial;

  @override
  Settings build() => _initial;

  @override
  Future<Settings> update(
    Settings Function(Settings currentState) mutator, {
    Settings Function(Object, StackTrace)? onError,
  }) async {
    state = mutator(state);
    return state;
  }
}

/// Profiles kept in memory, so no test reads or writes a profiles file.
class _TestProfilesSettingsManager extends ModProfilesSettingsManager {
  ModProfiles? _stored;

  @override
  Future<ModProfiles> read(
    ModProfiles fallback, {
    bool forceLoadFromDisk = false,
  }) async => _stored ?? fallback;

  @override
  Future<void> scheduleWrite(ModProfiles newState) async {
    _stored = newState;
  }

  @override
  Future<void> createBackup() async {}

  @override
  Future<DateTime?> lastBackupTime() async => DateTime.now();
}

/// Real profile logic on top of the in-memory store, seeded with [_profiles].
class _TestModProfileManagerNotifier extends ModProfileManagerNotifier {
  _TestModProfileManagerNotifier(this._profiles);

  final List<ModProfile> _profiles;

  @override
  GenericAsyncSettingsManager<ModProfiles> createSettingsManager() =>
      _TestProfilesSettingsManager();

  @override
  Future<ModProfiles> build() async => ModProfiles(modProfiles: _profiles);
}
