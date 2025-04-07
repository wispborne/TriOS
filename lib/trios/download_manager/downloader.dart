import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod
import 'package:html/parser.dart';
import 'package:trios/mod_manager/version_checker.dart';
import 'package:trios/trios/providers.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/http_client.dart';

import '../../utils/logging.dart';
import 'download_request.dart';
import 'download_status.dart';
import 'download_task.dart';

class DownloadManager {
  final Map<String, DownloadTask> _cache = <String, DownloadTask>{};
  final Queue<DownloadRequest> _queue = Queue();
  static const partialExtension = ".partial";
  static const tempExtension = ".temp";

  int maxConcurrentTasks = 2;
  int runningTasks = 0;

  final Ref ref; // Reference to Riverpod's ref to access providers

  // Singleton pattern with ref
  static DownloadManager? _instance;

  DownloadManager._internal(this.ref);

  factory DownloadManager({required Ref ref, int? maxConcurrentTasks}) {
    _instance ??= DownloadManager._internal(ref);
    if (maxConcurrentTasks != null) {
      _instance!.maxConcurrentTasks = maxConcurrentTasks;
    }
    return _instance!;
  }

  void Function(int, int) createDownloadProgressCallback(
    url,
    int partialFileLength,
  ) => (int received, int total) {
    final download = DownloadedAmount(
      received + partialFileLength,
      total + partialFileLength,
    );
    // getDownload(url)?.progressRatio.value =
    //     (received + partialFileLength) / (total + partialFileLength);
    getDownload(url)?.downloaded.value = download;

    if (total == -1) {}
  };

