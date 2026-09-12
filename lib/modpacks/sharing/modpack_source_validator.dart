import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/models/version_checker_info.dart';
import 'package:trios/mod_manager/version_checker.dart';
import 'package:trios/modpacks/models/modpack_definition.dart';
import 'package:trios/modpacks/modpack_format.dart';
import 'package:trios/utils/http_client.dart';
import 'package:trios/utils/http_probe.dart';

final modpackSourceValidatorProvider = Provider(
  (ref) => ModpackSourceValidator.forClient(ref.watch(triOSHttpClient)),
);

class ModpackSourceValidator {
  final HttpProbe probe;
  final Future<VersionCheckerInfo> Function(String, HttpProbeCancellation)?
  fetchVersionInfo;
  final DateTime Function() now;
  final Map<String, DateTime> _successes = {};
  ModpackSourceValidator(
    this.probe, {
    this.fetchVersionInfo,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  factory ModpackSourceValidator.forClient(TriOSHttpClient client) =>
      ModpackSourceValidator(
        client.probe,
        // Reads `.version` files exactly the way the update checker does,
        // including its certificate support.
        fetchVersionInfo: (url, cancellation) => fetchRemoteVersionCheckerInfo(
          url,
          client,
          cancellation: cancellation,
        ),
      );

  Future<VersionCheckerInfo> _readVersionInfo(
    String url,
    HttpProbeCancellation cancellation,
  ) =>
      fetchVersionInfo?.call(url, cancellation) ??
      readVersionCheckerInfo(url, cancellation, probe: probe);

  Future<bool> validate(
    ModpackItem item,
    HttpProbeCancellation cancellation,
  ) async {
    cancellation.check();
    final key = '${item.sourceType.name}|${item.url}';
    final previous = _successes[key];
    if (previous != null &&
        now().difference(previous) < const Duration(minutes: 60)) {
      return true;
    }
    if (!isSafeModpackUrl(item.url)) {
      throw const FormatException('Enter an HTTP or HTTPS download URL.');
    }
    var download = item.url;
    if (item.sourceType == ModpackItemSourceType.versionFile) {
      final info = await _readVersionInfo(item.url.trim(), cancellation);
      cancellation.check();
      final address = info.directDownloadURL;
      if (address is! String || !isSafeModpackUrl(address)) {
        throw const FormatException(
          'The Version Checker file has no usable direct download URL.',
        );
      }
      download = address;
    }
    final result = await probe(
      Uri.parse(fixUrl(download.trim())),
      maxBytes: 512,
      prefixOnly: true,
      cancellation: cancellation,
    );
    if (!isDownloadableModpackResponse(result)) {
      throw const FormatException(
        'The source returned a web page, empty response, or unsupported file instead of a mod archive.',
      );
    }
    cancellation.check();
    _successes.removeWhere(
      (_, at) => now().difference(at) >= const Duration(minutes: 60),
    );
    _successes[key] = now();
    return false;
  }
}

bool isDownloadableModpackResponse(HttpProbeResult response) {
  if (response.bytes.isEmpty) return false;
  final text = utf8
      .decode(response.bytes, allowMalformed: true)
      .trimLeft()
      .toLowerCase();
  if (text.startsWith('<') || text.startsWith('{') || text.startsWith('[')) {
    return false;
  }
  final type = response.contentType?.toLowerCase() ?? '';
  if (type == 'text/html' ||
      type == 'application/json' ||
      type == 'application/xhtml+xml') {
    return false;
  }
  final bytes = response.bytes;
  bool starts(List<int> signature) =>
      bytes.length >= signature.length &&
      signature.indexed.every((entry) => bytes[entry.$1] == entry.$2);
  return starts([0x50, 0x4b]) ||
      starts([0x37, 0x7a, 0xbc, 0xaf, 0x27, 0x1c]) ||
      starts([0x52, 0x61, 0x72, 0x21]) ||
      starts([0x1f, 0x8b]) ||
      {
        'application/octet-stream',
        'application/zip',
        'application/x-zip-compressed',
        'application/x-7z-compressed',
        'application/x-rar-compressed',
        'application/vnd.rar',
        'application/gzip',
        'application/x-tar',
      }.contains(type);
}
