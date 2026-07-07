import 'package:trios/fighter_viewer/models/wing.dart';

/// Per-variant cache payload for the fighter wings loader.
class WingsCachePayload {
  final List<Wing> wings;

  const WingsCachePayload({required this.wings});
}
