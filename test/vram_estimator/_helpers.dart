import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:trios/models/mod_info.dart';
import 'package:trios/vram_estimator/models/vram_checker_models.dart';
import 'package:trios/vram_estimator/selectors/vram_asset_selector.dart';

/// Creates a temporary mod folder at [dir] and writes each entry of [files]
/// (relative-path -> contents). Returns the `(mod, files)` pair a parser
/// would receive from `VramChecker`.
({VramCheckerMod mod, List<VramModFile> files}) buildModFixture(
  Directory dir,
  Map<String, String> files,
) {
  for (final entry in files.entries) {
    final absolute = p.join(dir.path, entry.key);
    final f = File(absolute);
    f.parent.createSync(recursive: true);
    f.writeAsStringSync(entry.value);
  }
  final mod = VramCheckerMod(
    ModInfo(id: 'test_mod', name: 'Test Mod'),
    dir.path,
  );
  final vramFiles = <VramModFile>[];
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is! File) continue;
    vramFiles.add(
      VramModFile(
        file: entity,
        relativePath: p.relative(entity.path, from: dir.path),
      ),
    );
  }
  return (mod: mod, files: vramFiles);
}

VramSelectorContext buildTestContext({
  List<String>? logLines,
  bool isCancelled = false,
}) {
  return VramSelectorContext(
    verboseOut: (msg) {
      logLines?.add(msg);
    },
    debugOut: (msg) {
      logLines?.add(msg);
    },
    isCancelled: () => isCancelled,
    showPerformance: false,
    graphicsLibEntries: const [],
  );
}