  Future<void> download(
    String url,
    String destFolder,
    String? filename, {
    forceDownload = false,
  }) async {
    late String partialFilePath;
    late File partialFile;
    final TriOSHttpClient httpClient = ref.watch(triOSHttpClient);
    final originalUrl = url;
    final startTime = DateTime.now().millisecondsSinceEpoch;
    Fimber.d(
      "Download T=${DateTime.now().millisecondsSinceEpoch - startTime}: Starting download of '$url' to '$destFolder/$filename'",
    );

    try {
      final task = getDownload(originalUrl);
      Fimber.d(
        "Download T=${DateTime.now().millisecondsSinceEpoch - startTime}: Task $task",
      );

      if (task == null || task.status.value == DownloadStatus.canceled) {
        return;
      }

      setStatus(task, DownloadStatus.retrievingFileInfo);

      url = await makeDirectDownloadLink(url, httpClient);
      Fimber.d(
        "Download T=${DateTime.now().millisecondsSinceEpoch - startTime}: Direct download link: '$url'",
      );
      final finalUrlAndHeaders = await fetchFinalUrlAndHeaders(
        url,
        httpClient,
        hostType: _determineHostType(url),
      );
      Fimber.d(
        "Download T=${DateTime.now().millisecondsSinceEpoch - startTime}: Final URL: '${finalUrlAndHeaders.url}' with headers: '${finalUrlAndHeaders.headersMap}'",
      );
      url = finalUrlAndHeaders.url;
      url = await makeDirectDownloadLink(url, httpClient);
      Fimber.d(
        "Download T=${DateTime.now().millisecondsSinceEpoch - startTime}: Final direct download link: '$url'",
      );
      Map<String, String> headersMap = finalUrlAndHeaders.headersMap;

      // If given a download folder, then get the file's name from the URL and put it in the folder.
      // If given an actual filename rather than a folder, then we already have the name.
      final isDirectory = await Directory(destFolder).exists();
      final downloadFile =
          isDirectory
              ? destFolder +
                  Platform.pathSeparator +
                  await fetchFileNameFromUrl(url, headersMap)
              : destFolder + Platform.pathSeparator + filename!;
      task.file.value = File(downloadFile);

      setStatus(task, DownloadStatus.downloading);

      Fimber.d(url);

      // Ensure there's a file to download
      if (await isDownloadableFile(url, headersMap, httpClient) == false) {
        throw Exception(
          "No file to download found at '$url'.\nPlease contact the mod author.",
        );
      }
      Fimber.d(
        "Download T=${DateTime.now().millisecondsSinceEpoch - startTime}: File is downloadable.",
      );

      final file = File(downloadFile.toString());
      partialFilePath = downloadFile + partialExtension;
      partialFile = File(partialFilePath);

      var fileExist = await file.exists();
      var partialFileExist = await partialFile.exists();

      if (fileExist) {
        Fimber.d("File already eists: $downloadFile");
        setStatus(task, DownloadStatus.completed);
      } else if (partialFileExist) {
        Fimber.d("Partial file already exists: $partialFilePath");

        final partialFileLength = await partialFile.length();

        final response = await httpClient.get(
          url,
          headers: {HttpHeaders.rangeHeader: 'bytes=$partialFileLength-'},
          onProgress: createDownloadProgressCallback(
            originalUrl,
            partialFileLength,
          ),
        );

        if (response.statusCode == HttpStatus.partialContent ||
            response.statusCode == HttpStatus.ok) {
          var ioSink = partialFile.openWrite(mode: FileMode.writeOnlyAppend);

          // Ensure response.data is a List<int>
          ioSink.add(getResponseBodyAsBytes(response.data));

          await ioSink.close();
          await partialFile.renameSafely(downloadFile);

          setStatus(task, DownloadStatus.completed);
        }
      } else {
        final response = await httpClient.get(
          url,
          onProgress: createDownloadProgressCallback(originalUrl, 0),
        );
        final responseData = getResponseBodyAsBytes(response.data);
        Fimber.d('Got response with data length: ${responseData.length}');

        if ((response.statusCode) <= 299) {
          await File(downloadFile).writeAsBytes(responseData);
          setStatus(task, DownloadStatus.completed);
        } else {
          throw Exception(
            "Failed to download file: ${response.statusCode} $url",
          );
        }
      }
    } catch (e) {
      final task = getDownload(originalUrl)!;
      if (task.status.value != DownloadStatus.canceled &&
          task.status.value != DownloadStatus.paused) {
        task.error = e;
        setStatus(task, DownloadStatus.failed);
        runningTasks--;

        if (_queue.isNotEmpty) {
          _startExecution();
        }
        rethrow;
      } else if (task.status.value == DownloadStatus.paused) {
        final ioSink = partialFile.openWrite(mode: FileMode.writeOnlyAppend);
        final f = File(partialFilePath + tempExtension);
        if (await f.exists()) {
          await ioSink.addStream(f.openRead());
        }
        await ioSink.close();
      }
    }

    runningTasks--;

    if (_queue.isNotEmpty) {
      _startExecution();
    }
  }

  static Map<String, String> _headersToMap(HttpHeaders headers) {
    final headersMap = <String, String>{};
    headers.forEach((key, value) {
      headersMap[key] = value.join(',');
    });
    return headersMap;
  }

  List<int> getResponseBodyAsBytes(dynamic response) {
    if (response is List<int>) {
      return response;
    } else if (response is String) {
      return utf8.encode(response);
    } else {
      throw Exception(
        'Unsupported response data type: ${response.runtimeType}',
      );
    }
  }

