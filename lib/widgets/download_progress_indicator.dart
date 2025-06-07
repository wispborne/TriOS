import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/models/download_progress.dart';
import 'package:trios/utils/extensions.dart';

class TriOSDownloadProgressIndicator extends ConsumerStatefulWidget {
  final TriOSDownloadProgress value;
  final Color? color;

  const TriOSDownloadProgressIndicator({
    super.key,
    required this.value,
    this.color,
  });

  @override
  ConsumerState createState() => _TriOSDownloadProgressIndicatorState();
}

class _TriOSDownloadProgressIndicatorState
    extends ConsumerState<TriOSDownloadProgressIndicator> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: widget.value.isIndeterminate
                ? null
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
