import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/catalog/catalog_download_resolver.dart';
import 'package:trios/catalog/catalog_mod_card.dart';
import 'package:trios/catalog/details_dialog/addons_tab.dart';
import 'package:trios/catalog/details_dialog/details_panel_section.dart';
import 'package:trios/catalog/download_candidate_actions.dart';
import 'package:trios/catalog/models/catalog_mod.dart';
import 'package:trios/mod_manager/mod_manager_extensions.dart';
import 'package:trios/mod_manager/mod_version_selection_dropdown.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/context_menu_items.dart';
import 'package:trios/trios/download_manager/download_manager.dart';
import 'package:trios/trios/download_manager/download_target.dart';
import 'package:trios/utils/extensions.dart';

/// The Get it panel: the same Install / Update / Installed button as the
/// mod's catalog card, with every download in an "Other download options"
/// menu. An installed mod also gets its state, Enable or Disable, and the
/// mute toggle.
class GetItPanel extends ConsumerWidget {
  final CatalogMod mod;

  /// Downloads the forum post offers for this mod that the card doesn't know
  /// about. Added to the end of the menu.
  final List<DownloadCandidate> postCandidates;
  final void Function(String url) linkLoader;

  const GetItPanel({
    super.key,
    required this.mod,
    required this.postCandidates,
    required this.linkLoader,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final entry = mod.entry;
    final installedMod = mod.installedMod;
    // Dart skips the argument when the mod isn't installed, so the version
    // checks are only watched for installed mods.
    final comparison = installedMod?.updateCheck(
      ref.watch(AppState.versionCheckResults).value,
    );
    final isUpdateMuted =
        installedMod != null &&
        ref
                .watch(AppState.modsMetadata)
                .value
                ?.getMergedModMetadata(installedMod.id)
                ?.isUpdateHidden(comparison?.remoteVersionString) ==
            true;

    final cardCandidates = resolveDownloadCandidates(
      entry,
      mod.llmMod,
      remoteVersion: comparison?.remoteVersionCheck?.remoteVersion,
    );
    final cardUrls = {for (final c in cardCandidates) c.url};
    final candidates = [
      ...cardCandidates,
      for (final c in postCandidates)
        if (!cardUrls.contains(c.url)) c,
    ];

    // Matches the card button's own target, so picking from the menu shows
    // progress on that button.
    final target = DownloadTarget(
      modId: installedMod?.id,
      url: primaryCandidate(cardCandidates)?.url,
      catalogName: entry.name,
      displayName: entry.name,
    );

    final muteItem = installedMod == null
        ? null
        : buildMenuItemToggleMuteUpdates(installedMod, ref);

    final isEnabled = installedMod?.isEnabledInGame ?? false;
    // Grey outlines, the same as the toolbar items on the other pages.
    final secondaryStyle = OutlinedButton.styleFrom(
      visualDensity: VisualDensity.compact,
      textStyle: theme.textTheme.labelMedium,
      padding: const .symmetric(horizontal: 12),
      side: BorderSide(color: theme.colorScheme.outlineVariant),
    );

    return SidePanelSection(
      title: 'Get it',
      children: [
        Row(
          spacing: 8,
          children: [
            Expanded(
              child: CatalogDownloadButton(
                mod: entry,
                installedMod: installedMod,
                versionCheckComparison: comparison,
                linkLoader: linkLoader,
                llmMainMod: mod.llmMod,
                isUpdateMuted: isUpdateMuted,
                large: true,
              ),
            ),
            if (candidates.length > 1)
              OtherDownloadOptionsButton(
                candidates: candidates,
                target: target,
                outlined: true,
                onSelected: (candidate) => executeDownloadCandidate(
                  context,
                  ref,
                  candidate,
                  modName: entry.name,
                  sourceHint: DownloadSourceHint.fromModRepoEntry(entry),
                  linkLoader: linkLoader,
                ),
              ),
          ],
        ),
        if (installedMod != null) ...[
          Row(
            spacing: 8,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isEnabled
                      ? theme.statusColors.success
                      : theme.statusColors.neutral,
                ),
              ),
              Text(
                isEnabled ? 'Enabled' : 'Installed, disabled',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // The Mods page's own button: enables, disables, and switches
              // between installed versions.
              ModVersionSelectionDropdown(
                mod: installedMod,
                width: 160,
                showTooltip: true,
              ),
              if (muteItem != null)
                OutlinedButton.icon(
                  style: secondaryStyle,
                  onPressed: muteItem.onSelected,
                  icon: Icon(muteItem.icon, size: 16),
                  label: Text(muteItem.label),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
