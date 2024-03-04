import 'package:fimber/fimber.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:http/http.dart' as http;
import 'package:trios/models/mod_info_json.dart';
import 'package:trios/utils/extensions.dart';

part '../generated/jre_manager/jre_23.freezed.dart';
part '../generated/jre_manager/jre_23.g.dart';

class Jre23 {
  static Jre23VersionChecker? getVersionCheckerInfo() {
    const versionCheckerUrl = "https://raw.githubusercontent.com/Yumeris/Mikohime_Repo/main/Java23.version";

    http.get(Uri.parse(versionCheckerUrl)).then((response) {
      if (response.statusCode == 200) {
        final parsableJson = response.body.fixJsonToMap();
        final versionChecker = Jre23VersionChecker.fromJson(parsableJson);
        Fimber.i("Jre23VersionChecker: $versionChecker");
        return versionChecker;
      }
    });
  }
}

// @jsonSerializable
// class Jre23VersionChecker {
//   String masterVersionFile;
//   String modName;
//   // @JsonProperty(converter: ToNullableStringJsonConverter())
//   int? modThreadId;
//   Version_095a modVersion;
//   String starsectorVersion;
//
//   String? windowsJDKDownload;
//   String? windowsConfigDownload;
//
//   String? linuxJDKDownload;
//   String? linuxConfigDownload;
//
//   Jre23VersionChecker(this.masterVersionFile, this.modName, this.modThreadId, this.modVersion, this.starsectorVersion,
//       this.windowsJDKDownload, this.windowsConfigDownload, this.linuxJDKDownload, this.linuxConfigDownload);
// }

@freezed
class Jre23VersionChecker with _$Jre23VersionChecker {
  factory Jre23VersionChecker({
    required final String masterVersionFile,
    required final String modName,
    final int? modThreadId,
    required final Version_095a modVersion,
    required final String starsectorVersion,
    final String? windowsJDKDownload,
    final String? windowsConfigDownload,
    final String? linuxJDKDownload,
    final String? linuxConfigDownload,
  }) = _Jre23VersionChecker;

  factory Jre23VersionChecker.fromJson(Map<String, dynamic> json) => _$Jre23VersionCheckerFromJson(json);
}
