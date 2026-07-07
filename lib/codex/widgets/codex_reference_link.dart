import 'package:flutter/material.dart';
import 'package:trios/codex/models/codex_entry.dart';

/// Wraps a cross-reference [child] so that, inside the Codex, a click navigates
/// to [entityKey].
///
/// When [onSelected] is null (the viewer tabs) the child is returned unchanged,
/// so nothing about those pages changes. When it is set (the Codex detail
/// panel) the child gets a click cursor and a tap fires the callback.
Widget asCodexLink(
  Widget child,
  CodexEntitySelected? onSelected,
  (CodexEntryType, String) entityKey,
) {
  if (onSelected == null) return child;
  return MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: () => onSelected(entityKey),
      child: child,
    ),
  );
}
