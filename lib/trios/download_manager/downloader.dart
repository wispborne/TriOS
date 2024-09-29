import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/http_client.dart';

import '../../utils/logging.dart';
import 'download_request.dart';
import 'download_status.dart';
import 'download_task.dart';

// Assuming you have a provider set up for your TriOSHttpClient
final triOSHttpClientProvider = Provider<TriOSHttpClient>((ref) {
  final config = ApiClientConfig(); // Configure as needed
  return TriOSHttpClient(config: config);
});

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

  void Function(int, int) createCallback(url, int partialFileLength) =>
      (int received, int total) {
        final download = DownloadedAmount(
            received + partialFileLength, total + partialFileLength);
        // getDownload(url)?.progressRatio.value =
        //     (received + partialFileLength) / (total + partialFileLength);
        getDownload(url)?.downloaded.value = download;

        if (total == -1) {}
      };

  Future<void> download(String url, String savePath,
      {forceDownload = false}) async {
    late String partialFilePath;
    late File partialFile;
    try {
      var task = getDownload(url);

      if (task == null || task.status.value == DownloadStatus.canceled) {
        return;
      }
      setStatus(task, DownloadStatus.downloading);

      Fimber.d(url);

      // Ensure there's a file to download
      if (await isDownloadableFile(url) == false) {
        throw Exception(
            "No file to download found at '$url'.\nPlease contact the mod author.");
      }

      var file = File(savePath.toString());
      partialFilePath = savePath + partialExtension;
      partialFile = File(partialFilePath);

      var fileExist = await file.exists();
      var partialFileExist = await partialFile.exists();

      // Access the HTTP client via ref
      final httpClient = ref.watch(triOSHttpClientProvider);

      if (fileExist) {
        Fimber.d("File Exists: $savePath");
        setStatus(task, DownloadStatus.completed);
      } else if (partialFileExist) {
        Fimber.d("Partial File Exists: $partialFilePath");

        final partialFileLength = await partialFile.length();

        final response = await httpClient.get(
          url,
          headers: {HttpHeaders.rangeHeader: 'bytes=$partialFileLength-'},
        );

        if (response.statusCode == HttpStatus.partialContent ||
            response.statusCode == HttpStatus.ok) {
          var ioSink = partialFile.openWrite(mode: FileMode.writeOnlyAppend);

          // Ensure response.data is a List<int>
          if (response.data is List<int>) {
            ioSink.add(response.data as List<int>);
          } else if (response.data is String) {
            // If data is a String, convert it to bytes
            ioSink.add(utf8.encode(response.data as String));
          } else {
            throw Exception(
                'Unsupported response data type: ${response.data.runtimeType}');
          }

          await ioSink.close();
          await partialFile.rename(savePath);

          setStatus(task, DownloadStatus.completed);
        }
      } else {
        final response = await httpClient.get(
          url,
          // You can add onReceiveProgress functionality if your TriOSHttpClient supports it
        );

        if ((response.statusCode) <= 299) {
          await File(savePath).writeAsBytes(response.data);
          setStatus(task, DownloadStatus.completed);
        } else {
          throw Exception(
              "Failed to download file: ${response.statusCode} ${response.data}");
        }
      }
    } catch (e) {
      final task = getDownload(url)!;
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

  Future<DownloadTask?> addDownload(String url, String savedDir) async {
    if (url.isNotEmpty) {
      if (savedDir.isEmpty) {
        savedDir = ".";
      }

      var isDirectory = await Directory(savedDir).exists();
      var downloadFilename = isDirectory
          ? savedDir + Platform.pathSeparator + await getFileNameFromUrl(url)
          : savedDir;

      return _addDownloadRequest(DownloadRequest(url, downloadFilename));
    }

    return null;
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

    _queue.add(DownloadRequest(downloadRequest.url, downloadRequest.path));
    var task = DownloadTask(_queue.last, File(downloadRequest.path));

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

  Future<DownloadStatus> whenDownloadComplete(String url,
      {Duration timeout = const Duration(hours: 2)}) async {
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
      addDownload(url, savedDir);
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

  ValueNotifier<DownloadedAmount> getBatchDownloadProgress(List<String> urls) {
    ValueNotifier<DownloadedAmount> progress =
        ValueNotifier(DownloadedAmount(0, 0));
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
          progress.value =
              DownloadedAmount(progressMap.values.sum.toInt(), total);
        }

        Null Function() progressListener;
        progressListener = () {
          progressMap[url] = task.downloaded.value.progressRatio;
          progress.value =
              DownloadedAmount(progressMap.values.sum.toInt(), total);
        };

        task.downloaded.addListener(progressListener);

        VoidCallback? listener;
        listener = () {
          if (task.status.value.isCompleted) {
            progressMap[url] = 1.0;
            progress.value =
                DownloadedAmount(progressMap.values.sum.toInt(), total);
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

  Future<List<DownloadTask?>?> whenBatchDownloadsComplete(List<String> urls,
      {Duration timeout = const Duration(hours: 2)}) async {
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

      runZonedGuarded(() {
        download(currentRequest.url, currentRequest.path);
      }, (e, s) {
        Fimber.w('Error downloading: $e', ex: e, stacktrace: s);
      });

      await Future.delayed(const Duration(milliseconds: 500), null);
    }
  }

  /// This function is used for get file name with extension from url
  Future<String> getFileNameFromUrl(String url) async {
    try {
      final httpClient = ref.watch(triOSHttpClientProvider);
      final response = await httpClient.get(url);

      Fimber.d("Url $url has headers ${response.headers}");
      final contentDisposition = response.headers['Content-Disposition']?.first;

      return contentDisposition?.fixFilenameForFileSystem() ??
          Uri.parse(url).pathSegments.last.fixFilenameForFileSystem();
    } catch (e) {
      Fimber.w("Error getting filename from url: $e");
      return Uri.parse(url).pathSegments.last.fixFilenameForFileSystem();
    }
  }

  Future<bool> isDownloadableFile(String url) async {
    try {
      final httpClient = ref.watch(triOSHttpClientProvider);

      // Send a HEAD request to the URL
      final response = await httpClient.get(
        url,
        headers: {
          'method': 'HEAD'
        }, // Assuming your client can handle HEAD requests
      );

      // Check if the status code is 200 (OK)
      if (response.statusCode == 200) {
        // Check for common headers that indicate a downloadable file
        final headers = response.headers;
        final contentType =
            headers['content-type']?.map((it) => it.toLowerCase()).toList() ??
                [];
        final contentDisposition = headers['content-disposition']
                ?.map((it) => it.toLowerCase())
                .toList() ??
            [];

        // Check if the Content-Type is a common file type or if Content-Disposition is attachment
        if (contentType.any((it) => it.startsWith('application/')) ||
            contentDisposition.any((it) => it.contains('attachment'))) {
          return true;
        }

        // Special handling for Google Drive and MEGA
        if (url.contains('drive.google.com')) {
          return await checkGoogleDriveLink(url);
        } else if (url.contains('mega.nz')) {
          return await checkMegaLink(url);
        }

        return false;
      } else {
        return false;
      }
    } catch (e) {
      // Handle any request exceptions
      Fimber.w('Error: $e');
      // Error checking headers, but might as well try.
      return true;
    }
  }

  Future<bool> checkGoogleDriveLink(String url) async {
    try {
      final httpClient = ref.watch(triOSHttpClientProvider);
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

  Future<bool> checkMegaLink(String url) async {
    try {
      final httpClient = ref.watch(triOSHttpClientProvider);
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
}
