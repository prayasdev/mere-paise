import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Double-rule hairline divider (two 1px lines 3px apart)
/// evoking a traditional bound ledger book.
class GothicDivider extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  final Color? color;
  final bool showArchMotif;

  const GothicDivider({
    super.key,
    this.padding = const EdgeInsets.symmetric(vertical: 12),
    this.color,
    this.showArchMotif = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ruleColor = color ?? (isDark ? AppColors.ironLine : AppColors.vellumIronLine);

    if (!showArchMotif) {
      return Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(height: 1, color: ruleColor),
            const SizedBox(height: 3),
            Container(height: 1, color: ruleColor),
          ],
        ),
      );
    }

    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(height: 1, color: ruleColor),
                const SizedBox(height: 3),
                Container(height: 1, color: ruleColor),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: CustomPaint(
              size: const Size(12, 10),
              painter: _PointedArchPainter(color: ruleColor),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(height: 1, color: ruleColor),
                const SizedBox(height: 3),
                Container(height: 1, color: ruleColor),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PointedArchPainter extends CustomPainter {
  final Color color;

  _PointedArchPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height);
    path.quadraticBezierTo(size.width * 0.25, 0, size.width * 0.5, 0);
    path.quadraticBezierTo(size.width * 0.75, 0, size.width, size.height);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PointedArchPainter oldDelegate) => oldDelegate.color != color;
}
