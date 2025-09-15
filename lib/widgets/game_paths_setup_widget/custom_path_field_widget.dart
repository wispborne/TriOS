
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/disable.dart';
import 'package:trios/widgets/moving_tooltip.dart';

/// A reusable widget for custom path fields that can be wired to settings
class CustomPathField extends ConsumerStatefulWidget {
  /// The label text for the field
  final String labelText;
  
  /// The hint text for the field (optional)
  final String? hintText;
  
  /// Tooltip message for the checkbox (optional)
  final String? checkboxTooltip;
  
  /// Tooltip message for the text field (optional) 
  final String? fieldTooltip;
  
  /// Current path value from settings
  final String currentPath;
  
  /// Whether the custom path is currently enabled
  final bool isEnabled;
  
  /// Whether this field is for selecting directories (true) or files (false)
  final bool isDirectoryPicker;
  
  /// Initial directory for file picker (optional)
  final String? initialDirectory;
  
  /// File type filters for file picker (only used when isDirectoryPicker is false)
  final List<String>? allowedExtensions;
  
  /// Dialog title for the picker
  final String? pickerDialogTitle;
  
  /// Validation function to check if the path is valid
  final bool Function(String path) validatePath;
  
  /// Error message to show when validation fails
  final String errorMessage;
  
  /// Callback when the enabled state changes
  final void Function(bool isEnabled) onEnabledChanged;
  
  /// Callback when the path value changes
  final void Function(String path) onPathChanged;

  const CustomPathField({
    super.key,
    required this.labelText,
    required this.currentPath,
    required this.isEnabled,
    required this.validatePath,
    required this.errorMessage,
    required this.onEnabledChanged,
    required this.onPathChanged,
    this.hintText,
    this.checkboxTooltip,
    this.fieldTooltip,
    this.isDirectoryPicker = true,
    this.initialDirectory,
    this.allowedExtensions,
    this.pickerDialogTitle,
  });

  @override
  ConsumerState<CustomPathField> createState() => _CustomPathFieldState();
}

class _CustomPathFieldState extends ConsumerState<CustomPathField> {
  late final TextEditingController _textController;
  bool _isPathValid = true;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.currentPath);
    _validateCurrentPath();
  }

  @override
  void didUpdateWidget(CustomPathField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPath != widget.currentPath) {
      _textController.text = widget.currentPath;
      _validateCurrentPath();
    }
  }

  void _validateCurrentPath() {
    _isPathValid = widget.validatePath(widget.currentPath);
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 700),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: widget.checkboxTooltip != null
                ? MovingTooltipWidget.text(
                    message: widget.checkboxTooltip!,
                    child: _buildCheckbox(),
                  )
                : _buildCheckbox(),
          ),
          Expanded(
            child: widget.fieldTooltip != null
                ? MovingTooltipWidget.text(
                    message: widget.fieldTooltip!,
                    child: _buildTextField(),
                  )
                : _buildTextField(),
          ),
          Disable(
            isEnabled: widget.isEnabled,
            child: IconButton(
              icon: const Icon(Icons.folder),
              onPressed: _handlePickPath,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckbox() {
    return Checkbox(
      value: widget.isEnabled,
      onChanged: (value) {
        widget.onEnabledChanged(value ?? false);
      },
    );
  }

  Widget _buildTextField() {
    return Disable(
      isEnabled: widget.isEnabled,
      child: TextField(
        controller: _textController,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          isDense: true,
          errorText: widget.isEnabled && !_isPathValid ? widget.errorMessage : null,
          labelText: widget.labelText,
          hintText: widget.hintText,
          hintStyle: Theme.of(context).textTheme.labelLarge,
          labelStyle: Theme.of(context).textTheme.labelLarge,
        ),
        onChanged: (newPath) {
          setState(() {
            _isPathValid = widget.validatePath(newPath);
          });
          widget.onPathChanged(newPath);
        },
      ),
    );
  }

  Future<void> _handlePickPath() async {
    String? newPath;
    
    if (widget.isDirectoryPicker) {
      newPath = await FilePicker.platform.getDirectoryPath(
        dialogTitle: widget.pickerDialogTitle,
        initialDirectory: widget.initialDirectory,
      );
      if (newPath != null) {
        newPath = newPath.toDirectory().normalize.path;
      }
    } else {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: widget.pickerDialogTitle,
        allowMultiple: false,
        initialDirectory: widget.initialDirectory,
        allowedExtensions: widget.allowedExtensions,
        type: widget.allowedExtensions != null ? FileType.custom : FileType.any,
      );
      newPath = result?.paths.firstOrNull;
    }
    
    if (newPath != null) {
      _textController.text = newPath;
      setState(() {
        _isPathValid = widget.validatePath(newPath!);
      });
      widget.onPathChanged(newPath);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
