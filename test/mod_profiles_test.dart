import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trios/mod_profiles/mod_profiles_manager.dart';
import 'package:trios/mod_profiles/models/mod_profile.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/models/mod_info.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/models/version.dart';

void main() {
  group('computeModProfileChanges', () {
    test('enables mod if it exists in profile but not currently enabled', () {
      final version = Version.parse("1.0.0", sanitizeInput: true);

      final allMods = [
        Mod(
          id: 'modA',
          isEnabledInGame: false,
          modVariants: [
            ModVariant(
              modInfo: ModInfo(id: 'modA', version: version),
              versionCheckerInfo: null,
              modFolder: Directory(''),
              hasNonBrickedModInfo: true,
              gameCoreFolder: Directory(''),
            ),
          ],
        ),
      ];

      final modVariants = [
        ModVariant(
          modInfo: ModInfo(id: 'modA', version: version),
          versionCheckerInfo: null,
          modFolder: Directory(''),
          hasNonBrickedModInfo: true,
          gameCoreFolder: Directory(''),
        ),
      ];

      final currentlyEnabledVariants = <ModVariant>[];

      final smolId = createSmolId('modA', version);

      final profile = ModProfile(
        id: 'profile1',
        name: 'Profile 1',
        description: '',
        sortOrder: 1,
        enabledModVariants: [
          ShallowModVariant(
            modId: 'modA',
            smolVariantId: smolId,
            version: version,
          ),
        ],
      );

      final changes = ModProfileManagerNotifier.computeModProfileChanges(
        profile,
        allMods,
        modVariants,
        currentlyEnabledVariants,
      );

      expect(changes, hasLength(1));
      expect(changes.first.changeType, ModChangeType.enable);
      expect(changes.first.modId, 'modA');
    });

    test('disables mod if currently enabled but not in profile', () {
      final allMods = [
        Mod(
          id: 'modA',
          isEnabledInGame: true,
          modVariants: [
            ModVariant(
              modInfo: ModInfo(
                id: 'modA',
                version: Version.parse("1.0.0", sanitizeInput: true),
              ),
              versionCheckerInfo: null,
              modFolder: Directory(''),
              hasNonBrickedModInfo: true,
              gameCoreFolder: Directory(''),
            ),
          ],
        ),
      ];

      final modVariants = [
        ModVariant(
          modInfo: ModInfo(
            id: 'modA',
            version: Version.parse("1.0.0", sanitizeInput: true),
          ),
          versionCheckerInfo: null,
          modFolder: Directory(''),
          hasNonBrickedModInfo: true,
          gameCoreFolder: Directory(''),
        ),
      ];

      // This variant is currently enabled
      final currentlyEnabledVariants = [
        ModVariant(
          modInfo: ModInfo(
            id: 'modA',
            version: Version.parse("1.0.0", sanitizeInput: true),
          ),
          versionCheckerInfo: null,
          modFolder: Directory(''),
          hasNonBrickedModInfo: true,
          gameCoreFolder: Directory(''),
        ),
      ];

      // Profile is empty (doesn't contain modA)
      final profile = ModProfile(
        id: 'profile1',
        name: 'Profile 1',
        description: '',
        sortOrder: 1,
        enabledModVariants: [],
      );

      final changes = ModProfileManagerNotifier.computeModProfileChanges(
        profile,
        allMods,
        modVariants,
        currentlyEnabledVariants,
      );

      expect(changes, hasLength(1));
      expect(changes.first.changeType, ModChangeType.disable);
      expect(changes.first.modId, 'modA');
    });

    test('swaps mod variant if different version exists in profile', () {
      final oldVersion = Version.parse("1.0.0", sanitizeInput: true);
      final newVersion = Version.parse("1.1.0", sanitizeInput: true);

      final allMods = [
        Mod(
          id: 'modA',
          isEnabledInGame: true,
          modVariants: [
            ModVariant(
              modInfo: ModInfo(id: 'modA', version: oldVersion),
              versionCheckerInfo: null,
              modFolder: Directory(''),
              hasNonBrickedModInfo: true,
              gameCoreFolder: Directory(''),
            ),
            ModVariant(
              modInfo: ModInfo(id: 'modA', version: newVersion),
              versionCheckerInfo: null,
              modFolder: Directory(''),
              hasNonBrickedModInfo: true,
              gameCoreFolder: Directory(''),
            ),
          ],
        ),
      ];

      // Include BOTH variants here so computeModProfileChanges can resolve fromVariant and toVariant.
      final modVariants = [
        ModVariant(
          modInfo: ModInfo(id: 'modA', version: oldVersion),
          versionCheckerInfo: null,
          modFolder: Directory(''),
          hasNonBrickedModInfo: true,
          gameCoreFolder: Directory(''),
        ),
        ModVariant(
          modInfo: ModInfo(id: 'modA', version: newVersion),
          versionCheckerInfo: null,
          modFolder: Directory(''),
          hasNonBrickedModInfo: true,
          gameCoreFolder: Directory(''),
        ),
      ];

      // Currently enabled is the old version
      final currentlyEnabledVariants = [
        ModVariant(
          modInfo: ModInfo(id: 'modA', version: oldVersion),
          versionCheckerInfo: null,
          modFolder: Directory(''),
          hasNonBrickedModInfo: true,
          gameCoreFolder: Directory(''),
        ),
      ];

      final newSmolId = createSmolId('modA', newVersion);

      final profile = ModProfile(
        id: 'profile1',
        name: 'Profile 1',
        description: '',
        sortOrder: 1,
        enabledModVariants: [
          ShallowModVariant(
            modId: 'modA',
            smolVariantId: newSmolId,
            version: newVersion,
          ),
        ],
      );

      final changes = ModProfileManagerNotifier.computeModProfileChanges(
        profile,
        allMods,
        modVariants,
        currentlyEnabledVariants,
      );

      expect(changes, hasLength(1));
      expect(changes.first.changeType, ModChangeType.swap);
      expect(changes.first.modId, 'modA');
      expect(changes.first.fromVariant?.modInfo.version, oldVersion);
      expect(changes.first.toVariant?.modInfo.version, newVersion);
    });

    test('detects missing mod in profile', () {
      final allMods = <Mod>[];
      final modVariants = <ModVariant>[];
      final currentlyEnabledVariants = <ModVariant>[];

      final profile = ModProfile(
        id: 'profile1',
        name: 'Profile 1',
        description: '',
        sortOrder: 1,
        enabledModVariants: [
          ShallowModVariant(
            modId: 'modA',
            smolVariantId: 'modA-100',
            version: Version.parse("1.0.0", sanitizeInput: true),
          ),
        ],
      );

      final changes = ModProfileManagerNotifier.computeModProfileChanges(
        profile,
        allMods,
        modVariants,
        currentlyEnabledVariants,
      );

      expect(changes, hasLength(1));
      expect(changes.first.changeType, ModChangeType.missingMod);
      expect(changes.first.modId, 'modA');
    });

    // -------------------------- MORE RIGOROUS TESTS BELOW --------------------------

    test(
      'missing variant if mod is present but variant not found in modVariants',
      () {
        final version = Version.parse("1.0.0", sanitizeInput: true);

        final allMods = [
          Mod(
            id: 'modA',
            isEnabledInGame: true,
            modVariants: [
              ModVariant(
                modInfo: ModInfo(id: 'modA', version: version),
                versionCheckerInfo: null,
                modFolder: Directory(''),
                hasNonBrickedModInfo: true,
                gameCoreFolder: Directory(''),
              ),
            ],
          ),
        ];

        final existingSmolId = createSmolId('modA', version);
        final modVariants = [
          ModVariant(
            modInfo: ModInfo(id: 'modA', version: version),
            versionCheckerInfo: null,
            modFolder: Directory(''),
            hasNonBrickedModInfo: true,
            gameCoreFolder: Directory(''),
          ),
        ];

        final currentlyEnabledVariants = [
          ModVariant(
            modInfo: ModInfo(id: 'modA', version: version),
            versionCheckerInfo: null,
            modFolder: Directory(''),
            hasNonBrickedModInfo: true,
            gameCoreFolder: Directory(''),
          ),
        ];

        // Make a guaranteed-nonexistent smolId. (Don't rely on replaceAll("100", ...) – smol IDs aren't shaped that way.)
        final profileVariantSmolId = '${existingSmolId}__does_not_exist';

        final profile = ModProfile(
          id: 'profile1',
          name: 'Profile 1',
          description: '',
          sortOrder: 1,
          enabledModVariants: [
            ShallowModVariant(
              modId: 'modA',
              smolVariantId: profileVariantSmolId,
              version: version,
            ),
          ],
        );

        final changes = ModProfileManagerNotifier.computeModProfileChanges(
          profile,
          allMods,
          modVariants,
          currentlyEnabledVariants,
        );

        expect(changes, hasLength(1));
        expect(changes.first.changeType, ModChangeType.missingVariant);
        expect(changes.first.modId, 'modA');
      },
    );

    test('handles multiple mods with mixed changes in one profile activation', () {
      final v100 = Version.parse("1.0.0", sanitizeInput: true);
      final v110 = Version.parse("1.1.0", sanitizeInput: true);
      final v200 = Version.parse("2.0.0", sanitizeInput: true);

      // 1) modA is disabled in the current set but present in the profile -> Should enable
      // 2) modB is currently enabled but not in the profile -> Should disable
      // 3) modC is currently enabled on old version, profile wants a newer version -> Should swap
      // 4) modD is missing entirely -> Should be missingMod
      // 5) modE is present, but the requested variant doesn't exist -> missingVariant

      final allMods = [
        // modA (has v1.0.0)
        Mod(
          id: 'modA',
          isEnabledInGame: false, // Not currently enabled
          modVariants: [
            ModVariant(
              modInfo: ModInfo(id: 'modA', version: v100),
              versionCheckerInfo: null,
              modFolder: Directory(''),
              hasNonBrickedModInfo: true,
              gameCoreFolder: Directory(''),
            ),
          ],
        ),
        // modB (has v1.0.0, currently enabled)
        Mod(
          id: 'modB',
          isEnabledInGame: true, // Will need to disable
          modVariants: [
            ModVariant(
              modInfo: ModInfo(id: 'modB', version: v100),
              versionCheckerInfo: null,
              modFolder: Directory(''),
              hasNonBrickedModInfo: true,
              gameCoreFolder: Directory(''),
            ),
          ],
        ),
        // modC (currently enabled on v1.0.0, we want to swap to v1.1.0)
        Mod(
          id: 'modC',
          isEnabledInGame: true,
          modVariants: [
            ModVariant(
              modInfo: ModInfo(id: 'modC', version: v100),
              versionCheckerInfo: null,
              modFolder: Directory(''),
              hasNonBrickedModInfo: true,
              gameCoreFolder: Directory(''),
            ),
            ModVariant(
              modInfo: ModInfo(id: 'modC', version: v110),
              versionCheckerInfo: null,
              modFolder: Directory(''),
              hasNonBrickedModInfo: true,
              gameCoreFolder: Directory(''),
            ),
          ],
        ),
        // modD doesn't exist in allMods -> missingMod
        // modE is defined below with only one variant that is v2.0.0
        Mod(
          id: 'modE',
          isEnabledInGame: false,
          modVariants: [
            ModVariant(
              modInfo: ModInfo(id: 'modE', version: v200),
              versionCheckerInfo: null,
              modFolder: Directory(''),
              hasNonBrickedModInfo: true,
              gameCoreFolder: Directory(''),
            ),
          ],
        ),
      ];

      final modVariants = [
        // The actual variants we know about in the system
        ModVariant(
          modInfo: ModInfo(id: 'modA', version: v100),
          versionCheckerInfo: null,
          modFolder: Directory(''),
          hasNonBrickedModInfo: true,
          gameCoreFolder: Directory(''),
        ),
        ModVariant(
          modInfo: ModInfo(id: 'modB', version: v100),
          versionCheckerInfo: null,
          modFolder: Directory(''),
          hasNonBrickedModInfo: true,
          gameCoreFolder: Directory(''),
        ),
        ModVariant(
          modInfo: ModInfo(id: 'modC', version: v100),
          versionCheckerInfo: null,
          modFolder: Directory(''),
          hasNonBrickedModInfo: true,
          gameCoreFolder: Directory(''),
        ),
        ModVariant(
          modInfo: ModInfo(id: 'modC', version: v110),
          versionCheckerInfo: null,
          modFolder: Directory(''),
          hasNonBrickedModInfo: true,
          gameCoreFolder: Directory(''),
        ),
        ModVariant(
          modInfo: ModInfo(id: 'modE', version: v200),
          versionCheckerInfo: null,
          modFolder: Directory(''),
          hasNonBrickedModInfo: true,
          gameCoreFolder: Directory(''),
        ),
      ];

      // Currently enabled:
      // - modB (v1.0.0)
      // - modC (v1.0.0)
      final currentlyEnabledVariants = [
        ModVariant(
          modInfo: ModInfo(id: 'modB', version: v100),
          versionCheckerInfo: null,
          modFolder: Directory(''),
          hasNonBrickedModInfo: true,
          gameCoreFolder: Directory(''),
        ),
        ModVariant(
          modInfo: ModInfo(id: 'modC', version: v100),
          versionCheckerInfo: null,
          modFolder: Directory(''),
          hasNonBrickedModInfo: true,
          gameCoreFolder: Directory(''),
        ),
      ];

      // Construct the smol IDs
      final aSmol = createSmolId('modA', v100);
      final cNewSmol = createSmolId('modC', v110);
      // For modE, we'll request a variant smolId that doesn't exist, even though v2.0.0 is known.
      // That means we get missingVariant for modE.
      final eWrongSmol = createSmolId('modE', v200).replaceAll("2", "9");

      final profile = ModProfile(
        id: 'profileX',
        name: 'Mixed Changes Profile',
        description:
            'Enables modA, disables modB, swaps modC, missing modD, missingVariant modE',
        sortOrder: 42,
        enabledModVariants: [
          // 1) enable modA (v1.0.0)
          ShallowModVariant(modId: 'modA', smolVariantId: aSmol, version: v100),
          // 2) modB is absent -> results in disable
          // 3) swap modC from v1.0.0 to v1.1.0
          ShallowModVariant(
            modId: 'modC',
            smolVariantId: cNewSmol,
            version: v110,
          ),
          // 4) missing modD
          ShallowModVariant(
            modId: 'modD',
            smolVariantId: 'modD-100',
            version: v100,
          ),
          // 5) missing variant for modE
          ShallowModVariant(
            modId: 'modE',
            smolVariantId: eWrongSmol,
            version: v200,
          ),
        ],
      );

      final changes = ModProfileManagerNotifier.computeModProfileChanges(
        profile,
        allMods,
        modVariants,
        currentlyEnabledVariants,
      );

      // Expecting:
      //  - enable modA
      //  - disable modB
      //  - swap modC
      //  - missingMod for modD
      //  - missingVariant for modE
      expect(changes, hasLength(5));

      final enable = changes.firstWhere(
        (c) => c.changeType == ModChangeType.enable,
      );
      expect(enable.modId, 'modA');

      final disable = changes.firstWhere(
        (c) => c.changeType == ModChangeType.disable,
      );
      expect(disable.modId, 'modB');

      final swap = changes.firstWhere(
        (c) => c.changeType == ModChangeType.swap,
      );
      expect(swap.modId, 'modC');

      final missingMod = changes.firstWhere(
        (c) => c.changeType == ModChangeType.missingMod,
      );
      expect(missingMod.modId, 'modD');

      final missingVariant = changes.firstWhere(
        (c) => c.changeType == ModChangeType.missingVariant,
      );
      expect(missingVariant.modId, 'modE');
    });
  });
}
