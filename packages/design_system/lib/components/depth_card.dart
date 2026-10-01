import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';

class DepthCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? color;
  final VoidCallback? onTap;
  final Border? border;
  final List<BoxShadow>? customShadow;

  const DepthCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = AppSpacing.radiusLg,
    this.color,
    this.onTap,
    this.border,
    this.customShadow,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final defaultBorderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    Widget content = Container(
      padding: padding ?? AppSpacing.paddingCard,
      decoration: BoxDecoration(
        color: color ?? defaultBg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ?? Border.all(color: defaultBorderColor, width: 1.0),
        boxShadow: customShadow ??
            [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.4)
                    : const Color(0xFF64748B).withOpacity(0.08),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.2)
                    : const Color(0xFF64748B).withOpacity(0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onTap,
          child: content,
        ),
      );
    }

    return content;
  }
}
