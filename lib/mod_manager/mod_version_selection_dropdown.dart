import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_color/flutter_color.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toastification/toastification.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/models/version.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/thirdparty/dartx/iterable.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
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
    final modCompatibilityMap = ref.watch(AppState.modCompatibility);
    final dependencyChecks =
        widget.mod.modVariants.map((v) {
          return modCompatibilityMap[v.smolId];
        }).toList();
    final isSupportedByGameVersion =
        dependencyChecks.isCompatibleWithGameVersion;
    final mainDependencyCheck = modCompatibilityMap[mainVariant?.smolId];
    final modDependenciesSatisfied = mainDependencyCheck?.dependencyChecks;

    // TODO consolidate this logic with the logic in smol2.
    var areAllDependenciesSatisfied = modDependenciesSatisfied?.every(
      (d) =>
          d.satisfiedAmount is Satisfied ||
          d.satisfiedAmount is VersionWarning ||
          d.satisfiedAmount is Disabled,
    );
    final isButtonEnabled = areAllDependenciesSatisfied == true;
    // Pseudo-disabled means it's enabled but has a warning outline.
    final isButtonPseudoDisabled = isButtonEnabled && !isSupportedByGameVersion;

    // Button color logic
    final buttonColor = switch ((
      hasMultipleEnabled,
      widget.mod.hasEnabledVariant,
    )) {
      (true, _) => errorColor,
      (false, true) => theme.colorScheme.secondary,
      _ => theme.colorScheme.surface,
    };

    final textColor = switch ((
      hasMultipleEnabled,
      widget.mod.hasEnabledVariant,
    )) {
      (true, _) => theme.colorScheme.onSecondary.darker(20),
      (false, true) => theme.colorScheme.onSecondary,
      _ => theme.colorScheme.onSurface,
    };

    final borderColor =
        (isButtonEnabled && !isButtonPseudoDisabled)
            ? (hasMultipleEnabled
                ? ThemeManager.vanillaErrorColor.darker(20)
                : theme.colorScheme.secondary.darker(20))
            : ThemeManager.vanillaErrorColor.withOpacity(0.4);

    Color? getGameCompatibilityTextColor(ModVariant variant) {
      // Special handling if background color is errorColor. GameCompat color is orange/red, which is too hard to see.
      return buttonColor == errorColor
          ? null
          : modCompatibilityMap[variant.smolId]?.gameCompatibility
              .getGameCompatibilityColor();
    }

    final buttonStyle = ElevatedButton.styleFrom(
      foregroundColor: textColor,
      disabledForegroundColor: textColor,
      backgroundColor: buttonColor,
      disabledBackgroundColor: buttonColor,
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      textStyle: const TextStyle(
        fontWeight: FontWeight.w900,
        fontFamily: "Orbitron",
      ),
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
    final errorTooltip =
        hasMultipleEnabled
            ? "Warning"
                "\nYou have two or more enabled mod folders for ${mainVariant?.modInfo.nameOrId}. The game will pick one at 'random'."
                "\nSelect one version from the dropdown."
            : areAllDependenciesSatisfied == false
            ? "Requires ${modDependenciesSatisfied?.where((it) => !it.canBeSatisfiedWithInstalledMods).joinToString(transform: (it) => it.dependency.nameOrId)}"
            : null;
    final warningIcon = Icon(Icons.warning, color: textColor, size: 20);
    final currentStarsectorVersion = ref.watch(
      appSettings.select((s) => s.lastStarsectorVersion),
    );
    final isGameRunning = ref.watch(AppState.isGameRunning).value == true;

    //////// Single variant button
    if (isSingleVariant) {
      final tooltipMessage =
          errorTooltip ??
          (widget.showTooltip
              ? (!isSupportedByGameVersion ? gameVersionMessage : "")
              : null);
      return MovingTooltipWidget.text(
        message: tooltipMessage,
        warningLevel:
            tooltipMessage != null
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
                  widget.mod.hasEnabledVariant
                      ? await switchToVariant(null)
                      : await switchToVariant(widget.mod.findHighestVersion);
                } catch (e, st) {
                  Fimber.e("Error changing active mod variant: $e\n$st");
                }
              },
              style: buttonStyle,
              child: Stack(
                children: [
                  (hasMultipleEnabled
                      ? Align(
                        alignment: Alignment.centerLeft,
                        child: warningIcon,
                      )
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
      );
    }

    //////// Multiple variants button
    final items = [
      if (widget.mod.hasEnabledVariant)
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
    final highestVersionVariant =
        widget.mod.modVariants.maxBy((v) => v.bestVersion ?? Version.zero())!;
    final enabledVariant = widget.mod.findFirstEnabled;
    final canUpgradeVersion =
        enabledVariant != null &&
        enabledVariant.smolId != highestVersionVariant.smolId;
    final variantThatCanBeUpgradedTo =
        canUpgradeVersion ? highestVersionVariant : null;

    return MovingTooltipWidget.text(
      message:
          errorTooltip ??
          (widget.showTooltip
              ? (!isSupportedByGameVersion ? gameVersionMessage : null)
              : null),
      child: Disable(
        isEnabled: isButtonEnabled,
        child: DropdownButton2<ModVariant?>(
          items: items,
          valueListenable: ValueNotifier(enabledVariant),
          openWithLongPress: false,
          alignment: Alignment.centerLeft,
          hint: buildDropdownButton(
            dropdownWidth,
            buttonStyle,
            hasMultipleEnabled,
            warningIcon,
            null,
            textColor,
            variantThatCanBeUpgradedTo,
          ),
          iconStyleData: const IconStyleData(iconSize: 0),
          // Removes ugly grey line below text
          underline: Container(),
          buttonStyleData: ButtonStyleData(
            height: buttonHeight,
            width: dropdownWidth,
            overlayColor: WidgetStateColor.transparent,
          ),
          dropdownStyleData: DropdownStyleData(openInterval: Interval(0, 0.15)),
          selectedItemBuilder: (BuildContext context) {
            return items.map((item) {
              return buildDropdownButton(
                dropdownWidth,
                buttonStyle,
                hasMultipleEnabled,
                warningIcon,
                item,
                textColor,
                variantThatCanBeUpgradedTo,
              );
            }).toList();
          },
          onChanged: (ModVariant? variant) async {
            await switchToVariant(variant);
          },
        ),
      ),
    );
  }

  Future<void> switchToVariant(ModVariant? modVariant) async {
    ref
        .read(modManager.notifier)
        .changeActiveModVariantWithForceModGameVersionDialogIfNeeded(
          widget.mod,
          modVariant,
        );
  }

  Widget buildDropdownButton(
    double dropdownWidth,
    ButtonStyle buttonStyle,
    bool hasMultipleEnabled,
    Icon warningIcon,
    DropdownItem<ModVariant?>? item,
    Color textColor,
    ModVariant? variantThatCanBeUpgradedTo,
  ) {
    return SizedBox(
      width: dropdownWidth,
      child: ElevatedButton(
        onPressed: null,
        style:
            variantThatCanBeUpgradedTo == null
                ? buttonStyle
                : buttonStyle.copyWith(
                  padding: WidgetStatePropertyAll(EdgeInsets.zero),
                ),
        child: Stack(
          children: [
            (hasMultipleEnabled
                ? Align(alignment: Alignment.centerLeft, child: warningIcon)
                : Container()),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 16),
                Expanded(
                  child: Align(
                    alignment: Alignment.center,
                    child:
                        item?.value == null
                            ? const Text("Enable")
                            : item?.child,
                  ),
                ),
                SizedBox(
                  width: 16,
                  child: Icon(
                    Icons.arrow_drop_down,
                    color: textColor,
                    size: 24,
                  ),
                ),
              ],
            ),
            if (variantThatCanBeUpgradedTo != null)
              buildUpgradeButton(
                variantThatCanBeUpgradedTo,
                getColorForCurrentState(buttonStyle.backgroundColor!, {
                  WidgetState.selected,
                }),
              ),
          ],
        ),
      ),
    );
  }

  Widget buildUpgradeButton(
    ModVariant variantThatCanBeUpgradedTo,
    Color? buttonBackgroundColor,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Spacer(),
        InkWell(
          onTap: () => switchToVariant(variantThatCanBeUpgradedTo),
          child: MovingTooltipWidget.text(
            message:
                "Click to use newer version ${variantThatCanBeUpgradedTo.bestVersion}",
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: SizedBox(
                    width: 32,
                    child: Container(
                      decoration: BoxDecoration(
                        color: buttonBackgroundColor?.lighter(8),
                        border: Border.all(
                          color: buttonBackgroundColor!.darker(6),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(ThemeManager.cornerRadius),
                          bottomRight: Radius.circular(
                            ThemeManager.cornerRadius,
                          ),
                        ),
                      ),
                      child: SvgImageIcon(
                        "assets/images/icon-swap-upgrade.svg",
                        height: 16,
                        width: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color? getColorForCurrentState(
    WidgetStateProperty<Color?> stateProperty,
    Set<WidgetState> states,
  ) {
    return stateProperty.resolve(states);
  }
}
