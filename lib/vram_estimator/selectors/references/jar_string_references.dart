import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:trios/vram_estimator/models/vram_checker_models.dart';
import 'package:trios/vram_estimator/selectors/path_normalizer.dart';
import 'package:trios/vram_estimator/selectors/references/_scripting_filter.dart';
import 'package:trios/vram_estimator/selectors/references/reference_parser.dart';
import 'package:trios/vram_estimator/selectors/vram_asset_selector.dart';

/// Scans every `.jar` file anywhere in the mod folder (not just `jars/`),
/// opens each as a zip archive, parses `.class` entries' constant pools,
/// and extracts `CONSTANT_Utf8` strings that look like asset paths.
///
/// Only the constant pool is parsed; bytecode is never walked.
class JarStringReferences extends ReferenceParser {
  @override
  String get id => 'jar-strings';

  @override
  String get displayName => 'JAR string literals';

  @override
  String get description =>
      'Path-like string literals in compiled classes of every .jar in the mod.';

  @override
  Future<Map<String, Set<String>>> collect(
    VramCheckerMod mod,
    List<VramModFile> allFiles,
    VramSelectorContext ctx,
  ) async {
    final onDiskImages = _collectOnDiskImages(allFiles);
    final refs = <String, Set<String>>{};

    for (final f in allFiles) {
      if (ctx.isCancelled()) break;
      if (!f.file.path.toLowerCase().endsWith('.jar')) continue;
      try {
        // Async read so file I/O doesn't block the UI.
        final bytes = await f.file.readAsBytes();
        // Zip decode + per-class constant-pool parsing run on a background
        // isolate — this is the single heaviest piece of scanning work and
        // would otherwise freeze the UI for hundreds of ms per mod.
        final jarRefs = await Isolate.run(
          () => _scanJarBytes(bytes, onDiskImages),
        );
        addRefsWithSource(refs, jarRefs, f.relativePath);
      } catch (e) {
        ctx.verboseOut(
          '[JarStringReferences] Failed to read ${f.file.path}: $e',
        );
      }
      // Yield between JARs — readAsBytes + Isolate.run handoff for a
      // large JAR is a main-isolate cost that can stack up on big mods.
      await Future<void>.delayed(Duration.zero);
    }

    return refs;
  }

  /// Run in a background isolate. Pure compute — takes bytes + a list of
  /// already-normalized on-disk image paths, returns the matched refs.
  static Set<String> _scanJarBytes(
    Uint8List bytes,
    List<String> onDiskImages,
  ) {
    final refs = <String>{};
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      for (final entry in archive.files) {
        if (!entry.isFile) continue;
        if (!entry.name.toLowerCase().endsWith('.class')) continue;
        final data = entry.content;
        if (data is! List<int>) continue;
        _extractFromClassFile(
          Uint8List.fromList(data),
          refs,
          onDiskImages,
        );
      }
    } catch (_) {
      // Caller logs the failure; just return what we have.
    }
    return refs;
  }

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

  /// Parse a Java class file's constant pool and extract CONSTANT_Utf8
  /// entries (tag 1). Format reference: JVMS §4.4.
  static void _extractFromClassFile(
    Uint8List bytes,
    Set<String> refs,
    List<String> onDiskImages,
  ) {
    if (bytes.length < 10) return;
    final bd = ByteData.sublistView(bytes);
    // Magic + minor + major = 8 bytes. Then 2-byte constant_pool_count.
    if (bd.getUint32(0) != 0xCAFEBABE) return;
    var offset = 8;
    final cpCount = bd.getUint16(offset);
    offset += 2;

    // Indices are 1-based; the `cpCount - 1` entries follow.
    var index = 1;
    while (index < cpCount && offset < bytes.length) {
      final tag = bytes[offset];
      offset += 1;
      switch (tag) {
        case 1: // CONSTANT_Utf8
          if (offset + 2 > bytes.length) return;
          final len = bd.getUint16(offset);
          offset += 2;
          if (offset + len > bytes.length) return;
          final s = _decodeJavaModifiedUtf8(
            Uint8List.sublistView(bytes, offset, offset + len),
          );
          offset += len;
          if (s != null) _consider(s, refs, onDiskImages);
          break;
        case 7: // CONSTANT_Class
        case 8: // CONSTANT_String
        case 16: // CONSTANT_MethodType
        case 19: // CONSTANT_Module
        case 20: // CONSTANT_Package
          offset += 2;
          break;
        case 9: // CONSTANT_Fieldref
        case 10: // CONSTANT_Methodref
        case 11: // CONSTANT_InterfaceMethodref
        case 12: // CONSTANT_NameAndType
        case 17: // CONSTANT_Dynamic
        case 18: // CONSTANT_InvokeDynamic
          offset += 4;
          break;
        case 3: // CONSTANT_Integer
        case 4: // CONSTANT_Float
          offset += 4;
          break;
        case 5: // CONSTANT_Long
        case 6: // CONSTANT_Double
          offset += 8;
          // Long/Double occupy two entries per JVMS §4.4.5.
          index += 1;
          break;
        case 15: // CONSTANT_MethodHandle
          offset += 3;
          break;
        default:
          // Unknown tag — bail to avoid misaligned reads.
          return;
      }
      index += 1;
    }
  }

  static void _consider(
    String raw,
    Set<String> refs,
    List<String> onDiskImages,
  ) {
    final normalized = PathNormalizer.normalize(raw);
    if (!ScriptingStringFilter.shouldRetain(normalized)) return;
    if (ScriptingStringFilter.isDirectoryPrefix(normalized)) {
      for (final disk in onDiskImages) {
        if (disk.startsWith(normalized)) {
          refs.add(disk);
        }
      }
    } else {
      refs.addAll(PathNormalizer.expand(raw));
    }
  }

  /// Decode Java's modified UTF-8 (JVMS §4.4.7). The common subset matches
  /// standard UTF-8 closely; this handles the deltas (null byte encoded as
  /// 0xC0 0x80, supplementary pairs). Falls back to latin-1 decoding on
  /// error — we only need string contents for literal matching, not full
  /// correctness.
  static String? _decodeJavaModifiedUtf8(Uint8List bytes) {
    final sb = StringBuffer();
    var i = 0;
    while (i < bytes.length) {
      final b = bytes[i];
      if (b == 0) {
        return null; // Invalid in modified UTF-8
      }
      if ((b & 0x80) == 0) {
        sb.writeCharCode(b);
        i++;
      } else if ((b & 0xE0) == 0xC0) {
        if (i + 1 >= bytes.length) return null;
        final b2 = bytes[i + 1];
        sb.writeCharCode(((b & 0x1F) << 6) | (b2 & 0x3F));
        i += 2;
      } else if ((b & 0xF0) == 0xE0) {
        if (i + 2 >= bytes.length) return null;
        final b2 = bytes[i + 1];
        final b3 = bytes[i + 2];
        sb.writeCharCode(
          ((b & 0x0F) << 12) | ((b2 & 0x3F) << 6) | (b3 & 0x3F),
        );
        i += 3;
      } else {
        // Unexpected in modified UTF-8; fall back to raw byte.
        sb.writeCharCode(b);
        i++;
      }
    }
    return sb.toString();
  }
}
