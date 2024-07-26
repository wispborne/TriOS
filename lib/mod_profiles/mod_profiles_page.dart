import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'mod_profiles_manager.dart';
import 'models/mod_profile.dart';

class ModProfilePage extends ConsumerWidget {
  const ModProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modProfilesAsync = ref.watch(modProfilesProvider);

    return Scaffold(
      body: modProfilesAsync.when(
        data: (modProfiles) {
          return ListView.builder(
            itemCount: modProfiles.modProfiles.length,
            itemBuilder: (context, index) {
              final profile = modProfiles.modProfiles[index];
              return ExpansionTile(
                title: Text(profile.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile.description),
                    Text('${profile.enabledModVariants.length} mods enabled'),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () =>
                          _showEditProfileDialog(context, ref, profile),
                    ),
                    if (modProfiles.modProfiles.length > 1)
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          ref
                              .read(modProfilesProvider.notifier)
                              .removeModProfile(profile.id);
                        },
                      ),
                  ],
                ),
                children: profile.enabledModVariants.map((mod) {
                  return ListTile(
                    title: Text(mod.modName ?? mod.modId),
                    subtitle: Text('Version: ${mod.version ?? 'Unknown'}'),
                  );
                }).toList(),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProfileDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showEditProfileDialog(
      BuildContext context, WidgetRef ref, ModProfile profile) {
    final nameController = TextEditingController(text: profile.name);
    final descriptionController =
        TextEditingController(text: profile.description);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                ref.read(modProfilesProvider.notifier).updateModProfile(
                      profile.copyWith(
                        name: nameController.text,
                        description: descriptionController.text,
                      ),
                    );
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showAddProfileDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                ref.read(modProfilesProvider.notifier).createModProfile(
                      nameController.text,
                      description: descriptionController.text,
                    );
                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
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
