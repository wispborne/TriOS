import 'package:trios/portraits/portrait_model.dart';

/// Per-variant cache payload for the portraits viewer.
class PortraitsCachePayload {
  final List<Portrait> portraits;

  const PortraitsCachePayload({required this.portraits});
}
