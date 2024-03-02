import 'dart:io';

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
