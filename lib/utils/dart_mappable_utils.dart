import 'dart:io';

import 'package:dart_mappable/dart_mappable.dart';

import '../models/version.dart';

class VersionHook extends MappingHook {
  const VersionHook();

  @override
  dynamic beforeDecode(dynamic value) {
    if (value == null) return null;
    try {
      if (value is Map<String, dynamic>) {
        // Handle decoding from map representation
        return VersionMapper.fromMap(value);
      }
      // Handle decoding from string
      return Version.parse(value.toString(), sanitizeInput: true);
    } catch (_) {
      return null; // Graceful fallback on error
    }
  }

  @override
  dynamic beforeEncode(dynamic value) {
    return value is Version ? value.toString() : value;
  }
}

class NullableHook<T> extends MappingHook {
  final MappingHook hook;

  const NullableHook(this.hook);

  @override
  dynamic beforeDecode(dynamic value) {
    return value == null ? null : hook.beforeDecode(value);
  }

  @override
  dynamic beforeEncode(dynamic value) {
    return value == null ? null : hook.beforeEncode(value);
  }
}

class BoolHook extends MappingHook {
  const BoolHook();

  @override
  bool beforeDecode(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) {
      final lower = value.toLowerCase();
      return lower == 'true'
          ? true
          : lower == 'false'
              ? false
              : false;
    }
    return false;
  }

  @override
  dynamic beforeEncode(dynamic value) {
    return value is bool ? value.toString() : value;
  }
}

class ToStringHook extends MappingHook {
  const ToStringHook();

  @override
  dynamic beforeDecode(dynamic value) => value?.toString();

  @override
  dynamic beforeEncode(dynamic value) => value;
}

class DirectoryHook extends MappingHook {
  const DirectoryHook();

  @override
  Directory? beforeDecode(dynamic value) {
    return value is String ? Directory(value) : null;
  }

  @override
  String? beforeEncode(dynamic value) {
    return value is Directory ? value.path : null;
  }
}

class SafeDecodeHook<T> extends MappingHook {
  final T? defaultValue;

  const SafeDecodeHook({this.defaultValue});

  @override
  dynamic beforeDecode(dynamic value) {
    try {
      return value;
    } catch (_) {
      return defaultValue;
    }
  }
}
