import 'dart:convert';

import 'package:trios/modpacks/models/modpack_definition.dart';

/// Size and length limits for shared modpack definitions.
///
/// TriLink enforces the same numbers. Keep the two in step.
abstract final class ModpackLimits {
  /// A whole share link, including the TriLink address.
  static const int maxLinkCharacters = 30000;

  /// The JSON a compressed payload is allowed to expand to.
  static const int maxExpandedBytes = 4 * 1024 * 1024;

  static const int maxItems = 5000;

  /// The largest integer JavaScript can hold exactly, so TriLink and browsers
  /// read pack versions the same way TriOS wrote them.
  static const int maxSafeInteger = 9007199254740991;

  /// Pack IDs are 16 random bytes as unpadded base64url.
  static const int packIdLength = 22;

  static const int maxNameLength = 200;
  static const int maxAuthorLength = 200;
  static const int maxDescriptionLength = 4000;
  static const int maxGameVersionLength = 40;
  static const int maxUrlLength = 2000;
  static const int maxModIdLength = 200;
  static const int maxItemNameLength = 200;
  static const int maxItemVersionLength = 60;
  static const int maxLabelLength = 40;
  static const int maxNoteLength = 2000;
  static const int maxCatalogNameLength = 200;
  static const int maxCatalogIdLength = 40;

  /// How deeply a preserved unknown field may nest.
  static const int maxUnknownFieldDepth = 8;
}

/// Why a definition or payload was refused. The [code] strings match
/// TriLink's, so the same input fails the same way on both sides.
enum ModpackFormatError {
  missingPayload('MISSING_MODPACK'),
  malformedPayload('MALFORMED_PAYLOAD'),
  payloadTooLarge('PAYLOAD_TOO_LARGE'),
  linkTooLarge('LINK_TOO_LARGE'),
  unsupportedTransportFormat('UNSUPPORTED_FORMAT'),
  decompressionFailed('DECOMPRESSION_FAILED'),
  invalidDefinition('INVALID_DEFINITION'),
  unsupportedDefinitionFormat('UNSUPPORTED_DEFINITION_FORMAT'),
  invalidId('INVALID_ID'),
  invalidName('INVALID_NAME'),
  invalidVersion('INVALID_VERSION'),
  invalidItems('INVALID_ITEMS'),
  tooManyItems('TOO_MANY_ITEMS'),
  invalidItem('INVALID_ITEM'),
  duplicateItem('DUPLICATE_ITEM'),
  invalidField('INVALID_FIELD'),
  fieldTooLong('FIELD_TOO_LONG'),
  unsafeUrl('UNSAFE_URL'),
  invalidSourceType('INVALID_SOURCE_TYPE'),
  invalidLabel('INVALID_LABEL'),
  invalidNote('INVALID_NOTE'),
  invalidCatalog('INVALID_CATALOG'),
  invalidUnknownField('INVALID_UNKNOWN_FIELD');

  const ModpackFormatError(this.code);

  final String code;
}

/// A shared modpack definition or payload TriOS refused to read or write.
class ModpackFormatException implements Exception {
  final ModpackFormatError error;
  final String message;

  const ModpackFormatException(this.error, this.message);

  /// True when the fix is to update TriOS rather than treat the data as
  /// broken.
  bool get needsNewerTriOS =>
      error == ModpackFormatError.unsupportedDefinitionFormat ||
      error == ModpackFormatError.unsupportedTransportFormat;

  @override
  String toString() => 'ModpackFormatException(${error.code}): $message';
}

const List<String> _definitionKnownKeys = [
  'formatVersion',
  'id',
  'name',
  'version',
  'author',
  'description',
  'gameVersion',
  'homepageUrl',
  'updateUrl',
  'items',
];

const List<String> _itemKnownKeys = [
  'id',
  'name',
  'version',
  'label',
  'note',
  'url',
  'sourceType',
  'catalog',
];

const List<String> _catalogKnownKeys = ['name', 'forumTopicId', 'nexusModsId'];

