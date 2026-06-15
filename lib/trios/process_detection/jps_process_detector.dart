import 'dart:io';

import 'package:trios/models/result.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/utils/util.dart';

import 'process_detector.dart';

/// Detects Starsector by spawning `java -jar JpsAtHome.jar` using the
/// JVM Attach API. Requires a JDK on the host machine.
///
/// Cross-platform, but heavyweight (spawns a JVM each poll).
class JpsProcessDetector extends ProcessDetector {
  final String javaExecutablePath;

  JpsProcessDetector(this.javaExecutablePath);

  @override
  String get name => 'JPS';

  @override
  Future<Result?> isStarsectorRunning(List<String> executableNames) async {
    final jpsAtHomePath = getAssetsPath().toFile().resolve(
      "common/JpsAtHome.jar",
    );
    final process = await Process.start(javaExecutablePath, [
      '-jar',
      jpsAtHomePath.path,
    ]);

    final outputBuffer = StringBuffer();
    process.stdout.transform(systemEncoding.decoder).listen(outputBuffer.write);
    process.stderr.transform(systemEncoding.decoder).listen(outputBuffer.write);

    final exitCodeFuture = process.exitCode;
    const jpsRunMaxDuration = Duration(milliseconds: 750);
    final result = await Future.any<int>([
      exitCodeFuture,
      Future.delayed(jpsRunMaxDuration, () => -1),
    ]);

    if (result == -1) {
      process.kill(ProcessSignal.sigkill);
      Fimber.w(
        "Killed java process after $jpsRunMaxDuration because it has a result of -1.",
      );
    } else {
      final output = outputBuffer.toString().toLowerCase();
      Fimber.v(() => "JPS output: $output");
      if (output.contains("com.fs.starfarer.starfarerlauncher")) {
        return Result.unmitigatedSuccess();
      }
    }

    return null;
  }
}
