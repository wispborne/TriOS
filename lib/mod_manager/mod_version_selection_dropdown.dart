import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_color/flutter_color.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toastification/toastification.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/thirdparty/dartx/iterable.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/disable.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/svg_image_icon.dart';

import '../models/mod.dart';
import '../models/mod_variant.dart';
import '../utils/logging.dart';

/// Button that lets user Enable/Disable a mod or swap to a different version
class ModVersionSelectionDropdown extends ConsumerStatefulWidget {
  final Mod mod;
  final double width;
  final bool showTooltip;

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
    final isSingleVariant = widget.mod.modVariants.length == 1;
    final theme = Theme.of(context);
    const buttonHeight = 32.00;
    final buttonWidth = widget.width;
    final mainVariant = widget.mod.findFirstEnabledOrHighestVersion;
    final hasMultipleEnabled = widget.mod.enabledVariants.length > 1;
    final groupsOfMultipleSameVersionInModsFolder =
        widget.mod.modVariants.groupBy((it) => it.bestVersion)
          ..removeWhere((k, v) => v.length < 2);
    final hasMultipleSameVersionInModsFolder =
        groupsOfMultipleSameVersionInModsFolder.isNotEmpty;
    final modCompatibilityMap = ref.watch(AppState.modCompatibility);
    final dependencyChecks = widget.mod.modVariants.map((v) {
      return modCompatibilityMap[v.smolId];
    }).toList();
    final isSupportedByGameVersion =
        dependencyChecks.isCompatibleWithGameVersion;
    final mainDependencyCheck = modCompatibilityMap[mainVariant?.smolId];
    final modDependenciesSatisfied = mainDependencyCheck?.dependencyChecks;
    final useWarningUi =
        hasMultipleEnabled || hasMultipleSameVersionInModsFolder;

    // TODO consolidate this logic with the logic in smol2.
    final areAllDependenciesSatisfied = modDependenciesSatisfied?.every(
      (d) =>
          d.satisfiedAmount is Satisfied ||
          d.satisfiedAmount is VersionWarning ||
          d.satisfiedAmount is Disabled,
    );
    final isEnabled = widget.mod.hasEnabledVariant;
    // You can always disable a mod, but you can't enable a mod if dependencies are missing.
    final isButtonEnabled = areAllDependenciesSatisfied == true || isEnabled;
    // Pseudo-disabled means it's enabled but has a warning outline.
    final isButtonPseudoDisabled =
        isButtonEnabled &&
        (!isSupportedByGameVersion || areAllDependenciesSatisfied != true);

    // Button color logic
    final buttonColor = switch ((useWarningUi, isEnabled)) {
      (true, _) => errorColor,
      (false, true) => theme.colorScheme.secondary,
      _ => theme.colorScheme.surfaceContainerLow,
    };

    final textColor = switch ((useWarningUi, isEnabled)) {
      (true, _) => theme.colorScheme.onSecondary.darker(20),
      (false, true) => theme.colorScheme.onSecondary,
      _ => theme.colorScheme.onSurface,
    };

    final borderColor = (isButtonEnabled && !isButtonPseudoDisabled)
        ? (useWarningUi
              ? ThemeManager.vanillaErrorColor.darker(20)
              : theme.colorScheme.secondary.darker(20))
        : ThemeManager.vanillaErrorColor.withOpacity(isEnabled ? 0.8 : 0.4);

    Color? getGameCompatibilityTextColor(ModVariant variant) {
      // Special handling if background color is errorColor. GameCompat color is orange/red, which is too hard to see.
      return buttonColor == errorColor
          ? null
          : modCompatibilityMap[variant.smolId]?.gameCompatibility
                .getGameCompatibilityColor();
    }

