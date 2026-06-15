import 'package:dart_mappable/dart_mappable.dart';

part 'activity_entry.mapper.dart';

@MappableEnum()
enum ActivitySourceType {
  download,
  archive,
}

@MappableEnum()
enum ActivityStatus {
  completed,
  failed,
  cancelled,
}

@MappableClass()
class ActivityEntry with ActivityEntryMappable {
  final String id;
  final String modName;
  final String? modId;
  final String? modVersion;
  final ActivitySourceType sourceType;
  final String? sourceDetail;
  final DateTime timestamp;
  final ActivityStatus status;
  final String? errorMessage;
  final String? modIconPath;

  const ActivityEntry({
    required this.id,
    required this.modName,
    this.modId,
    this.modVersion,
    required this.sourceType,
    this.sourceDetail,
    required this.timestamp,
    required this.status,
    this.errorMessage,
    this.modIconPath,
  });
}

/// Wrapper for persisting a list of [ActivityEntry]s.
@MappableClass()
class ActivityHistory with ActivityHistoryMappable {
  final List<ActivityEntry> entries;

  const ActivityHistory({this.entries = const []});
}
