import 'app_state.dart';

String createSystemCopyString(LogChips? chips) =>
    "Game: ${chips?.gameVersion ?? "Not found in log."}\nJava: ${chips?.javaVersion ?? "Not found in log."}\nOS: ${chips?.os ?? "Not found in log."}";

String createModsCopyString(LogChips? chips, {bool minify = false}) =>
    "Mods (${chips?.modList.modList.length})\n${chips?.modList.modList.map((e) => minify ? "${e.modId} ${e.modVersion}" : "${e.modName}  v${e.modVersion}  [${e.modId}]").join('\n')}";

String createErrorsCopyString(LogChips? chips) =>
    "Line: Error message\n${chips?.errorBlock.map((e) => "${e.lineNumber}: ${e.fullError}").join('\n')}";
