import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/mod.dart';

class ModVersionSelectionDropdown extends ConsumerStatefulWidget {
  final Mod mod;
  const ModVersionSelectionDropdown({super.key, required this.mod});

  @override
  ConsumerState createState() => _ModVersionSelectionDropdownState();
}

class _ModVersionSelectionDropdownState
    extends ConsumerState<ModVersionSelectionDropdown> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
