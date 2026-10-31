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

  /// Re-registers the handler if it is missing or points at a different
  /// TriOS executable, e.g. after the user moved the TriOS folder.
  static Future<void> ensureRegistered() async {
    if (await isRegistered()) return;
    Fimber.i('Protocol handler missing or points elsewhere, re-registering.');
    await register();
  }

  /// Checks if the protocol handler is registered and points at this
  /// TriOS executable.
  static Future<bool> isRegistered() async {
    try {
      if (Platform.isWindows) {
        return await _isRegisteredWindows();
      } else if (Platform.isMacOS) {
        // Always registered via Info.plist.
        return true;
      } else if (Platform.isLinux) {
        return await _isRegisteredLinux();
      }
    } catch (e) {
      Fimber.w('Error checking protocol registration', ex: e);
    }
    return false;
  }

  // ── Windows ──────────────────────────────────────────────────────────

  static String get _windowsCommand => '"${Platform.resolvedExecutable}" "%1"';

  static Future<void> _registerWindows() async {
    final command = _windowsCommand;

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

  static Future<bool> _isRegisteredWindows() async {
    try {
      final result = await Process.run('reg', [
        'query',
        r'HKCU\Software\Classes\' + deepLinkScheme + r'\shell\open\command',
        '/ve',
      ]);
      if (result.exitCode != 0) return false;
      // Windows paths are case-insensitive.
      return result.stdout.toString().toLowerCase().contains(
        _windowsCommand.toLowerCase(),
      );
    } catch (_) {
      return false;
    }
  }

  // ── Linux ────────────────────────────────────────────────────────────

  static String get _linuxDesktopEntry => '''[Desktop Entry]
Name=TriOS
Exec="${Platform.resolvedExecutable}" %u
Type=Application
MimeType=x-scheme-handler/$deepLinkScheme;
NoDisplay=true
''';

  static File get _linuxDesktopFile => File(
    '${Platform.environment['HOME']}/.local/share/applications/trios-starsector-mod.desktop',
  );

  static Future<void> _registerLinux() async {
    final applicationsDir = _linuxDesktopFile.parent;
    if (!applicationsDir.existsSync()) {
      applicationsDir.createSync(recursive: true);
    }

    await _linuxDesktopFile.writeAsString(_linuxDesktopEntry);

    await Process.run('xdg-mime', [
      'default',
      'trios-starsector-mod.desktop',
      'x-scheme-handler/$deepLinkScheme',
    ]);

    // Rebuild mimeinfo.cache so the desktop entry is discoverable as a scheme
    // handler. Without this, GNOME/GIO ignores the default association above
    // and clicking a link shows "No Apps Available".
    await Process.run('update-desktop-database', [applicationsDir.path]);
  }

  static Future<void> _unregisterLinux() async {
    final applicationsDir =
        '${Platform.environment['HOME']}/.local/share/applications';
    final desktopFile = File('$applicationsDir/trios-starsector-mod.desktop');
    if (desktopFile.existsSync()) {
      await desktopFile.delete();
    }
    // Refresh the cache so the removed handler stops being advertised.
    await Process.run('update-desktop-database', [applicationsDir]);
  }

  static Future<bool> _isRegisteredLinux() async {
    try {
      final result = await Process.run('xdg-mime', [
        'query',
        'default',
        'x-scheme-handler/$deepLinkScheme',
      ]);
      final output = result.stdout.toString().trim();
      if (!output.contains('trios')) return false;
      final desktopFile = _linuxDesktopFile;
      return await desktopFile.exists() &&
          await desktopFile.readAsString() == _linuxDesktopEntry;
    } catch (_) {
      return false;
    }
  }
}
