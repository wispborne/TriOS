/// Minimal reproducer for Dart AOT compiler crash.
///
/// Crashes with 0xc0000005 (access violation) in Release/Profile AOT builds.
/// Works fine in Debug (JIT) builds.
///
/// The bug: `await` calling a non-trivial async method inside a for loop,
/// within a sufficiently complex async method, generates a corrupted async
/// state machine in AOT compilation.
///
/// Workaround: extract the for-loop-with-await into a separate async method.
///
/// Environment where the bug was found:
///   Flutter 3.44.0 / Dart SDK 3.12.0 / Windows 11
///
/// To reproduce:
///   Debug (no crash):   dart run dart_aot_crash_repro.dart
///   AOT (crash):        dart compile exe dart_aot_crash_repro.dart && dart_aot_crash_repro.exe
///
/// If the pure-Dart AOT doesn't crash, try a Flutter project in Profile/Release,
/// which uses gen_snapshot (a different AOT pipeline).
import 'dart:io';

Future<void> main() async {
  final manager = Manager();
  print('Disabling item...');
  await manager.changeActiveVariant(disable: true);
  print('Done disabling.');

  print('Enabling item...');
  await manager.changeActiveVariant(disable: false);
  print('Done enabling.');
}

class Variant {
  final String id;
  final String version;
  final bool isEnabled;
  Variant(this.id, this.version, {this.isEnabled = true});
  String get smolId => '$id-$version';
}

class Manager {
  final List<Variant> _allVariants = [
    Variant('modA', '1.0.0'),
    Variant('modA', '2.0.0', isEnabled: false),
    Variant('modB', '1.0.0'),
  ];

  Map<String, bool> _enabledMods = {'modA': true, 'modB': true};

  /// This method crashes in AOT when the for loop body contains
  /// `await _disableVariant(...)`.
  ///
  /// Extracting the loop into a separate async method avoids the crash.
  Future<void> changeActiveVariant({
    bool disable = false,
    Variant? targetVariant,
    bool notifyWatchers = true,
    bool validateDependencies = true,
  }) async {
    final isDisabling = targetVariant == null && disable;

    // Read some state — adds variables to the async state machine.
    final parentInfo = targetVariant?.id;
    if (parentInfo != null && parentInfo != 'modA') {
      throw Exception('Variant does not belong to mod.');
    }

    // Early return path — adds a branch.
    if (targetVariant != null && _enabledMods[targetVariant.id] == true) {
      return;
    }

    final enabledVariants =
        _allVariants.where((v) => v.isEnabled).toList();

    if (isDisabling && enabledVariants.isEmpty) {
      return;
    }

    // ===== THIS IS THE CRASH SITE =====
    // `await _disableVariant(...)` inside this for loop generates a bad
    // async state machine in AOT. A trivial `await Future.value()` here
    // does NOT crash — only a real async method call triggers it.
    for (final variant in enabledVariants) {
      if (variant.smolId != targetVariant?.smolId) {
        try {
          await _disableVariant(
            variant,
            removeFromLauncher: isDisabling,
            brick: !isDisabling && _allVariants.length > 1,
            reason: isDisabling
                ? 'Disabled ${variant.id} (${variant.version} was enabled).'
                : 'Changed to ${targetVariant!.version}, disabling ${variant.version}.',
          );
        } catch (e) {
          stderr.writeln('Error disabling variant: $e');
        }
      }
    }

    if (!isDisabling && targetVariant != null) {
      await _enableVariant(targetVariant);
    } else {
      final disabledVariants =
          _allVariants.where((v) => !v.isEnabled).toList();
      for (final v in disabledVariants) {
        try {
          await _unbrick(v);
        } catch (e) {
          stderr.writeln('Error unbricking: $e');
        }
      }
    }

    if (notifyWatchers) {
      await _reload();
    }
    if (validateDependencies) {
      await _validate();
    }
  }

  Future<void> _disableVariant(
    Variant variant, {
    bool brick = false,
    bool removeFromLauncher = true,
    required String reason,
  }) async {
    final mods = Map<String, bool>.from(_enabledMods);

    if (brick) {
      _brick(variant);
    }

    if (removeFromLauncher) {
      if (mods[variant.id] == true) {
        await _disableInLauncher(variant.id);
      }
    }

    _addAudit(variant.smolId, reason);
  }

  Future<void> _enableVariant(Variant variant) async {
    _enabledMods[variant.id] = true;
    await Future<void>.delayed(Duration(milliseconds: 1));
  }

  Future<void> _disableInLauncher(String modId) async {
    _enabledMods[modId] = false;
    await Future<void>.delayed(Duration(milliseconds: 1));
  }

  void _brick(Variant v) {
    print('  Bricking ${v.smolId}');
  }

  Future<void> _unbrick(Variant v) async {
    print('  Unbricking ${v.smolId}');
    await Future<void>.delayed(Duration(milliseconds: 1));
  }

  Future<void> _reload() async {
    await Future<void>.delayed(Duration(milliseconds: 1));
  }

  Future<void> _validate() async {
    await Future<void>.delayed(Duration(milliseconds: 1));
  }

  void _addAudit(String smolId, String reason) {
    print('  Audit: $smolId — $reason');
  }
}