/// Whether [value] contains a control character TriOS will not accept. Tab,
/// newline, and carriage return are allowed, because notes may have line
/// breaks.
bool _hasBannedControlCharacters(String value) {
  for (final code in value.codeUnits) {
    if (code == 0x09 || code == 0x0a || code == 0x0d) continue;
    if (code < 0x20 || code == 0x7f) return true;
  }
  return false;
}

final RegExp _packIdPattern = RegExp(r'^[A-Za-z0-9_-]{22}$');

bool isValidModpackId(String value) => _packIdPattern.hasMatch(value);

Never _fail(ModpackFormatError error, String message) =>
    throw ModpackFormatException(error, message);

/// Decodes a shared definition from parsed JSON.
///
/// Throws [ModpackFormatException] for anything TriOS won't edit, install, or
/// share. Unknown fields are kept so data from a newer TriOS survives a round
/// trip through this one.
ModpackDefinition decodeModpackDefinition(Object? raw) {
  if (raw is! Map) {
    _fail(
      ModpackFormatError.invalidDefinition,
      'The modpack definition is not an object.',
    );
  }
  final map = _asStringKeyedMap(
    raw,
    ModpackFormatError.invalidDefinition,
    'The modpack definition is not an object.',
  );

  final formatVersion = map['formatVersion'];
  if (formatVersion is! int) {
    _fail(
      ModpackFormatError.invalidDefinition,
      'The modpack definition has no format version.',
    );
  }
  if (formatVersion != ModpackDefinition.currentFormatVersion) {
    _fail(
      ModpackFormatError.unsupportedDefinitionFormat,
      'This modpack uses format version $formatVersion. Update TriOS to read it.',
    );
  }

  final id = map['id'];
  if (id is! String || !isValidModpackId(id)) {
    _fail(
      ModpackFormatError.invalidId,
      'The modpack ID must be ${ModpackLimits.packIdLength} '
      'base64url characters.',
    );
  }

  final name = map['name'];
  if (name is! String || name.trim().isEmpty) {
    _fail(ModpackFormatError.invalidName, 'The modpack has no name.');
  }
  _checkLength(name, ModpackLimits.maxNameLength, 'name');

  final version = _readInteger(map['version'], 'modpack version');

  final rawItems = map['items'];
  if (rawItems is! List) {
    _fail(ModpackFormatError.invalidItems, 'The modpack items are not a list.');
  }
  if (rawItems.length > ModpackLimits.maxItems) {
    _fail(
      ModpackFormatError.tooManyItems,
      'The modpack has more than ${ModpackLimits.maxItems} items.',
    );
  }

  final items = <ModpackItem>[];
  final seenModIds = <String>{};
  for (final rawItem in rawItems) {
    final item = _decodeItem(rawItem);
    if (!seenModIds.add(item.modId)) {
      _fail(
        ModpackFormatError.duplicateItem,
        'The modpack lists ${item.modId} more than once.',
      );
    }
    items.add(item);
  }

  return ModpackDefinition(
    formatVersion: formatVersion,
    id: id,
    name: name.trim(),
    version: version,
    author: _readOptionalString(
      map['author'],
      ModpackLimits.maxAuthorLength,
      'author',
    ),
    description: _readOptionalString(
      map['description'],
      ModpackLimits.maxDescriptionLength,
      'description',
    ),
    gameVersion: _readOptionalString(
      map['gameVersion'],
      ModpackLimits.maxGameVersionLength,
      'Starsector version',
    ),
    homepageUrl: _readOptionalUrl(map['homepageUrl'], 'homepage address'),
    updateUrl: _readOptionalUrl(map['updateUrl'], 'update address'),
    items: items,
    unknownFields: _collectUnknownFields(map, _definitionKnownKeys),
  );
}

