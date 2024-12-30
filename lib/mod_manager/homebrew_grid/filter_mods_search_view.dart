import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/mod_manager/smol4.dart';

class FilterModsSearchBar extends StatelessWidget {
  const FilterModsSearchBar({
    super.key,
    required this.searchController,
    required this.query,
    required this.ref,
  });

  final SearchController searchController;
  final String query;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return SearchAnchor(
      searchController: searchController,
      builder: (BuildContext context, SearchController controller) {
        return SearchBar(
            controller: controller,
            leading: const Icon(Icons.search),
            hintText: "Filter mods...",
            trailing: [
              query.isEmpty
                  ? Container()
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        controller.clear();
                        ref.read(searchQuery.notifier).state = "";
                        // allMods =
                        //     filterMods(query);
                      },
                    )
            ],
            backgroundColor: WidgetStateProperty.all(
                Theme.of(context).colorScheme.surfaceContainer),
            onChanged: (value) {
              ref.read(searchQuery.notifier).state = value;
              // setState(() {
              //   query = value;
              //   allMods = filterMods(value);
              // });
            });
      },
      suggestionsBuilder: (BuildContext context, SearchController controller) {
        return [];
      },
    );
  }
}
