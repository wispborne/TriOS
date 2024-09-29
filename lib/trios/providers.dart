import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/utils/http_client.dart';

final triOSHttpClient = Provider<TriOSHttpClient>(
    (ref) => TriOSHttpClient(config: ApiClientConfig()));
