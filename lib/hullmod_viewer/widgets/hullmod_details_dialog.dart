import 'package:flutter/material.dart';
import 'package:trios/hullmod_viewer/models/hullmod.dart';
import 'package:trios/hullmod_viewer/widgets/hullmod_codex_card.dart';

/// Shows the full hullmod details dialog — the same dialog opened by clicking a
/// row in the Hullmods viewer. Extracted here so the Codex can open it too.
void showHullmodDetailsDialog(BuildContext context, Hullmod h) {
  showDialog(
    context: context,
    builder: (ctx) {
      return Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        tooltip: 'Close',
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  HullmodCodexCard.create(hullmod: h),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
