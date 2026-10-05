import 'package:material_ui/material_ui.dart';
import 'package:trios/save_archiver/save_archiver.dart';
import 'package:trios/themes/theme.dart';
import 'package:trios/widgets/rainbow/themed_progress_indicator.dart';

/// Runs one job and says how it went.
typedef SaveArchiveJobRunner = Future<SaveArchiveJobResult> Function(
  SaveArchiveProgressCallback onStep,
);

/// One save to archive, or one archive to restore.
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

/// How a job turned out.
class SaveArchiveJobResult {
  final bool succeeded;

  /// True when it worked but there is something the person should know — the
  /// usual one being that the archive is fine but the save folder is still
  /// there, so there are now two copies.
  final bool needsAttention;

  final String message;

  const SaveArchiveJobResult({
    required this.succeeded,
    required this.message,
    this.needsAttention = false,
  });
}

enum _JobStatus { waiting, running, done, warned, failed, skipped }

class _JobState {
  final SaveArchiveJobRequest request;
  _JobStatus status = _JobStatus.waiting;
  SaveArchiveStep? step;
  String? message;

  _JobState(this.request);
}

/// Runs [jobs] one at a time and shows how each one went.
///
/// Modal on purpose. These jobs move save folders around, and wandering off to
/// launch the game halfway through a batch is exactly the situation worth
/// making awkward. "Stop" finishes the job in flight and skips the rest — it
/// never interrupts one partway, because a half-finished job is the only way
/// this feature could lose anything.
Future<void> showSaveArchiveRunnerDialog({
  required BuildContext context,
  required String title,
  required List<SaveArchiveJobRequest> jobs,
  VoidCallback? onFinished,
}) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (context) => _SaveArchiveRunnerDialog(
    title: title,
    jobs: jobs,
    onFinished: onFinished,
  ),
);

class _SaveArchiveRunnerDialog extends StatefulWidget {
  final String title;
  final List<SaveArchiveJobRequest> jobs;
  final VoidCallback? onFinished;

  const _SaveArchiveRunnerDialog({
    required this.title,
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
          message: 'Something went wrong: $error',
        );
      }

      if (!mounted) return;
      setState(() {
        job.step = null;
        job.message = result.message;
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

    // Closing while jobs are still running would hide what is happening to
    // somebody's saves. Once everything has finished, Escape works again.
    return PopScope(
      canPop: _finished,
      child: AlertDialog(
        title: Text(widget.title),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              if (!_finished)
                ThemedLinearProgressIndicator(
                  value: _jobs.isEmpty
                      ? 0
                      : _jobs
                                .where(
                                  (job) =>
                                      job.status != _JobStatus.waiting &&
                                      job.status != _JobStatus.running,
                                )
                                .length /
                            _jobs.length,
                ),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 8,
                    children: [
                      for (final job in _jobs) _buildJobRow(theme, job),
                    ],
                  ),
                ),
              ),
              if (_finished)
                Padding(
                  padding: const .only(top: 8),
                  child: Text(
                    _buildSummary(succeeded, warned, failed, skipped),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          if (!_finished)
            TextButton(
              onPressed: _stopRequested
                  ? null
                  : () => setState(() => _stopRequested = true),
              child: Text(
                _stopRequested ? 'Finishing current…' : 'Stop after this one',
              ),
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

  String _buildSummary(int succeeded, int warned, int failed, int skipped) {
    final parts = <String>[];
    if (succeeded > 0) parts.add('$succeeded finished');
    if (warned > 0) parts.add('$warned need a look');
    if (failed > 0) parts.add('$failed failed');
    if (skipped > 0) parts.add('$skipped skipped');
    if (parts.isEmpty) return 'Nothing to do.';
    return '${parts.join(', ')}.';
  }

  Widget _buildJobRow(ThemeData theme, _JobState job) {
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
      _ => job.message ?? '',
    };

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
              if (job.request.subtitle.isNotEmpty)
                Text(
                  job.request.subtitle,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.textTheme.labelSmall?.color?.withAlpha(180),
                  ),
                ),
              if (detail.isNotEmpty)
                Text(
                  detail,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: switch (job.status) {
                      _JobStatus.failed => theme.colorScheme.error,
                      _JobStatus.warned => semantic?.warning ?? Colors.amber,
                      _ => theme.textTheme.labelSmall?.color,
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
