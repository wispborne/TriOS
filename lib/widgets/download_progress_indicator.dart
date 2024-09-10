import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/models/download_progress.dart';
import 'package:trios/utils/extensions.dart';

class DownloadProgressIndicator extends ConsumerStatefulWidget {
  final DownloadProgress value;
  final Color? color;

  const DownloadProgressIndicator({super.key, required this.value, this.color});

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
                : widget.value.progressPercent,
            minHeight: 10,
            color: widget.color,
          ),
        ),
        Text(
          widget.value.bytesReceived == 0 && widget.value.bytesTotal == 0
              ? ""
              : widget.value.bytesReceived == widget.value.bytesTotal
                  ? widget.value.bytesTotal.bytesAsReadableMB()
                  : "${widget.value.bytesReceived.bytesAsReadableMB()} / ${widget.value.bytesTotal.bytesAsReadableMB()}",
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}
