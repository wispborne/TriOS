import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

class HttpProbeCancelled implements Exception {
  const HttpProbeCancelled();
  @override
  String toString() => 'Source check cancelled.';
}

class HttpProbeCancellation {
  final _cancelled = Completer<void>();
  bool get isCancelled => _cancelled.isCompleted;
  Future<void> get whenCancelled => _cancelled.future;
  void cancel() {
    if (!isCancelled) _cancelled.complete();
  }

  void check() {
    if (isCancelled) throw const HttpProbeCancelled();
  }
}

class HttpProbeResult {
  final Uri url;
  final List<int> bytes;
  final String? contentType;
  final String? disposition;
  const HttpProbeResult(
    this.url,
    this.bytes,
    this.contentType,
    this.disposition,
  );
}

/// Reads only the beginning of a response using the existing HTTP client.
/// Aborts this request on cancellation; other requests keep their connections.
Future<HttpProbeResult> probeHttpUrl(
  Uri url, {
  required int maxBytes,
  required bool prefixOnly,
  required HttpProbeCancellation cancellation,
  Duration timeout = const Duration(seconds: 20),
  required HttpClient client,
}) async {
  cancellation.check();
  HttpClientRequest? activeRequest;
  var finishedReading = false;
  final finished = Completer<void>();
  unawaited(
    Future.any([cancellation.whenCancelled, finished.future]).then((_) {
      if (cancellation.isCancelled) {
        activeRequest?.abort(const HttpProbeCancelled());
      }
    }),
  );
  Future<HttpProbeResult> read() async {
    var current = url;
    for (var redirects = 0; redirects <= 5; redirects++) {
      cancellation.check();
      if (!{'http', 'https'}.contains(current.scheme) ||
          current.host.isEmpty ||
          current.userInfo.isNotEmpty) {
        throw const FormatException(
          'Enter an HTTP or HTTPS URL without login details.',
        );
      }
      final request = await client.getUrl(current);
      activeRequest = request;
      if (finishedReading || cancellation.isCancelled) {
        request.abort(const HttpProbeCancelled());
        throw const HttpProbeCancelled();
      }
      request.followRedirects = false;
      if (prefixOnly) {
        request.headers.set(HttpHeaders.rangeHeader, 'bytes=0-${maxBytes - 1}');
      }
      final response = await request.close();
      if ({301, 302, 303, 307, 308}.contains(response.statusCode)) {
        final location = response.headers.value(HttpHeaders.locationHeader);
        await response.listen((_) {}).cancel();
        if (location == null) {
          throw const FormatException(
            'The source redirects without a destination.',
          );
        }
        current = current.resolve(location);
        continue;
      }
      if (response.statusCode != 200 &&
          !(prefixOnly && response.statusCode == 206)) {
        throw HttpException(
          'Source returned HTTP ${response.statusCode}.',
          uri: current,
        );
      }
      final bytes = BytesBuilder(copy: false);
      await for (final chunk in response) {
        cancellation.check();
        if (!prefixOnly && bytes.length + chunk.length > maxBytes) {
          throw const FormatException('The Version Checker file is too large.');
        }
        bytes.add(
          prefixOnly ? chunk.take(maxBytes - bytes.length).toList() : chunk,
        );
        if (prefixOnly && bytes.length > 0) break;
      }
      cancellation.check();
      return HttpProbeResult(
        current,
        bytes.takeBytes(),
        response.headers.contentType?.mimeType,
        response.headers.value('content-disposition'),
      );
    }
    throw const FormatException('The source redirects too many times.');
  }

  try {
    return await read().timeout(timeout);
  } catch (_) {
    cancellation.check();
    rethrow;
  } finally {
    finishedReading = true;
    finished.complete();
    activeRequest?.abort(const HttpProbeCancelled());
  }
}
