import 'package:material_ui/material_ui.dart';
import 'package:trios/modpacks/sharing/modpack_share_controller.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/rainbow/themed_progress_indicator.dart';
import 'package:trios/widgets/text_trios.dart';

class ModpackSourceCheckSection extends StatelessWidget {
  final ModpackShareState state;
  final VoidCallback onCancel;
  final VoidCallback onRepair;
  const ModpackSourceCheckSection({
    super.key,
    required this.state,
    required this.onCancel,
    required this.onRepair,
  });
  @override
  Widget build(BuildContext context) {
    if (state.checks.isEmpty) return const SizedBox.shrink();
    final done = state.checks
        .where((check) => check.status == .passed || check.status == .failed)
        .length;
    final failed = state.checks.any((check) => check.status == .failed);
    return Padding(
      padding: const .fromLTRB(8, 8, 8, 0),
      child: Card(
        margin: .zero,
        child: Padding(
          padding: const .all(8),
          child: Column(
            crossAxisAlignment: .stretch,
            spacing: 8,
            children: [
              Row(
                spacing: 8,
                children: [
                  Expanded(
                    child: Text(
                      'Source checks · $done of ${state.checks.length}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  if (state.running)
                    TextButton(
                      onPressed: onCancel,
                      child: const Text('Cancel checks'),
                    ),
                  if (failed && !state.running)
                    TextButton.icon(
                      onPressed: onRepair,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Repair sources'),
                    ),
                ],
              ),
              if (state.running)
                ThemedLinearProgressIndicator(
                  value: done / state.checks.length,
                ),
              SizedBox(
                height: (state.checks.length * 40.0).clamp(40, 200),
                child: ListView.builder(
                  itemCount: state.checks.length,
                  itemExtent: 40,
                  itemBuilder: (context, index) {
                    final check = state.checks[index];
                    final label = switch (check.status) {
                      .waiting => 'Waiting',
                      .checking => 'Checking…',
                      .passed =>
                        check.cached ? 'Passed · checked recently' : 'Passed',
                      .failed => check.error ?? 'Failed',
                      .cancelled => 'Cancelled',
                    };
                    return Row(
                      spacing: 8,
                      children: [
                        Icon(
                          switch (check.status) {
                            .passed => Icons.check_circle_outline,
                            .failed => Icons.warning_amber,
                            .cancelled => Icons.cancel_outlined,
                            _ => Icons.hourglass_empty,
                          },
                          size: 16,
                          color: check.status == .failed
                              ? Theme.of(context).colorScheme.error
                              : null,
                        ),
                        Expanded(
                          child: TextTriOS(check.item.displayName, maxLines: 1),
                        ),
                        Expanded(
                          flex: 2,
                          child: MovingTooltipWidget.text(
                            message: label,
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: .ellipsis,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ),
                        ),
                        if (check.status == .failed && !state.running)
                          TextButton(
                            onPressed: onRepair,
                            child: const Text('Repair'),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
