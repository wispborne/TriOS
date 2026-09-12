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
  /// The file extension TriOS claims, and the Windows program id and Linux
  /// names that go with it. Written by register and read back by the checks,
  /// so they stay in step.
  static const _modpackExtension = '.trios-modpack';
  static const _windowsProgramId = 'TriOS.Modpack';
  static const _linuxDesktopFile = 'trios-starsector-mod.desktop';
  static const _linuxMimeType = 'application/x-trios-modpack';

  static String get _classesRoot => r'HKCU\Software\Classes';
  static String get _extensionKey => '$_classesRoot\\$_modpackExtension';
  static String get _programIdKey => '$_classesRoot\\$_windowsProgramId';
  static String get _schemeKey => '$_classesRoot\\$deepLinkScheme';
  static String get _linuxShare =>
      '${Platform.environment['HOME']}/.local/share';
  static String get _linuxMimeDir => '$_linuxShare/mime';
  static String get _linuxApplicationsDir => '$_linuxShare/applications';
  static String get _linuxMimeFilePath =>
      '$_linuxMimeDir/packages/trios-modpack.xml';
  static String get _linuxDesktopFilePath =>
      '$_linuxApplicationsDir/$_linuxDesktopFile';

  /// Writes one registry value. Pass [name] for a named value, or leave it out
  /// for the key's default value.
  static Future<void> _regAdd(String key, String data, {String? name}) =>
      Process.run('reg', [
        'add',
        key,
        if (name == null) '/ve' else ...['/v', name],
        '/d',
        data,
        '/f',
      ]);

  /// Adds file handling for installations that enabled links before modpacks
  /// existed. Leave an existing file association alone.
  static Future<void> ensureModpackFileRegistration() async {
    if (Platform.isWindows) {
      final result = await Process.run('reg', ['query', _extensionKey]);
      if (result.exitCode != 0) await register();
    } else if (Platform.isLinux) {
      if (!await File(_linuxMimeFilePath).exists()) await register();
    }
  }

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
    final command = '"${Platform.resolvedExecutable}" "%1"';

    // reg.exe is used instead of importing win32_registry, so this file has no
    // platform-specific imports.
    await _regAdd(_schemeKey, 'URL:Starsector Mod Protocol');
    await _regAdd(_schemeKey, '', name: 'URL Protocol');
    await _regAdd('$_schemeKey\\shell\\open\\command', command);
    await _regAdd(_extensionKey, _windowsProgramId);
    await _regAdd(_programIdKey, 'TriOS Modpack');
    await _regAdd('$_programIdKey\\shell\\open\\command', command);
  }

  static Future<void> _unregisterWindows() async {
    await Process.run('reg', ['delete', _schemeKey, '/f']);
    await Process.run('reg', ['delete', _programIdKey, '/f']);
    final extension = await Process.run('reg', ['query', _extensionKey, '/ve']);
    if (extension.stdout.toString().contains(_windowsProgramId)) {
      await Process.run('reg', ['delete', _extensionKey, '/ve', '/f']);
    }
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
    final desktopEntry =
        '''[Desktop Entry]
Name=TriOS
Exec="${Platform.resolvedExecutable}" %u
Type=Application
MimeType=x-scheme-handler/$deepLinkScheme;$_linuxMimeType;
NoDisplay=true
''';

    final applicationsDir = Directory(_linuxApplicationsDir);
    if (!applicationsDir.existsSync()) {
      applicationsDir.createSync(recursive: true);
    }

    await File(_linuxDesktopFilePath).writeAsString(desktopEntry);
    final mimeFile = File(_linuxMimeFilePath);
    await mimeFile.parent.create(recursive: true);
    await mimeFile.writeAsString('''<?xml version="1.0" encoding="UTF-8"?>
<mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
  <mime-type type="$_linuxMimeType">
    <comment>TriOS Modpack</comment><glob pattern="*$_modpackExtension"/>
  </mime-type>
</mime-info>
''');
    await Process.run('update-mime-database', [_linuxMimeDir]);
    await Process.run('xdg-mime', [
      'default',
      _linuxDesktopFile,
      _linuxMimeType,
    ]);
    await Process.run('xdg-mime', [
      'default',
      _linuxDesktopFile,
      'x-scheme-handler/$deepLinkScheme',
    ]);

    // Rebuild mimeinfo.cache so the desktop entry is discoverable as a scheme
    // handler. Without this, GNOME/GIO ignores the default association above
    // and clicking a link shows "No Apps Available".
    await Process.run('update-desktop-database', [applicationsDir.path]);
  }

  static Future<void> _unregisterLinux() async {
    final desktopFile = File(_linuxDesktopFilePath);
    if (desktopFile.existsSync()) await desktopFile.delete();
    final mimeFile = File(_linuxMimeFilePath);
    if (await mimeFile.exists()) await mimeFile.delete();
    await Process.run('update-mime-database', [_linuxMimeDir]);
    // Refresh the cache so the removed handler stops being advertised.
    await Process.run('update-desktop-database', [_linuxApplicationsDir]);
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
