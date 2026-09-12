import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:trios/modpacks/models/modpack_definition.dart';
import 'package:trios/modpacks/models/modpack_library_entry.dart';
import 'package:trios/modpacks/modpack_format.dart';
import 'package:trios/modpacks/modpack_file_parser.dart';
import 'package:trios/modpacks/modpack_link_codec.dart';
import 'package:trios/utils/http_client.dart';
import 'package:trios/utils/http_probe.dart';

bool isModpackFile(String path) =>
    path.toLowerCase().endsWith('.trios-modpack');

/// Any transport prefix, not just [modpackPayloadFormat]. A payload numbered
/// for a format TriOS doesn't know is still a modpack, and must report that
/// rather than be downloaded as an archive.
final RegExp _payloadPrefix = RegExp(r'^\d+\.');

/// Recognizes even malformed pack links so they cannot fall through to an
/// ordinary archive download. Decoding remains the codec's job, so this stays
/// deliberately looser than [extractModpackLinkPayload]: an empty or
/// wrong-format payload is recognized here and rejected there.
bool isIncomingModpack(String input) {
  final text = input.trim();
  if (isModpackFile(text)) return true;
  if (_payloadPrefix.hasMatch(text)) return true;
  final uri = Uri.tryParse(text);
  if (uri == null) return false;
  if (uri.scheme == 'file') return isModpackFile(uri.path);
  try {
    return uri.queryParameters.containsKey(modpackLinkParameter) ||
        Uri.splitQueryString(uri.fragment).containsKey(modpackLinkParameter);
  } on FormatException {
    return text.contains(modpackLinkParameter);
  }
}

Future<ModpackDefinition> readIncomingModpack(String input) async {
  final text = input.trim();
  final uri = Uri.tryParse(text);
  if (uri?.scheme == 'file' || (isModpackFile(text) && !text.contains('://'))) {
    if (uri?.scheme == 'file' &&
        uri!.host.isNotEmpty &&
        uri.host != 'localhost') {
      throw const FormatException('Open a local modpack file.');
    }
    final file = uri?.scheme == 'file' ? File.fromUri(uri!) : File(text);
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in file.openRead()) {
      if (bytes.length + chunk.length > ModpackLimits.maxExpandedBytes) {
        throw const FormatException('The modpack file is larger than 4 MB.');
      }
      bytes.add(chunk);
    }
    return decodeModpackFileBytes(bytes.takeBytes());
  }
  return decodeModpackLink(text);
}

ModpackDefinition decodeModpackFileBytes(List<int> bytes) {
  if (bytes.length > ModpackLimits.maxExpandedBytes) {
    throw const FormatException('The modpack file is larger than 4 MB.');
  }
  return decodeModpackDefinition(parseModpackFileText(utf8.decode(bytes)));
}

enum IncomingModpackMatch {
  newPack,
  saved,
  draft,
  savedConflict,
  draftConflict,
}

IncomingModpackMatch matchIncomingModpack(
  ModpackDefinition incoming,
  ModpacksData data,
) {
  final draft = data.drafts[incoming.id];
  if (draft != null) {
    // Drafts have no version of their own. Compare their editable contents.
    return draft.isCommittable &&
            modpackDefinitionsAreIdentical(
              draft.toDefinition(version: incoming.version),
              incoming,
            )
        ? .draft
        : .draftConflict;
  }
  final saved = data.packs[incoming.id];
  if (saved == null) return .newPack;
  return modpackDefinitionsAreIdentical(saved.definition, incoming)
      ? .saved
      : .savedConflict;
}

typedef IncomingModpackFetch = Future<ModpackDefinition> Function(
  String url,
  HttpProbeCancellation cancellation,
);

Future<ModpackDefinition> fetchHostedModpack(
  TriOSHttpClient client,
  String url,
  HttpProbeCancellation cancellation,
) async {
  final response = await client.probe(
    Uri.parse(url),
    maxBytes: ModpackLimits.maxExpandedBytes,
    prefixOnly: false,
    cancellation: cancellation,
  );
  return decodeModpackFileBytes(response.bytes);
}

/// No I/O on construction. A check offers another definition without selecting
/// it. Starting an add freezes the chosen definition and ignores late results.
class IncomingModpackSession extends ChangeNotifier {
  final ModpackDefinition embedded;
  final IncomingModpackFetch fetch;
  late ModpackDefinition selected = embedded;
  ModpackDefinition? online;
  String? message;
  bool checking = false;
  bool acting = false;
  bool _disposed = false;
  int _generation = 0;
  HttpProbeCancellation? _cancellation;

  IncomingModpackSession(this.embedded, {required this.fetch});

  /// True once a check's result no longer matters: the session is gone, or a
  /// newer check or an add has started. [beginAction] bumps the generation, so
  /// this covers acting too.
  bool _stale(int generation) => _disposed || generation != _generation;

  Future<void> checkForUpdate() async {
    final url = selected.updateUrl;
    if (checking || acting || url == null) return;
    final generation = ++_generation;
    final snapshot = selected;
    final cancellation = HttpProbeCancellation();
    _cancellation = cancellation;
    checking = true;
    message = null;
    online = null;
    notifyListeners();
    try {
      final result = await fetch(url, cancellation);
      if (_stale(generation)) return;
      if (result.id != snapshot.id) {
        message = 'The update address returned a different modpack. It cannot replace this pack.';
      } else if (result.version < snapshot.version) {
        message = 'The online copy is older than this modpack.';
      } else if (modpackDefinitionsAreIdentical(result, snapshot)) {
        message = 'This modpack is up to date.';
      } else {
        online = result;
        message = 'An online definition is available to review.';
      }
    } catch (e) {
      if (_stale(generation)) return;
      message = 'Could not check for an update: $e';
    } finally {
      if (!_stale(generation)) {
        checking = false;
        notifyListeners();
      }
    }
  }

  void selectOnline() {
    if (acting || online == null) return;
    selected = online!;
    online = null;
    message = 'The preview now shows the online definition.';
    notifyListeners();
  }

  ModpackDefinition beginAction() {
    acting = true;
    checking = false;
    _generation++;
    _cancellation?.cancel();
    notifyListeners();
    return selected;
  }

  void endAction() {
    if (_disposed) return;
    acting = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _cancellation?.cancel();
    super.dispose();
  }
}
