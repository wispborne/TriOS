import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_color/flutter_color.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toastification/toastification.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/thirdparty/dartx/iterable.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/disable.dart';
import 'package:trios/widgets/moving_tooltip.dart';

import '../models/mod.dart';
import '../models/mod_variant.dart';
import '../utils/logging.dart';

class ModVersionSelectionDropdown extends ConsumerStatefulWidget {
  final Mod mod;
  final double width;
  final showTooltip;

  const ModVersionSelectionDropdown({
    super.key,
    required this.mod,
    required this.width,
    required this.showTooltip,
  });

  @override
  ConsumerState createState() => _ModVersionSelectionDropdownState();
}

class _ModVersionSelectionDropdownState
    extends ConsumerState<ModVersionSelectionDropdown> {
  @override
  Widget build(BuildContext context) {
    // final enabledMods = ref.watch(AppState.enabledModsFile).valueOrNull;
    final isSingleVariant = widget.mod.modVariants.length == 1;
    final theme = Theme.of(context);
    const buttonHeight = 32.00;
    final buttonWidth = widget.width;
    final mainVariant = widget.mod.findFirstEnabledOrHighestVersion;
    final hasMultipleEnabled = widget.mod.enabledVariants.length > 1;
    final modCompatibilityMap = ref.watch(AppState.modCompatibility);
    final dependencyChecks = widget.mod.modVariants.map((v) {
      return modCompatibilityMap[v.smolId];
    }).toList();
    final isSupportedByGameVersion =
        dependencyChecks.isCompatibleWithGameVersion;
    final mainDependencyCheck = modCompatibilityMap[mainVariant?.smolId];
    final modDependenciesSatisfied = mainDependencyCheck?.dependencyChecks;

    // TODO consolidate this logic with the logic in smol2.
    var areAllDependenciesSatisfied = modDependenciesSatisfied?.every((d) =>
        d.satisfiedAmount is Satisfied ||
        d.satisfiedAmount is VersionWarning ||
        d.satisfiedAmount is Disabled);
    final isButtonEnabled =
        isSupportedByGameVersion && areAllDependenciesSatisfied == true;

    final buttonColor = hasMultipleEnabled
        ? errorColor
        : widget.mod.isEnabledInGame
            ? theme.colorScheme.secondary
            : theme.colorScheme.surface;
    var textColor = hasMultipleEnabled
        ? theme.colorScheme.onSecondary.darker(20)
        : widget.mod.isEnabledInGame
            ? theme.colorScheme.onSecondary
            : theme.colorScheme.onSurface;
    final buttonStyle = ElevatedButton.styleFrom(
      foregroundColor: textColor,
      disabledForegroundColor: textColor,
      backgroundColor: buttonColor,
      disabledBackgroundColor: buttonColor,
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      textStyle:
          const TextStyle(fontWeight: FontWeight.w900, fontFamily: "Orbitron"),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ThemeManager.cornerRadius),
        side: BorderSide(
          color: isButtonEnabled
              ? hasMultipleEnabled
                  ? ThemeManager.vanillaErrorColor.darker(20)
                  : theme.colorScheme.secondary.darker(20)
              : ThemeManager.vanillaErrorColor.withOpacity(0.4),
          // Slightly darker buttonColor
          width: 2.0,
        ),
      ),
    );

    const gameVersionMessage =
        "This mod requires a different version of the game.";
    final errorTooltip = hasMultipleEnabled
        ? "Warning"
            "\nYou have two or more enabled mod folders for ${mainVariant?.modInfo.nameOrId}. The game will pick one at 'random'."
            "\nSelect one version from the dropdown."
        : "";
    final warningIcon = Icon(
      Icons.warning,
      color: textColor,
      size: 20,
    );

    if (isSingleVariant) {
      return Tooltip(
        message: widget.showTooltip
            ? (!isSupportedByGameVersion ? gameVersionMessage : "")
            : "",
        child: Disable(
          isEnabled: isButtonEnabled,
          child: SizedBox(
            width: buttonWidth,
            height: buttonHeight,
            child: MovingTooltipWidget.text(
              message: errorTooltip,
              child: ElevatedButton(
                onPressed: () async {
                  if (!mounted) return;
                  // Enable if disabled, disable if enabled
                  try {
                    if (widget.mod.hasEnabledVariant) {
                      await ref
                          .read(AppState.modVariants.notifier)
                          .changeActiveModVariant(widget.mod, null);
                    } else {
                      await ref
                          .read(AppState.modVariants.notifier)
                          .changeActiveModVariant(
                              widget.mod, widget.mod.findHighestVersion);
                    }
                  } catch (e, st) {
                    Fimber.e("Error changing active mod variant: $e\n$st");
                  }
                },
                style: buttonStyle,
                child: Stack(
                  children: [
                    (hasMultipleEnabled
                        ? Align(
                            alignment: Alignment.centerLeft, child: warningIcon)
                        : Container()),
                    Center(
                      child: Text(
                        widget.mod.hasEnabledVariant ? "Disable" : "Enable",
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Multiple variants tracked
    final items = [
      const DropdownMenuItem(
        value: null,
        child: Text("Disable", overflow: TextOverflow.ellipsis),
      ),
      ...(widget.mod.modVariants
          .map(
            (variant) => DropdownMenuItem(
              value: variant,
              child: Text(variant.modInfo.version.toString(),
                  style: TextStyle(
                      color: modCompatibilityMap[variant.smolId]
                          ?.gameCompatibility
                          .getGameCompatibilityColor()),
                  overflow: TextOverflow.ellipsis),
            ),
          )
          .distinctBy((item) => item.value?.smolId)
          .sortedByDescending<ModVariant>((item) => item.value))
    ];

    final dropdownWidth = buttonWidth;
    return Tooltip(
      message: widget.showTooltip
          ? (!isSupportedByGameVersion ? gameVersionMessage : "")
          : "",
      child: Disable(
        isEnabled: isButtonEnabled,
        child: DropdownButton2<ModVariant?>(
          items: items,
          value: widget.mod.findFirstEnabled,
          alignment: Alignment.centerLeft,
          iconStyleData: const IconStyleData(iconSize: 0),
          // Removes ugly grey line below text
          underline: Container(),
          buttonStyleData: ButtonStyleData(
              height: buttonHeight,
              width: dropdownWidth,
              overlayColor: WidgetStateColor.transparent),
          dropdownStyleData: DropdownStyleData(openInterval: Interval(0, 0.15)),
          selectedItemBuilder: (BuildContext context) {
            return items.map((item) {
              return SizedBox(
                width: dropdownWidth,
                child: MovingTooltipWidget.text(
                  message: errorTooltip,
                  child: ElevatedButton(
                    onPressed: null,
                    style: buttonStyle,
                    child: Stack(
                      children: [
                        (hasMultipleEnabled
                            ? Align(
                                alignment: Alignment.centerLeft,
                                child: warningIcon)
                            : Container()),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(width: 10),
                            Expanded(
                                child: Align(
                              alignment: Alignment.center,
                              child: item.value == null
                                  ? const Text("Enable")
                                  : item.child,
                            )),
                            SizedBox(
                              width: 10,
                              child: Icon(
                                Icons.arrow_drop_down,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList();
          },
          onChanged: (ModVariant? variant) async {
            await ref
                .read(AppState.modVariants.notifier)
                .changeActiveModVariant(widget.mod, variant);
          },
        ),
      ),
    );
  }
}
