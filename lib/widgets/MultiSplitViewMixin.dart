import 'package:flutter/material.dart';
import 'package:multi_split_view/multi_split_view.dart';

mixin MultiSplitViewMixin<T extends StatefulWidget> on State<T> {
  late MultiSplitViewController multiSplitController =
      MultiSplitViewController(areas: areas);

  List<Area> get areas;

  @override
  void initState() {
    super.initState();
    multiSplitController.addListener(onMultiSplitViewChanged);
  }

  @override
  void dispose() {
    multiSplitController.removeListener(onMultiSplitViewChanged);
    super.dispose();
  }

  /// Called when the MultiSplitView changes
  void onMultiSplitViewChanged() {
    setState(() {
      // Rebuild to update the UI when the controller changes
    });
  }
}