ModpackItem _decodeItem(Object? raw) {
  if (raw is! Map) {
    _fail(ModpackFormatError.invalidItem, 'A modpack item is not an object.');
  }
  final map = _asStringKeyedMap(
    raw,
    ModpackFormatError.invalidItem,
    'A modpack item is not an object.',
  );

  final modId = map['id'];
  if (modId is! String || modId.trim().isEmpty) {
    _fail(ModpackFormatError.invalidItem, 'A modpack item has no mod ID.');
  }
  _checkLength(modId, ModpackLimits.maxModIdLength, 'mod ID');

  final url = map['url'];
  if (url is! String || !isSafeModpackUrl(url)) {
    _fail(
      ModpackFormatError.unsafeUrl,
      'A modpack item address must be an HTTP or HTTPS URL.',
    );
  }
  _checkLength(url, ModpackLimits.maxUrlLength, 'item address');

  final sourceType = switch (map['sourceType']) {
    'versionFile' => ModpackItemSourceType.versionFile,
    'directDownload' => ModpackItemSourceType.directDownload,
    _ => _fail(
      ModpackFormatError.invalidSourceType,
      'A modpack item has an unknown source type.',
    ),
  };

  return ModpackItem(
    modId: modId.trim(),
    url: url.trim(),
    sourceType: sourceType,
    name: _readOptionalString(
      map['name'],
      ModpackLimits.maxItemNameLength,
      'item name',
    ),
    version: _readOptionalString(
      map['version'],
      ModpackLimits.maxItemVersionLength,
      'item version',
    ),
    label: _readLabel(map['label']),
    note: _readNote(map['note']),
    catalog: _decodeCatalogClues(map['catalog']),
    unknownFields: _collectUnknownFields(map, _itemKnownKeys),
  );
}

ModpackCatalogClues? _decodeCatalogClues(Object? raw) {
  if (raw == null) return null;
  if (raw is! Map) {
    _fail(
      ModpackFormatError.invalidCatalog,
      'A modpack item has invalid catalog information.',
    );
  }
  final map = _asStringKeyedMap(
    raw,
    ModpackFormatError.invalidCatalog,
    'A modpack item has invalid catalog information.',
  );

  return ModpackCatalogClues(
    name: _readOptionalString(
      map['name'],
      ModpackLimits.maxCatalogNameLength,
      'catalog name',
      error: ModpackFormatError.invalidCatalog,
    ),
    forumTopicId: _readOptionalString(
      map['forumTopicId'],
      ModpackLimits.maxCatalogIdLength,
      'forum topic ID',
      error: ModpackFormatError.invalidCatalog,
    ),
    nexusModsId: _readOptionalString(
      map['nexusModsId'],
      ModpackLimits.maxCatalogIdLength,
      'Nexus Mods ID',
      error: ModpackFormatError.invalidCatalog,
    ),
    unknownFields: _collectUnknownFields(map, _catalogKnownKeys),
  );
}

Map<String, Object?> _asStringKeyedMap(
  Map raw,
  ModpackFormatError error,
  String message,
) {
  final result = <String, Object?>{};
  for (final entry in raw.entries) {
    final key = entry.key;
    if (key is! String) _fail(error, message);
    result[key] = entry.value;
  }
  return result;
}

int _readInteger(Object? value, String label) {
  if (value is! int) {
    _fail(
      ModpackFormatError.invalidVersion,
      'The $label must be a whole number.',
    );
  }
  if (value <= 0 || value > ModpackLimits.maxSafeInteger) {
    _fail(
      ModpackFormatError.invalidVersion,
      'The $label must be a positive whole number no larger than '
      '${ModpackLimits.maxSafeInteger}.',
    );
  }
  return value;
}

String? _readOptionalString(
  Object? value,
  int maxLength,
  String label, {
  ModpackFormatError error = ModpackFormatError.invalidField,
}) {
  if (value == null) return null;
  if (value is! String) {
    _fail(error, 'The modpack $label is not text.');
  }
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  if (trimmed.length > maxLength) {
    _fail(
      ModpackFormatError.fieldTooLong,
      'The modpack $label is longer than $maxLength characters.',
    );
  }
  if (_hasBannedControlCharacters(trimmed)) {
    _fail(error, 'The modpack $label contains control characters.');
  }
  return trimmed;
}

