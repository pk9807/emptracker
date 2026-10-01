import 'package:core/core.dart';
import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_typography.dart';
import '../tokens/app_spacing.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;
  final bool showDot;

  const StatusBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
    this.showDot = false,
  });

  factory StatusBadge.fromTrackingStatus(TrackingLiveStatus status) {
    switch (status) {
      case TrackingLiveStatus.live:
        return const StatusBadge(
          label: 'LIVE',
          backgroundColor: AppColors.liveGreenSubtle,
          textColor: AppColors.liveGreenDark,
          showDot: true,
        );
      case TrackingLiveStatus.recent:
        return const StatusBadge(
          label: 'RECENT',
          backgroundColor: AppColors.recentAmberSubtle,
          textColor: AppColors.recentAmber,
          showDot: true,
        );
      case TrackingLiveStatus.stale:
        return const StatusBadge(
          label: 'STALE',
          backgroundColor: AppColors.staleOrangeSubtle,
          textColor: AppColors.staleOrange,
          showDot: true,
        );
      case TrackingLiveStatus.offline:
        return const StatusBadge(
          label: 'OFFLINE',
          backgroundColor: AppColors.offlineRoseSubtle,
          textColor: AppColors.offlineRose,
          showDot: false,
        );
    }
  }

  factory StatusBadge.fromDutyStatus(DutyStatus status) {
    switch (status) {
      case DutyStatus.active:
        return const StatusBadge(
          label: 'ON DUTY',
          backgroundColor: AppColors.liveGreenSubtle,
          textColor: AppColors.liveGreenDark,
          icon: Icons.check_circle_outline,
        );
      case DutyStatus.inactive:
        return const StatusBadge(
          label: 'OFF DUTY',
          backgroundColor: Color(0xFFF1F5F9),
          textColor: Color(0xFF64748B),
          icon: Icons.pause_circle_outline,
        );
      case DutyStatus.paused:
        return const StatusBadge(
          label: 'BREAK',
          backgroundColor: AppColors.recentAmberSubtle,
          textColor: AppColors.recentAmber,
          icon: Icons.timer_outlined,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(
          color: textColor.withOpacity(0.2),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: textColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
          ],
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTypography.badge(color: textColor),
          ),
        ],
      ),
    );
  }
}
