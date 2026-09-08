import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/modpacks/models/modpack_definition.dart';
import 'package:trios/modpacks/sharing/modpack_source_validator.dart';
import 'package:trios/utils/http_probe.dart';

enum ModpackSourceCheckStatus { waiting, checking, passed, failed, cancelled }

class ModpackSourceCheck {
  final ModpackItem item;
  final ModpackSourceCheckStatus status;
  final String? error;
  final bool cached;
  const ModpackSourceCheck(
    this.item,
    this.status, {
    this.error,
    this.cached = false,
  });
}

class ModpackShareState {
  final List<ModpackSourceCheck> checks;
  final bool running;
  const ModpackShareState({this.checks = const [], this.running = false});
}

final modpackShareControllerProvider = NotifierProvider.autoDispose
    .family<ModpackShareController, ModpackShareState, String>(
      ModpackShareController.new,
    );

class ModpackShareController extends Notifier<ModpackShareState> {
  final String packId;
  ModpackShareController(this.packId);
  HttpProbeCancellation? _cancellation;
  @override
  ModpackShareState build() {
    ref.onDispose(() => _cancellation?.cancel());
    return const ModpackShareState();
  }

  void cancel() {
    _cancellation?.cancel();
    state = ModpackShareState(
      checks: [
        for (final check in state.checks)
          if (check.status == .waiting || check.status == .checking)
            ModpackSourceCheck(check.item, .cancelled)
          else
            check,
      ],
    );
  }

  Future<bool> validate(ModpackDefinition definition) async {
    if (state.running) return false;
    final cancellation = HttpProbeCancellation();
    _cancellation = cancellation;
    final validator = ref.read(modpackSourceValidatorProvider);
    state = ModpackShareState(
      running: true,
      checks: [
        for (final item in definition.items) ModpackSourceCheck(item, .waiting),
      ],
    );
    // Every item is at least one network round trip, so they run together
    // instead of one after another. The HTTP client's own request queue caps
    // how many are actually in flight.
    await Future.wait([
      for (var index = 0; index < definition.items.length; index++)
        _validateItem(validator, definition.items[index], index, cancellation),
    ]);
    if (cancellation.isCancelled) return false;
    state = ModpackShareState(checks: state.checks);
    return state.checks.every((check) => check.status == .passed);
  }

  Future<void> _validateItem(
    ModpackSourceValidator validator,
    ModpackItem item,
    int index,
    HttpProbeCancellation cancellation,
  ) async {
    if (cancellation.isCancelled) return;
    _setCheck(index, ModpackSourceCheck(item, .checking));
    try {
      final cached = await validator.validate(item, cancellation);
      if (cancellation.isCancelled) return;
      _setCheck(index, ModpackSourceCheck(item, .passed, cached: cached));
    } catch (e) {
      if (cancellation.isCancelled) return;
      _setCheck(index, ModpackSourceCheck(item, .failed, error: e.toString()));
    }
  }

  void _setCheck(int index, ModpackSourceCheck check) {
    final checks = [...state.checks];
    checks[index] = check;
    state = ModpackShareState(checks: checks, running: true);
  }
}
