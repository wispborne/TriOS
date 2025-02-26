import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/http_client.dart';

final triOSHttpClient = Provider<TriOSHttpClient>(
  (ref) => TriOSHttpClient(
    config: ApiClientConfig(),
    maxConcurrentRequests: ref.watch(
      appSettings.select((s) => s.maxHttpRequestsAtOnce),
    ),
  ),
);
