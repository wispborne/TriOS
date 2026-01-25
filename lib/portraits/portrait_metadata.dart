import 'package:dart_mappable/dart_mappable.dart';
import 'package:trios/utils/extensions.dart';

part 'portrait_metadata.mapper.dart';

/// Gender classification for portraits as defined in faction files.
enum PortraitGender {
  male,
  female,
  any;

  @override
  String toString() {
    switch (this) {
      case PortraitGender.male:
        return 'Male';
      case PortraitGender.female:
        return 'Female';
      case PortraitGender.any:
        return 'Any';
    }
  }
}

/// Represents a faction that uses a portrait.
@MappableClass()
class FactionInfo with FactionInfoMappable {
  /// The faction ID from the faction file (e.g., "hegemony", "pirates").
  final String id;

  /// The display name of the faction (e.g., "Hegemony", "Pirates").
  final String? displayName;

  FactionInfo({required this.id, this.displayName});

  @override
  String toString() => id == 'player' ? "Player" : displayName?.toTitleCase() ?? id.toTitleCase();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FactionInfo &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Metadata about a portrait extracted from mod data files.
///
/// This information is hydrated from:
/// - Faction files (*.faction) which define which portraits are used by which
///   factions and their gender classification.
/// - Settings files (settings.json) which define character portraits with IDs
///   under `graphics.characters`.
@MappableClass()
class PortraitMetadata with PortraitMetadataMappable {
  /// The relative path of the portrait (used as a key to match with Portrait objects).
  final String relativePath;

  /// The gender of the portrait as classified in faction files.
  final PortraitGender? gender;

  /// The factions that use this portrait.
  final Set<FactionInfo> factions;

  /// The portrait ID from settings.json `graphics.characters` section.
  /// This is the key used to reference the portrait in game code.
  final String? portraitId;

  PortraitMetadata({
    required this.relativePath,
    required this.gender,
    required this.factions,
    this.portraitId,
  });

  /// Creates an empty metadata object for portraits not found in any faction file.
  factory PortraitMetadata.unknown(String relativePath) {
    return PortraitMetadata(
      relativePath: relativePath,
      gender: PortraitGender.any,
      factions: {},
    );
  }

  /// Whether this portrait has any known metadata (is in at least one faction or has an ID).
  bool get hasMetadata => factions.isNotEmpty || portraitId != null;

  /// Returns a copy with additional factions merged in.
  PortraitMetadata mergeWith(PortraitMetadata other) {
    if (relativePath != other.relativePath) {
      throw ArgumentError('Cannot merge metadata for different portraits');
    }

    // If gender differs, prefer non-unknown, or keep original
    final mergedGender = gender == PortraitGender.any ? other.gender : gender;

    // Keep the first non-null portrait ID
    final mergedPortraitId = portraitId ?? other.portraitId;

    return PortraitMetadata(
      relativePath: relativePath,
      gender: mergedGender,
      factions: {...factions, ...other.factions},
      portraitId: mergedPortraitId,
    );
  }

  @override
  String toString() {
    final factionNames = factions.map((f) => f.toString()).join(', ');
    return 'PortraitMetadata{path: $relativePath, gender: $gender, factions: [$factionNames], id: $portraitId}';
  }
}
