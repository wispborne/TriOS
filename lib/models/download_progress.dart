import 'package:freezed_annotation/freezed_annotation.dart';

part '../generated/models/download_progress.freezed.dart';

@freezed
class DownloadProgress with _$DownloadProgress {
  const DownloadProgress._();

  const factory DownloadProgress(final int bytesReceived, final int bytesTotal,
      {@Default(false) final bool isIndeterminate, final String? customStatus}) = _DownloadProgress;

  double get progressPercent => (bytesReceived / bytesTotal).clamp(0, 1);
}
