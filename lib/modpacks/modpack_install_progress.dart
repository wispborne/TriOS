import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'modpack_install_progress.mapper.dart';

/// How far one pack's installation has got. Held in memory only; nothing
/// about a running installation is saved.
@MappableClass()
class ModpackInstallProgress with ModpackInstallProgressMappable {
  /// Items that have finished, whether they installed or failed.
  final int finishedCount;

  /// Items the person chose to install.
  final int totalCount;

  const ModpackInstallProgress({
    required this.finishedCount,
    required this.totalCount,
  });

  /// 0 to 1. Null when there's nothing to count yet, so a bar can show
  /// "working" rather than "0%".
  double? get fraction =>
      totalCount <= 0 ? null : (finishedCount / totalCount).clamp(0.0, 1.0);
}

/// Every pack installation running right now, keyed by pack ID.
///
/// The installation manager (phase 8) supplies the live map. Until then no
/// pack is ever installing, and the library page shows no progress.
final runningModpackInstallationsProvider =
    Provider<Map<String, ModpackInstallProgress>>((ref) => const {});
