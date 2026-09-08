import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/mod_profiles/models/mod_profile.dart';
import 'package:trios/mod_records/mod_records_store.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/modpacks/editor/modpack_editor_logic.dart';
import 'package:trios/modpacks/library/modpacks_page_controller.dart';
import 'package:trios/modpacks/models/modpack_draft.dart';
import 'package:trios/modpacks/modpack_store.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/navigation.dart';
import 'package:trios/trios/navigation_request.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';

/// Every creation action opens the same autosaved editor.
Future<void> createModpackFromSelection(
  WidgetRef ref, {
  String name = '',
  List<ModVariant> variants = const [],
  List<ShallowModVariant>? profileVariants,
}) async {
  await ref.read(modpackStoreProvider.future);
  final records = await ref.read(modRecordsStore.future);
  if (!ref.context.mounted) return;
  final items = <String, ModpackDraftItem>{};
  if (profileVariants != null) {
    final installed = ref.read(AppState.modVariants).value ?? [];
    final exactVariants = {
      for (final variant in installed) variant.smolId: variant,
    };
    for (final selected in profileVariants) {
      final exact = exactVariants[selected.smolVariantId];
      items.putIfAbsent(
        selected.modId,
        () => exact == null
            ? ModpackDraftItem(
                modId: selected.modId,
                name: selected.modName,
                version: selected.version?.toString(),
              )
            : discoverModpackItem(exact, records.records[selected.modId]),
      );
    }
  } else {
    for (final variant in variants) {
      items.putIfAbsent(
        variant.modInfo.id,
        () => discoverModpackItem(variant, records.records[variant.modInfo.id]),
      );
    }
  }
  final draft = await ref
      .read(modpackStoreProvider.notifier)
      .createDraft(
        name: name,
        gameVersion: ref.read(appSettings).lastStarsectorVersion,
        items: items.values.toList(),
      );
  if (!ref.context.mounted) return;
  ref.read(modpacksPageControllerProvider.notifier).editPack(draft.id);
  ref.read(AppState.navigationRequest.notifier).state = const NavigationRequest(
    destination: TriOSTools.modpacks,
  );
}
