import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:intl/intl.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/widgets/blur.dart';
import 'package:trios/widgets/disable.dart';

import '../widgets/trios_expansion_tile.dart';
import 'mod_profiles_manager.dart';
import 'models/mod_profile.dart';

class ModProfilePage extends ConsumerStatefulWidget {
  const ModProfilePage({super.key});

  @override
  ConsumerState<ModProfilePage> createState() => _ModProfilePageState();
}

class _ModProfilePageState extends ConsumerState<ModProfilePage>
    with AutomaticKeepAliveClientMixin<ModProfilePage> {
  @override
  bool get wantKeepAlive => true;

  final TextEditingController _nameController = TextEditingController();
  String? _editingProfileId;

  @override
  Widget build(BuildContext context) {
    final modProfilesAsync = ref.watch(modProfilesProvider);
    final activeProfileId =
        ref.watch(appSettings.select((s) => s.activeModProfileId));
    final theme = Theme.of(context);
    final dateFormat = DateFormat.yMMMMd(Intl.getCurrentLocale()).add_jm();
    const minHeight = 120.0;
    const cardPadding = 8.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: modProfilesAsync.when(
        data: (modProfiles) {
          return AlignedGridView.count(
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            crossAxisCount: 3,
            itemCount: modProfiles.modProfiles.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: minHeight),
                    child: IntrinsicHeight(child: _buildNewProfileCard()));
              } else {
                final profile = modProfiles.modProfiles[index - 1];
                final isEditing = profile.id == _editingProfileId;
                final isActiveProfile = profile.id == activeProfileId;

                return ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: minHeight),
                  child: Card(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: isActiveProfile
                                ? theme.colorScheme.primary
                                : Colors.transparent,
                            width: 2),
                        borderRadius:
                            BorderRadius.circular(ThemeManager.cornerRadius),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: 0,
                            top: 0,
                            child: isEditing
                                ? IconButton(
                                    icon: const Icon(Icons.check),
                                    onPressed: () {
                                      ref
                                          .read(modProfilesProvider.notifier)
                                          .updateModProfile(
                                            profile.copyWith(
                                                name: _nameController.text),
                                          );
                                      setState(() {
                                        _editingProfileId = null;
                                      });
                                    },
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      setState(() {
                                        _editingProfileId = profile.id;
                                        _nameController.text = profile.name;
                                      });
                                    },
                                  ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                  padding: const EdgeInsets.all(cardPadding),
                                  child: isEditing
                                      ? TextField(
                                          controller: _nameController,
                                          decoration: const InputDecoration(
                                              labelText: 'Name'),
                                        )
                                      : Text(profile.name,
                                          style: theme.textTheme.bodyLarge
                                              ?.copyWith(
                                                  fontSize: 20,
                                                  fontFamily:
                                                      ThemeManager.orbitron))),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: cardPadding),
                                child: Row(
                                  children: [
                                    Text(
                                      '${profile.enabledModVariants.length} mods',
                                      style: theme.textTheme.labelSmall,
                                    ),
                                    // bullet
                                    Text(" • ",
                                        style: theme.textTheme.labelSmall),
                                    Tooltip(
                                      message:
                                          'Created: ${dateFormat.format(profile.dateCreated?.toLocal() ?? DateTime.now())}\n'
                                          'Last modified: ${dateFormat.format(profile.dateModified?.toLocal() ?? DateTime.now())}',
                                      child: Text(
                                        dateFormat.format(
                                            profile.dateCreated?.toLocal() ??
                                                DateTime.now()),
                                        style: theme.textTheme.labelSmall,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              TriOSExpansionTile(
                                title: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Spacer(),
                                    Blur(
                                      blur: isActiveProfile ? 5 : 0,
                                      child: IconButton(
                                          onPressed: () {
                                            ref
                                                .read(modProfilesProvider
                                                    .notifier)
                                                .activateModProfile(profile.id);
                                          },
                                          icon: Icon(Icons.power_settings_new,
                                              color: profile.id ==
                                                      activeProfileId
                                                  ? theme.colorScheme.primary
                                                  : null)),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.content_copy),
                                      tooltip: 'Copy mod list to clipboard',
                                      onPressed: () {
                                        _copyModListToClipboard(profile);
                                      },
                                    ),
                                    Disable(
                                      isEnabled:
                                          modProfiles.modProfiles.length > 1 &&
                                              activeProfileId != profile.id,
                                      child: IconButton(
                                        icon: const Icon(Icons.delete),
                                        tooltip: 'Delete profile',
                                        onPressed: () {
                                          showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                    title: const Text(
                                                        'Delete profile?'),
                                                    content: Text(
                                                        "Are you sure you want to delete profile '${profile.name}'?"),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () {
                                                          Navigator.of(context)
                                                              .pop();
                                                        },
                                                        child: const Text(
                                                            'Cancel'),
                                                      ),
                                                      TextButton(
                                                        onPressed: () {
                                                          Navigator.of(context)
                                                              .pop();
                                                          ref
                                                              .read(
                                                                  modProfilesProvider
                                                                      .notifier)
                                                              .removeModProfile(
                                                                  profile.id);
                                                        },
                                                        child: const Text(
                                                            'Delete'),
                                                      ),
                                                    ],
                                                  ));
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                expansionAnimationStyle:
                                    AnimationStyle.noAnimation,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                backgroundColor:
                                    theme.colorScheme.surfaceContainerLow,
                                collapsedShape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        ThemeManager.cornerRadius)),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        ThemeManager.cornerRadius)),
                                dense: true,
                                onExpansionChanged: (isExpanded) {
                                  //on next frame, set state to rebuild the card
                                  WidgetsBinding.instance.addPostFrameCallback(
                                      (_) => setState(() {}));
                                },
                                childrenPadding: const EdgeInsets.all(8),
                                children: profile.enabledModVariants.map((mod) {
                                  return Row(
                                    children: [
                                      Expanded(
                                        child: Text(mod.modName ?? mod.modId,
                                            overflow: TextOverflow.fade,
                                            maxLines: 1,
                                            style: theme.textTheme.labelLarge),
                                      ),
                                      Text(mod.version?.toString() ?? 'Unknown',
                                          style: theme.textTheme.labelLarge),
                                    ],
                                  );
                                }).toList(),
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildNewProfileCard() {
    final newProfileNameController = TextEditingController();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
                controller: newProfileNameController,
                decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 8.0),
            ElevatedButton(
              onPressed: () {
                if (newProfileNameController.text.isNotEmpty) {
                  ref
                      .read(modProfilesProvider.notifier)
                      .createModProfile(newProfileNameController.text);
                  newProfileNameController.clear();
                }
              },
              child: const Text('Create Profile'),
            ),
          ],
        ),
      ),
    );
  }

  void _copyModListToClipboard(ModProfile profile) {
    final modList = profile.enabledModVariants
        .map((mod) =>
            '${mod.modName ?? mod.modId} - Version: ${mod.version ?? 'Unknown'}')
        .join('\n');
    Clipboard.setData(ClipboardData(text: modList));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mod list copied to clipboard')),
    );
  }
}

void main() {
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mod Profiles',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ModProfilePage(),
    );
  }
}
