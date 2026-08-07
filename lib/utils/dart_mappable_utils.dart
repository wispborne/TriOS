import 'dart:io';
import 'dart:ui';

import 'package:dart_mappable/dart_mappable.dart';

import '../models/version.dart';

class VersionHook extends MappingHook {
  const VersionHook();

  @override
  Version? beforeDecode(dynamic value) {
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

class FileHook extends MappingHook {
  const FileHook();

  @override
  File? beforeDecode(dynamic value) {
    return value is String ? File(value) : null;
  }

  @override
  String? beforeEncode(dynamic value) {
    return value is File ? value.path : null;
  }
}

/// Drops the field's value on encode and always decodes to null. Used for
/// `@MappableField(mode: FieldMode.member)` fields that should be excluded
/// from serialization (e.g. back-references to `ModVariant` that are
/// reattached by the cache layer after decode).
class SkipSerializationHook extends MappingHook {
  const SkipSerializationHook();

  @override
  dynamic beforeEncode(dynamic value) => null;

  @override
  dynamic beforeDecode(dynamic value) => null;
}

class SafeDoubleHook extends MappingHook {
  const SafeDoubleHook();

  @override
  dynamic beforeDecode(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    final parsed = double.tryParse(value.toString());
    return parsed; // Returns null for non-numeric strings like "jaaf1".
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

class ColorHook extends MappingHook {
  const ColorHook();

  @override
  dynamic beforeDecode(dynamic value) {
    if (value == null) return null;
    if (value is int) return Color(value);
    if (value is String) return Color(int.parse(value));
    return null;
  }

  @override
  dynamic beforeEncode(dynamic value) {
    if (value is Color) return value.toARGB32();
    return null;
  }
}

/// Json: "one,tag, three"
/// Dart: ["one", "tag", "three"]
class StringArrayHook extends MappingHook {
  const StringArrayHook();

  @override
  List<String>? beforeDecode(dynamic value) {
    if (value is String) {
      return value.split(',').map((e) => e.trim()).toList();
    }
    return null;
  }

  @override
  dynamic beforeEncode(dynamic value) {
    if (value is List<String>) {
      return value.join(',');
    }
    return value;
  }
}

/// A data map with its unusable numbers blanked out, plus one message per
/// blanked field saying what was there instead.
typedef CleanedNumbers = ({
  Map<String, dynamic> data,
  Map<String, String> errors,
});

/// Blanks out values that should have been numbers but aren't, and explains
/// each one.
///
/// The game does the same thing quietly. It reads every number in
/// `weapon_data.csv` and `ship_data.csv` with `optDouble`/`optInt`, which fall
/// back to a default when the cell holds something like `DS` or `0.0.05`.
/// dart_mappable throws instead, which would drop a whole weapon or ship over
/// one bad cell. This keeps the item and leaves the one stat blank.
///
/// Which fields are numbers comes from [mapper], so this can't drift from the
/// model. Keys in [data] must already be in the mapper's own key style.
/// The returned errors are keyed by Dart field name, so UI can look up the
/// stat it is about to draw; the message names the column as the file writes
/// it.
CleanedNumbers blankUnusableNumbers<T extends Object>(
  ClassMapperBase<T> mapper,
  Map<String, dynamic> data,
) {
  Map<String, dynamic>? cleaned;
  Map<String, String>? errors;

  for (final field in mapper.fields.values) {
    if (field is! Field<T, double> && field is! Field<T, int>) continue;

    final value = data[field.key];
    if (value == null || value is num) continue;
    if (num.tryParse(value.toString()) != null) continue;

    cleaned ??= {...data};
    errors ??= {};
    cleaned[field.key] = null;
    errors[field.name] = '"${field.key}" is "$value", which is not a number.';
  }

  return (data: cleaned ?? data, errors: errors ?? const {});
}
