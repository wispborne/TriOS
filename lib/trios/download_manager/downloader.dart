import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:trios/utils/extensions.dart';

import '../../utils/logging.dart';
import 'download_request.dart';
import 'download_status.dart';
import 'download_task.dart';

class DownloadManager {
  final Map<String, DownloadTask> _cache = <String, DownloadTask>{};
  final Queue<DownloadRequest> _queue = Queue();
  final dio = Dio();
  static const partialExtension = ".partial";
  static const tempExtension = ".temp";

  // var tasks = StreamController<DownloadTask>();

  int maxConcurrentTasks = 2;
  int runningTasks = 0;

  static final DownloadManager _dm = DownloadManager._internal();

  DownloadManager._internal();

  factory DownloadManager({int? maxConcurrentTasks}) {
    if (maxConcurrentTasks != null) {
      _dm.maxConcurrentTasks = maxConcurrentTasks;
    }
    return _dm;
  }

  void Function(int, int) createCallback(url, int partialFileLength) =>
      (int received, int total) {
        final download = DownloadedAmount(received, total);
        // getDownload(url)?.progressRatio.value =
        //     (received + partialFileLength) / (total + partialFileLength);
        getDownload(url)?.downloaded.value = download;

        if (total == -1) {}
      };

  Future<void> download(String url, String savePath, cancelToken,
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
        throw Exception("No file to download found at '$url'.\nPlease contact the mod author.");
      }

      var file = File(savePath.toString());
      partialFilePath = savePath + partialExtension;
      partialFile = File(partialFilePath);

      var fileExist = await file.exists();
      var partialFileExist = await partialFile.exists();

      if (fileExist) {
        Fimber.d("File Exists: $savePath");
        setStatus(task, DownloadStatus.completed);
      } else if (partialFileExist) {
        Fimber.d("Partial File Exists: $partialFilePath");

        final partialFileLength = await partialFile.length();

        final response = await dio.download(
            url, partialFilePath + tempExtension,
            onReceiveProgress: createCallback(url, partialFileLength),
            options: Options(
              headers: {HttpHeaders.rangeHeader: 'bytes=$partialFileLength-'},
            ),
            cancelToken: cancelToken,
            deleteOnError: true);

        if (response.statusCode == HttpStatus.partialContent) {
          var ioSink = partialFile.openWrite(mode: FileMode.writeOnlyAppend);
          var f0 = File(partialFilePath + tempExtension);
          await ioSink.addStream(f0.openRead());
          await f0.delete();
          await ioSink.close();
          await partialFile.rename(savePath);

          setStatus(task, DownloadStatus.completed);
        }
      } else {
        final response = await dio.download(url, partialFilePath,
            onReceiveProgress: createCallback(url, 0),
            cancelToken: cancelToken,
            deleteOnError: false);

        if (response.statusCode == HttpStatus.ok) {
          await partialFile.rename(savePath);
          setStatus(task, DownloadStatus.completed);
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
    task.request.cancelToken.cancel();

    _queue.remove(task.request);
  }

  Future<void> cancelDownload(String url) async {
    Fimber.d("Cancel Download: $url");
    var task = getDownload(url)!;
    setStatus(task, DownloadStatus.canceled);
    _queue.remove(task.request);
    task.request.cancelToken.cancel();
  }

  Future<void> resumeDownload(String url) async {
    Fimber.d("Resume Download: $url");
    var task = getDownload(url)!;
    setStatus(task, DownloadStatus.downloading);
    task.request.cancelToken = CancelToken();
    _queue.add(task.request);

    _startExecution();
  }

  Future<void> removeDownload(String url) async {
    cancelDownload(url);
    _cache.remove(url);
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

      download(
          currentRequest.url, currentRequest.path, currentRequest.cancelToken);

      await Future.delayed(const Duration(milliseconds: 500), null);
    }
  }

  /// This function is used for get file name with extension from url
  Future<String> getFileNameFromUrl(String url) async {
    // val conn = URL(url).openConnection()
    // Timber.v { "Url $url has headers ${conn.headerFields.entries.joinToString(separator = "\n")}" }
    //
    // Timber.i { "Downloadable file clicked: $url." }
    // val contentDisposition = ContentDisposition.parse(conn.getHeaderField("Content-Disposition"))
    // val filename = contentDisposition.parameter("filename")

    try {
      final uri = Uri.parse(url);
      final headers = (await dio.headUri(uri)).headers;
      Fimber.d("Url $url has headers ${headers.map.entries.join("\n")}");
      final contentDisposition = headers.value("Content-Disposition");
      return contentDisposition?.fixFilenameForFileSystem() ??
          uri.pathSegments.last.fixFilenameForFileSystem();
    } catch (e) {
      Fimber.w("Error getting filename from url: $e");
      return Uri.parse(url).pathSegments.last.fixFilenameForFileSystem();
    }
  }

  static Future<bool> isDownloadableFile(String url) async {
    try {
      var dio = Dio();
      // Send a HEAD request to the URL
      final response = await dio.headUri(Uri.parse(url));

      // Check if the status code is 200 (OK)
      if (response.statusCode == 200) {
        // Check for common headers that indicate a downloadable file
        final headers = response.headers.map;
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
      return false;
    }
  }

  static Future<bool> checkGoogleDriveLink(String url) async {
    try {
      var dio = Dio();
      // Google Drive files usually require confirmation to download
      final response = await dio.get(url);

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

  static Future<bool> checkMegaLink(String url) async {
    try {
      var dio = Dio();
      // MEGA links should be direct or use a confirmation link
      final response = await dio.get(url);

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
