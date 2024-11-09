import 'package:flutter/material.dart';

class TristateIconButton extends StatefulWidget {
  final bool? value;
  final ValueChanged<bool?> onChanged;
  final Widget trueIcon;
  final Widget? falseIcon;
  final Widget? nullIcon;

  const TristateIconButton({
    super.key,
    required this.value,
    required this.onChanged,
    required this.trueIcon,
    this.falseIcon,
    this.nullIcon,
  });

  @override
  State<TristateIconButton> createState() => _TristateIconButtonState();
}

class _TristateIconButtonState extends State<TristateIconButton> {
  bool? _currentState;

  @override
  void initState() {
    super.initState();
    _currentState = widget.value;
  }

  void _toggleState() {
    setState(() {
      _currentState = switch (_currentState) {
        true => false,
        false => null,
        null => true,
      };
      widget.onChanged(_currentState);
    });
  }

  Widget get _currentIcon {
    if (_currentState == true) {
      return widget.trueIcon;
    } else if (_currentState == false) {
      return widget.falseIcon ?? widget.trueIcon;
    } else {
      return widget.nullIcon ?? widget.falseIcon ?? widget.trueIcon;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: _currentIcon,
      onPressed: _toggleState,
      color: Theme.of(context).iconTheme.color,
    );
  }
}
