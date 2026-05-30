import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:raheeq_main/utils/colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final double height;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackTap;
  final bool hasBackgroundColor;

  final bool centerTitle;
  final bool isStartAligned;

  const CustomAppBar({
    super.key,
    required this.title,
    this.height = 90.0,
    this.subtitle,
    this.leading,
    this.actions,
    this.hasBackgroundColor = false,
    this.showBackButton = false,
    this.onBackTap,
    this.centerTitle = true,
    this.isStartAligned = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget? leadingWidget = leading;
    if (leadingWidget == null && showBackButton) {
      leadingWidget = _buildBackButton(context);
    }

    final hasSubtitle = subtitle != null && subtitle!.isNotEmpty;

    return AppBar(
      toolbarHeight: height,
      centerTitle: isStartAligned ? false : centerTitle,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: hasBackgroundColor
          ? const Color(0x4D91E3FE)
          : Colors.transparent,

      leading: leadingWidget,
      leadingWidth: showBackButton ? 56 : null,
      title: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: isStartAligned
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          if (hasSubtitle) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.headersubtitlecolor,
              ),
            ),
          ],
        ],
      ),
      actions: actions,
      flexibleSpace: Container(color: const Color(0x4D91E3FE)),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
            onPressed: onBackTap ?? () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(90);
}

class CustomSliverAppBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackTap;
  final bool centerTitle;
  final bool isStartAligned;
  final bool pinned;
  final bool floating;
  final double expandedHeight;

  const CustomSliverAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.showBackButton = false,
    this.onBackTap,
    this.centerTitle = true,
    this.isStartAligned = false,
    this.pinned = true,
    this.floating = false,
    this.expandedHeight = 120.0,
  });

  @override
  Widget build(BuildContext context) {
    Widget? leadingWidget = leading;
    if (leadingWidget == null && showBackButton) {
      leadingWidget = _buildBackButton(context);
    }

    final hasSubtitle = subtitle != null && subtitle!.isNotEmpty;

    return SliverAppBar(
      pinned: pinned,
      floating: floating,
      expandedHeight: hasSubtitle ? expandedHeight : 70.0,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      leading: leadingWidget,
      leadingWidth: showBackButton ? 56 : null,
      actions: actions,
      centerTitle: isStartAligned ? false : centerTitle,
      // If there is no subtitle, place the title in standard AppBar title.
      title: !hasSubtitle
          ? Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            )
          : null,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(color: const Color(0x4D91E3FE)),
        title: hasSubtitle
            ? LayoutBuilder(
                builder: (context, constraints) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: isStartAligned
                          ? CrossAxisAlignment.start
                          : CrossAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: AppColors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  );
                },
              )
            : null,
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
            onPressed: onBackTap ?? () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ),
      ),
    );
  }
}
