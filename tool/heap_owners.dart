// Second pass over a heap snapshot: for the classes using the most memory,
// print which classes point at them, and through which field.
//
// Usage: dart run tool/heap_owners.dart <snapshot.data> [ClassName ...]
import 'dart:io';
import 'dart:typed_data';

import 'package:vm_service/vm_service.dart';

String mb(int bytes) => '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';

void main(List<String> args) {
  final bytes = File(args.first).readAsBytesSync();
  final wanted = args.skip(1).toSet();
  stderr.writeln('Parsing ${mb(bytes.length)}...');

  final graph = HeapSnapshotGraph.fromChunks(
    [ByteData.view(bytes.buffer, bytes.offsetInBytes, bytes.length)],
    calculateReferrers: true,
    decodeObjectData: false,
    decodeExternalProperties: false,
    decodeIdentityHashCodes: false,
  );
  stderr.writeln('Parsed. ${graph.objects.length} objects.');

  final objects = graph.objects;

  for (final target in wanted) {
    // Bytes of `target` instances, grouped by the class that points at them.
    final bytesByOwner = <String, int>{};
    final bytesByField = <String, int>{};
    var total = 0;
    var count = 0;

    for (var i = 0; i < objects.length; i++) {
      final object = objects[i];
      if (object.klass.name != target) continue;
      total += object.shallowSize;
      count++;

      // Charge the object to each distinct class holding it, so a shared
      // string shows up under every owner rather than being lost.
      final owners = <String>{};
      final fields = <String>{};
      for (final referrerIndex in object.referrers) {
        final referrer = objects[referrerIndex];
        final ownerName = referrer.klass.name;
        owners.add(ownerName);
        // Which field of the owner points here.
        for (var slot = 0; slot < referrer.references.length; slot++) {
          if (referrer.references[slot] != i) continue;
          final name = referrer.klass.fields
              .where((f) => f.index == slot)
              .map((f) => f.name)
              .firstOrNull;
          fields.add('$ownerName.${name ?? '[$slot]'}');
        }
      }
      if (owners.isEmpty) owners.add('<no referrer>');
      for (final owner in owners) {
        bytesByOwner[owner] = (bytesByOwner[owner] ?? 0) + object.shallowSize;
      }
      for (final field in fields) {
        bytesByField[field] = (bytesByField[field] ?? 0) + object.shallowSize;
      }
    }

    print('');
    print('=== $target: ${mb(total)} across $count objects ===');
    print('-- by owning class --');
    final owners = bytesByOwner.keys.toList()
      ..sort((a, b) => bytesByOwner[b]!.compareTo(bytesByOwner[a]!));
    for (final owner in owners.take(20)) {
      print('${mb(bytesByOwner[owner]!).padLeft(10)}  $owner');
    }
    print('-- by owning field --');
    final fields = bytesByField.keys.toList()
      ..sort((a, b) => bytesByField[b]!.compareTo(bytesByField[a]!));
    for (final field in fields.take(25)) {
      print('${mb(bytesByField[field]!).padLeft(10)}  $field');
    }
  }
}