  /// Partly AI Generated
  Future<String> makeDirectDownloadLink(
    String url,
    TriOSHttpClient http,
  ) async {
    // Create a lowercase version of the URL for comparison purposes
    final urlLower = url.toLowerCase();

    // Google Drive
    if (isGoogleDrive(urlLower)) {
      if (!urlLower.contains("export=download")) {
        if (urlLower.contains("/file/d/")) {
          final fileIdMatch = RegExp(
            r'file/d/([^/]+)',
            caseSensitive: false,
          ).firstMatch(url);
          final fileId = fileIdMatch?.group(1);
          if (fileId != null) {
            url = "https://drive.google.com/uc?export=download&id=$fileId";
          }
        } else if (urlLower.contains("open") && urlLower.contains("id=")) {
          url =
              "${url.replaceFirst(RegExp("open", caseSensitive: false), "uc")}&export=download";
        }
      }

      Uri uri = Uri.parse(url);
      url =
          uri
              .replace(
                queryParameters: {
                  ...uri.queryParameters,
                  'confirm': 't', // Skip Google Drive confirmation page
                },
              )
              .toString();
    }
    // Dropbox
    else if (urlLower.contains("dropbox.com") && !urlLower.contains("dl=1")) {
      if (urlLower.contains("dl=0")) {
        url = url.replaceFirst(RegExp("dl=0", caseSensitive: false), "dl=1");
      } else if (url.contains("?")) {
        url = "$url&dl=1";
      } else {
        url = "$url?dl=1";
      }
    }
    // OneDrive
    else if (urlLower.contains("onedrive.live.com") &&
        !urlLower.contains("download=1")) {
      if (url.contains("?")) {
        url = "$url&download=1";
      } else {
        url = "$url?download=1";
      }
    }
    // GitHub (raw file download)
    else if (urlLower.contains("github.com") && urlLower.contains("/blob/")) {
      url = url
          .replaceFirst(
            RegExp("github.com", caseSensitive: false),
            "raw.githubusercontent.com",
          )
          .replaceFirst(RegExp("/blob/", caseSensitive: false), "/");
    }
    // MediaFire - Fetch the direct download link
    else if (urlLower.contains("mediafire.com")) {
      try {
        url = await getMediafireDirectLink(url, http);
      } catch (e) {
        Fimber.w("Failed to retrieve MediaFire direct link: $e");
      }
    }

    return url;
  }

