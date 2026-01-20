import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/logging.dart';

final triOSHttpClient = Provider<TriOSHttpClient>(
  (ref) => TriOSHttpClient(
    config: ApiClientConfig(),
    maxConcurrentRequests: ref.watch(
      appSettings.select((s) => s.maxHttpRequestsAtOnce),
    ),
    allowInsecureConnectionsByDefault: ref.watch(
      appSettings.select((s) => s.allowInsecureConnections),
    ),
  ),
);

// Custom response class to encapsulate useful details
class TriOSHttpResponse<T> {
  final T data;
  final int statusCode;
  final HttpHeaders headers;
  final HttpClientResponse httpResponse;
  final String? contentType;

  TriOSHttpResponse({
    required this.data,
    required this.statusCode,
    required this.headers,
    required this.httpResponse,
    this.contentType,
  });
}

class ApiClientConfig {
  final String? baseUrl;
  final Map<String, String> defaultHeaders;

  ApiClientConfig({this.baseUrl, this.defaultHeaders = const {}});
}

class TriOSHttpClient {
  final int maxConcurrentRequests;
  final bool allowInsecureConnectionsByDefault;
  final HttpClient _defaultHttpClient;
  final HttpClient _selfSignedHttpClient;
  final Queue<_RequestItem> _requestQueue = Queue();
  final ApiClientConfig config;
  int _activeRequests = 0;

  TriOSHttpClient({
    required this.config,
    this.maxConcurrentRequests = 10,
    this.allowInsecureConnectionsByDefault = false,
  })  : _defaultHttpClient = HttpClient(),
        _selfSignedHttpClient = HttpClient() {
    // Set up the client that allows self-signed certificates
    _selfSignedHttpClient.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;

    // Connection pooling and keep-alive settings
    _defaultHttpClient.idleTimeout = const Duration(seconds: 10);
    _selfSignedHttpClient.idleTimeout = const Duration(seconds: 10);
    _defaultHttpClient.maxConnectionsPerHost = 10;
    _selfSignedHttpClient.maxConnectionsPerHost = 10;
  }

