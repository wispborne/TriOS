import 'dart:io';

import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:trios/utils/logging.dart';

/// Total GPU VRAM in bytes (`freeVRAM`), or null when it can't be reliably
/// determined. `freeVRAM` keeps its historical (misleading) name; it has always
/// held the *total* VRAM, in bytes.
abstract class GPUInfo {
  abstract double? freeVRAM;
  abstract List<String>? gpuString;
}

Future<GPUInfo?> getGPUInfo() async {
  if (Platform.isWindows) {
    return _getWindowsGPUInfo();
  } else if (Platform.isLinux) {
    return _getLinuxGPUInfo();
  } else if (Platform.isMacOS) {
    try {
      return await _getMacOSGPUInfo();
    } catch (e) {
      Fimber.w(e.toString());
      return null;
    }
  }

  return null;
}

class _GPUInfo implements GPUInfo {
  @override
  double? freeVRAM;
  @override
  List<String>? gpuString;

  _GPUInfo(this.freeVRAM, this.gpuString);

  @override
  String toString() => "GPUInfo(freeVRAM: $freeVRAM, gpuString: $gpuString)";
}

/// Reads total VRAM from the display-adapter registry key, using the 64-bit
/// `HardwareInformation.qwMemorySize` value (not WMI `AdapterRAM`, which caps at
/// ~4 GiB). Picks the adapter with the most VRAM.
Future<GPUInfo?> _getWindowsGPUInfo() async {
  const classKey =
      r'HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}';
  try {
    // List the immediate adapter subkeys (0000, 0001, ...) without recursing.
    // Recursing (/s) into this key walks the entire driver-settings subtree
    // (NVIDIA in particular stores a huge amount here), which takes tens of
    // seconds. Each adapter's DriverDesc and qwMemorySize are direct values on
    // its own subkey, so a per-adapter non-recursive query is far cheaper.
    final listResult = await Process.run('reg', ['query', classKey]);
    if (listResult.exitCode != 0) {
      Fimber.w('reg query for GPU adapters failed (exit ${listResult.exitCode})');
      return null;
    }

    final adapterKeys = listResult.stdout
        .toString()
        .split('\n')
        .map((line) => line.trim())
        .where((line) => RegExp(r'\\\d{4}$').hasMatch(line));

    int bestBytes = -1;
    String? bestName;
    for (final adapterKey in adapterKeys) {
      final values = await Process.run('reg', ['query', adapterKey]);
      if (values.exitCode != 0) continue;

      String? name;
      int? bytes;
      for (final line in values.stdout.toString().split('\n')) {
        final trimmed = line.trim();
        if (trimmed.contains('DriverDesc') && trimmed.contains('REG_SZ')) {
          final idx = trimmed.indexOf('REG_SZ');
          name = trimmed.substring(idx + 'REG_SZ'.length).trim();
        } else if (trimmed.contains('HardwareInformation.qwMemorySize') &&
            trimmed.contains('REG_QWORD')) {
          final hex = trimmed.split(RegExp(r'\s+')).last;
          bytes = int.tryParse(hex.replaceFirst('0x', ''), radix: 16);
        }
      }

      if (bytes != null && bytes > bestBytes) {
        bestBytes = bytes;
        bestName = name;
      }
    }

    if (bestBytes <= 0) return null;
    return _GPUInfo(bestBytes.toDouble(), bestName == null ? null : [bestName]);
  } catch (e) {
    Fimber.w('Failed to read Windows GPU VRAM: $e');
    return null;
  }
}

/// Reads total VRAM from amdgpu sysfs (`mem_info_vram_total`) for AMD GPUs and
/// from `nvidia-smi` for NVIDIA GPUs. Picks the GPU with the most VRAM. Returns
/// null when neither source yields a value (e.g. Intel integrated graphics).
Future<GPUInfo?> _getLinuxGPUInfo() async {
  int? bestBytes;

  // AMD: amdgpu kernel driver exposes total VRAM in bytes via sysfs.
  try {
    final drmDir = Directory('/sys/class/drm');
    if (drmDir.existsSync()) {
      for (final entry in drmDir.listSync()) {
        final name = entry.path.split('/').last;
        // Match real GPU devices (card0, card1), not connectors
        // (card0-HDMI-A-1) or render nodes (renderD128).
        if (!RegExp(r'^card\d+$').hasMatch(name)) continue;
        final file = File('${entry.path}/device/mem_info_vram_total');
        if (file.existsSync()) {
          final bytes = int.tryParse((await file.readAsString()).trim());
          if (bytes != null && (bestBytes == null || bytes > bestBytes)) {
            bestBytes = bytes;
          }
        }
      }
    }
  } catch (e) {
    Fimber.w('Failed to read AMD VRAM from sysfs: $e');
  }

  // NVIDIA: nvidia-smi reports total VRAM in MiB.
  try {
    final result = await Process.run('nvidia-smi', [
      '--query-gpu=memory.total',
      '--format=csv,noheader,nounits',
    ]);
    if (result.exitCode == 0) {
      for (final line in result.stdout.toString().split('\n')) {
        final mib = int.tryParse(line.trim());
        if (mib != null) {
          final bytes = mib * 1024 * 1024;
          if (bestBytes == null || bytes > bestBytes) bestBytes = bytes;
        }
      }
    }
  } catch (e) {
    // nvidia-smi not installed; expected on non-NVIDIA systems.
  }

  if (bestBytes == null) return null;
  return _GPUInfo(bestBytes.toDouble(), null);
}

Future<GPUInfo?> _getMacOSGPUInfo() async {
  const memoryCmd = "sysctl";

  final process = await Process.run(memoryCmd, ['-a'], runInShell: true);
  if (process.exitCode != 0) {
    throw Exception(
      "'$memoryCmd' failed with code ${process.exitCode}\n${process.stderr}",
    );
  }

  final line = process.stdout
      .toString()
      .split("\n")
      .firstWhere((it) => it.containsIgnoreCase("hw.memsize_usable"));

  return _GPUInfo(line.split(":")[1].trim().toDouble(), []);
}