String? _readOptionalUrl(Object? value, String label) {
  if (value == null) return null;
  if (value is! String || !isSafeModpackUrl(value)) {
    _fail(
      ModpackFormatError.unsafeUrl,
      'The modpack $label must be an HTTP or HTTPS URL.',
    );
  }
  _checkLength(value, ModpackLimits.maxUrlLength, label);
  return value.trim();
}

String? _readLabel(Object? value) {
  if (value == null) return null;
  if (value is! String) {
    _fail(ModpackFormatError.invalidLabel, 'An item label is not text.');
  }
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  if (trimmed.length > ModpackLimits.maxLabelLength) {
    _fail(
      ModpackFormatError.invalidLabel,
      'An item label is longer than ${ModpackLimits.maxLabelLength} '
      'characters.',
    );
  }
  if (trimmed.contains('\n') ||
      trimmed.contains('\r') ||
      _hasBannedControlCharacters(trimmed)) {
    _fail(
      ModpackFormatError.invalidLabel,
      'An item label must be a single line of text.',
    );
  }
  return ModpackItemLabels.normalize(trimmed);
}

String? _readNote(Object? value) {
  if (value == null) return null;
  if (value is! String) {
    _fail(ModpackFormatError.invalidNote, 'An item note is not text.');
  }
  if (value.isEmpty) return null;
  if (value.length > ModpackLimits.maxNoteLength) {
    _fail(
      ModpackFormatError.invalidNote,
      'An item note is longer than ${ModpackLimits.maxNoteLength} characters.',
    );
  }
  if (_hasBannedControlCharacters(value)) {
    _fail(
      ModpackFormatError.invalidNote,
      'An item note contains control characters.',
    );
  }
  return value;
}

void _checkLength(String value, int maxLength, String label) {
  if (value.trim().length > maxLength) {
    _fail(
      ModpackFormatError.fieldTooLong,
      'The modpack $label is longer than $maxLength characters.',
    );
  }
}

/// Whether [value] is an address TriOS will fetch: HTTP or HTTPS, with a host
/// and no embedded credentials.
bool isSafeModpackUrl(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty || trimmed.length > ModpackLimits.maxUrlLength) {
    return false;
  }
  final parsed = Uri.tryParse(trimmed);
  if (parsed == null) return false;
  if (parsed.scheme != 'http' && parsed.scheme != 'https') return false;
  if (parsed.host.isEmpty) return false;
  if (parsed.userInfo.isNotEmpty) return false;
  return true;
}

/// Keeps fields this TriOS doesn't know about, checking they're plain JSON
/// and not nested too deep.
Map<String, dynamic> _collectUnknownFields(
  Map<String, Object?> map,
  List<String> knownKeys,
) {
  final unknown = <String, dynamic>{};
  for (final entry in map.entries) {
    if (knownKeys.contains(entry.key)) continue;
    unknown[entry.key] = _checkedJsonValue(entry.value, 1, entry.key);
  }
  return unknown;
}

Object? _checkedJsonValue(Object? value, int depth, String path) {
  if (depth > ModpackLimits.maxUnknownFieldDepth) {
    _fail(
      ModpackFormatError.invalidUnknownField,
      'The field $path is nested more than '
      '${ModpackLimits.maxUnknownFieldDepth} levels deep.',
    );
  }
  if (value == null || value is bool || value is num || value is String) {
    return value;
  }
  if (value is List) {
    return value
        .map((element) => _checkedJsonValue(element, depth + 1, path))
        .toList();
  }
  if (value is Map) {
    final result = <String, Object?>{};
    for (final entry in value.entries) {
      final key = entry.key;
      if (key is! String) {
        _fail(
          ModpackFormatError.invalidUnknownField,
          'The field $path has a non-text key.',
        );
      }
      result[key] = _checkedJsonValue(entry.value, depth + 1, '$path.$key');
    }
    return result;
  }
  _fail(
    ModpackFormatError.invalidUnknownField,
    'The field $path is not plain JSON data.',
  );
}

