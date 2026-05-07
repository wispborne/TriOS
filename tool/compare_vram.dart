// One-off comparison tool: TriOS VRAM cache JSON vs in-game profiler JSON.
// Run with:
//   dart run tool/compare_vram.dart <trios.json> <game.json>

import 'dart:convert';
import 'dart:io';

import 'package:trios/vram_estimator/models/vram_checker_models.dart';

void main(List<String> args) async {
  if (args.length != 2) {
    stderr.writeln(
      'Usage: dart run tool/compare_vram.dart <trios.json> <game.json>',
    );
    exit(2);
  }

  // Game JSON has trailing commas + Java-style line continuations within
  // string literals (`\\\n   ` = backslash-newline-indent). Strip both.
  final gameRaw = await File(args[1]).readAsString();
  final noContinuations = gameRaw.replaceAll(RegExp(r'\\\r?\n\s*'), '');
  final gameClean = noContinuations.replaceAllMapped(
    RegExp(r',(\s*[}\]])'),
    (m) => m.group(1)!,
  );
  final gameJson = jsonDecode(gameClean) as Map<String, dynamic>;
  final gameTextures = (gameJson['textures'] as List).cast<Map>();

  // Build path -> {bytes, w, h} map.
  final gameByPath = <String, _GameEntry>{};
  int gameGrandTotal = 0;
  for (final t in gameTextures) {
    final path = (t['path'] as String).replaceAll('\\', '/').toLowerCase();
    final bytes = t['totalBytes'] as int;
    final w = t['gpuWidth'] as int;
    final h = t['gpuHeight'] as int;
    final existing = gameByPath[path];
    if (existing == null) {
      gameByPath[path] = _GameEntry(bytes, w, h);
    } else {
      gameByPath[path] = _GameEntry(existing.bytes + bytes, w, h);
    }
    gameGrandTotal += bytes;
  }

  // TriOS JSON.
  final triosJson =
      jsonDecode(await File(args[0]).readAsString()) as Map<String, dynamic>;
  final modVramInfo = (triosJson['modVramInfo'] as Map);

  int triosGrandTotal = 0;
  // Keyed by relPath, stores {bytes, w, h} (last-write-wins on dims —
  // when multiple mods have same relPath, this is approximate).
  final triosByPath = <String, _TriosEntry>{};
  int totalImages = 0;

  for (final entry in modVramInfo.entries) {
    final mod = entry.value as Map;
    final imagesObj = mod['images'];
    if (imagesObj is! Map) continue;
    final filePaths = (imagesObj['filePaths'] as List).cast<String>();
    final widths = (imagesObj['textureWidths'] as List).cast<int>();
    final heights = (imagesObj['textureHeights'] as List).cast<int>();
    for (var i = 0; i < filePaths.length; i++) {
      totalImages++;
      final w = widths[i];
      final h = heights[i];

      final hasMipmaps = w <= 1024 && h <= 1024;
      final totalBytes = hasMipmaps ? mipmapChainBytes(w, h) : w * h * 4;
      // Skip TriOS background-vanilla subtraction here — we want the raw
      // estimated bytes to compare against the game's totalBytes.

      triosGrandTotal += totalBytes;

      final fullPath = filePaths[i].replaceAll('\\', '/').toLowerCase();
      // Game JSON paths are mod-relative ("graphics/...").
      // TriOS stores absolute paths. Find the last "graphics/" or
      // "/data/" segment and key on that suffix.
      final relIdx = _findGameRelative(fullPath);
      if (relIdx < 0) continue;
      final relPath = fullPath.substring(relIdx);

      final existing = triosByPath[relPath];
      if (existing == null) {
        triosByPath[relPath] = _TriosEntry(totalBytes, w, h);
      } else {
        triosByPath[relPath] = _TriosEntry(
          existing.bytes + totalBytes,
          w,
          h,
        );
      }

    }
  }

  print('=== Inputs ===');
  print(
    'Game JSON:  ${gameTextures.length} textures, '
    '${(gameGrandTotal / 1024 / 1024).toStringAsFixed(2)} MB',
  );
  print(
    'TriOS JSON: $totalImages images across ${modVramInfo.length} mods, '
    '${(triosGrandTotal / 1024 / 1024).toStringAsFixed(2)} MB',
  );
  print('');

  // Compare on intersection.
  final allPaths = <String>{...triosByPath.keys, ...gameByPath.keys};
  int sameDimsExactMatch = 0;
  int sameDimsBytesMismatch = 0;
  int dimsMismatch = 0;
  int onlyInTrios = 0;
  int onlyInGame = 0;
  final dimMismatches = <_Mismatch>[];
  final byteMismatches = <_Mismatch>[];

  for (final path in allPaths) {
    final t = triosByPath[path];
    final g = gameByPath[path];
    if (t == null) {
      onlyInGame++;
      continue;
    }
    if (g == null) {
      onlyInTrios++;
      continue;
    }
    final dimsMatch = (t.w == g.w && t.h == g.h);
    if (!dimsMatch) {
      dimsMismatch++;
      dimMismatches.add(_Mismatch(path, t.bytes, g.bytes, t.w, t.h, g.w, g.h));
      continue;
    }
    if (t.bytes == g.bytes) {
      sameDimsExactMatch++;
    } else {
      sameDimsBytesMismatch++;
      byteMismatches.add(
        _Mismatch(path, t.bytes, g.bytes, t.w, t.h, g.w, g.h),
      );
    }
  }

  print('=== Comparison (intersection by path) ===');
  print('Dim match + bytes exact:  $sameDimsExactMatch');
  print('Dim match + bytes differ: $sameDimsBytesMismatch  (FORMULA BUG if >0)');
  print('Dim mismatch:             $dimsMismatch  (game runtime-resized)');
  print('In TriOS only (not loaded this session):     $onlyInTrios');
  print('In game only (vanilla / not in TriOS scan):  $onlyInGame');

  // Sum byte totals on the dim-match subset (formula validity).
  final dimMatchTriosTotal = sameDimsExactMatch == 0
      ? 0
      : allPaths
          .where((p) {
            final t = triosByPath[p];
            final g = gameByPath[p];
            return t != null && g != null && t.w == g.w && t.h == g.h;
          })
          .fold<int>(0, (a, p) => a + triosByPath[p]!.bytes);
  print('');
  print('Dim-match-set TriOS bytes: ${(dimMatchTriosTotal / 1024).toStringAsFixed(0)} KB');

  if (byteMismatches.isNotEmpty) {
    print('');
    print('=== Same-dim byte mismatches (formula issues) — top 25 ===');
    byteMismatches.sort(
      (a, b) =>
          (b.trios - b.game).abs().compareTo((a.trios - a.game).abs()),
    );
    for (final m in byteMismatches.take(25)) {
      final d = m.trios - m.game;
      print('  ${m.path}  ${m.tw}x${m.th}');
      print('    trios=${m.trios}  game=${m.game}  delta=$d');
    }
  }

  if (dimMismatches.isNotEmpty) {
    print('');
    print('=== Dim mismatches — top 10 (largest TriOS overestimate) ===');
    dimMismatches.sort((a, b) => b.trios.compareTo(a.trios));
    for (final m in dimMismatches.take(10)) {
      print(
        '  ${m.path}  trios=${m.tw}x${m.th} (${m.trios}b)  game=${m.gw}x${m.gh} (${m.game}b)',
      );
    }
  }
}

class _GameEntry {
  final int bytes;
  final int w;
  final int h;
  _GameEntry(this.bytes, this.w, this.h);
}

class _TriosEntry {
  final int bytes;
  final int w;
  final int h;
  _TriosEntry(this.bytes, this.w, this.h);
}

/// Extract a path suffix that should match between the absolute TriOS path
/// and the mod-relative game path. The game uses paths starting with
/// "graphics/" (or sometimes "data/"); we key on those segments.
int _findGameRelative(String fullPath) {
  // Prefer the last occurrence (in case a parent path contains "graphics" too).
  final candidates = ['/graphics/', '/data/', '/sounds/'];
  int best = -1;
  for (final c in candidates) {
    final idx = fullPath.lastIndexOf(c);
    if (idx > best) best = idx + 1; // skip leading slash
  }
  return best;
}

class _Mismatch {
  final String path;
  final int trios;
  final int game;
  final int tw;
  final int th;
  final int gw;
  final int gh;
  _Mismatch(this.path, this.trios, this.game, this.tw, this.th, this.gw, this.gh);
}
