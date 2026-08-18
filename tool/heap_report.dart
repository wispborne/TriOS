// Reads a DevTools heap snapshot (.data) and prints what is using the memory.
//
// Usage: dart run tool/heap_report.dart <snapshot.data>
import 'dart:io';
import 'dart:typed_data';

import 'package:vm_service/vm_service.dart';

String mb(int bytes) => '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';

void main(List<String> args) {
  final file = File(args.first);
  final bytes = file.readAsBytesSync();
  stderr.writeln('Read ${mb(bytes.length)} of snapshot, parsing...');

  final graph = HeapSnapshotGraph.fromChunks(
    [ByteData.view(bytes.buffer, bytes.offsetInBytes, bytes.length)],
    calculateReferrers: false,
    decodeObjectData: false,
    decodeExternalProperties: true,
    decodeIdentityHashCodes: false,
  );

  print('isolate:      ${graph.name}');
  print('shallow size: ${mb(graph.shallowSize)}');
  print('capacity:     ${mb(graph.capacity)}');
  print('external:     ${mb(graph.externalSize)}');
  print('objects:      ${graph.objects.length}');
  print('');

  final bytesByClass = <int, int>{};
  final countByClass = <int, int>{};
  for (final object in graph.objects) {
    final id = object.classId;
    bytesByClass[id] = (bytesByClass[id] ?? 0) + object.shallowSize;
    countByClass[id] = (countByClass[id] ?? 0) + 1;
  }

  final ranked = bytesByClass.keys.toList()
    ..sort((a, b) => bytesByClass[b]!.compareTo(bytesByClass[a]!));

  // `--csv` dumps every class instead of the top few, for comparing two runs.
  if (args.contains('--csv')) {
    print('Class,Instances,Bytes');
    for (final id in ranked) {
      print('${graph.classes[id].name},${countByClass[id]},'
          '${bytesByClass[id]}');
    }
    return;
  }

  print('Top classes by shallow size');
  print('${'size'.padLeft(10)}  ${'count'.padLeft(9)}  class');
  for (final id in ranked.take(45)) {
    final klass = graph.classes[id];
    final where = klass.libraryName.isEmpty
        ? klass.libraryUri.toString()
        : klass.libraryName;
    print(
      '${mb(bytesByClass[id]!).padLeft(10)}  '
      '${countByClass[id].toString().padLeft(9)}  '
      '${klass.name}  ($where)',
    );
  }

  // External memory is pixels and other native buffers a Dart object owns.
  if (graph.externalProperties.isNotEmpty) {
    final externalByClass = <int, int>{};
    final externalByName = <String, int>{};
    for (final property in graph.externalProperties) {
      final classId = graph.objects[property.object].classId;
      externalByClass[classId] =
          (externalByClass[classId] ?? 0) + property.externalSize;
      externalByName[property.name] =
          (externalByName[property.name] ?? 0) + property.externalSize;
    }
    print('');
    print('Top holders of external (native) memory');
    final externalRanked = externalByClass.keys.toList()
      ..sort((a, b) => externalByClass[b]!.compareTo(externalByClass[a]!));
    for (final id in externalRanked.take(15)) {
      print(
        '${mb(externalByClass[id]!).padLeft(10)}  ${graph.classes[id].name}',
      );
    }
    print('');
    print('External memory by name');
    final nameRanked = externalByName.keys.toList()
      ..sort((a, b) => externalByName[b]!.compareTo(externalByName[a]!));
    for (final name in nameRanked.take(15)) {
      print('${mb(externalByName[name]!).padLeft(10)}  $name');
    }
  }
}
