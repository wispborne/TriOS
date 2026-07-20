import 'package:trios/faction_viewer/models/faction.dart';

/// One source's worth of raw `.faction` files. Merging happens later, in
/// `mergedFactionListProvider`, so the cache stays independent of which mods
/// are enabled.
class FactionsCachePayload {
  final List<FactionFileData> files;

  const FactionsCachePayload({required this.files});
}
