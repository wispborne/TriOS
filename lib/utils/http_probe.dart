import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

class HttpProbeCancelled implements Exception {
  const HttpProbeCancelled();
  @override
  String toString() => 'Source check cancelled.';
}

class HttpProbeStatusException extends HttpException {
  final int statusCode;
  HttpProbeStatusException(this.statusCode, Uri url)
    : super('Source returned HTTP $statusCode.', uri: url);
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

/// Reads the beginning of an HTTP response. Matches [TriOSHttpClient.probe]
/// and the test fakes that stand in for it.
typedef HttpProbe = Future<HttpProbeResult> Function(
  Uri url, {
  required int maxBytes,
  required bool prefixOnly,
  required HttpProbeCancellation cancellation,
});

class HttpProbeResult {
  final Uri url;
  final List<int> bytes;
  final String? contentType;
  const HttpProbeResult(this.url, this.bytes, this.contentType);
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
      // getUrl covers the DNS lookup and the TCP/TLS connect. The client is
      // shared, so there is no way to abort that work from here. Stop waiting
      // on it when the check is cancelled and abort the request if it turns up
      // afterwards; waiting would hold a slot in the client's request queue
      // until the connect finished or timed out, delaying other requests.
      var abandoned = false;
      final pending = client.getUrl(current);
      unawaited(
        pending
            .then((late) {
              if (abandoned) late.abort(const HttpProbeCancelled());
            })
            .catchError((Object _) {}),
      );
      final HttpClientRequest request;
      try {
        request = await Future.any([
          pending,
          cancellation.whenCancelled.then<HttpClientRequest>(
            (_) => throw const HttpProbeCancelled(),
          ),
        ]);
      } catch (_) {
        abandoned = true;
        rethrow;
      }
      activeRequest = request;
      if (finished.isCompleted || cancellation.isCancelled) {
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
        throw HttpProbeStatusException(response.statusCode, current);
      }
      final bytes = BytesBuilder(copy: false);
      await for (final chunk in response) {
        cancellation.check();
        if (!prefixOnly && bytes.length + chunk.length > maxBytes) {
          throw const FormatException('The source response is too large.');
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
    finished.complete();
    activeRequest?.abort(const HttpProbeCancelled());
  }
}
