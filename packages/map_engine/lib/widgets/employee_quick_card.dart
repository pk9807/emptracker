import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:models/models.dart';

class EmployeeQuickCard extends StatelessWidget {
  final LiveLocationModel location;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onViewRoute;

  const EmployeeQuickCard({
    super.key,
    required this.location,
    this.isSelected = false,
    this.onTap,
    this.onViewRoute,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = location.liveStatus;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 280,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.2)
                  : Colors.black.withOpacity(0.04),
              blurRadius: isSelected ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primarySubtle,
                  child: Text(
                    location.name.isNotEmpty ? location.name[0] : 'E',
                    style: AppTypography.headingSmall(isDark: false).copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        location.name,
                        style: AppTypography.headingSmall(isDark: isDark),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.battery_charging_full,
                            size: 13,
                            color: location.battery > 20
                                ? AppColors.liveGreen
                                : AppColors.offlineRose,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${location.battery}%',
                            style: AppTypography.bodySmall(isDark: isDark),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '±${location.accuracy.round()}m',
                            style: AppTypography.bodySmall(isDark: isDark),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                StatusBadge.fromTrackingStatus(status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateTimeUtils.formatSecondsAgo(location.updatedAt),
                  style: AppTypography.bodySmall(isDark: isDark),
                ),
                if (onViewRoute != null)
                  InkWell(
                    onTap: onViewRoute,
                    child: Row(
                      children: [
                        Text(
                          'Route',
                          style: AppTypography.badge(color: AppColors.primary),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 10,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
