import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'download_request.dart';
import 'download_status.dart';

class DownloadTask {
  final DownloadRequest request;
  final ValueNotifier<DownloadStatus> status =
      ValueNotifier(DownloadStatus.queued);
  final ValueNotifier<DownloadedAmount> downloaded =
      ValueNotifier(DownloadedAmount(0, 0));
  final ValueNotifier<File?> file = ValueNotifier(null);
  Object? error;

  DownloadTask(
    this.request,
  );

  Future<DownloadStatus> whenDownloadComplete(
      {Duration timeout = const Duration(hours: 2)}) async {
    var completer = Completer<DownloadStatus>();

    if (status.value.isCompleted) {
      completer.complete(status.value);
    }

    VoidCallback? listener;
    listener = () {
      if (status.value.isCompleted) {
        completer.complete(status.value);
        status.removeListener(listener!);
      }
    };

    status.addListener(listener);

    return completer.future.timeout(timeout);
  }
}

class DownloadedAmount {
  final int bytesReceived;
  final int totalBytes;
  late double progressRatio = totalBytes == 0 ? 0 : bytesReceived / totalBytes;

  DownloadedAmount(this.bytesReceived, this.totalBytes);
}
