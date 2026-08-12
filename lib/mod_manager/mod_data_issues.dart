import 'package:trios/models/mod_variant.dart';
import 'package:trios/models/version.dart';

/// The kinds of data problems a mod can ship with.
enum ModDataIssueType { versionCheckerMismatch }

/// One detected problem with a mod's data.
class ModDataIssue {
  final ModDataIssueType type;

  /// One line, shown in the tooltip and as the dialog heading.
  final String summary;

  /// Longer explanation, shown only in the dialog.
  final String? detail;

  ModDataIssue({required this.type, required this.summary, this.detail});
}

/// A single check. Returns an issue, or null if the mod passes.
typedef ModDataCheck = ModDataIssue? Function(ModVariant variant);

/// All checks, run in order.
/// To add a check: add a [ModDataIssueType] value, write a function like
/// [_checkVersionCheckerVersionMatchesModInfo], and list it here.
const List<ModDataCheck> _allChecks = [
  _checkVersionCheckerVersionMatchesModInfo,
];

/// Checks a mod variant for data problems shipped by the mod author.
List<ModDataIssue> checkModDataIssues(ModVariant variant) =>
    _allChecks.map((check) => check(variant)).nonNulls.toList();

/// Warns when the `.version` file and `mod_info.json` list different versions.
ModDataIssue? _checkVersionCheckerVersionMatchesModInfo(ModVariant variant) {
  final versionCheckerVersion = variant.versionCheckerVersion;
  final modInfoVersion = variant.modInfo.version;
  if (versionCheckerVersion == null || modInfoVersion == null) return null;

  // Sanitize both the same way (strips letters, keeps digits/dots/hyphens) so
  // formatting differences like "v1.2.3" vs "1.2.3" don't warn, but genuinely
  // different numbers like "0.35" vs "0.3.5" do.
  final versionsMatch = Version.parse(
    versionCheckerVersion.toString(),
  ).equalsSymbolic(Version.parse(modInfoVersion.toString()));
  if (versionsMatch) return null;

  return ModDataIssue(
    type: ModDataIssueType.versionCheckerMismatch,
    summary:
        "Version Checker says $versionCheckerVersion but mod_info.json says $modInfoVersion",
    detail:
        "The mod's .version file and its mod_info.json list different versions."
        " This is a mistake by the mod author."
        " TriOS uses the Version Checker version ($versionCheckerVersion) when comparing versions.",
  );
}