/// Builds the definition as a map with fixed field order: known fields in
/// documented order, then unknown fields sorted by name. Same data always
/// produces the same map, so comparison and link generation use it too.
Map<String, Object?> canonicalModpackMap(ModpackDefinition definition) {
  final map = <String, Object?>{
    'formatVersion': definition.formatVersion,
    'id': definition.id,
    'name': definition.name,
    'version': definition.version,
  };
  _putIfPresent(map, 'author', definition.author);
  _putIfPresent(map, 'description', definition.description);
  _putIfPresent(map, 'gameVersion', definition.gameVersion);
  _putIfPresent(map, 'homepageUrl', definition.homepageUrl);
  _putIfPresent(map, 'updateUrl', definition.updateUrl);
  map['items'] = definition.items.map(_canonicalItemMap).toList();
  _addSortedUnknownFields(map, definition.unknownFields);
  return map;
}

Map<String, Object?> _canonicalItemMap(ModpackItem item) {
  final map = <String, Object?>{'id': item.modId};
  _putIfPresent(map, 'name', item.name);
  _putIfPresent(map, 'version', item.version);
  _putIfPresent(map, 'label', item.label);
  _putIfPresent(map, 'note', item.note);
  map['url'] = item.url;
  map['sourceType'] = item.sourceType.name;
  final catalog = item.catalog;
  if (catalog != null && !catalog.isEmpty) {
    final catalogMap = <String, Object?>{};
    _putIfPresent(catalogMap, 'name', catalog.name);
    _putIfPresent(catalogMap, 'forumTopicId', catalog.forumTopicId);
    _putIfPresent(catalogMap, 'nexusModsId', catalog.nexusModsId);
    _addSortedUnknownFields(catalogMap, catalog.unknownFields);
    map['catalog'] = catalogMap;
  }
  _addSortedUnknownFields(map, item.unknownFields);
  return map;
}

void _putIfPresent(Map<String, Object?> map, String key, String? value) {
  if (value != null && value.isNotEmpty) map[key] = value;
}

void _addSortedUnknownFields(
  Map<String, Object?> map,
  Map<String, dynamic> unknownFields,
) {
  if (unknownFields.isEmpty) return;
  final keys = unknownFields.keys.toList()..sort();
  for (final key in keys) {
    map[key] = _sortedJsonValue(unknownFields[key]);
  }
}

Object? _sortedJsonValue(Object? value) {
  if (value is Map) {
    final keys = value.keys.map((key) => key.toString()).toList()..sort();
    return {for (final key in keys) key: _sortedJsonValue(value[key])};
  }
  if (value is List) {
    return value.map(_sortedJsonValue).toList();
  }
  return value;
}

/// The definition as compact JSON. Used for links, for comparison, and for
/// hosted definitions.
String encodeModpackDefinitionJson(ModpackDefinition definition) =>
    jsonEncode(canonicalModpackMap(definition));

/// The definition as readable JSON, for a `.trios-modpack` file.
String encodeModpackDefinitionFileJson(ModpackDefinition definition) =>
    const JsonEncoder.withIndent('  ').convert(canonicalModpackMap(definition));

/// Whether two definitions hold exactly the same data, pack ID and version
/// included. Used for duplicate imports and update checks.
bool modpackDefinitionsAreIdentical(ModpackDefinition a, ModpackDefinition b) =>
    encodeModpackDefinitionJson(a) == encodeModpackDefinitionJson(b);

/// Whether two definitions hold the same shared content, ignoring pack ID and
/// version. A save whose content matches the stored copy isn't an edit, so it
/// doesn't bump the version.
bool modpackSharedContentMatches(ModpackDefinition a, ModpackDefinition b) =>
    encodeModpackDefinitionJson(a.copyWith(id: b.id, version: b.version)) ==
    encodeModpackDefinitionJson(b);
