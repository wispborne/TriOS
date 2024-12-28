import 'package:dart_mappable/dart_mappable.dart';

part 'download_progress.mapper.dart';

@MappableClass()
class TriOSDownloadProgress with TriOSDownloadProgressMappable {
  final int bytesReceived;
  final int bytesTotal;
  final bool isIndeterminate;
  final String? customStatus;

  const TriOSDownloadProgress(
    this.bytesReceived,
    this.bytesTotal, {
    this.isIndeterminate = false,
    this.customStatus,
  });

  double get progressPercent => (bytesReceived / bytesTotal).clamp(0, 1);
}
