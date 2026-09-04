import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'modpack_install_progress.mapper.dart';

/// Installation progress, kept only in memory.
@MappableClass()
class ModpackInstallProgress with ModpackInstallProgressMappable {
  final int finishedCount;

  final int totalCount;

  const ModpackInstallProgress({
    required this.finishedCount,
    required this.totalCount,
  });

  /// Completed fraction, or null when the total is unknown.
  double? get fraction =>
      totalCount <= 0 ? null : (finishedCount / totalCount).clamp(0.0, 1.0);
}

final runningModpackInstallationsProvider =
    Provider<Map<String, ModpackInstallProgress>>((ref) => const {});
