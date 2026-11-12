import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trios/mod_manager/homebrew_grid/wispgrid_group.dart';
import 'package:trios/mod_manager/mods_grid_page_controller.dart';
import 'package:trios/mod_tag_manager/category.dart';
import 'package:trios/mod_tag_manager/category_manager.dart';
import 'package:trios/mod_tag_manager/category_store.dart';
import 'package:trios/mod_tag_manager/mod_category_assignment.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/models/mod_info.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/models/version.dart';
import 'package:trios/trios/app_state.dart';

class _InMemoryCategoryNotifier extends CategoryManagerNotifier {
  _InMemoryCategoryNotifier(this.initial);

  final CategoryStore initial;

  @override
  Future<CategoryStore> build() async => initial;

  @override
  Future<CategoryStore> updateState(
    FutureOr<CategoryStore> Function(CategoryStore currentState) mutator, {
    FutureOr<CategoryStore> Function(Object, StackTrace)? onError,
    bool skipChangeCheck = false,
  }) async {
    final updated = await mutator(state.requireValue);
    state = AsyncData(updated);
    return updated;
  }
}

Mod _mod(String id) => Mod(
  id: id,
  isEnabledInGame: true,
  modVariants: [
    ModVariant(
      modInfo: ModInfo(id: id, name: id, version: Version.parse('1.0.0')),
      versionCheckerInfo: null,
      modFolder: Directory('test_mod_$id'),
      hasNonBrickedModInfo: true,
      gameCoreFolder: Directory('test_game_core'),
    ),
  ],
);

const _graphics = Category(
  id: 'graphics',
  name: 'Graphics',
  isUserCreated: true,
  sortOrder: 0,
);
const _favorites = Category(
  id: 'favorites',
  name: 'Favorites',
  isUserCreated: true,
  sortOrder: 1,
);

const _store = CategoryStore(
  categories: [_graphics, _favorites],
  modAssignments: {
    'both_categories': [
      ModCategoryAssignment(categoryId: 'graphics', isPrimary: true),
      ModCategoryAssignment(categoryId: 'favorites'),
    ],
    'graphics_only': [
      ModCategoryAssignment(categoryId: 'graphics', isPrimary: true),
    ],
  },
);

void main() {
  group('category: search', () {
    late ProviderContainer container;

    List<String> search(String query) {
      container
          .read(modsGridSearchControllerProvider.notifier)
          .updateSearchQuery(query);
      return container
          .read(modsGridSearchControllerProvider)
          .filteredMods
          .map((m) => m.id)
          .toList();
    }

    setUp(() async {
      container = ProviderContainer(
        overrides: [
          AppState.mods.overrideWithValue([
            _mod('both_categories'),
            _mod('graphics_only'),
            _mod('no_category'),
          ]),
          categoryManagerProvider.overrideWith(
            () => _InMemoryCategoryNotifier(_store),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.listen(modsGridSearchControllerProvider, (_, _) {});
      container.listen(categoryManagerProvider, (_, _) {});
      await pumpEventQueue();
    });

    test('finds a mod by a category that is not its primary one', () {
      expect(search('category:favorites'), ['both_categories']);
    });

    test('still finds a mod by its primary category', () {
      expect(search('category:graphics'), ['both_categories', 'graphics_only']);
    });

    test('matches part of a category name, ignoring case', () {
      expect(search('category:FAV'), ['both_categories']);
    });

    test('a minus sign excludes mods in the category', () {
      expect(search('-category:favorites'), ['graphics_only', 'no_category']);
    });

    test('results update when a mod is added to the category', () async {
      expect(search('category:favorites'), ['both_categories']);

      container
          .read(categoryManagerProvider.notifier)
          .addCategoryToMod('no_category', 'favorites');
      await pumpEventQueue();

      expect(
        container
            .read(modsGridSearchControllerProvider)
            .filteredMods
            .map((m) => m.id),
        ['both_categories', 'no_category'],
      );
    });
  });

  testWidgets('dropping on a group uses that group, not its first mod primary '
      'category', (tester) async {
    late WidgetRef widgetRef;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoryManagerProvider.overrideWith(
            () => _InMemoryCategoryNotifier(_store),
          ),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            widgetRef = ref;
            ref.watch(categoryManagerProvider);
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pump();

    // both_categories is first in the Favorites group, but its primary
    // category is Graphics.
    CategoryModGridGroup(widgetRef).onItemsDropped(
      ['graphics_only'],
      [_mod('both_categories')],
      widgetRef,
      groupSortValue: 'favorites',
    );
    await tester.pump();

    final notifier = widgetRef.read(categoryManagerProvider.notifier);
    expect(notifier.getPrimaryCategory('graphics_only')?.id, 'favorites');
  });
}
