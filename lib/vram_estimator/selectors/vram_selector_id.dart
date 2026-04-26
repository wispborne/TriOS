import 'package:dart_mappable/dart_mappable.dart';

part 'vram_selector_id.mapper.dart';

/// Stable identifier for a registered [VramAssetSelector]. The
/// [wireValue] is the persisted form (settings JSON, msgpack cache file
/// name suffix, isolate transfer payload) — keep stable across releases.
@MappableEnum(defaultValue: VramSelectorId.folderScan)
enum VramSelectorId {
  @MappableValue('folder-scan')
  folderScan('folder-scan'),
  @MappableValue('referenced')
  referenced('referenced');

  const VramSelectorId(this.wireValue);

  final String wireValue;

  /// Resolve a wire value back into the enum. Unknown values fall back
  /// to [VramSelectorId.folderScan], matching the rest of the system.
  static VramSelectorId fromWire(String value) {
    for (final v in values) {
      if (v.wireValue == value) return v;
    }
    return VramSelectorId.folderScan;
  }
}
