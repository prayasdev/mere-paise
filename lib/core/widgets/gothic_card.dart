import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Solid, architectural container with 1px hairline border and 3px radius.
/// Automatically adapts background and border between Obsidian (dark) and Vellum (light).
class GothicCard extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final Color? borderColor;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;

  const GothicCard({
    super.key,
    required this.child,
    this.backgroundColor,
    this.borderColor,
    this.padding = const EdgeInsets.all(14),
    this.margin = EdgeInsets.zero,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = backgroundColor ?? (isDark ? AppColors.crypt : AppColors.vellumCrypt);
    final border = borderColor ?? (isDark ? AppColors.ironLine : AppColors.vellumIronLine);

    final widget = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: border, width: 1),
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(3),
        child: widget,
      );
    }
    return widget;
  }
}
