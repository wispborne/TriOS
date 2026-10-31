import 'package:material_ui/material_ui.dart';
import 'package:trios/widgets/search_hotkey.dart';

/// Reusable search box for viewer pages (Ships, Weapons, Hullmods, etc.).
class ViewerSearchBox extends StatelessWidget {
  final SearchController searchController;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const ViewerSearchBox({
    super.key,
    required this.searchController,
    required this.hintText,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      width: 300,
      child: SearchHotkey(
        controller: searchController,
        builder: (context, focusNode) => SearchAnchor(
          searchController: searchController,
          builder: (context, controller) {
            return SearchBar(
              controller: controller,
              focusNode: focusNode,
              leading: const Icon(Icons.search),
              hintText: '$hintText$searchHotkeyHint',
              trailing: [
                if (controller.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    padding: .zero,
                    onPressed: () {
                      controller.clear();
                      onClear();
                    },
                  ),
              ],
              onChanged: onChanged,
              backgroundColor: WidgetStateProperty.all(
                Theme.of(context).colorScheme.surfaceContainer,
              ),
            );
          },
          suggestionsBuilder: (_, _) => [],
        ),
      ),
    );
  }
}
