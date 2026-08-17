import 'package:material_ui/material_ui.dart';
import 'package:trios/hullmod_viewer/models/hullmod.dart';
import 'package:trios/hullmod_viewer/widgets/hullmod_codex_card.dart';
import 'package:trios/widgets/dialog_pager.dart';

/// Shows the full hullmod details dialog — the same dialog opened by clicking a
/// row in the Hullmods viewer. Extracted here so the Codex can open it too.
///
/// Pass [siblings] (the hullmods in display order) to get Previous/Next paging
/// in the dialog. With no list, the dialog shows just [h] with no paging.
void showHullmodDetailsDialog(
  BuildContext context,
  Hullmod h, {
  List<Hullmod>? siblings,
}) {
  final items = (siblings != null && siblings.any((other) => other.id == h.id))
      ? siblings
      : [h];
  final startIndex = items.indexWhere((other) => other.id == h.id);

  showDialog(
    context: context,
    builder: (ctx) {
      return Dialog(
        clipBehavior: Clip.antiAlias,
        insetPadding: const EdgeInsets.all(16),
        child: DialogPager<Hullmod>(
          items: items,
          startIndex: startIndex,
          itemBuilder: (ctx, hullmod, pagerControls) =>
              buildHullmodDetailsDialogBody(
                ctx,
                hullmod,
                pagerControls: pagerControls,
              ),
        ),
      );
    },
  );
}

/// The hullmod dialog's contents for one hullmod. [pagerControls] is the
/// Previous/Next button pair from [DialogPager]; it sits in the top-right
/// corner, left of the Close icon.
Widget buildHullmodDetailsDialogBody(
  BuildContext context,
  Hullmod h, {
  Widget pagerControls = const SizedBox.shrink(),
}) {
  return ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 600),
    child: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                pagerControls,
                IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            HullmodCodexCard.create(hullmod: h),
            const SizedBox(height: 12),
            Row(
              children: [
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