  /// Sends an HTTP GET request to the specified [url] with optional headers and timeout.
  Future<TriOSHttpResponse<dynamic>> get(
    String endpointOrUrl, {
    bool? allowSelfSignedCertificates,
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 30),
    int tries = 2,
    void Function(int receivedBytes, int totalBytes)? onProgress,
  }) {
    return _enqueueRequest(() {
      final Uri url = _resolveUrl(endpointOrUrl);
      if (url.host.isEmpty) {
        return Future.error(Exception('Invalid URL: $url'));
      }

      final useInsecure = allowSelfSignedCertificates ?? allowInsecureConnectionsByDefault;
      final client = useInsecure
          ? _selfSignedHttpClient
          : _defaultHttpClient;
      return _retry(
        () => _createRequest(
          () => client.getUrl(url),
          headers: headers,
          onProgress: onProgress,
          inactivityTimeout: timeout,
        ),
        retries: tries,
      );
    });
  }

  /// Resolves whether to use baseUrl or treat it as a fully qualified URL.
  Uri _resolveUrl(String endpointOrUrl) {
    if (config.baseUrl != null && !endpointOrUrl.startsWith('http')) {
      return Uri.parse('${config.baseUrl}$endpointOrUrl');
    }
    return Uri.parse(endpointOrUrl); // Direct URL for arbitrary websites
  }

  /// Enqueues the request and ensures concurrency limit.
  Future<TriOSHttpResponse<dynamic>> _enqueueRequest(
    Future<TriOSHttpResponse<dynamic>> Function() requestFactory,
  ) {
    final completer = Completer<TriOSHttpResponse<dynamic>>();
    final requestItem = _RequestItem(requestFactory, completer);
    _requestQueue.add(requestItem);
    _tryExecuteNext();
    return completer.future;
  }

  /// Executes the next request if under concurrency limit.
  void _tryExecuteNext() {
    if (_activeRequests >= maxConcurrentRequests || _requestQueue.isEmpty) {
      return;
    }

    _activeRequests++;
    final requestItem = _requestQueue.removeFirst();

    requestItem
        .requestFactory()
        .then((response) {
          requestItem.completer.complete(response);
        })
        .catchError((error) {
          requestItem.completer.completeError(error);
        })
        .whenComplete(() {
          _activeRequests--;
          _tryExecuteNext();
        });
  }

  /// Creates an HTTP request with optional headers and returns the full response.
  Future<TriOSHttpResponse<dynamic>> _createRequest(
    Future<HttpClientRequest> Function() requestFactory, {
    Map<String, String>? headers,
    void Function(int receivedBytes, int totalBytes)? onProgress,
    Duration inactivityTimeout = const Duration(seconds: 30),
  }) async {
    final request = await requestFactory();
    _logRequest(request);

    // Set default headers and any additional custom headers
    config.defaultHeaders.forEach(request.headers.set);
    headers?.forEach(request.headers.set);

    final response = await request.close();
    _logResponse(request, response);

    final contentType = response.headers.contentType?.mimeType;
    final statusCode = response.statusCode;
    final headersMap = response.headers;
    final totalBytes = response.contentLength; // May be -1 if unknown

    // Read the raw bytes with an inactivity (stall) timeout:
    final rawBytes = await readStreamWithIdleTimeout(
      response,
      inactivityTimeout,
      onProgress: onProgress,
      totalBytes: totalBytes,
    );

    // Convert the bytes based on the MIME type
    dynamic responseBody;
    if (contentType == 'application/json') {
      responseBody = jsonDecode(utf8.decode(rawBytes));
    } else if (contentType != null && contentType.startsWith('text/')) {
      responseBody = utf8.decode(rawBytes);
    } else {
      // Binary response (e.g., for file downloads)
      responseBody = rawBytes;
    }

    return TriOSHttpResponse(
      data: responseBody,
      statusCode: statusCode,
      headers: headersMap,
      httpResponse: response,
      contentType: contentType,
    );
  }

  Future<TriOSHttpResponse<dynamic>> _retry(
    Future<TriOSHttpResponse<dynamic>> Function() requestFunction, {
    int retries = 3,
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    int attempt = 0;
    while (attempt < retries) {
      try {
        return await requestFunction();
      } on TimeoutException catch (e) {
        Fimber.w(
          'Request timed out on attempt ${attempt + 1}: ${e.toString()}',
        );
      } catch (e, stacktrace) {
        Fimber.w(
          'Request failed on attempt ${attempt + 1}: ${e.toString()}',
          ex: e,
          stacktrace: stacktrace,
        );
      }
      attempt++;
      if (attempt < retries) {
        await Future.delayed(retryDelay * attempt); // Exponential backoff
      }
    }

    // If all retries fail, throw an exception.
    throw Exception('Request failed after $retries attempts');
  }

  Future<List<int>> readStreamWithIdleTimeout(
    Stream<List<int>> stream,
    Duration inactivityTimeout, {
    void Function(int receivedBytes, int totalBytes)? onProgress,
    int totalBytes = -1,
  }) {
    final completer = Completer<List<int>>();
    final buffer = <int>[];

    Timer? inactivityTimer;
    var receivedBytesCount = 0;

    void resetTimer() {
      inactivityTimer?.cancel();
      inactivityTimer = Timer(inactivityTimeout, () {
        if (!completer.isCompleted) {
          completer.completeError(
            TimeoutException('No data received for $inactivityTimeout'),
          );
        }
      });
    }

    // Start the timer as soon as we begin reading
    resetTimer();

    stream.listen(
      (chunk) {
        buffer.addAll(chunk);
        receivedBytesCount += chunk.length;

        // We got data, so reset the "stall" timer
        resetTimer();

        // Progress callback, if any
        onProgress?.call(receivedBytesCount, totalBytes);
      },
      onDone: () {
        inactivityTimer?.cancel();
        if (!completer.isCompleted) {
          completer.complete(buffer);
        }
      },
      onError: (error, stackTrace) {
        inactivityTimer?.cancel();
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
      },
      cancelOnError: true,
    );

    return completer.future;
  }

  void _logRequest(HttpClientRequest request) {
    Fimber.v(
      () =>
          'Request: ${request.method} ${request.uri}\nHeaders:${request.headers}',
    );
  }

  void _logResponse(HttpClientRequest request, HttpClientResponse response) {
    Fimber.v(
      () =>
          'Response:${request.method} ${request.uri}:  ${response.statusCode}',
    );
    Fimber.v(() => 'Headers: ${response.headers}');
  }

  /// Closes the [HttpClient] to free up resources.
  void close({bool force = false}) {
    _defaultHttpClient.close(force: force);
    _selfSignedHttpClient.close(force: force);
  }
}

class _RequestItem {
  final Future<TriOSHttpResponse<dynamic>> Function() requestFactory;
  final Completer<TriOSHttpResponse<dynamic>> completer;

  _RequestItem(this.requestFactory, this.completer);
}
