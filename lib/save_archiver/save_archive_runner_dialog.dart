import 'package:collection/collection.dart';
import 'package:material_ui/material_ui.dart';
import 'package:trios/save_archiver/save_archiver.dart';
import 'package:trios/save_archiver/size_stat.dart';
import 'package:trios/themes/theme.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/rainbow/themed_progress_indicator.dart';

typedef SaveArchiveJobRunner = Future<SaveArchiveJobResult> Function(
  SaveArchiveProgressCallback onStep,
);

class SaveArchiveJobRequest {
  final String title;
  final String subtitle;
  final SaveArchiveJobRunner run;

  const SaveArchiveJobRequest({
    required this.title,
    required this.subtitle,
    required this.run,
  });
}

class SaveArchiveJobResult {
  final bool succeeded;

  /// Marks a successful job with a warning, such as an original folder that
  /// could not be removed.
  final bool needsAttention;

  final String message;

  /// Set when a save was archived, to show how much space it saved.
  final int? originalSizeInBytes;
  final int? archiveSizeInBytes;

  const SaveArchiveJobResult({
    required this.succeeded,
    required this.message,
    this.needsAttention = false,
    this.originalSizeInBytes,
    this.archiveSizeInBytes,
  });
}

enum _JobStatus { waiting, running, done, warned, failed, skipped }

class _JobState {
  final SaveArchiveJobRequest request;
  _JobStatus status = _JobStatus.waiting;
  SaveArchiveStep? step;
  SaveArchiveJobResult? result;

  _JobState(this.request);
}

/// Runs [jobs] sequentially and keeps the dialog open until they finish.
/// Cancel finishes the current job, then skips the rest, so file operations
/// are not interrupted midway. [finishedTitle] replaces [title] once every
/// job is done.
Future<void> showSaveArchiveRunnerDialog({
  required BuildContext context,
  required String title,
  required String finishedTitle,
  required List<SaveArchiveJobRequest> jobs,
  VoidCallback? onFinished,
}) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (context) => _SaveArchiveRunnerDialog(
    title: title,
    finishedTitle: finishedTitle,
    jobs: jobs,
    onFinished: onFinished,
  ),
);

class _SaveArchiveRunnerDialog extends StatefulWidget {
  final String title;
  final String finishedTitle;
  final List<SaveArchiveJobRequest> jobs;
  final VoidCallback? onFinished;

  const _SaveArchiveRunnerDialog({
    required this.title,
    required this.finishedTitle,
    required this.jobs,
    this.onFinished,
  });

  @override
  State<_SaveArchiveRunnerDialog> createState() =>
      _SaveArchiveRunnerDialogState();
}

