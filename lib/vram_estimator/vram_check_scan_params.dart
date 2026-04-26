import 'package:trios/vram_estimator/models/graphics_lib_config.dart';
import 'package:trios/vram_estimator/models/vram_checker_models.dart';
import 'package:trios/vram_estimator/selectors/referenced_assets_selector_config.dart';
import 'package:trios/vram_estimator/selectors/vram_selector_id.dart';

/// Serializable parameter object for [scanOneMod].
///
/// All fields cross an isolate boundary in the multithreaded path, so they
/// must be primitives, dart_mappable types, or other reliably-copyable
/// values. The selector is reconstructed inside the worker via
/// `VramAssetSelector.fromId(selectorId, selectorConfig)`; the config
/// object itself must be either a `Map<String, dynamic>` (a `.toMap()`
/// payload) or a `ReferencedAssetsSelectorConfig` instance.
class VramCheckScanParams {
  final VramCheckerMod modInfo;
  final List<String> enabledModIds;
  final VramSelectorId selectorId;
  final Object? selectorConfig;
  final GraphicsLibConfig graphicsLibConfig;
  final bool showGfxLibDebugOutput;
  final bool showPerformance;
  final bool showSkippedFiles;
  final bool showCountedFiles;
  final int maxFileHandles;

  const VramCheckScanParams({
    required this.modInfo,
    required this.enabledModIds,
    required this.selectorId,
    required this.selectorConfig,
    required this.graphicsLibConfig,
    required this.showGfxLibDebugOutput,
    required this.showPerformance,
    required this.showSkippedFiles,
    required this.showCountedFiles,
    required this.maxFileHandles,
  });

  /// Serialize for transmission across an isolate boundary. Object types
  /// either round-trip through dart_mappable (`.toMap()`) or are reduced
  /// to primitives. The selector config is normalized to a Map when it's
  /// a `ReferencedAssetsSelectorConfig`; null and primitive configs
  /// pass through unchanged.
  Map<String, dynamic> toTransfer() {
    Object? configForTransfer;
    final cfg = selectorConfig;
    if (cfg is ReferencedAssetsSelectorConfig) {
      configForTransfer = cfg.toMap();
    } else {
      configForTransfer = cfg;
    }
    return <String, dynamic>{
      'modInfo': modInfo.toMap(),
      'enabledModIds': List<String>.from(enabledModIds),
      'selectorId': selectorId.wireValue,
      'selectorConfig': configForTransfer,
      'graphicsLibConfig': graphicsLibConfig.toMap(),
      'showGfxLibDebugOutput': showGfxLibDebugOutput,
      'showPerformance': showPerformance,
      'showSkippedFiles': showSkippedFiles,
      'showCountedFiles': showCountedFiles,
      'maxFileHandles': maxFileHandles,
    };
  }

  /// Inverse of [toTransfer].
  factory VramCheckScanParams.fromTransfer(Map<String, dynamic> map) {
    return VramCheckScanParams(
      modInfo: VramCheckerModMapper.fromMap(
        Map<String, dynamic>.from(map['modInfo'] as Map),
      ),
      enabledModIds: List<String>.from(map['enabledModIds'] as List),
      selectorId: VramSelectorId.fromWire(map['selectorId'] as String),
      selectorConfig: map['selectorConfig'],
      graphicsLibConfig: GraphicsLibConfigMapper.fromMap(
        Map<String, dynamic>.from(map['graphicsLibConfig'] as Map),
      ),
      showGfxLibDebugOutput: map['showGfxLibDebugOutput'] as bool,
      showPerformance: map['showPerformance'] as bool,
      showSkippedFiles: map['showSkippedFiles'] as bool,
      showCountedFiles: map['showCountedFiles'] as bool,
      maxFileHandles: map['maxFileHandles'] as int,
    );
  }
}

/// Result of one mod's scan. Either [mod] is non-null (success) or
/// [errorMessage]/[errorStack] are non-null (failure). The captured
/// per-mod [logBuffer] is replayed by the dispatcher into the
/// `verboseOut`/`debugOut` callbacks after the task settles, preserving
/// per-mod-atomic log ordering even when several mods scan in parallel.
class VramScanOutcome {
  final VramMod? mod;
  final String? errorMessage;
  final String? errorStack;
  final String logBuffer;

  /// True when a worker observed cancellation. Cancelled outcomes are
  /// dropped from the final mod list rather than logged as errors.
  final bool cancelled;

  const VramScanOutcome._({
    this.mod,
    this.errorMessage,
    this.errorStack,
    required this.logBuffer,
    this.cancelled = false,
  });

  factory VramScanOutcome.success({
    required VramMod mod,
    required String logBuffer,
  }) => VramScanOutcome._(mod: mod, logBuffer: logBuffer);

  factory VramScanOutcome.failed({
    required String message,
    required String stack,
    required String logBuffer,
  }) => VramScanOutcome._(
    errorMessage: message,
    errorStack: stack,
    logBuffer: logBuffer,
  );

  factory VramScanOutcome.cancelled({required String logBuffer}) =>
      VramScanOutcome._(logBuffer: logBuffer, cancelled: true);

  bool get isSuccess => mod != null;
  bool get isFailure => errorMessage != null;

  /// Serialize for transmission across an isolate boundary.
  Map<String, dynamic> toTransfer() => <String, dynamic>{
    if (mod != null) 'mod': mod!.toMap(),
    if (errorMessage != null) 'errorMessage': errorMessage,
    if (errorStack != null) 'errorStack': errorStack,
    'logBuffer': logBuffer,
    'cancelled': cancelled,
  };

  /// Inverse of [toTransfer]. Returns the appropriate variant.
  factory VramScanOutcome.fromTransfer(Map<String, dynamic> map) {
    final cancelled = (map['cancelled'] as bool?) ?? false;
    final logBuffer = (map['logBuffer'] as String?) ?? '';
    if (cancelled) return VramScanOutcome.cancelled(logBuffer: logBuffer);
    final modMap = map['mod'];
    if (modMap is Map) {
      return VramScanOutcome.success(
        mod: VramModMapper.fromMap(Map<String, dynamic>.from(modMap)),
        logBuffer: logBuffer,
      );
    }
    return VramScanOutcome.failed(
      message: (map['errorMessage'] as String?) ?? 'Unknown error',
      stack: (map['errorStack'] as String?) ?? '',
      logBuffer: logBuffer,
    );
  }
}
