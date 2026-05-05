import 'chipper_state.dart';

String createSystemCopyString(LogChips? chips) =>
    "Game: ${chips?.gameVersion ?? "Not found in log."}\nJava: ${chips?.javaVersion ?? "Not found in log."}\nOS: ${chips?.os ?? "Not found in log."}";

String createModsCopyString(LogChips? chips, {bool minify = false}) {
  final mods = chips?.modList.modList ?? const [];
  final lines = mods.map((e) {
    if (minify) {
      // Fall back to modName when id/version are missing (e.g. poor man's
      // mod list parsed from "Loading CSV data from" lines).
      if (e.modId == null && e.modVersion == null) {
        return e.modName ?? '';
      }
      return "${e.modId ?? e.modName ?? ''} ${e.modVersion ?? ''}".trimRight();
    }
    if (e.modId == null && e.modVersion == null) {
      return e.modName ?? '';
    }
    return "${e.modName ?? ''}  v${e.modVersion ?? ''}  [${e.modId ?? ''}]";
  });
  return "Mods (${mods.length})\n${lines.join('\n')}";
}

String createErrorsCopyString(LogChips? chips) =>
    "Line: Error message\n${chips?.errorBlock.map((e) => "${e.lineNumber}: ${e.fullError}").join('\n')}";
