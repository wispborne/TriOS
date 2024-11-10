import 'package:freezed_annotation/freezed_annotation.dart';

part '../generated/models/download_progress.freezed.dart';

@freezed
class TriOSDownloadProgress with _$TriOSDownloadProgress {
  const TriOSDownloadProgress._();

  const factory TriOSDownloadProgress(final int bytesReceived, final int bytesTotal,
      {@Default(false) final bool isIndeterminate, final String? customStatus}) = _TriOSDownloadProgress;

  double get progressPercent => (bytesReceived / bytesTotal).clamp(0, 1);
}
