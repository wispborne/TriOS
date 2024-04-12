import 'dart:io';

import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:trios/utils/logging.dart';
import 'package:flutter/material.dart';
import 'package:trios/utils/extensions.dart';
import 'package:windows_system_info/windows_system_info.dart';

abstract class GPUInfo {
  abstract double freeVRAM;
  abstract List<String>? gpuString;
}

GPUInfo? getGPUInfo() {
  if (Platform.isWindows) {
    var gpu = WindowsSystemInfo.graphics?.controllers
        .maxByOrNull<num>((controller) => controller.vram);
    if (gpu != null) {
      return WindowsGPUInfo(gpu);
    }
  } else if (Platform.isMacOS) {
    try {
      return MacOSGPUInfo();
    } catch (e) {
      Fimber.w(e.toString());
      return null;
    }
  }

  return null;
}

class WindowsGPUInfo implements GPUInfo {
  @override
  late double freeVRAM;
  @override
  late List<String>? gpuString;
  Controller controller;

  WindowsGPUInfo(this.controller) {
    freeVRAM = controller.vram;
    gpuString = [controller.model];
  }

  @override
  String toString() {
    return "GPUInfo(freeVRAM: $freeVRAM, gpuString: $gpuString)";
  }
}

class MacOSGPUInfo implements GPUInfo {
  @override
  late double freeVRAM;

  @override
  late List<String>? gpuString;

  MacOSGPUInfo() {
    const memoryCmd = "sysctl";

    final process = Process.runSync(memoryCmd, ['-a'], runInShell: true);
    var result = process.stdout.toString();
    if (process.exitCode != 0) {
      throw Exception(
          "'$memoryCmd' failed with code ${process.exitCode}\n${process.stderr}");
    }

    result = result
        .split("\n")
        .firstWhere((it) => it.containsIgnoreCase("hw.memsize_usable"));

    gpuString = [];
    freeVRAM = result.split(":")[1].trim().toDouble();
  }
}