    const textStyle = TextStyle(
      fontWeight: FontWeight.w900,
      fontFamily: "Orbitron",
    );
    final buttonStyle = ElevatedButton.styleFrom(
      foregroundColor: textColor,
      disabledForegroundColor: textColor,
      backgroundColor: buttonColor,
      disabledBackgroundColor: buttonColor,
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      textStyle: textStyle,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ThemeManager.cornerRadius),
        side: BorderSide(
          color: borderColor,
          // Slightly darker buttonColor
          width: 2.0,
        ),
      ),
    );

    const gameVersionMessage =
        "This mod requires a different version of the game";
    final errorTooltip = switch (true) {
      _ when hasMultipleEnabled =>
        "Warning"
            "\nYou have two or more enabled mod folders for ${mainVariant?.modInfo.nameOrId}. The game will pick one at 'random'."
            "\nSelect one version from the dropdown.",
      _ when areAllDependenciesSatisfied == false =>
        "Requires ${modDependenciesSatisfied?.where((it) => !it.canBeSatisfiedWithInstalledMods).joinToString(transform: (it) => it.dependency.nameOrId)}",

      _ when hasMultipleSameVersionInModsFolder =>
        "Warning"
            "\nYou have two or more of the same version (${groupsOfMultipleSameVersionInModsFolder.keys.join(", ")}) of this mod in your mods folder. ${Constants.appName} may not handle this correctly."
            "\nPlease remove one manually.",
      _ => null,
    };
    final warningIcon = Icon(Icons.warning, color: textColor, size: 20);

    //////// Single variant button
    if (isSingleVariant) {
      final tooltipMessage =
          errorTooltip ??
          (widget.showTooltip
              ? (!isSupportedByGameVersion ? gameVersionMessage : "")
              : null);
      return MovingTooltipWidget.text(
        message: tooltipMessage,
        warningLevel: tooltipMessage != null
            ? TooltipWarningLevel.warning
            : TooltipWarningLevel.none,
        child: Disable(
          isEnabled: isButtonEnabled,
          child: SizedBox(
            width: buttonWidth,
            height: buttonHeight,
            child: ElevatedButton(
              onPressed: () async {
                if (!mounted) return;
                // Enable if disabled, disable if enabled
                try {
                  isEnabled
                      ? await switchToVariant(null)
                      : await switchToVariant(widget.mod.findHighestVersion);
                } catch (e, st) {
                  Fimber.e("Error changing active mod variant: $e\n$st");
                }
              },
              style: buttonStyle,
              child: Stack(
                children: [
                  (useWarningUi
                      ? Align(
                          alignment: Alignment.centerLeft,
                          child: warningIcon,
                        )
                      : Container()),
                  Center(child: Text(isEnabled ? "Disable" : "Enable")),
                ],
              ),
            ),
          ),
        ),
      );
    }

    //////// Multiple variants button
    final items = [
      if (isEnabled)
        const DropdownItem(
          value: null,
          child: Text("Disable", overflow: TextOverflow.ellipsis),
        ),
      ...(widget.mod.modVariants
          .map(
            (variant) => DropdownItem(
              value: variant,
              child: Text(
                variant.modInfo.version.toString(),
                style: TextStyle(color: getGameCompatibilityTextColor(variant)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .distinctBy((item) => item.value?.smolId)
          .sortedByDescending<ModVariant>((item) => item.value)),
    ];

    final dropdownWidth = buttonWidth;
    final highestVersionVariant = widget.mod.modVariants.max()!;
    final enabledVariant = widget.mod.findFirstEnabled;
    final canUpgradeVersion =
        enabledVariant != null &&
        enabledVariant.smolId != highestVersionVariant.smolId;
    final variantThatCanBeUpgradedTo = canUpgradeVersion
        ? highestVersionVariant
        : null;

    final subButtonBgColor = getColorForCurrentState(
      buttonStyle.backgroundColor!,
      {WidgetState.selected},
    )!.lighter(enabledVariant == null ? 6 : 8);
    final subButtonBorderColor = buttonColor.darker(
      enabledVariant == null ? 12 : 6,
    );

    return MovingTooltipWidget.text(
      message:
          errorTooltip ??
          (widget.showTooltip
              ? (!isSupportedByGameVersion ? gameVersionMessage : null)
              : null),
      warningLevel: errorTooltip != null
          ? TooltipWarningLevel.warning
          : TooltipWarningLevel.none,
      child: Disable(
        isEnabled: isButtonEnabled,
        child: SizedBox(
          width: dropdownWidth,
          height: buttonHeight,
          child: Material(
            color: buttonColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ThemeManager.cornerRadius),
              side: BorderSide(color: borderColor, width: 2.0),
            ),
            clipBehavior: Clip.antiAlias,
            child: DefaultTextStyle.merge(
              style: TextStyle(
                color: textColor,
                fontStyle: textStyle.fontStyle,
                fontWeight: textStyle.fontWeight,
                fontFamily: textStyle.fontFamily,
                fontSize: 14,
              ),
              child: Row(
                children: [
                  // Main tap area — enable/disable
                  Expanded(
                    child: MovingTooltipWidget.text(
                      message: isEnabled ? "Click to disable" : null,
                      child: InkWell(
                        onTap: () async {
                          if (!mounted) return;
                          try {
                            isEnabled
                                ? await switchToVariant(null)
                                : await switchToVariant(
                                    widget.mod.findHighestVersion,
                                  );
                          } catch (e, st) {
                            Fimber.e(
                              "Error changing active mod variant: $e\n$st",
                            );
                          }
                        },
                        child: Row(
                          children: [
                            SizedBox(width: 32),
                            Expanded(
                              child: Stack(
                                children: [
                                  if (useWarningUi)
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 4),
                                        child: warningIcon,
                                      ),
                                    ),
                                  Center(
                                    child: Text(
                                      isEnabled
                                          ? enabledVariant!.modInfo.version
                                                .toString()
                                          : "Enable",
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Sub-button on right side
                  if (variantThatCanBeUpgradedTo != null)
                    _buildUpgradeSubButton(
                      variantThatCanBeUpgradedTo,
                      subButtonBgColor,
                      subButtonBorderColor,
                      textColor,
                    )
                  else
                    _buildDropdownSubButton(
                      items: items,
                      enabledVariant: enabledVariant,
                      textColor: textColor,
                      bgColor: subButtonBgColor,
                      borderColor: subButtonBorderColor,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> switchToVariant(ModVariant? modVariant) async {
    await ref
        .read(modManager.notifier)
        .changeActiveModVariantWithForceModGameVersionDialogIfNeeded(
          widget.mod,
          modVariant,
        );
  }

  /// Dropdown arrow sub-button that opens a version picker.
  Widget _buildDropdownSubButton({
    required List<DropdownItem<ModVariant?>> items,
    required ModVariant? enabledVariant,
    required Color textColor,
    required Color bgColor,
    required Color borderColor,
  }) {
    return MovingTooltipWidget.text(
      message: "Select a different version",
      child: Container(
        width: 32,
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(left: BorderSide(color: borderColor, width: 1)),
        ),
        child: DropdownButton2<ModVariant?>(
          items: items,
          valueListenable: ValueNotifier(enabledVariant),
          customButton: Center(
            child: Padding(
              padding: const .only(right: 2),
              child: Icon(Icons.arrow_drop_down, color: textColor, size: 24),
            ),
          ),
          iconStyleData: const IconStyleData(iconSize: 0),
          underline: Container(),
          dropdownStyleData: const DropdownStyleData(width: 120),
          onChanged: (ModVariant? variant) async {
            await switchToVariant(variant);
          },
        ),
      ),
    );
  }

  /// Upgrade sub-button that switches to the latest version.
  Widget _buildUpgradeSubButton(
    ModVariant variantThatCanBeUpgradedTo,
    Color bgColor,
    Color borderColor,
    Color iconColor,
  ) {
    return MovingTooltipWidget.text(
      message:
          "Click to use newer version ${variantThatCanBeUpgradedTo.bestVersion}",
      child: InkWell(
        onTap: () => switchToVariant(variantThatCanBeUpgradedTo),
        child: Container(
          width: 32,
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(left: BorderSide(color: borderColor, width: 1)),
          ),
          child: Center(
            child: SvgImageIcon(
              "assets/images/icon-swap-upgrade.svg",
              height: 16,
              width: 16,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }

  Color? getColorForCurrentState(
    WidgetStateProperty<Color?> stateProperty,
    Set<WidgetState> states,
  ) {
    return stateProperty.resolve(states);
  }
}
