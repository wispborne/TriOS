import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:trios/models/mod_info_json.dart';
import 'package:trios/utils/util.dart';

part '../generated/models/version_checker_info.freezed.dart';

part '../generated/models/version_checker_info.g.dart';

@freezed
class VersionCheckerInfo with _$VersionCheckerInfo {
  const VersionCheckerInfo._();

  // TODO Warning: case sensitive because that's how json_serializable works.
  const factory VersionCheckerInfo({
    String? modName,
    String? masterVersionFile,
    @JsonConverterToString() String? modNexusId,
    @JsonConverterToString() String? modThreadId,
    VersionObject? modVersion,
    String? directDownloadURL,
    String? changelogURL,
  }) = _VersionCheckerInfo;

  factory VersionCheckerInfo.fromJson(Map<String, dynamic> json) =>
      _$VersionCheckerInfoFromJson(json);

  /// Whether there's a valid direct download url.
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

// data class VersionCheckerInfo(
//     @SerializedName("masterVersionFile") val masterVersionFile: String?,
//     @SerializedName("modNexusId") val modNexusId: String?,
//     @SerializedName("modThreadId") val modThreadId: String?,
//     @SerializedName("modVersion") val modVersion: Version?,
//     @SerializedName("directDownloadURL") val directDownloadUrl: String?,
//     @SerializedName("changelogURL") val changelogUrl: String?,
// ) {
//     data class Version(
//         @SerializedName("major") val major: String?,
//         @SerializedName("minor") val minor: String?,
//         @SerializedName("patch") val patch: String?
//     ) : Comparable<Version> {
//         override fun toString() = listOfNotNull(major, minor, patch).joinToString(separator = ".")
//
//         override operator fun compareTo(other: Version): Int {
//             (this.major ?: "0").compareRecognizingNumbers(other.major ?: "0").run { if (this != 0) return this }
//
//             (this.minor ?: "0").compareRecognizingNumbers(other.minor ?: "0").run { if (this != 0) return this }
//
//             (this.patch ?: "0").compareRecognizingNumbers(other.patch ?: "0").run { if (this != 0) return this }
//             return 0
//         }
//     }
// }
