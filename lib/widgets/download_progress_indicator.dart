import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/models/download_progress.dart';
import 'package:trios/utils/extensions.dart';

class DownloadProgressIndicator extends ConsumerStatefulWidget {
  final DownloadProgress value;

  const DownloadProgressIndicator({super.key, required this.value});

  @override
  ConsumerState createState() => _DownloadProgressIndicatorState();
}

class _DownloadProgressIndicatorState
    extends ConsumerState<DownloadProgressIndicator> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: widget.value.isIndeterminate
                ? 0
                : widget.value.progressPercent ?? 0,
            minHeight: 10,
          ),
        ),
        Text(
          widget.value.bytesReceived == 0 && widget.value.bytesTotal == 0
              ? ""
              : "${widget.value.bytesReceived.bytesAsReadableMB() ?? "-"} / ${widget.value.bytesTotal.bytesAsReadableMB() ?? "-"}",
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}
