import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class MethodBadge extends StatelessWidget {
  final String method;
  final double fontSize;
  final EdgeInsetsGeometry? padding;

  const MethodBadge({
    super.key,
    required this.method,
    this.fontSize = 11,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.methodColor(method);
    return Container(
      padding: padding ??
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(100), width: 0.5),
      ),
      child: Text(
        method.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          fontFamily: 'RobotoMono',
        ),
      ),
    );
  }
}

class StatusCodeBadge extends StatelessWidget {
  final int statusCode;
  final double fontSize;

  const StatusCodeBadge({
    super.key,
    required this.statusCode,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.statusColor(statusCode);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(100), width: 0.5),
      ),
      child: Text(
        statusCode.toString(),
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          fontFamily: 'RobotoMono',
        ),
      ),
    );
  }
}
