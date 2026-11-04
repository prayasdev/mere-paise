import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class GothicEmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;

  const GothicEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final archColor = isDark ? AppColors.ironLine : AppColors.vellumIronLine;
    final titleColor = isDark ? AppColors.ash : AppColors.vellumAsh;
    final subColor = isDark ? AppColors.ashDark : AppColors.vellumAshDark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomPaint(
              size: const Size(40, 48),
              painter: _GothicArchCrossHatchPainter(color: archColor),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.headingMedium(color: titleColor),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall(color: subColor),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class _GothicArchCrossHatchPainter extends CustomPainter {
  final Color color;
  _GothicArchCrossHatchPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, size.height * 0.4);
    path.quadraticBezierTo(0, 0, size.width * 0.5, 0);
    path.quadraticBezierTo(size.width, 0, size.width, size.height * 0.4);
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, strokePaint);

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..strokeWidth = 0.5;

    for (double i = -size.height; i < size.width + size.height; i += 6) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        fillPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GothicArchCrossHatchPainter oldDelegate) => oldDelegate.color != color;
}
