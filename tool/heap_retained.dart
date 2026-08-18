// Third pass over a heap snapshot: builds the dominator tree and reports
// retained size — how much memory is freed if a given object goes away.
//
// Usage: dart run tool/heap_retained.dart <snapshot.data>
import 'dart:io';
import 'dart:typed_data';

import 'package:vm_service/vm_service.dart';

String mb(int bytes) => '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';

void main(List<String> args) {
  final bytes = File(args.first).readAsBytesSync();
  stderr.writeln('Parsing ${mb(bytes.length)}...');
  final graph = HeapSnapshotGraph.fromChunks(
    [ByteData.view(bytes.buffer, bytes.offsetInBytes, bytes.length)],
    calculateReferrers: false,
    decodeObjectData: false,
    decodeExternalProperties: false,
    decodeIdentityHashCodes: false,
  );
  final objects = graph.objects;
  final n = objects.length;
  stderr.writeln('Parsed $n objects. Numbering...');

  // Depth-first order from the root, iteratively (the graph is far too deep
  // for recursion).
  final order = Int32List(n); // visit order -> node
  final position = Int32List(n)..fillRange(0, n, -1); // node -> visit order
  // Index 0 is a sentinel in this format; the real root is the object whose
  // class is named "Root".
  var root = 0;
  for (var i = 0; i < n && i < 10; i++) {
    if (objects[i].klass.name == 'Root') {
      root = i;
      break;
    }
  }
  stderr.writeln(
    'root is object $root (${objects[root].klass.name}, '
    '${objects[root].references.length} refs)',
  );

  var visited = 0;
  final stack = <int>[root];
  final nextEdge = Int32List(n);
  position[root] = 0;
  order[0] = root;
  visited = 1;
  while (stack.isNotEmpty) {
    final node = stack.last;
    final edges = objects[node].references;
    if (nextEdge[node] < edges.length) {
      final child = edges[nextEdge[node]++];
      if (child >= 0 && child < n && position[child] == -1) {
        position[child] = visited;
        order[visited] = child;
        visited++;
        stack.add(child);
      }
    } else {
      stack.removeLast();
    }
  }
  stderr.writeln('Reached $visited of $n objects.');

  // Predecessors, as one flat array with a start index per node.
  final predCount = Int32List(n);
  for (var node = 0; node < n; node++) {
    if (position[node] == -1) continue;
    for (final child in objects[node].references) {
      if (child >= 0 && child < n && position[child] != -1) predCount[child]++;
    }
  }
  final predStart = Int32List(n + 1);
  for (var node = 0; node < n; node++) {
    predStart[node + 1] = predStart[node] + predCount[node];
  }
  final preds = Int32List(predStart[n]);
  final fill = Int32List.fromList(predStart.sublist(0, n));
  for (var node = 0; node < n; node++) {
    if (position[node] == -1) continue;
    for (final child in objects[node].references) {
      if (child >= 0 && child < n && position[child] != -1) {
        preds[fill[child]++] = node;
      }
    }
  }

  // Cooper/Harvey/Kennedy iterative dominators, working in visit order.
  final idom = Int32List(n)..fillRange(0, n, -1);
  idom[root] = root;
  var changed = true;
  var round = 0;
  while (changed) {
    changed = false;
    round++;
    for (var i = 1; i < visited; i++) {
      final node = order[i];
      var newIdom = -1;
      for (var p = predStart[node]; p < predStart[node + 1]; p++) {
        final pred = preds[p];
        if (idom[pred] == -1) continue;
        if (newIdom == -1) {
          newIdom = pred;
          continue;
        }
        // Walk both up the tree until they meet.
        var a = pred;
        var b = newIdom;
        while (a != b) {
          while (position[a] > position[b]) {
            a = idom[a];
          }
          while (position[b] > position[a]) {
            b = idom[b];
          }
        }
        newIdom = a;
      }
      if (newIdom != -1 && idom[node] != newIdom) {
        idom[node] = newIdom;
        changed = true;
      }
    }
    stderr.writeln('dominator pass $round done');
  }

  // Retained size: roll each node's own size up into its dominator.
  final retained = Int64List(n);
  for (var i = 0; i < visited; i++) {
    retained[order[i]] = objects[order[i]].shallowSize;
  }
  for (var i = visited - 1; i >= 1; i--) {
    final node = order[i];
    final parent = idom[node];
    if (parent >= 0 && parent != node) retained[parent] += retained[node];
  }

  // Label each object with the field that points at it, for readability.
  final label = List<String>.filled(n, '');
  for (var node = 0; node < n; node++) {
    if (position[node] == -1) continue;
    final refs = objects[node].references;
    final fields = objects[node].klass.fields;
    for (final field in fields) {
      if (field.index < refs.length) {
        final child = refs[field.index];
        if (child > 0 && child < n && label[child].isEmpty) {
          label[child] = '${objects[node].klass.name}.${field.name}';
        }
      }
    }
  }

  final ranked = List<int>.generate(visited, (i) => order[i])
    ..sort((a, b) => retained[b].compareTo(retained[a]));

  // Extra arguments are field-name fragments to look up by name, for
  // comparing one run against another.
  final lookups = args.skip(1).where((a) => !a.startsWith('-')).toList();
  if (lookups.isNotEmpty) {
    for (final want in lookups) {
      var total = 0;
      var found = 0;
      for (final node in ranked) {
        if (!label[node].toLowerCase().contains(want.toLowerCase())) continue;
        total += retained[node];
        found++;
        if (found <= 3) {
          print('${mb(retained[node]).padLeft(10)}  ${label[node]}');
        }
      }
      print('${mb(total).padLeft(10)}  TOTAL for "$want" ($found objects)');
      print('');
    }
    return;
  }

  print('total heap: ${mb(graph.shallowSize)}');
  print('');
  print('Biggest retainers (freeing this object frees this much)');
  print('${'retained'.padLeft(10)}  ${'shallow'.padLeft(9)}  what');
  var shown = 0;
  for (final node in ranked) {
    if (shown >= 60) break;
    final name = objects[node].klass.name;
    // Skip VM bookkeeping that isn't actionable.
    if (name == 'Root' || name == 'Isolate' || name == 'ObjectStore') continue;
    print(
      '${mb(retained[node]).padLeft(10)}  '
      '${mb(objects[node].shallowSize).padLeft(9)}  '
      '$name  ${label[node]}',
    );
    shown++;
  }

  // Retained size grouped by the class of the retaining object.
  final byClass = <String, int>{};
  for (var i = 0; i < visited; i++) {
    final node = order[i];
    final name = objects[node].klass.name;
    byClass[name] = (byClass[name] ?? 0) + retained[node];
  }
  // For the biggest retainers, show the path down from the root and what the
  // big collections actually hold.
  print('');
  print('=== Detail on the biggest retainers ===');
  var detailed = 0;
  final seenChain = <int>{};
  for (final node in ranked) {
    if (detailed >= 12) break;
    if (retained[node] < 4 * 1024 * 1024) break;
    final name = objects[node].klass.name;
    if (name == 'Root' || name == 'Isolate' || name == 'ObjectStore') continue;
    // Only the top of each chain, not every link in it.
    if (seenChain.contains(node)) continue;
    var walk = node;
    while (walk != root && idom[walk] != walk) {
      seenChain.add(walk);
      walk = idom[walk];
    }

    print('');
    print('${mb(retained[node])}  $name  ${label[node]}');
    // Path from the root down to this object.
    final path = <int>[];
    var up = node;
    while (up != root && idom[up] != up && path.length < 40) {
      path.add(up);
      up = idom[up];
    }
    print('  path from root:');
    for (final step in path.reversed) {
      final stepLabel = label[step];
      print(
        '    ${objects[step].klass.name}'
        '${stepLabel.isEmpty ? '' : '   <- $stepLabel'}',
      );
    }
    // What is inside, if it is a collection.
    final contents = <String, int>{};
    for (final child in objects[node].references) {
      if (child <= 0 || child >= n) continue;
      final childName = objects[child].klass.name;
      contents[childName] = (contents[childName] ?? 0) + 1;
    }
    if (contents.isNotEmpty) {
      final top = contents.keys.toList()
        ..sort((a, b) => contents[b]!.compareTo(contents[a]!));
      print(
        '  holds: ${top.take(4).map((c) => '${contents[c]}x $c').join(', ')}',
      );
    }
    detailed++;
  }

  print('');
  print(
    'Retained size summed per class (double counts nesting, use as a hint)',
  );
  final classRanked = byClass.keys.toList()
    ..sort((a, b) => byClass[b]!.compareTo(byClass[a]!));
  for (final name in classRanked.take(30)) {
    print('${mb(byClass[name]!).padLeft(10)}  $name');
  }
}
