import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/models/mod.dart';

/// Turns an installed catalog mod on or off. Turning it on picks the highest
/// installed version. Used by the catalog card's right-click menu and the
/// details dialog's Get it panel.
void setCatalogModEnabled(WidgetRef ref, Mod mod, bool enabled) {
  if (enabled) {
    final variant = mod.findHighestVersion;
    if (variant == null) return;
    ref.read(modManager.notifier).changeActiveModVariant(mod, variant);
  } else {
    ref.read(modManager.notifier).changeActiveModVariant(mod, null);
  }
}
