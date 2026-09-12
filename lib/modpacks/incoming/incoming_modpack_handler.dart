import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:trios/modpacks/incoming/incoming_modpack.dart';
import 'package:trios/modpacks/incoming/incoming_modpack_dialog.dart';
import 'package:trios/modpacks/library/modpacks_page_controller.dart';
import 'package:trios/modpacks/modpack_store.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/deep_link/deep_link_handler.dart';
import 'package:trios/trios/navigation.dart';
import 'package:trios/trios/navigation_request.dart';
import 'package:trios/utils/dialogs.dart';
import 'package:trios/utils/logging.dart';

final incomingModpackHandlerProvider = Provider(IncomingModpackHandler.new);

/// One serialized preview path for paste/import, drops, and OS delivery.
class IncomingModpackHandler {
  final Ref ref;
  Future<void> _pending = Future.value();
  IncomingModpackHandler(this.ref);

  Future<void> receive(String input, {BuildContext? context}) {
    final next = _pending.then<void>((_) async {
      if (context != null && !context.mounted) return;
      return _receive(input, context);
    });
    _pending = next.catchError((Object _) {});
    return next;
  }

  Future<void> _receive(String input, BuildContext? suppliedContext) async {
    // Cold-start delivery begins from TriOSApp.initState, before MaterialApp
    // has attached its navigator. Hold the input until that navigator exists.
    if (suppliedContext == null && rootNavigatorKey.currentContext == null) {
      await rootNavigatorReady.future;
    }
    if (!ref.mounted) return;
    final context = suppliedContext ?? rootNavigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    try {
      final definition = await readIncomingModpack(input);
      final data = await ref.read(modpackStoreProvider.future);
      if (!context.mounted) return;
      if (ref.read(modpackStoreProvider.notifier).storageProblem != null) {
        throw StateError(
          'Restore your modpack library backup or choose Start empty in Modpacks before importing.',
        );
      }
      final match = matchIncomingModpack(definition, data);
      final result = match == .saved || match == .draft
          ? IncomingModpackResult(definition.id, openDraft: match == .draft)
          : await showDialog<IncomingModpackResult>(
              context: context,
              builder: (_) => IncomingModpackDialog(definition: definition),
            );
      if (result == null || !context.mounted) return;
      final controller = ref.read(modpacksPageControllerProvider.notifier);
      if (result.openDraft) {
        controller.editPack(result.packId);
      } else {
        controller.viewPack(result.packId);
      }
      ref.read(AppState.navigationRequest.notifier).state =
          const NavigationRequest(destination: TriOSTools.modpacks);
    } catch (e, st) {
      Fimber.w('Could not open modpack.', ex: e, stacktrace: st);
      if (!context.mounted) return;
      // showAlertDialog makes the text selectable and linkifies URLs, which
      // matters because the message can carry the source address.
      await showAlertDialog(
        context,
        title: 'Could not open modpack',
        content: e.toString(),
      );
    }
  }
}
