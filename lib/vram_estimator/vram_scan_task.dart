import 'dart:async';

import 'package:async_task/async_task.dart';
import 'package:trios/vram_estimator/vram_check_scan_params.dart';
import 'package:trios/vram_estimator/vram_scan_one_mod.dart';

/// AsyncTask wrapper around [scanOneMod]. Parameters and result both
/// cross the isolate boundary as Maps; the inner function is unchanged
/// from the single-isolate path.
class VramScanTask extends AsyncTask<Map<String, dynamic>, Map<String, dynamic>> {
  final Map<String, dynamic> _paramsMap;

  VramScanTask(this._paramsMap);

  @override
  AsyncTask<Map<String, dynamic>, Map<String, dynamic>> instantiate(
    Map<String, dynamic> parameters, [
    Map<String, SharedData>? sharedData,
  ]) => VramScanTask(parameters);

  @override
  Map<String, dynamic> parameters() => _paramsMap;

  @override
  AsyncTaskChannel? channelInstantiator() => AsyncTaskChannel();

  @override
  FutureOr<Map<String, dynamic>> run() async {
    final channel = channelResolved();
    final params = VramCheckScanParams.fromTransfer(_paramsMap);
    final outcome = await scanOneMod(params, channel: channel);
    return outcome.toTransfer();
  }
}

/// Top-level function used by [AsyncExecutor.taskTypeRegister] to discover
/// the registered task types.
List<AsyncTask> vramScanTaskRegister() => [VramScanTask(const {})];
