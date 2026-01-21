import 'package:collection/collection.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trios/mod_manager/mod_manager_extensions.dart';
import 'package:trios/mod_profiles/models/mod_profile.dart';
import 'package:trios/mod_profiles/models/shared_mod_list.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/thirdparty/dartx/iterable.dart';
import 'package:trios/utils/extensions.dart';

/// Utilities for exporting mod lists to various formats (CSV, clipboard, shared format).
///
/// These functions handle:
/// - Converting mod lists to CSV format
/// - Copying mod information to clipboard with user feedback
/// - Creating shared mod list format for import/export between profiles

/// Exports all mods to CSV format.
///
/// Creates a CSV with mod_info.json field headers and values for each mod.
/// Uses the first enabled or highest version variant for each mod.
String allModsAsCsv(List<Mod> allMods) {
  final modFields = allMods.isNotEmpty
      ? allMods.first.findFirstEnabledOrHighestVersion?.modInfo
                .toMap()
                .keys
                .toList() ??
            []
      : [];
  List<List<dynamic>> rows = [modFields];

  if (allMods.isNotEmpty) {
    rows.addAll(
      allMods.map((mod) {
        final variant = mod.findFirstEnabledOrHighestVersion;
        return variant?.modInfo.toMap().values.toList() ?? [];
      }).toList(),
    );
  }

  final csvContent = const ListToCsvConverter(
    convertNullTo: "",
  ).convert(rows);

  return csvContent;
}

/// Copies mod list to clipboard from mod IDs.
///
/// Looks up mods by ID, sorts them by name, and formats the list
/// before copying to clipboard with a snackbar notification.
void copyModListToClipboardFromIds(
  Set<String>? modIds,
  List<Mod> allMods,
  BuildContext context,
) {
  final enabledModsList = modIds
      .orEmpty()
      .map((id) => allMods.firstWhereOrNull((mod) => mod.id == id))
      .nonNulls
      .toList()
      .sortedByName;
  copyModListToClipboardFromMods(enabledModsList, context);
}

/// Copies a formatted mod list to clipboard.
///
/// Format: "Mods (count)\nModName  vVersion  [modId]"
/// Shows a snackbar notification when complete.
void copyModListToClipboardFromMods(List<Mod> mods, BuildContext context) {
  Clipboard.setData(
    ClipboardData(
      text:
          "Mods (${mods.length})\n${mods.map((mod) {
            final variant = mod.findFirstEnabledOrHighestVersion;
            return "${variant?.modInfo.name}  v${variant?.modInfo.version}  [${mod.id}]";
          }).join('\n')}",
    ),
  );
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Copied mod list to clipboard.")),
  );
}

/// Copies a mod list to clipboard using profile variant information.
///
/// Creates a SharedModList from the provided variants and copies it
/// in a shareable format.
void copyModListToClipboard({
  String? id,
  String? name,
  String? description,
  required List<ShallowModVariant> variants,
  DateTime? dateCreated,
  DateTime? dateModified,
  required BuildContext context,
}) {
  final sharedList = createSharedModListFromVariants(
    id,
    name,
    description,
    dateCreated,
    dateModified,
    variants,
  );
  copySharedModListToClipboard(sharedList, context);
}

/// Copies a SharedModList to clipboard in shareable format.
///
/// Shows a snackbar with instructions for importing via the Mod Profiles page.
void copySharedModListToClipboard(
  SharedModList sharedModList,
  BuildContext context,
) {
  Clipboard.setData(ClipboardData(text: sharedModList.toShareString()));
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        "Copied mod list to clipboard. Import via Mod Profiles page.",
      ),
    ),
  );
}

/// Creates a SharedModList from profile variants.
///
/// Converts profile-specific variant information into the shared mod list
/// format that can be imported/exported between profiles.
SharedModList createSharedModListFromVariants(
  String? id,
  String? name,
  String? description,
  DateTime? dateCreated,
  DateTime? dateModified,
  List<ShallowModVariant> variants,
) {
  final enabledModVariants = variants.map((variant) {
    return SharedModVariant(
      modId: variant.modId,
      modName: variant.modName,
      smolVariantId: variant.smolVariantId,
      versionName: variant.version,
    );
  }).toList();

  return SharedModList.create(
    id: id,
    name: name,
    description: description ?? "Generated mod list from TriOS",
    mods: enabledModVariants,
    dateCreated: dateCreated,
    dateModified: dateModified,
  );
}
