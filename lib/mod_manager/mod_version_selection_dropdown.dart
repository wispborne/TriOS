import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/extensions.dart';

import '../models/mod.dart';
import '../models/mod_variant.dart';

class ModVersionSelectionDropdown extends ConsumerStatefulWidget {
  final Mod mod;
  final double width;

  const ModVersionSelectionDropdown(
      {super.key, required this.mod, required this.width});

  @override
  ConsumerState createState() => _ModVersionSelectionDropdownState();
}

class _ModVersionSelectionDropdownState
    extends ConsumerState<ModVersionSelectionDropdown> {
  @override
  Widget build(BuildContext context) {
    final enabledMods = ref.watch(AppState.enabledMods).valueOrNull;
    final isSingleVariant = widget.mod.modVariants.length == 1;

    if (isSingleVariant) {
      return ElevatedButton(
          onPressed: () {},
          child: Text(widget.mod.modVariants.first.isEnabled(enabledMods)
              ? "Disable"
              : "Enable"));
    }

    // Multiple variants tracked
    final items = (widget.mod.modVariants
        .map(
          (variant) => DropdownMenuItem(
            value: variant,
            child: Text(variant.modInfo.version.toString(),
                overflow: TextOverflow.ellipsis),
          ),
        )
        .toList()
        .sortedByDescending<String>(
            // TODO implement comparable in Version
            (item) => item.value?.modInfo.version.toString() ?? "")
      ..add(const DropdownMenuItem(child: Text("Disable"), value: null)));

    return DropdownButton(
      items: items,
      value: widget.mod.findFirstEnabled,
      selectedItemBuilder: (BuildContext context) {
        return items.map((item) {
          return SizedBox(
            width: widget.width - 30,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Align(alignment: Alignment.centerLeft, child: item.child),
            ),
          );
        }).toList();
      },
      onChanged: (ModVariant? variant) {
        if (variant != null) {
          // context.read(modManagerLogicProvider).selectModVariant(variant);
        }
      },
    );
  }
}
