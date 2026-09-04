import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:trios/modpacks/models/modpack_definition.dart';
import 'package:trios/modpacks/modpack_format.dart';

/// The transport number prefixed to a compressed payload. It describes
/// compression and encoding, not the definition's `formatVersion`.
const String modpackPayloadFormat = '1';

/// The query and fragment parameter name carrying a whole modpack.
const String modpackLinkParameter = 'modpack';

/// Where TriLink lives.
const String trilinkOpenPageUrl = 'https://trilink.wispborne.com/open.html';

/// Compresses a definition into a `1.<base64url>` link payload: canonical
/// JSON, zlib deflate, unpadded base64url, transport prefix.
String encodeModpackPayload(ModpackDefinition definition) {
  final json = encodeModpackDefinitionJson(definition);
  final deflated = ZLibCodec(level: 9).encode(utf8.encode(json));
  final encoded = base64Url.encode(deflated).replaceAll('=', '');
  return '$modpackPayloadFormat.$encoded';
}

/// Reads a definition back out of a link payload. Throws
/// [ModpackFormatException] for anything that isn't a valid TriOS payload.
ModpackDefinition decodeModpackPayload(String payload) {
  final trimmed = payload.trim();
  if (trimmed.isEmpty) {
    throw const ModpackFormatException(
      ModpackFormatError.missingPayload,
      'The modpack link has no pack in it.',
    );
  }
  if (trimmed.length > ModpackLimits.maxLinkCharacters) {
    throw const ModpackFormatException(
      ModpackFormatError.payloadTooLarge,
      'The modpack link is too large to read.',
    );
  }

  final separator = trimmed.indexOf('.');
  if (separator <= 0) {
    throw const ModpackFormatException(
      ModpackFormatError.malformedPayload,
      'The modpack payload is malformed.',
    );
  }
  final format = trimmed.substring(0, separator);
  if (format != modpackPayloadFormat) {
    throw ModpackFormatException(
      ModpackFormatError.unsupportedTransportFormat,
      'This modpack link uses format $format. Update TriOS to open it.',
    );
  }

  final body = trimmed.substring(separator + 1);
  if (body.isEmpty) {
    throw const ModpackFormatException(
      ModpackFormatError.malformedPayload,
      'The modpack payload is empty.',
    );
  }

  final List<int> deflated;
  try {
    deflated = base64Url.decode(base64.normalize(body));
  } catch (_) {
    throw const ModpackFormatException(
      ModpackFormatError.malformedPayload,
      'The modpack payload is not valid base64url.',
    );
  }

  final expanded = _inflateWithLimit(deflated);

  final Object? parsed;
  try {
    parsed = jsonDecode(utf8.decode(expanded));
  } catch (_) {
    throw const ModpackFormatException(
      ModpackFormatError.malformedPayload,
      'The modpack payload does not contain valid JSON.',
    );
  }

  return decodeModpackDefinition(parsed);
}

/// Inflates [deflated], stopping as soon as the output passes the expanded
/// limit so an oversized payload can't use up memory first.
List<int> _inflateWithLimit(List<int> deflated) {
  final sink = _LimitedByteSink(ModpackLimits.maxExpandedBytes);
  final inflater = ZLibCodec().decoder.startChunkedConversion(sink);
  try {
    inflater.add(deflated);
    inflater.close();
  } on _ExpandedTooLargeError {
    throw const ModpackFormatException(
      ModpackFormatError.payloadTooLarge,
      'The modpack is larger than 4 MB once unpacked.',
    );
  } catch (_) {
    throw const ModpackFormatException(
      ModpackFormatError.decompressionFailed,
      'The modpack payload could not be decompressed.',
    );
  }
  return sink.bytes;
}

class _LimitedByteSink extends ByteConversionSink {
  _LimitedByteSink(this.maxBytes);

  final int maxBytes;
  final BytesBuilder _builder = BytesBuilder(copy: false);

  List<int> get bytes => _builder.toBytes();

  @override
  void add(List<int> chunk) {
    if (_builder.length + chunk.length > maxBytes) {
      throw _ExpandedTooLargeError();
    }
    _builder.add(chunk);
  }

  @override
  void addSlice(List<int> chunk, int start, int end, bool isLast) {
    add(chunk.sublist(start, end));
    if (isLast) close();
  }

  @override
  void close() {}
}

class _ExpandedTooLargeError extends Error {}

/// Builds the browser link someone shares.
///
/// The pack lives in the fragment, which browsers don't send to the server, so
/// a long link never reaches GitHub Pages. The `name` and `version` fields are
/// decoration; only the payload is trusted.
///
/// Throws [ModpackFormatException] with [ModpackFormatError.linkTooLarge] when
/// the link would pass [ModpackLimits.maxLinkCharacters].
String buildModpackShareLink(
  ModpackDefinition definition, {
  String openPageUrl = trilinkOpenPageUrl,
}) {
  final payload = encodeModpackPayload(definition);
  final fragment = [
    'name=${Uri.encodeComponent(_linkNameSlug(definition.name))}',
    'version=${definition.version}',
    '$modpackLinkParameter=$payload',
  ].join('&');
  final link = '$openPageUrl#$fragment';

  if (link.length > ModpackLimits.maxLinkCharacters) {
    throw ModpackFormatException(
      ModpackFormatError.linkTooLarge,
      'This modpack is too large to share as a link '
      '(${link.length} of ${ModpackLimits.maxLinkCharacters} characters).',
    );
  }
  return link;
}

/// Builds the registered-scheme address TriLink hands to TriOS.
String buildModpackDeepLinkUri(String payload) =>
    'starsector-mod://install?$modpackLinkParameter=$payload';

/// Turns a pack name into the readable part of a link.
String _linkNameSlug(String name) {
  final slug = name
      .trim()
      .replaceAll(RegExp(r"[^\w\s-]"), '')
      .replaceAll(RegExp(r'\s+'), '-');
  return slug.isEmpty ? 'Modpack' : slug;
}
