import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_color/flutter_color.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/extensions.dart';

import '../models/mod.dart';
import '../models/mod_variant.dart';
import '../models/version.dart';
import '../utils/logging.dart';

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
    final enabledMods = ref.watch(AppState.enabledModsFile).valueOrNull;
    final isSingleVariant = widget.mod.modVariants.length == 1;
    final theme = Theme.of(context);
    const buttonHeight = 35.00;
    final buttonWidth = widget.width;
    final buttonStyle = ElevatedButton.styleFrom(
      foregroundColor: theme.colorScheme.onSecondary,
      disabledForegroundColor: theme.colorScheme.onSecondary,
      backgroundColor: theme.colorScheme.secondary,
      disabledBackgroundColor: theme.colorScheme.secondary,
      textStyle:
          const TextStyle(fontWeight: FontWeight.w900, fontFamily: "Orbitron"),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ThemeManager.cornerRadius),
        side: BorderSide(
          color: theme.colorScheme.secondary.darker(20),
          // Slightly darker color
          width: 2.0,
        ),
      ),
    );

    if (isSingleVariant) {
      return SizedBox(
        width: buttonWidth,
        height: buttonHeight,
        child: ElevatedButton(
          onPressed: () async {
            // Enable if disabled, disable if enabled
            try {
              if (widget.mod.hasEnabledVariant) {
                await changeActiveModVariant(widget.mod, null, ref);
              } else {
                await changeActiveModVariant(
                    widget.mod, widget.mod.findHighestVersion, ref);
              }
            } catch (e, st) {
              Fimber.e("Error changing active mod variant: $e\n$st");
            }

            // TODO update ONLY the mod that changed and any dependents/dependencies.
            ref.invalidate(AppState.modVariants);
          },
          style: buttonStyle,
          child: Text(
            widget.mod.hasEnabledVariant ? "Disable" : "Enable",
          ),
        ),
      );
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
        .sortedByDescending<Version>((item) => item.value?.modInfo.version)
      ..add(const DropdownMenuItem(
          value: null,
          child: Text("Disable", overflow: TextOverflow.ellipsis))));

    var dropdownWidth = buttonWidth - 6;
    return DropdownButton2(
      items: items,
      value: widget.mod.findFirstEnabled,
      alignment: Alignment.centerLeft,
      iconStyleData: const IconStyleData(iconSize: 0),
      buttonStyleData: ButtonStyleData(
          height: buttonHeight,
          width: dropdownWidth,
          overlayColor: WidgetStateColor.transparent),
      selectedItemBuilder: (BuildContext context) {
        return items.map((item) {
          return SizedBox(
            width: dropdownWidth,
            child: ElevatedButton(
              onPressed: null,
              style: buttonStyle,
              child: Row(
                children: [
                  const SizedBox(width: 10),
                  Expanded(
                      child: Align(
                    alignment: Alignment.center,
                    child:
                        item.value == null ? const Text("Enable") : item.child,
                  )),
                  SizedBox(
                    width: 10,
                    child: Icon(
                      Icons.arrow_drop_down,
                      color: theme.colorScheme.onSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList();
      },
      onChanged: (ModVariant? variant) async {
        await changeActiveModVariant(widget.mod, variant, ref);
        // TODO update ONLY the mod that changed and any dependents/dependencies.
        ref.invalidate(AppState.modVariants);
      },
    );
  }
}
