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

  /// Aggregates multiple `TriOSDownloadProgress` objects into a single one.
  /// - Sums `bytesReceived` and `bytesTotal`.
  /// - Sets `isIndeterminate` to `true` if **any** progress is indeterminate.
  /// - For `customStatus`, you could:
  ///   - Use the first non-null,
  ///   - Combine them,
  ///   - Or omit it.
  ///   Adjust to your needs.
  static TriOSDownloadProgress? aggregate(
    Iterable<TriOSDownloadProgress> progressList,
  ) {
    if (progressList.isEmpty) {
      return null;
    }

    final totalReceived = progressList.fold<int>(
      0,
      (sum, p) => sum + p.bytesReceived,
    );
    final totalBytes = progressList.fold<int>(
      0,
      (sum, p) => sum + p.bytesTotal,
    );
    final anyIndeterminate = progressList.any((p) => p.isIndeterminate);

    // Show first non-null custom status
    final firstNonNullStatus = progressList
        .map((p) => p.customStatus)
        .firstWhere((s) => s != null, orElse: () => null);

    return TriOSDownloadProgress(
      totalReceived,
      totalBytes,
      isIndeterminate: anyIndeterminate,
      customStatus: firstNonNullStatus,
    );
  }
}
