import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/disable.dart';
import 'package:trios/widgets/moving_tooltip.dart';

/// A reusable widget for custom path fields that can be wired to settings
class CustomPathField extends ConsumerStatefulWidget {
  final String labelText;
  final String? hintText;
  final String? checkboxTooltip;
  final String? fieldTooltip;
  final String pathWhenUnchecked;
  final String? customPathWhenChecked;

  /// Apply will make it wider than this value, if shown.
  final double width;
  final bool isChecked;
  final bool isDirectoryPicker;
  final String? initialDirectory;
  final List<String>? allowedExtensions;
  final String? pickerDialogTitle;
  final String? errorMessage;
  final void Function(bool isEnabled) onCheckedChanged;
  final void Function(String path) onPathChanged;
  final void Function(String path) onSubmitted;
  final bool Function(String text)? showApplyButton;

  const CustomPathField({
    super.key,
    required this.labelText,
    required this.pathWhenUnchecked,
    required this.customPathWhenChecked,
    required this.isChecked,
    required this.errorMessage,
    required this.onCheckedChanged,
    required this.onPathChanged,
    required this.onSubmitted,
    this.width = 700,
    this.hintText,
    this.checkboxTooltip,
    this.fieldTooltip,
    this.isDirectoryPicker = true,
    this.initialDirectory,
    this.allowedExtensions,
    this.pickerDialogTitle,
    this.showApplyButton,
  });

  @override
  ConsumerState<CustomPathField> createState() => _CustomPathFieldState();
}

class _CustomPathFieldState extends ConsumerState<CustomPathField> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;
  String? _manuallyEnteredPath;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: widget.isChecked
          ? widget.customPathWhenChecked
          : widget.pathWhenUnchecked,
    );
    _focusNode = FocusNode();
    // _manuallyEnteredPath = widget.customPathWhenChecked;

    // Listen for focus changes to auto-submit when user navigates away
    // _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(CustomPathField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isChecked != oldWidget.isChecked) {
      if (widget.isChecked) {
        if (_manuallyEnteredPath != null) {
          _textController.text = _manuallyEnteredPath!;
        } else {
          _textController.text =
              widget.customPathWhenChecked ?? widget.pathWhenUnchecked;
        }
      } else {
        _textController.text = widget.pathWhenUnchecked;
      }

      widget.onPathChanged(_textController.text);
    }
  }

  void _submitIfChanged() {
    final currentText = _textController.text;
    // if (currentText != _lastSubmittedValue)
    widget.onSubmitted(currentText);
    // }
  }

  @override
  Widget build(BuildContext context) {
    final showApplyButton =
        (widget.showApplyButton?.call(_textController.text) == true) ||
        (widget.isChecked &&
            _textController.text.toFile().normalize.path !=
                widget.customPathWhenChecked?.toFile().normalize.path);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: widget.width),
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
              SizedBox(width: 4),
              Disable(
                isEnabled: widget.isChecked,
                child: IconButton(
                  icon: const Icon(Icons.folder),
                  onPressed: _handlePickPath,
                ),
              ),
            ],
          ),
        ),
        if (showApplyButton)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: TextButton.icon(
              label: const Text("Apply"),
              icon: const Icon(Icons.check),
              onPressed: () => widget.onSubmitted(_textController.text),
            ),
          ),
        if (showApplyButton)
          MovingTooltipWidget.text(
            message: "Discard change",
            child: IconButton(
              icon: Icon(
                Icons.undo,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              onPressed: () =>
                  widget.onSubmitted(widget.customPathWhenChecked ?? ""),
            ),
          ),
      ],
    );
  }

  Widget _buildCheckbox() {
    return Checkbox(
      value: widget.isChecked,
      onChanged: (value) {
        widget.onCheckedChanged(value ?? false);
      },
    );
  }

  Widget _buildTextField() {
    return Disable(
      isEnabled: widget.isChecked,
      child: TextField(
        controller: _textController,
        focusNode: _focusNode,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          isDense: true,
          errorText: widget.isChecked && widget.errorMessage != null
              ? widget.errorMessage
              : null,
          labelText: widget.labelText,
          hintText: widget.hintText,
          hintStyle: Theme.of(context).textTheme.labelLarge,
          labelStyle: Theme.of(context).textTheme.labelLarge,
        ),
        onChanged: (newPath) {
          widget.onPathChanged(newPath);
          if (widget.isChecked) {
            _manuallyEnteredPath = newPath;
          }
        },
        onSubmitted: (value) {
          _submitIfChanged();
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
      widget.onPathChanged(newPath);
      widget.onSubmitted(newPath);
    }
  }

  @override
  void dispose() {
    // _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _textController.dispose();
    super.dispose();
  }
}
