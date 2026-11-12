import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/catalog/catalog_download_resolver.dart';
import 'package:trios/catalog/catalog_mod_card.dart';
import 'package:trios/catalog/details_dialog/details_panel_section.dart';
import 'package:trios/catalog/download_candidate_actions.dart';
import 'package:trios/catalog/models/catalog_mod.dart';
import 'package:trios/mod_manager/mod_manager_extensions.dart';
import 'package:trios/mod_manager/mod_version_selection_dropdown.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/context_menu_items.dart';
import 'package:trios/trios/download_manager/download_manager.dart';

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
    final candidates = uniqueByLink([...cardCandidates, ...postCandidates]);

    final muteItem = installedMod == null
        ? null
        : buildMenuItemToggleMuteUpdates(installedMod, ref);

    return SidePanelSection(
      title: 'Get it',
      children: [
        Row(
          spacing: 8,
          children: [
            // The Mods page's own button: shows the enabled version or
            // "Enable", and switches between installed versions.
            if (installedMod != null)
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) =>
                      ModVersionSelectionDropdown(
                        mod: installedMod,
                        width: constraints.maxWidth,
                        showTooltip: true,
                      ),
                ),
              ),
            Expanded(
              child: CatalogDownloadButton(
                mod: entry,
                installedMod: installedMod,
                versionCheckComparison: comparison,
                linkLoader: linkLoader,
                llmMainMod: mod.llmMod,
                isUpdateMuted: isUpdateMuted,
                large: true,
                otherOptions: candidates,
                onOtherOptionSelected: (candidate) => executeDownloadCandidate(
                  context,
                  ref,
                  candidate,
                  modName: entry.name,
                  sourceHint: DownloadSourceHint.fromModRepoEntry(entry),
                  linkLoader: linkLoader,
                ),
              ),
            ),
          ],
        ),
        if (installedMod != null) ...[
          if (muteItem != null)
            Align(
              alignment: Alignment.centerLeft,
              child: SidePanelLink(
                icon: muteItem.icon,
                label: muteItem.label,
                onTap: muteItem.onSelected,
              ),
            ),
        ],
      ],
    );
  }
}
