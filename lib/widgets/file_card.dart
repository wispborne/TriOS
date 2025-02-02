import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/dotted_border.dart';

class DragDropInstallModOverlay extends StatelessWidget {
  final List<FileSystemEntity> entities;
  final List<Uri> urls;

  const DragDropInstallModOverlay({super.key, required this.entities, required this.urls});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ThemeManager.cornerRadius),
      ),
      // color: const Color(0xFF34556D),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DottedBorder(
          color: theme.colorScheme.onSurface.withOpacity(0.5),
          radius: const Radius.circular(ThemeManager.cornerRadius),
          strokeWidth: 3,
          dashPattern: const [12, 8],
          stackFit: StackFit.loose,
          strokeCap: StrokeCap.round,
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.create_new_folder_rounded,
                        size: 64,
                        color: theme.iconTheme.color?.withOpacity(0.9)),
                    const SizedBox(height: 8.0),
                    const Text(
                      'Add to Starsector',
                      style: TextStyle(
                          fontSize: 16.0, fontFamily: ThemeManager.orbitron),
                    ),
                    const SizedBox(height: 16),
                    ...entities.map((entity) {
                      final fileName = p.basename(entity.path);
                      return Column(
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            fileName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          _buildDroppedFileWidget(entity, theme),
                          const SizedBox(height: 8.0),
                        ],
                      );
                    }),
                    ...urls.map((url) {
                      return Column(
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            url.toString(),
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 16.0,
                            ),
                          ),
                          Text("Drop to download",
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontStyle: FontStyle.italic,
                              )),
                          const SizedBox(height: 8.0),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  FutureBuilder<String> _buildDroppedFileWidget(
      FileSystemEntity entity, ThemeData theme) {
    return FutureBuilder<String>(
      future: _getFileOrDirectorySize(entity),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text(
            'Error: ${snapshot.error}',
            style: const TextStyle(color: Colors.red),
          );
        } else {
          return Text(
            snapshot.data ?? "Calculating...",
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 16.0,
            ),
          );
        }
      },
    );
  }

  Future<String> _getFileOrDirectorySize(FileSystemEntity entity) async {
    if (entity.isFile() && entity is File) {
      final bytes = await entity.length();
      return bytes.bytesAsReadableMB();
    } else if (entity.isDirectory()) {
      final bytes = await _getDirectorySize(entity.toDirectory());
      return bytes.bytesAsReadableMB();
    }
    return (-1).bytesAsReadableMB();
  }

  Future<int> _getDirectorySize(Directory directory) async {
    int totalSize = 0;
    await for (final entity
        in directory.list(recursive: true, followLinks: true)) {
      if (entity is File) {
        totalSize += await entity.length();
      }
    }
    return totalSize;
  }
}
