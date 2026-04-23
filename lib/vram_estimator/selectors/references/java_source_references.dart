import 'package:trios/vram_estimator/models/vram_checker_models.dart';
import 'package:trios/vram_estimator/selectors/path_normalizer.dart';
import 'package:trios/vram_estimator/selectors/references/_scripting_filter.dart';
import 'package:trios/vram_estimator/selectors/references/reference_parser.dart';
import 'package:trios/vram_estimator/selectors/vram_asset_selector.dart';

/// Scans every `.java` source file anywhere in the mod for double-quoted
/// string literals that look like asset paths. Some mods ship unbuilt
/// sources instead of (or alongside) compiled jars.
class JavaSourceReferences extends ReferenceParser {
  @override
  String get id => 'java-sources';

  @override
  String get displayName => 'Loose .java sources';

  @override
  String get description =>
      'Path-like string literals in any .java source file in the mod.';

  // Match double-quoted string literals. Handles escaped quotes (\") and
  // escaped backslashes. Does not attempt to handle Java 15+ text blocks
  // (triple-quoted) — rare in mod scripts; they'd appear as empty matches
  // which the filter rejects.
  static final RegExp _stringLiteral = RegExp(r'"((?:\\.|[^"\\])*)"');

  @override
  Future<Map<String, Set<String>>> collect(
    VramCheckerMod mod,
    List<VramModFile> allFiles,
    VramSelectorContext ctx,
  ) async {
    // Pre-compute normalized on-disk image paths for directory-prefix expansion.
    final onDiskImages = _collectOnDiskImages(allFiles);

    final refs = <String, Set<String>>{};

    for (final f in allFiles) {
      if (ctx.isCancelled()) break;
      if (!f.file.path.toLowerCase().endsWith('.java')) continue;
      try {
        // Async read so file I/O doesn't block the UI.
        final text = await f.file.readAsString();
        _extractFromSource(text, f.relativePath, refs, onDiskImages);
        // Yield to the event loop between files so a large source set
        // doesn't monopolize the UI thread.
        await Future<void>.delayed(Duration.zero);
      } catch (e) {
        ctx.verboseOut(
          '[JavaSourceReferences] Failed to read ${f.file.path}: $e',
        );
      }
    }

    return refs;
  }

  /// Pre-compute normalized paths of every image file in the mod, so
  /// directory-prefix literals can be expanded without repeatedly walking
  /// `allFiles`.
  static List<String> _collectOnDiskImages(List<VramModFile> allFiles) {
    final out = <String>[];
    for (final f in allFiles) {
      final norm = PathNormalizer.normalize(f.relativePath);
      if (PathNormalizer.hasImageExtension(norm)) {
        out.add(norm);
      }
    }
    return out;
  }

  static void _extractFromSource(
    String src,
    String source,
    Map<String, Set<String>> refs,
    List<String> onDiskImages,
  ) {
    final stripped = _stripLineAndBlockComments(src);
    for (final m in _stringLiteral.allMatches(stripped)) {
      final raw = m.group(1) ?? '';
      if (raw.isEmpty) continue;
      final unescaped = _unescape(raw);
      final normalized = PathNormalizer.normalize(unescaped);
      if (!ScriptingStringFilter.shouldRetain(normalized)) continue;
      if (ScriptingStringFilter.isDirectoryPrefix(normalized)) {
        final matched = <String>[];
        for (final disk in onDiskImages) {
          if (disk.startsWith(normalized)) {
            matched.add(disk);
          }
        }
        if (matched.isNotEmpty) {
          addRefsWithSource(refs, matched, source);
        }
      } else {
        addRefsWithSource(refs, PathNormalizer.expand(unescaped), source);
      }
    }
  }

  /// Strip `//` and `/* */` comments while preserving string literals.
  static String _stripLineAndBlockComments(String src) {
    final sb = StringBuffer();
    var i = 0;
    var inString = false;
    var prev = '';
    while (i < src.length) {
      final c = src[i];
      if (inString) {
        sb.write(c);
        if (c == '"' && prev != r'\') inString = false;
        prev = c;
        i++;
        continue;
      }
      if (c == '"') {
        inString = true;
        sb.write(c);
        prev = c;
        i++;
        continue;
      }
      if (c == '/' && i + 1 < src.length) {
        final next = src[i + 1];
        if (next == '/') {
          final nl = src.indexOf('\n', i + 2);
          if (nl == -1) return sb.toString();
          i = nl;
          continue;
        }
        if (next == '*') {
          final end = src.indexOf('*/', i + 2);
          if (end == -1) return sb.toString();
          i = end + 2;
          continue;
        }
      }
      sb.write(c);
      prev = c;
      i++;
    }
    return sb.toString();
  }

  static String _unescape(String s) {
    final sb = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final c = s[i];
      if (c == r'\' && i + 1 < s.length) {
        final next = s[i + 1];
        switch (next) {
          case r'\':
            sb.write(r'\');
            break;
          case '"':
            sb.write('"');
            break;
          case 'n':
            sb.write('\n');
            break;
          case 't':
            sb.write('\t');
            break;
          case 'r':
            sb.write('\r');
            break;
          default:
            sb.write(next);
        }
        i++;
      } else {
        sb.write(c);
      }
    }
    return sb.toString();
  }
}
