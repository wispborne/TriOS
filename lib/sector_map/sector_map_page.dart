import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/mod_profiles/save_reader.dart';
import 'package:trios/sector_map/finder/widgets/finder_panel.dart';
import 'package:trios/sector_map/finder/widgets/hint_ladder.dart';
import 'package:trios/sector_map/models/sector.dart';
import 'package:trios/sector_map/sector_map_controller.dart';
import 'package:trios/sector_map/sector_map_manager.dart';
import 'package:trios/sector_map/widgets/sector_map_canvas.dart';
import 'package:trios/sector_map/widgets/system_detail_panel.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/widgets/moving_tooltip.dart';

class SectorMapPage extends ConsumerStatefulWidget {
  const SectorMapPage({super.key});

  @override
  ConsumerState<SectorMapPage> createState() => _SectorMapPageState();
}

class _SectorMapPageState extends ConsumerState<SectorMapPage>
    with AutomaticKeepAliveClientMixin<SectorMapPage> {
  @override
  bool get wantKeepAlive => true;

  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final saves = (ref.watch(saveFileProvider).valueOrNull ?? []).toList()
      ..sort(
        (a, b) => (b.saveDate ?? DateTime(0)).compareTo(a.saveDate ?? DateTime(0)),
      );

    final controller = ref.watch(sectorMapControllerProvider.notifier);
    final state = ref.watch(sectorMapControllerProvider);

    // auto-select the most recent save once saves are available
    if (state.source == null && saves.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && ref.read(sectorMapControllerProvider).source == null) {
          controller.selectSave(saves.first.sectorSource);
        }
      });
    }

    return Column(
      children: [
        _buildToolbar(context, saves, state, controller),
        const Divider(height: 1),
        Expanded(child: _buildBody(context, state, controller)),
      ],
    );
  }

  Widget _buildToolbar(
    BuildContext context,
    List<SaveFile> saves,
    SectorMapState state,
    SectorMapController controller,
  ) {
    final theme = Theme.of(context);
    final sectorAsync = state.source == null
        ? null
        : ref.watch(sectorMapProvider(state.source!));
    final sector = sectorAsync?.valueOrNull;

    SaveFile? selectedSave;
    for (final s in saves) {
      if (s.sectorSource == state.source) {
        selectedSave = s;
        break;
      }
    }

    final isAtlas = state.mode == SectorMapMode.atlas;

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        spacing: 12,
        children: [
          const Icon(Icons.scatter_plot),
          // save picker
          DropdownButton<SaveFile>(
            value: selectedSave,
            hint: const Text('Select a save'),
            underline: const SizedBox.shrink(),
            items: [
              for (final s in saves)
                DropdownMenuItem(
                  value: s,
                  child: Text(
                    '${s.characterName} (lvl ${s.characterLevel})',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (s) {
              if (s != null) controller.selectSave(s.sectorSource);
            },
          ),
          if (isAtlas) ...[
            // search (atlas only — the finder hides locations on purpose)
            SizedBox(
              width: 240,
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  isDense: true,
                  prefixIcon: Icon(Icons.search, size: 18),
                  hintText: 'Find system…',
                  border: OutlineInputBorder(),
                ),
                onChanged: controller.setSearch,
                onSubmitted: (q) => _jumpToSystem(sector, q, controller),
              ),
            ),
            if (sector != null)
              _buildFactionFilter(context, sector, controller),
          ] else
            Text('System Finder', style: theme.textTheme.titleMedium),
          const Spacer(),
          if (sector != null && isAtlas)
            Text(
              '${sector.systems.length} systems  •  '
              '${sector.systems.where((s) => s.isInhabited).length} inhabited',
              style: theme.textTheme.bodySmall,
            ),
          if (isAtlas)
            MovingTooltipWidget.text(
              message: 'Back to the System Finder',
              child: TextButton.icon(
                onPressed: () => controller.setMode(SectorMapMode.finder),
                icon: const Icon(Icons.travel_explore, size: 18),
                label: const Text('Finder'),
              ),
            )
          else
            MovingTooltipWidget.text(
              message: 'Reveal the whole sector now',
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'atlas',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.public),
                      title: Text('Show everything (spoiler)'),
                    ),
                  ),
                ],
                onSelected: (v) {
                  if (v == 'atlas') controller.setMode(SectorMapMode.atlas);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFactionFilter(
    BuildContext context,
    Sector sector,
    SectorMapController controller,
  ) {
    final colors = ref.watch(factionColorsProvider);
    final names = ref.watch(factionNamesProvider);
    final factionIds =
        (sector.systems
              .expand((s) => s.markets.map((m) => m.factionId))
              .toSet()
              .toList())
          ..sort();
    final state = ref.watch(sectorMapControllerProvider);

    return MovingTooltipWidget.text(
      message: 'Filter systems by faction',
      child: PopupMenuButton<String>(
        icon: Badge(
          isLabelVisible: state.hiddenFactionIds.isNotEmpty,
          label: Text('${state.hiddenFactionIds.length}'),
          child: const Icon(Icons.filter_alt),
        ),
        itemBuilder: (context) => [
          PopupMenuItem(
            enabled: false,
            child: TextButton.icon(
              icon: const Icon(Icons.clear, size: 16),
              label: const Text('Show all'),
              onPressed: () {
                controller.clearFactionFilter();
                Navigator.pop(context);
              },
            ),
          ),
          const PopupMenuDivider(),
          for (final id in factionIds)
            CheckedPopupMenuItem(
              value: id,
              checked: !state.hiddenFactionIds.contains(id),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: factionColorFor(colors, id),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Text(factionNameFor(names, id)),
                ],
              ),
            ),
        ],
        onSelected: controller.toggleFaction,
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    SectorMapState state,
    SectorMapController controller,
  ) {
    if (state.source == null) {
      return const Center(child: Text('Select a save to view its sector.'));
    }

    final sectorAsync = ref.watch(sectorMapProvider(state.source!));
    final colors = ref.watch(factionColorsProvider);
    final names = ref.watch(factionNamesProvider);

    return sectorAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) {
        Fimber.w('Failed to parse sector: $e');
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not read this sector.\n\n$e',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        );
      },
      data: (sector) {
        Color colorFor(String id) => factionColorFor(colors, id);
        String nameFor(String id) => factionNameFor(names, id);

        if (state.mode == SectorMapMode.finder) {
          final engine = ref.watch(finderEngineProvider(state.source!));
          if (engine == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return Row(
            children: [
              SizedBox(
                width: 380,
                child: FinderPanel(sector: sector),
              ),
              const VerticalDivider(width: 1),
              Expanded(child: HintLadder(sector: sector, engine: engine)),
            ],
          );
        }

        SectorSystem? selected;
        if (state.selectedSystemId != null) {
          for (final s in sector.systems) {
            if (s.id == state.selectedSystemId) {
              selected = s;
              break;
            }
          }
        }

        return Stack(
          children: [
            Positioned.fill(
              child: SectorMapCanvas(
                sector: sector,
                factionColors: colors,
                colorFor: colorFor,
                nameFor: nameFor,
                hiddenFactionIds: state.hiddenFactionIds,
                selectedSystemId: state.selectedSystemId,
                focusRequest: state.focusRequest,
                onSelect: controller.selectSystem,
              ),
            ),
            if (selected != null)
              Positioned(
                top: 0,
                right: 0,
                bottom: 0,
                child: SystemDetailPanel(
                  system: selected,
                  constellationName: selected.constellationId == null
                      ? null
                      : sector.constellations
                            .firstWhere(
                              (c) => c.id == selected!.constellationId,
                              orElse: () =>
                                  const SectorConstellation(id: '', name: ''),
                            )
                            .name,
                  colorFor: colorFor,
                  nameFor: nameFor,
                  onClose: () => controller.selectSystem(null),
                  onCenter: () => controller.focusSystem(selected!.id),
                ),
              ),
          ],
        );
      },
    );
  }

  void _jumpToSystem(
    Sector? sector,
    String query,
    SectorMapController controller,
  ) {
    if (sector == null || query.trim().isEmpty) return;
    final q = query.trim().toLowerCase();
    final match = sector.systems
        .where((s) => s.name.toLowerCase().contains(q))
        .cast<SectorSystem?>()
        .firstWhere((s) => true, orElse: () => null);
    if (match != null) controller.focusSystem(match.id);
  }
}
