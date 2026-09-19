import 'dart:async';
import 'dart:io';

/// Streams an archive with bounded redirects, size, total and idle time. The
/// caller supplies the public-address-only client used for modpack metadata.
Future<Uri> downloadHttpArchive(
  HttpClient client,
  Uri url,
  File destination, {
  required void Function(int, int) onProgress,
  int maxBytes = 8 * 1024 * 1024 * 1024,
  Duration timeout = const Duration(hours: 2),
}) async {
  HttpClientRequest? active;
  final sink = destination.openWrite();
  var expired = false;
  Future<Uri> transfer() async {
    var current = url;
    for (var redirects = 0; redirects <= 5; redirects++) {
      if (!{'http', 'https'}.contains(current.scheme) ||
          current.host.isEmpty ||
          current.userInfo.isNotEmpty) {
        throw const FormatException('Use a public HTTP or HTTPS source.');
      }
      final request = await client.getUrl(current);
      active = request;
      if (expired) {
        request.abort();
        throw TimeoutException('Archive download timed out.');
      }
      request.followRedirects = false;
      final response = await request.close().timeout(
        const Duration(seconds: 30),
      );
      if ({301, 302, 303, 307, 308}.contains(response.statusCode)) {
        final location = response.headers.value(HttpHeaders.locationHeader);
        await response.listen((_) {}).cancel();
        if (location == null) {
          throw const FormatException('Missing redirect address.');
        }
        current = current.resolve(location);
        continue;
      }
      if (response.statusCode != 200) {
        throw HttpException(
          'Archive returned HTTP ${response.statusCode}.',
          uri: current,
        );
      }
      if (response.contentLength > maxBytes) {
        throw const FormatException(
          'Archive exceeds the 8 GiB download limit.',
        );
      }
      var received = 0;
      await for (final chunk in response.timeout(const Duration(seconds: 30))) {
        if (expired) throw TimeoutException('Archive download timed out.');
        received += chunk.length;
        if (received > maxBytes) {
          throw const FormatException('Archive is too large.');
        }
        sink.add(chunk);
        // Apply backpressure rather than buffering a whole mod in memory.
        await sink.flush();
        onProgress(received, response.contentLength);
      }
      if (received == 0) throw const FormatException('Archive is empty.');
      return current;
    }
    throw const FormatException('Archive redirects too many times.');
  }

  try {
    return await transfer().timeout(timeout);
  } finally {
    expired = true;
    active?.abort();
    await sink.close();
  }
}
