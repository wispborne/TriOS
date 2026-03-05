// Copyright (c) 2012, the Dart project authors.
// Copyright (c) 2006, Kirill Simonov.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

import 'src/charcodes.dart';
import 'src/error_listener.dart';
import 'src/event.dart';
import 'src/loader.dart';
import 'src/parser.dart';
import 'src/style.dart';
import 'src/yaml_document.dart';
import 'src/yaml_exception.dart';
import 'src/yaml_node.dart';

export 'src/style.dart';
export 'src/utils.dart' show YamlWarningCallback, yamlWarningCallback;
export 'src/yaml_document.dart';
export 'src/yaml_exception.dart';
export 'src/yaml_node.dart' hide setSpan;

/// Loads a single document from a YAML string.
///
/// If the string contains more than one document, this throws a
/// [YamlException]. In future releases, this will become an [ArgumentError].
///
/// The return value is mostly normal Dart objects. However, since YAML mappings
/// support some key types that the default Dart map implementation doesn't
/// (NaN, lists, and maps), all maps in the returned document are [YamlMap]s.
/// These have a few small behavioral differences from the default Map
/// implementation; for details, see the [YamlMap] class.
///
/// If [sourceUrl] is passed, it's used as the URL from which the YAML
/// originated for error reporting.
///
/// If [recover] is true, will attempt to recover from parse errors and may
/// return invalid or synthetic nodes. If [errorListener] is also supplied, its
/// onError method will be called for each error recovered from. It is not valid
/// to provide [errorListener] if [recover] is false.
dynamic loadYaml(String yaml,
        {Uri? sourceUrl, bool recover = false, ErrorListener? errorListener}) =>
    loadYamlNode(yaml,
            sourceUrl: sourceUrl,
            recover: recover,
            errorListener: errorListener)
        .value;

/// Loads a single document from a YAML string as a [YamlNode].
///
/// This is just like [loadYaml], except that where [loadYaml] would return a
/// normal Dart value this returns a [YamlNode] instead. This allows the caller
/// to be confident that the return value will always be a [YamlNode].
YamlNode loadYamlNode(String yaml,
        {Uri? sourceUrl, bool recover = false, ErrorListener? errorListener}) =>
    loadYamlDocument(yaml,
            sourceUrl: sourceUrl,
            recover: recover,
            errorListener: errorListener)
        .contents;

/// Loads a single document from a YAML string as a [YamlDocument].
///
/// This is just like [loadYaml], except that where [loadYaml] would return a
/// normal Dart value this returns a [YamlDocument] instead. This allows the
/// caller to access document metadata.
YamlDocument loadYamlDocument(String yaml,
    {Uri? sourceUrl, bool recover = false, ErrorListener? errorListener}) {
  var loader = Loader(yaml,
      sourceUrl: sourceUrl, recover: recover, errorListener: errorListener);
  var document = loader.load();
  if (document == null) {
    return YamlDocument.internal(YamlScalar.internalWithSpan(null, loader.span),
        loader.span, null, const []);
  }

  var nextDocument = loader.load();
  if (nextDocument != null) {
    throw YamlException('Only expected one document.', nextDocument.span);
  }

  return document;
}

/// Loads a stream of documents from a YAML string.
///
/// The return value is mostly normal Dart objects. However, since YAML mappings
/// support some key types that the default Dart map implementation doesn't
/// (NaN, lists, and maps), all maps in the returned document are [YamlMap]s.
/// These have a few small behavioral differences from the default Map
/// implementation; for details, see the [YamlMap] class.
///
/// If [sourceUrl] is passed, it's used as the URL from which the YAML
/// originated for error reporting.
YamlList loadYamlStream(String yaml, {Uri? sourceUrl}) {
  var loader = Loader(yaml, sourceUrl: sourceUrl);

  var documents = <YamlDocument>[];
  var document = loader.load();
  while (document != null) {
    documents.add(document);
    document = loader.load();
  }

  // TODO(jmesserly): the type on the `document` parameter is a workaround for:
  // https://github.com/dart-lang/dev_compiler/issues/203
  return YamlList.internal(
      documents.map((YamlDocument document) => document.contents).toList(),
      loader.span,
      CollectionStyle.ANY);
}

/// Loads a stream of documents from a YAML string.
///
/// This is like [loadYamlStream], except that it returns [YamlDocument]s with
/// metadata wrapping the document contents.
List<YamlDocument> loadYamlDocuments(String yaml, {Uri? sourceUrl}) {
  var loader = Loader(yaml, sourceUrl: sourceUrl);

  var documents = <YamlDocument>[];
  var document = loader.load();
  while (document != null) {
    documents.add(document);
    document = loader.load();
  }

  return documents;
}

