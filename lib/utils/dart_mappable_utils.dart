import 'package:dart_mappable/dart_mappable.dart';
import 'package:trios/models/mod_info_json.dart';
import 'package:trios/models/version.dart';

class VersionMappingHook extends MappingHook {
  const VersionMappingHook();

  @override
  dynamic beforeDecode(dynamic value) {
    if (value is Map<String, dynamic>) {
      return Version.parse(VersionObject.fromJson(value).toString(),
          sanitizeInput: false);
    }
    return Version.parse(value, sanitizeInput: true);
  }

  @override
  dynamic beforeEncode(dynamic value) {
    if (value is VersionObject) {
      return "${value.major}.${value.minor}.${value.patch}";
    } else {
      return value.toString();
    }
  }
}

class NullableVersionMappingHook extends MappingHook {
  const NullableVersionMappingHook();

  @override
  dynamic beforeDecode(dynamic value) {
    if (value == null) return null;
    return const VersionMappingHook().beforeDecode(value);
  }

  @override
  dynamic beforeEncode(dynamic value) {
    if (value == null) return null;
    return const VersionMappingHook().beforeEncode(value);
  }
}

class StringMappingHook extends MappingHook {
  const StringMappingHook();

  @override
  dynamic beforeDecode(dynamic value) {
    return value.toString();
  }

  @override
  dynamic beforeEncode(dynamic value) {
    return value;
  }
}

class BoolMappingHook extends MappingHook {
  const BoolMappingHook();

  @override
  dynamic beforeDecode(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) {
      return bool.tryParse(value, caseSensitive: false) ?? false;
    }
    return false;
  }

  @override
  dynamic beforeEncode(dynamic value) {
    return value.toString();
  }
}
