import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:material_ui/material_ui.dart';
import 'package:trios/modpacks/models/modpack_definition.dart';
import 'package:trios/modpacks/models/modpack_draft.dart';
import 'package:trios/modpacks/modpack_format.dart';

/// The same comparison is used for saved conflicts and a requested online copy.
class ModpackComparison extends StatelessWidget {
  final ModpackDefinition incoming;
  final ModpackDefinition? saved;
  final ModpackDraft? draft;
  const ModpackComparison({
    super.key,
    required this.incoming,
    this.saved,
    this.draft,
  });

  @override
  Widget build(BuildContext context) {
    final before = draft == null
        ? canonicalModpackMap(saved!)
        : draft!.isCommittable
        ? canonicalModpackMap(
            draft!.toDefinition(version: saved?.version ?? incoming.version),
          )
        : {
            ...draft!.unknownFields,
            ...draft!.toMap()
              ..remove('updatedAt')
              ..remove('unknownFields'),
            'items': [
              for (final item in draft!.items)
                {
                  ...item.unknownFields,
                  ...item.toMap()
                    ..remove('modId')
                    ..remove('unknownFields'),
                  'id': item.modId,
                },
            ],
          };
    final after = canonicalModpackMap(incoming);
    final oldItems = (before['items'] as List).cast<Map>();
    final newItems = (after['items'] as List).cast<Map>();
    final oldById = {for (final item in oldItems) item['id']: item};
    final newById = {for (final item in newItems) item['id']: item};
    return Column(
      crossAxisAlignment: .start,
      spacing: 8,
      children: [
        Text(
          'Pack information',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        ..._changes(before, after, skip: {'items', 'id'}),
        if (!const DeepCollectionEquality().equals(
          oldById.keys.toList(),
          newById.keys.toList(),
        ))
          const Text('Mod order or membership changes.'),
        Text('Added mods', style: Theme.of(context).textTheme.titleMedium),
        for (final item in newItems.where((i) => !oldById.containsKey(i['id'])))
          Text('${item['name'] ?? item['id']} (${item['id']})'),
        Text('Removed mods', style: Theme.of(context).textTheme.titleMedium),
        for (final item in oldItems.where((i) => !newById.containsKey(i['id'])))
          Text('${item['name'] ?? item['id']} (${item['id']})'),
        Text('Changed mods', style: Theme.of(context).textTheme.titleMedium),
        for (final item in newItems)
          if (oldById.containsKey(item['id']) &&
              !const DeepCollectionEquality().equals(oldById[item['id']], item))
            Column(
              crossAxisAlignment: .start,
              spacing: 4,
              children: [
                Text('${item['name'] ?? item['id']} (${item['id']})'),
                ..._changes(oldById[item['id']]!, item, skip: {'id'}),
              ],
            ),
      ],
    );
  }

  List<Widget> _changes(Map before, Map after, {required Set<String> skip}) => [
    for (final key in {...before.keys, ...after.keys})
      if (!skip.contains(key) &&
          !const DeepCollectionEquality().equals(before[key], after[key]))
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '${_labels[key] ?? key}: '),
              TextSpan(
                text: _value(before[key]),
                style: const TextStyle(decoration: TextDecoration.lineThrough),
              ),
              TextSpan(text: ' → ${_value(after[key])}'),
            ],
          ),
        ),
  ];

  String _value(Object? value) => value == null
      ? 'Not set'
      : value is String
      ? value
      : jsonEncode(value);
  static const _labels = {
    'version': 'Version',
    'name': 'Name',
    'author': 'Author',
    'description': 'Description',
    'gameVersion': 'Starsector version',
    'homepageUrl': 'Homepage',
    'updateUrl': 'Update address',
    'sourceType': 'Source type',
    'url': 'Source address',
    'label': 'Label',
    'note': 'Note',
    'catalog': 'Catalog clues',
  };
}
