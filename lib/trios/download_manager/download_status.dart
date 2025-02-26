enum DownloadStatus {
  queued,
  retrievingFileInfo,
  downloading,
  completed,
  failed,
  paused,
  canceled,
}

extension DownloadStatusExtension on DownloadStatus {
  bool get isCompleted {
    switch (this) {
      case DownloadStatus.queued:
        return false;
      case DownloadStatus.retrievingFileInfo:
        return false;
      case DownloadStatus.downloading:
        return false;
      case DownloadStatus.paused:
        return false;
      case DownloadStatus.completed:
        return true;
      case DownloadStatus.failed:
        return true;

      case DownloadStatus.canceled:
        return true;
    }
  }

  String get displayString {
    switch (this) {
      case DownloadStatus.queued:
        return "Queued";
      case DownloadStatus.retrievingFileInfo:
        return "Retrieving File Info";
      case DownloadStatus.downloading:
        return "Downloading";
      case DownloadStatus.completed:
        return "Completed";
      case DownloadStatus.failed:
        return "Failed";
      case DownloadStatus.paused:
        return "Paused";
      case DownloadStatus.canceled:
        return "Canceled";
    }
  }
}
