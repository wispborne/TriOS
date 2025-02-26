class DownloadRequest {
  final String url;
  final String directory;
  final String? filename;

  // var cancelToken = CancelToken();
  var forceDownload = false;

  DownloadRequest(this.url, this.directory, this.filename);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DownloadRequest &&
          runtimeType == other.runtimeType &&
          url == other.url &&
          directory == other.directory &&
          filename == other.filename;

  @override
  int get hashCode =>
      url.hashCode ^ directory.hashCode ^ (filename?.hashCode ?? 42);
}
