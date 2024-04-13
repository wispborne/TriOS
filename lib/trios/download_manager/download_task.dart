import 'dart:async';

import 'package:flutter/foundation.dart';

import 'download_request.dart';
import 'download_status.dart';

class DownloadTask {
  final DownloadRequest request;
  ValueNotifier<DownloadStatus> status = ValueNotifier(DownloadStatus.queued);
  ValueNotifier<double> progressRatio = ValueNotifier(0);
  ValueNotifier<int> bytesReceived = ValueNotifier(0);
  ValueNotifier<int> totalBytes = ValueNotifier(0);

  DownloadTask(
    this.request,
  );

  Future<DownloadStatus> whenDownloadComplete(
      {Duration timeout = const Duration(hours: 2)}) async {
    var completer = Completer<DownloadStatus>();

    if (status.value.isCompleted) {
      completer.complete(status.value);
    }

    var listener;
    listener = () {
      if (status.value.isCompleted) {
        completer.complete(status.value);
        status.removeListener(listener);
      }
    };

    status.addListener(listener);

    return completer.future.timeout(timeout);
  }
}