class _SaveArchiveRunnerDialogState extends State<_SaveArchiveRunnerDialog> {
  late final List<_JobState> _jobs = widget.jobs.map(_JobState.new).toList();
  var _stopRequested = false;
  var _finished = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runAll());
  }

  Future<void> _runAll() async {
    for (final job in _jobs) {
      if (_stopRequested) {
        if (mounted) setState(() => job.status = _JobStatus.skipped);
        continue;
      }

      if (mounted) setState(() => job.status = _JobStatus.running);

      SaveArchiveJobResult result;
      try {
        result = await job.request.run((step) {
          if (mounted) setState(() => job.step = step);
        });
      } catch (error) {
        result = SaveArchiveJobResult(
          succeeded: false,
          message: 'This job failed: $error',
        );
      }

      if (!mounted) return;
      setState(() {
        job.step = null;
        job.result = result;
        job.status = result.succeeded
            ? (result.needsAttention ? _JobStatus.warned : _JobStatus.done)
            : _JobStatus.failed;
      });
    }

    widget.onFinished?.call();
    if (mounted) setState(() => _finished = true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final succeeded = _jobs
        .where((job) => job.status == _JobStatus.done)
        .length;
    final warned = _jobs.where((job) => job.status == _JobStatus.warned).length;
    final failed = _jobs.where((job) => job.status == _JobStatus.failed).length;
    final skipped = _jobs
        .where((job) => job.status == _JobStatus.skipped)
        .length;
    // With one save, its row's spinner and step text already show progress,
    // and there are no later saves for Cancel to skip.
    final showBatchControls = _jobs.length > 1 && !_finished;
    final position = _jobs
        .where((job) => job.status != _JobStatus.waiting)
        .length;
    // When everything worked, the checkmarks already say so.
    final showCounts = _jobs.isEmpty || warned + failed + skipped > 0;
    final sizedResults = _jobs
        .where((job) => job.status == _JobStatus.done)
        .mapNotNull((job) => job.result)
        .where((result) => result.originalSizeInBytes != null)
        .toList();
    final showTotal = _jobs.length > 1 && sizedResults.isNotEmpty;
    // The folder name is only needed to tell apart saves with the same name.
    final titleCounts = <String, int>{};
    for (final job in _jobs) {
      titleCounts.update(
        job.request.title,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }
    final summaryStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.bold,
    );

    // Keep progress visible until all file operations have finished.
    return PopScope(
      canPop: _finished,
      child: AlertDialog(
        title: Text(_finished ? widget.finishedTitle : widget.title),
        content: SizedBox(
          width: 560,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              if (showBatchControls)
                Row(
                  spacing: 8,
                  children: [
                    Expanded(
                      child: ThemedLinearProgressIndicator(
                        value:
                            _jobs
                                .where(
                                  (job) =>
                                      job.status != _JobStatus.waiting &&
                                      job.status != _JobStatus.running,
                                )
                                .length /
                            _jobs.length,
                      ),
                    ),
                    Text(
                      '$position of ${_jobs.length}',
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 8,
                    children: [
                      for (final job in _jobs)
                        _buildJobRow(
                          theme,
                          job,
                          showSubtitle: titleCounts[job.request.title]! > 1,
                        ),
                    ],
                  ),
                ),
              ),
              if (_finished && (showTotal || showCounts))
                Padding(
                  padding: const .only(top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 8,
                    children: [
                      const Divider(height: 1),
                      if (showTotal)
                        _buildTotals(
                          originalSize: sizedResults
                              .map((result) => result.originalSizeInBytes!)
                              .sum,
                          archiveSize: sizedResults
                              .map((result) => result.archiveSizeInBytes ?? 0)
                              .sum,
                        ),
                      if (showCounts)
                        Text(
                          _buildSummary(succeeded, warned, failed, skipped),
                          style: summaryStyle,
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          if (showBatchControls)
            TextButton(
              onPressed: _stopRequested
                  ? null
                  : () => setState(() => _stopRequested = true),
              child: Text(_stopRequested ? 'Canceling…' : 'Cancel'),
            ),
          if (_finished)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
        ],
      ),
    );
  }

  Widget _buildTotals({required int originalSize, required int archiveSize}) {
    final saved = originalSize - archiveSize;
    return Row(
      spacing: 32,
      children: [
        SizeStat(label: 'Original size', value: originalSize.bytesAsReadable()),
        SizeStat(label: 'Archive size', value: archiveSize.bytesAsReadable()),
        if (saved > 0)
          SizeStat(
            label: 'Space saved',
            value:
                '${saved.bytesAsReadable()} '
                '(${(saved * 100 / originalSize).round()}%)',
          ),
      ],
    );
  }

  String _buildSummary(int succeeded, int warned, int failed, int skipped) {
    final parts = <String>[];
    if (succeeded > 0) parts.add('$succeeded finished');
    if (warned > 0) parts.add('$warned completed with warnings');
    if (failed > 0) parts.add('$failed failed');
    if (skipped > 0) parts.add('$skipped skipped');
    if (parts.isEmpty) return 'Nothing to do.';
    return '${parts.join(', ')}.';
  }

  Widget _buildJobRow(
    ThemeData theme,
    _JobState job, {
    required bool showSubtitle,
  }) {
    final semantic = theme.extension<TriOSThemeExtension>();

    final Widget icon = switch (job.status) {
      _JobStatus.waiting => Icon(
        Icons.schedule,
        size: 20,
        color: theme.disabledColor,
      ),
      _JobStatus.running => const SizedBox(
        width: 20,
        height: 20,
        child: ThemedCircularProgressIndicator(strokeWidth: 2),
      ),
      _JobStatus.done => Icon(
        Icons.check_circle,
        size: 20,
        color: semantic?.success ?? Colors.green,
      ),
      _JobStatus.warned => Icon(
        Icons.warning_amber,
        size: 20,
        color: semantic?.warning ?? Colors.amber,
      ),
      _JobStatus.failed => Icon(
        Icons.error,
        size: 20,
        color: theme.colorScheme.error,
      ),
      _JobStatus.skipped => Icon(
        Icons.remove_circle_outline,
        size: 20,
        color: theme.disabledColor,
      ),
    };

    final detail = switch (job.status) {
      _JobStatus.running => job.step?.label ?? 'Working',
      _JobStatus.waiting => 'Waiting',
      _JobStatus.skipped => 'Skipped',
      _ => job.result?.message ?? '',
    };
    final result = job.result;
    final originalSize = result?.originalSizeInBytes;
    final archiveSize = result?.archiveSizeInBytes;
    final detailStyle = theme.textTheme.labelSmall?.copyWith(
      color: switch (job.status) {
        _JobStatus.failed => theme.colorScheme.error,
        _JobStatus.warned => semantic?.warning ?? Colors.amber,
        _ => theme.textTheme.labelSmall?.color,
      },
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Padding(padding: const .only(top: 2), child: icon),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(job.request.title, style: theme.textTheme.bodyMedium),
              if (showSubtitle && job.request.subtitle.isNotEmpty)
                Text(
                  job.request.subtitle,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.textTheme.labelSmall?.color?.withAlpha(180),
                  ),
                ),
              if (job.status == _JobStatus.done &&
                  originalSize != null &&
                  archiveSize != null)
                _SizeChange(
                  before: originalSize,
                  after: archiveSize,
                  style: detailStyle,
                ),
              if (detail.isNotEmpty) Text(detail, style: detailStyle),
            ],
          ),
        ),
      ],
    );
  }
}

/// Shows "24.96 MB compressed to 2.59 MB   Space saved 22.37 MB (90%)".
class _SizeChange extends StatelessWidget {
  final int before;
  final int after;
  final TextStyle? style;

  const _SizeChange({required this.before, required this.after, this.style});

  @override
  Widget build(BuildContext context) {
    final saved = before - after;

    return Wrap(
      spacing: 16,
      children: [
        Text(
          '${before.bytesAsReadable()} compressed to '
          '${after.bytesAsReadable()}',
          style: style,
        ),
        if (saved > 0)
          Text(
            'Space saved ${saved.bytesAsReadable()} '
            '(${(saved * 100 / before).round()}%)',
            style: style,
          ),
      ],
    );
  }
}
