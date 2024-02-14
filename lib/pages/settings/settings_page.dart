import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vram_estimator_flutter/settings/settings.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final gamePathTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    gamePathTextController.text = ref.read(appSettings).gameDir ?? "";
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TextField(
        controller: gamePathTextController,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Starsector Folder',
        ),
      ),
    );
  }
}
