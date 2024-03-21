import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:trios/models/mod_info_json.dart';
import 'package:trios/models/version.dart';
import 'package:trios/utils/util.dart';

part '../generated/models/version_checker_info.freezed.dart';
part '../generated/models/version_checker_info.g.dart';

@freezed
class VersionCheckerInfo with _$VersionCheckerInfo {
  const VersionCheckerInfo._();

  const factory VersionCheckerInfo({
    String? masterVersionFile,
    @JsonConverterToString() String? modNexusId,
    @JsonConverterToString() String? modThreadId,
    VersionObject? modVersion,
    String? directDownloadURL,
    String? changelogUrl,
  }) = _VersionCheckerInfo;

  factory VersionCheckerInfo.fromJson(Map<String, dynamic> json) => _$VersionCheckerInfoFromJson(json);
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
