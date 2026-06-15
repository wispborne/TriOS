import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/material.dart';

part 'catalog_card_click_action.mapper.dart';

/// Preference for what happens when the user clicks the body of a mod card
/// on the Catalog page.
///
/// The dispatch honors the existing card behavior for cached forum detail
/// HTML (which always opens `forum_post_dialog`); this enum determines what
/// happens when the card falls through to its `linkLoader` callback.
@MappableEnum(defaultValue: CatalogCardClickAction.forumDialog)
enum CatalogCardClickAction {
  /// Prefer the forum post dialog (falls back to system browser when no
  /// cached detail HTML is available).
  forumDialog,

  /// Load the URL in the embedded browser panel. Auto-opens the panel when
  /// it is currently closed.
  embeddedBrowser,

  /// Open the URL in the operating system's default browser.
  systemBrowser,
}

extension CatalogCardClickActionDisplay on CatalogCardClickAction {
  String get label => switch (this) {
    CatalogCardClickAction.forumDialog => 'Forum dialog',
    CatalogCardClickAction.embeddedBrowser => 'Embedded browser',
    CatalogCardClickAction.systemBrowser => 'System browser',
  };

  IconData get icon => switch (this) {
    CatalogCardClickAction.forumDialog => Icons.chat_bubble_outline,
    CatalogCardClickAction.embeddedBrowser => Icons.public,
    CatalogCardClickAction.systemBrowser => Icons.open_in_new,
  };
}
