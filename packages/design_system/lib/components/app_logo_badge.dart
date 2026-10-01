import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';

class AppLogoBadge extends StatelessWidget {
  final double size;
  final bool showGlow;

  const AppLogoBadge({
    super.key,
    this.size = 80.0,
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: size * 0.35,
                  offset: Offset(0, size * 0.1),
                ),
                BoxShadow(
                  color: AppColors.liveGreen.withOpacity(0.25),
                  blurRadius: size * 0.25,
                  offset: Offset(0, size * 0.05),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.28),
        child: Image.asset(
          'assets/images/logo.png',
          package: 'design_system',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: AppColors.primary,
            child: const Icon(Icons.radar, color: Colors.white, size: 36),
          ),
        ),
      ),
    );
  }
}
