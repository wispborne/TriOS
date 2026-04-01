import 'package:flutter/material.dart';
import 'package:trios/toolbar/app_action_buttons.dart';
import 'package:trios/toolbar/app_brand_header.dart';
import 'package:trios/toolbar/app_right_toolbar.dart';

/// Thin top bar used in sidebar layout mode.
/// Contains brand header, launcher, action buttons, and right-side status items.
class CompactTopBar extends StatelessWidget implements PreferredSizeWidget {
  final ScrollController scrollController;

  const CompactTopBar({super.key, required this.scrollController});

  @override
  Size get preferredSize => const Size.fromHeight(32);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: preferredSize.height,
      title: Row(
        children: [
          const AppBrandHeader(compact: true),
          Expanded(
            child: Scrollbar(
              controller: scrollController,
              scrollbarOrientation: ScrollbarOrientation.top,
              thickness: 4,
              child: SingleChildScrollView(
                controller: scrollController,
                scrollDirection: Axis.horizontal,
                reverse: true,
                clipBehavior: Clip.antiAlias,
                child: IconButtonTheme(
                  data: IconButtonThemeData(
                    style: IconButton.styleFrom(
                      minimumSize: const Size(20, 20),
                      iconSize: 20,
                    ),
                  ),
                  child: IconTheme(
                    data: IconTheme.of(context).copyWith(size: 18),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const GameFolderButton(),
                        const LogFileButton(),
                        const BugReportButton(),
                        SizedBox(
                          height: preferredSize.height - 16,
                          child: VerticalDivider(
                            color: Theme.of(
                              context,
                            ).dividerColor.withAlpha(100),
                          ),
                        ),
                        FilePermissionShield(),
                        const AdminPermissionShield(),
                        const DonateButton(),
                        const ChangelogButton(),
                        const AboutButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
