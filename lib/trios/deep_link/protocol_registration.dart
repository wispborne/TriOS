import 'dart:io';

import 'package:trios/trios/deep_link/deep_link_parser.dart';
import 'package:trios/utils/logging.dart';

/// Registers or unregisters the `starsector-mod://` protocol handler
/// on the current platform.
///
/// - **Windows**: Writes/removes registry keys under HKCU\Software\Classes.
/// - **macOS**: Handled via Info.plist at build time (always registered).
/// - **Linux**: Copies/removes a .desktop file and runs xdg-mime.
class ProtocolRegistration {
  /// Registers the protocol handler on the current platform.
  static Future<void> register() async {
    try {
      if (Platform.isWindows) {
        await _registerWindows();
      } else if (Platform.isLinux) {
        await _registerLinux();
      }
      // macOS: registration is via Info.plist, no runtime action needed.
      Fimber.i('Protocol handler registered for $deepLinkScheme://');
    } catch (e) {
      Fimber.e('Failed to register protocol handler', ex: e);
    }
  }

  /// Unregisters the protocol handler on the current platform.
  static Future<void> unregister() async {
    try {
      if (Platform.isWindows) {
        await _unregisterWindows();
      } else if (Platform.isLinux) {
        await _unregisterLinux();
      }
      Fimber.i('Protocol handler unregistered for $deepLinkScheme://');
    } catch (e) {
      Fimber.e('Failed to unregister protocol handler', ex: e);
    }
  }

  /// Checks if the protocol handler is currently registered.
  static Future<bool> isRegistered() async {
    try {
      if (Platform.isWindows) {
        return _isRegisteredWindows();
      } else if (Platform.isMacOS) {
        // Always registered via Info.plist.
        return true;
      } else if (Platform.isLinux) {
        return _isRegisteredLinux();
      }
    } catch (e) {
      Fimber.w('Error checking protocol registration', ex: e);
    }
    return false;
  }

  // ── Windows ──────────────────────────────────────────────────────────

  static Future<void> _registerWindows() async {
    // Import win32_registry only on Windows.
    final exePath = Platform.resolvedExecutable;
    final command = '"$exePath" "%1"';

    // Use reg.exe to write keys — avoids needing to import win32_registry
    // directly here (keeps this file platform-agnostic at the import level).
    final regPath = r'HKCU\Software\Classes\' + deepLinkScheme;

    await Process.run('reg', [
      'add',
      regPath,
      '/ve',
      '/d',
      'URL:Starsector Mod Protocol',
      '/f',
    ]);

    await Process.run('reg', [
      'add',
      regPath,
      '/v',
      'URL Protocol',
      '/d',
      '',
      '/f',
    ]);

    await Process.run('reg', [
      'add',
      '$regPath\\shell\\open\\command',
      '/ve',
      '/d',
      command,
      '/f',
    ]);
  }

  static Future<void> _unregisterWindows() async {
    final regPath = r'HKCU\Software\Classes\' + deepLinkScheme;
    await Process.run('reg', ['delete', regPath, '/f']);
  }

  static bool _isRegisteredWindows() {
    try {
      final result = Process.runSync('reg', [
        'query',
        r'HKCU\Software\Classes\' + deepLinkScheme,
        '/ve',
      ]);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  // ── Linux ────────────────────────────────────────────────────────────

  static Future<void> _registerLinux() async {
    final desktopEntry = '''[Desktop Entry]
Name=TriOS
Exec=${Platform.resolvedExecutable} %u
Type=Application
MimeType=x-scheme-handler/$deepLinkScheme;
NoDisplay=true
''';

    final applicationsDir = Directory(
      '${Platform.environment['HOME']}/.local/share/applications',
    );
    if (!applicationsDir.existsSync()) {
      applicationsDir.createSync(recursive: true);
    }

    final desktopFile = File(
      '${applicationsDir.path}/trios-starsector-mod.desktop',
    );
    await desktopFile.writeAsString(desktopEntry);

    await Process.run('xdg-mime', [
      'default',
      'trios-starsector-mod.desktop',
      'x-scheme-handler/$deepLinkScheme',
    ]);
  }

  static Future<void> _unregisterLinux() async {
    final desktopFile = File(
      '${Platform.environment['HOME']}/.local/share/applications/trios-starsector-mod.desktop',
    );
    if (desktopFile.existsSync()) {
      await desktopFile.delete();
    }
  }

  static bool _isRegisteredLinux() {
    try {
      final result = Process.runSync('xdg-mime', [
        'query',
        'default',
        'x-scheme-handler/$deepLinkScheme',
      ]);
      final output = result.stdout.toString().trim();
      return output.contains('trios');
    } catch (_) {
      return false;
    }
  }
}