  /// Extracts and fetches the direct download link from a MediaFire URL.
  Future<String> getMediafireDirectLink(
    String url,
    TriOSHttpClient http,
  ) async {
    try {
      // Define regex patterns for different MediaFire link formats
      final patterns = [
        RegExp(r"https://www\.mediafire\.com/file/([^/]+)/?"),
        RegExp(r"https://www\.mediafire\.com/view/([^/]+)/?"),
        RegExp(r"https://www\.mediafire\.com/download/([^/]+)/?"),
        RegExp(r"https://www\.mediafire\.com/\?([^/]+)/?"),
      ];

      // Check if the URL matches any MediaFire patterns
      bool isValid = false;
      for (var pattern in patterns) {
        if (pattern.hasMatch(url)) {
          isValid = true;
          break;
        }
      }

      if (!isValid) {
        throw Exception("Invalid MediaFire URL.");
      }

      // Fetch the MediaFire page
      final response = await http.get(url);
      if (response.statusCode != 200) {
        throw Exception(
          "Failed to load MediaFire page, status: ${response.statusCode}",
        );
      }

      // Extract the direct download link
      final match = RegExp(
        "https://download[0-9]+.mediafire.com/[^\"]+",
      ).firstMatch(response.data);
      if (match != null) {
        return match.group(0)!;
      } else {
        throw Exception("Failed to find the direct download link.");
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }

  void disposeNotifiers(DownloadTask task) {
    // task.status.dispose();
    // task.progress.dispose();
  }

  void setStatus(DownloadTask? task, DownloadStatus status) {
    if (task != null) {
      task.status.value = status;

      // tasks.add(task);
      if (status.isCompleted) {
        disposeNotifiers(task);
      }
    }
  }

  /// Adds a download task with a given URL and saves it to the specified directory.
  /// If the filename is not provided, it will be fetched from the URL.
  ///
  /// Returns a `DownloadTask` or `null` if the URL is empty.
  Future<DownloadTask?> addDownload(
    String url,
    String destFolder,
    String? fileName,
  ) async {
    if (url.isEmpty) {
      return null;
    }

    if (destFolder.isEmpty) {
      destFolder = ".";
    }

    return _addDownloadRequest(DownloadRequest(url, destFolder, fileName));
  }

  Future<DownloadTask> _addDownloadRequest(
    DownloadRequest downloadRequest,
  ) async {
    if (_cache[downloadRequest.url] != null) {
      if (!_cache[downloadRequest.url]!.status.value.isCompleted &&
          _cache[downloadRequest.url]!.request == downloadRequest) {
        // Do nothing
        return _cache[downloadRequest.url]!;
      } else {
        _queue.remove(_cache[downloadRequest.url]?.request);
      }
    }

    _queue.add(
      DownloadRequest(
        downloadRequest.url,
        downloadRequest.directory,
        downloadRequest.filename,
      ),
    );
    final task = DownloadTask(_queue.last);

    _cache[downloadRequest.url] = task;

    _startExecution();

    return task;
  }

  Future<void> pauseDownload(String url) async {
    Fimber.d("Pause Download: $url");
    var task = getDownload(url)!;
    setStatus(task, DownloadStatus.paused);
    // Handle cancellation logic with your HTTP client if supported

    _queue.remove(task.request);
  }

  Future<void> cancelDownload(String url) async {
    Fimber.d("Cancel Download: $url");
    var task = getDownload(url)!;
    setStatus(task, DownloadStatus.canceled);
    _queue.remove(task.request);
    // Handle cancellation logic with your HTTP client if supported
  }

  Future<void> resumeDownload(String url) async {
    Fimber.d("Resume Download: $url");
    var task = getDownload(url)!;
    setStatus(task, DownloadStatus.downloading);
    // Reset cancel tokens or other cancellation mechanisms if needed
    _queue.add(task.request);

    _startExecution();
  }

  // Do not immediately call getDownload After addDownload, rather use the returned DownloadTask from addDownload
  DownloadTask? getDownload(String url) {
    return _cache[url];
  }

  Future<DownloadStatus> whenDownloadComplete(
    String url, {
    Duration timeout = const Duration(hours: 2),
  }) async {
    DownloadTask? task = getDownload(url);

    if (task != null) {
      return task.whenDownloadComplete(timeout: timeout);
    } else {
      return Future.error("Not found");
    }
  }

  List<DownloadTask> getAllDownloads() {
    return _cache.values.toList();
  }

  // Batch Download Mechanism
  Future<void> addBatchDownloads(List<String> urls, String savedDir) async {
    for (final url in urls) {
      addDownload(url, savedDir, null);
    }
  }

  List<DownloadTask?> getBatchDownloads(List<String> urls) {
    return urls.map((e) => _cache[e]).toList();
  }

  Future<void> pauseBatchDownloads(List<String> urls) async {
    for (var element in urls) {
      pauseDownload(element);
    }
  }

  Future<void> cancelBatchDownloads(List<String> urls) async {
    for (var element in urls) {
      cancelDownload(element);
    }
  }

  Future<void> resumeBatchDownloads(List<String> urls) async {
    for (var element in urls) {
      resumeDownload(element);
    }
  }

  ValueNotifier<DownloadedAmount> getBatchTriOSDownloadProgress(
    List<String> urls,
  ) {
    ValueNotifier<DownloadedAmount> progress = ValueNotifier(
      DownloadedAmount(0, 0),
    );
    var total = urls.length;

    if (total == 0) {
      return progress;
    }

    if (total == 1) {
      return getDownload(urls.first)?.downloaded ?? progress;
    }

    var progressMap = <String, double>{};

    for (var url in urls) {
      DownloadTask? task = getDownload(url);

      if (task != null) {
        progressMap[url] = 0.0;

        if (task.status.value.isCompleted) {
          progressMap[url] = 1.0;
          progress.value = DownloadedAmount(
            progressMap.values.sum.toInt(),
            total,
          );
        }

        Null Function() progressListener;
        progressListener = () {
          progressMap[url] = task.downloaded.value.progressRatio;
          progress.value = DownloadedAmount(
            progressMap.values.sum.toInt(),
            total,
          );
        };

        task.downloaded.addListener(progressListener);

        VoidCallback? listener;
        listener = () {
          if (task.status.value.isCompleted) {
            progressMap[url] = 1.0;
            progress.value = DownloadedAmount(
              progressMap.values.sum.toInt(),
              total,
            );
            task.status.removeListener(listener!);
            task.downloaded.removeListener(progressListener);
          }
        };

        task.status.addListener(listener);
      } else {
        total--;
      }
    }

    return progress;
  }

  Future<List<DownloadTask?>?> whenBatchDownloadsComplete(
    List<String> urls, {
    Duration timeout = const Duration(hours: 2),
  }) async {
    var completer = Completer<List<DownloadTask?>?>();

    var completed = 0;
    var total = urls.length;

    for (var url in urls) {
      DownloadTask? task = getDownload(url);

      if (task != null) {
        if (task.status.value.isCompleted) {
          completed++;

          if (completed == total) {
            completer.complete(getBatchDownloads(urls));
          }
        }

        VoidCallback? listener;
        listener = () {
          if (task.status.value.isCompleted) {
            completed++;

            if (completed == total) {
              completer.complete(getBatchDownloads(urls));
              task.status.removeListener(listener!);
            }
          }
        };

        task.status.addListener(listener);
      } else {
        total--;

        if (total == 0) {
          completer.complete(null);
        }
      }
    }

    return completer.future.timeout(timeout);
  }

  void _startExecution() async {
    if (runningTasks == maxConcurrentTasks || _queue.isEmpty) {
      return;
    }

    while (_queue.isNotEmpty && runningTasks < maxConcurrentTasks) {
      runningTasks++;
      Fimber.d('Concurrent workers: $runningTasks');
      var currentRequest = _queue.removeFirst();

      runZonedGuarded(
        () {
          download(
            currentRequest.url,
            currentRequest.directory,
            currentRequest.filename,
          );
        },
        (e, s) {
          Fimber.w('Error downloading: $e', ex: e, stacktrace: s);
        },
      );

      await Future.delayed(const Duration(milliseconds: 500), null);
    }
  }

  /// This function is used for get file name with extension from url
  Future<String> fetchFileNameFromUrl(
    String url,
    Map<String, String>? headers,
  ) async {
    try {
      Fimber.d("Getting filename from url: $url");
      Fimber.d("Url $url has headers:\n$headers");
      final contentDisposition = headers?['Content-Disposition'];

      return contentDisposition?.fixFilenameForFileSystem() ??
          Uri.parse(url).pathSegments.last.fixFilenameForFileSystem();
    } catch (e) {
      Fimber.w("Error getting filename from url: $e");
      return Uri.parse(url).pathSegments.last.fixFilenameForFileSystem();
    }
  }

  /// Sends a HEAD request to the given URL and returns the response headers.
  /// Returns null if there was an error.
  Future<HttpHeaders?> fetchHeaders(String url) async {
    try {
      final httpClient = ref.watch(triOSHttpClient);

      // Send a HEAD request to the URL
      final response = await httpClient.get(url, headers: {'method': 'HEAD'});

      // Return headers if the request is successful
      if (response.statusCode == 200) {
        return response.headers;
      }
    } catch (e) {
      // Log the error
      Fimber.w('Error fetching headers: $e');
    }

    // Return null if the request fails
    return null;
  }

  /// Checks if a given URL points to a downloadable file.
  /// Uses headers to determine if the content is downloadable.
  static Future<bool> isDownloadableFile(
    String url,
    Map<String, String>? headers,
    TriOSHttpClient httpClient,
  ) async {
    if (headers != null) {
      final contentType = headers['content-type']?.toLowerCase() ?? "";
      final contentDisposition =
          headers['content-disposition']?.toLowerCase() ?? "";

      // Check if the Content-Type indicates a downloadable file
      if (contentType.startsWith('application/') ||
          contentDisposition.contains('attachment')) {
        return true;
      }

      // Special handling for Google Drive and MEGA
      if (isGoogleDrive(url)) {
        return await checkGoogleDriveLink(url, httpClient);
      } else if (url.contains('mega.nz')) {
        return await checkMegaLink(url, httpClient);
      }
    }

    // Return false if no downloadable file detected
    return false;
  }

  /// Efficiently fetch headers.
  /// - **Uses a fast "Range: bytes=0-0" GET request instead of HEAD, first.**
  /// - **Falls back to HEAD request if needed.**
  static Future<Map<String, String>> fetchHeadersEfficiently(
    String url,
    TriOSHttpClient httpClient,
    HostType hostType,
  ) async {
    Fimber.d("Fetching headers efficiently for URL: $url, HostType: $hostType");

    // Try quick empty GET request that returns headers
    if (hostType != HostType.googleDrive && hostType != HostType.dropbox) {
      try {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final getResponse = await httpClient.get(
          url,
          headers: {'Range': 'bytes=0-0'},
        );
        Fimber.d(
          "Partial GET request took ${DateTime.now().millisecondsSinceEpoch - timestamp} ms for URL: $url",
        );
        final headers = _headersToMap(getResponse.headers);

        if (await isDownloadableFile(url, headers, httpClient)) {
          return headers;
        } else {
          Fimber.d(
            "No downloadable file found from efficient GET request, falling back to normal HEAD request.",
          );
        }
      } catch (e) {
        Fimber.d(
          "Partial GET request failed for URL: $url, falling back to normal GET request. Error: $e",
        );
      }
    }

    // Slower fallback (4+ seconds)
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final headResponse = await httpClient.get(
        url,
        headers: {'method': 'HEAD'},
      );
      Fimber.d(
        "HEAD request took ${DateTime.now().millisecondsSinceEpoch - timestamp} ms for URL: $url",
      );
      return _headersToMap(headResponse.headers);
    } catch (e) {
      Fimber.w(
        "HEAD request failed for URL: $url, falling back to empty headers. Error: $e",
      );
      return {};
    }
  }

  static Future<UrlResponse> fetchFinalUrlAndHeaders(
    String url,
    TriOSHttpClient httpClient, {
    HostType hostType = HostType.unknown,
  }) async {
    const int maxRedirects = 3;
    int redirectCount = 0;
    String currentUrl = url;

    Map<String, String> currentHeaders = await fetchHeadersEfficiently(
      url,
      httpClient,
      hostType,
    );

    switch (hostType) {
      case HostType.github:
      case HostType.dropbox:
        {
          if (currentHeaders.isNotEmpty &&
              await isDownloadableFile(url, currentHeaders, httpClient)) {
            Fimber.d(
              "Skipping additional GET request for URL: $url, headers found: $currentHeaders",
            );
            return UrlResponse(url, currentHeaders);
          }
        }

      case _:
    }

    while (redirectCount < maxRedirects) {
      Fimber.d("Redirect count: $redirectCount, Current URL: $currentUrl");
      final response = await httpClient.get(url, headers: {'method': 'HEAD'});

      if (response.httpResponse.redirects.isNotEmpty) {
        currentUrl = response.httpResponse.redirects.last.location.toString();
        currentUrl = fixUrl(currentUrl);
      }

      // Store headers from the latest response
      currentHeaders = _headersToMap(response.headers);

      // Check for HTTP redirect
      if (response.httpResponse.isRedirect ||
          response.statusCode == 301 ||
          response.statusCode == 302) {
        final location = response.headers['location']?.firstOrNull;
        if (location != null) {
          currentUrl = Uri.parse(currentUrl).resolve(location).toString();
          redirectCount++;
          continue;
        }
      }

      // If not an HTTP redirect, try a GET request to detect meta refresh
      final getResponse = await httpClient.get(
        currentUrl,
        headers: {'User-Agent': 'Mozilla/5.0'},
      );

      // Update headers from the GET response
      currentHeaders = _headersToMap(getResponse.headers);

      if (getResponse.headers['content-type']
              ?.join(';')
              .contains('text/html') ??
          false) {
        // Parse HTML to find <meta http-equiv="Refresh" content="...">
        final document = parse(getResponse.data);
        final metaRefresh = document.head
            ?.getElementsByTagName('meta')
            .firstWhereOrNull(
              (element) =>
                  element.attributes['http-equiv']?.toLowerCase() == 'refresh',
            );

        if (metaRefresh != null) {
          final content = metaRefresh.attributes['content'];
          final urlMatch = RegExp(
            r'url=(.*)',
            caseSensitive: false,
          ).firstMatch(content ?? '');
          if (urlMatch != null) {
            currentUrl =
                Uri.parse(currentUrl).resolve(urlMatch.group(1)!).toString();
            redirectCount++;
            continue;
          }
        }
      }

      // If no redirect or meta refresh, return the current URL and headers as final
      return UrlResponse(currentUrl, currentHeaders);
    }

    // If max redirects exceeded, throw an error or return the last URL and headers
    throw Exception('Too many redirects: $url');
  }

  static bool isGoogleDrive(String url) {
    return (url.toLowerCase().contains("drive.google.com") ||
        url.toLowerCase().contains("drive.usercontent.google.com"));
  }

  // Determines if a Google Drive link has a download (because it doesn't use proper headers).
  static Future<bool> checkGoogleDriveLink(
    String url,
    TriOSHttpClient httpClient,
  ) async {
    try {
      if (url.contains('export=download')) {
        return true;
      }

      // Google Drive files usually require confirmation to download
      final response = await httpClient.get(url);

      // Check for specific identifiers in the HTML content
      if (response.data.toString().contains('download')) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      Fimber.w('Error checking Google Drive link: $e');
      return false;
    }
  }

  // Determines if a MEGA link has a download (because it doesn't use proper headers).
  static Future<bool> checkMegaLink(
    String url,
    TriOSHttpClient httpClient,
  ) async {
    try {
      // MEGA links should be direct or use a confirmation link
      final response = await httpClient.get(url);

      // Check for specific identifiers in the HTML content
      if (response.data.toString().contains('MEGA')) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      Fimber.w('Error checking MEGA link: $e');
      return false;
    }
  }

  HostType _determineHostType(String url) {
    try {
      final urlLower = url.toLowerCase();
      final uri = Uri.parse(urlLower);
      final host = uri.host;

      if (host.contains('github.com') ||
          host.contains('raw.githubusercontent.com')) {
        return HostType.github;
      } else if (host.contains('drive.google.com') ||
          host.contains('drive.usercontent.google.com')) {
        return HostType.googleDrive;
      } else if (host.contains('dropbox.com')) {
        return HostType.dropbox;
      } else if (host.contains('onedrive.live.com')) {
        return HostType.oneDrive;
      } else if (host.contains('mediafire.com')) {
        return HostType.mediaFire;
      } else if (host.contains('gitlab.com')) {
        return HostType.gitLab;
      } else if (host.contains('gitgud.io')) {
        return HostType.gitGud;
      }
    } catch (e) {
      Fimber.d("Error determining host type: $e");
    }

    return HostType.unknown;
  }
}

enum HostType {
  github,
  googleDrive,
  dropbox,
  oneDrive,
  mediaFire,
  gitLab,
  gitGud,
  unknown,
}

class UrlResponse {
  final String url;
  final Map<String, String> headersMap;

  UrlResponse(this.url, this.headersMap);
}