/// Loads a single document from a YAML string as plain Dart objects.
///
/// Returns [Map]s, [List]s, and scalar values (String, int, double, bool,
/// null) without any [YamlNode] wrappers. More efficient than [loadYaml]
/// when source span metadata is not needed.
///
/// If [sourceUrl] is passed, it's used as the URL from which the YAML
/// originated for error reporting.
dynamic loadYamlValue(String yaml, {Uri? sourceUrl}) {
  var parser = Parser(yaml, sourceUrl: sourceUrl);
  var event = parser.parse();
  assert(event.type == EventType.streamStart);

  event = parser.parse();
  if (event.type == EventType.streamEnd) return null;

  // Skip DocumentStart.
  var docEvent = event as DocumentStartEvent;
  var result = _loadValue(parser, parser.parse());

  // Skip DocumentEnd.
  parser.parse();

  return result;
}

/// Recursively builds plain Dart objects from parser events.
dynamic _loadValue(Parser parser, Event event) => switch (event.type) {
      EventType.scalar => _parseScalarValue((event as ScalarEvent).value),
      EventType.alias => null,
      EventType.sequenceStart => _loadListValue(parser),
      EventType.mappingStart => _loadMapValue(parser),
      _ => throw StateError('Unreachable'),
    };

/// Builds a plain [List] from parser events.
List _loadListValue(Parser parser) {
  var list = [];
  var event = parser.parse();
  while (event.type != EventType.sequenceEnd) {
    list.add(_loadValue(parser, event));
    event = parser.parse();
  }
  return list;
}

/// Builds a plain [Map] from parser events.
Map _loadMapValue(Parser parser) {
  var map = <dynamic, dynamic>{};
  var event = parser.parse();
  while (event.type != EventType.mappingEnd) {
    var key = _loadValue(parser, event);
    var value = _loadValue(parser, parser.parse());
    map[key] = value;
    event = parser.parse();
  }
  return map;
}

/// Parses a scalar string into the appropriate Dart type.
dynamic _parseScalarValue(String value) {
  var length = value.length;
  if (length == 0) return null;

  var firstChar = value.codeUnitAt(0);
  return switch (firstChar) {
    $dot || $plus || $minus => _parseNumberValue(value),
    $n || $N => length == 4 ? _parseNullValue(value) : value,
    $t || $T => length == 4 ? _parseBoolValue(value) ?? value : value,
    $f || $F => length == 5 ? _parseBoolValue(value) ?? value : value,
    $tilde => length == 1 ? null : value,
    _ => (firstChar >= $0 && firstChar <= $9)
        ? _parseNumberValue(value) ?? value
        : value,
  };
}

dynamic _parseNullValue(String value) => switch (value) {
      'null' || 'Null' || 'NULL' => null,
      _ => value,
    };

bool? _parseBoolValue(String value) => switch (value) {
      'true' || 'True' || 'TRUE' => true,
      'false' || 'False' || 'FALSE' => false,
      _ => null,
    };

dynamic _parseNumberValue(String contents) {
  var firstChar = contents.codeUnitAt(0);
  var length = contents.length;

  if (length == 1) {
    var digit = firstChar - $0;
    return digit >= 0 && digit <= 9 ? digit : contents;
  }

  var secondChar = contents.codeUnitAt(1);

  if (firstChar == $0) {
    if (secondChar == $x) return int.tryParse(contents) ?? contents;
    if (secondChar == $o) {
      return int.tryParse(contents.substring(2), radix: 8) ?? contents;
    }
  }

  if ((firstChar >= $0 && firstChar <= $9) ||
      ((firstChar == $plus || firstChar == $minus) &&
          secondChar >= $0 &&
          secondChar <= $9)) {
    return int.tryParse(contents, radix: 10) ??
        double.tryParse(contents) ??
        contents;
  }

  if ((firstChar == $dot && secondChar >= $0 && secondChar <= $9) ||
      (firstChar == $minus || firstChar == $plus) && secondChar == $dot) {
    if (length == 5) {
      switch (contents) {
        case '+.inf' || '+.Inf' || '+.INF':
          return double.infinity;
        case '-.inf' || '-.Inf' || '-.INF':
          return -double.infinity;
      }
    }
    return double.tryParse(contents) ?? contents;
  }

  if (length == 4 && firstChar == $dot) {
    switch (contents) {
      case '.inf' || '.Inf' || '.INF':
        return double.infinity;
      case '.nan' || '.NaN' || '.NAN':
        return double.nan;
    }
  }

  return contents;
}
