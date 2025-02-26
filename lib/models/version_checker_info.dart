import 'package:dart_mappable/dart_mappable.dart';
import 'package:trios/models/mod_info_json.dart';
import 'package:trios/utils/util.dart';

part 'version_checker_info.mapper.dart';

@MappableClass()
class VersionCheckerInfo with VersionCheckerInfoMappable {
  final String? modName;
  final String? masterVersionFile;
  final String? modNexusId;
  final String? modThreadId;
  final VersionObject? modVersion;
  final String? directDownloadURL;
  final String? changelogURL;

  VersionCheckerInfo({
    this.modName,
    this.masterVersionFile,
    this.modNexusId,
    this.modThreadId,
    this.modVersion,
    this.directDownloadURL,
    this.changelogURL,
  });

  /// Whether there's a valid direct download URL.
  bool get hasDirectDownload =>
      directDownloadURL != null &&
      directDownloadURL!.isNotEmpty &&
      Uri.tryParse(directDownloadURL!) != null;

  /// Whether the basic fields are present and ostensibly valid.
  bool get seemsLegit =>
      masterVersionFile != null &&
      masterVersionFile!.isNotEmpty &&
      Uri.tryParse(masterVersionFile!) != null &&
      modVersion != null;
}
