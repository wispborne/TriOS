import 'package:trios/hullmod_viewer/models/hullmod.dart';

/// Per-variant cache payload for the hullmods viewer.
class HullmodsCachePayload {
  final List<Hullmod> hullmods;

  const HullmodsCachePayload({required this.hullmods});
}
