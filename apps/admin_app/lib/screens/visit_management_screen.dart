import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:firebase_repository/firebase_repository.dart';
import 'package:flutter/material.dart';
import 'package:models/models.dart';

class VisitManagementScreen extends StatefulWidget {
  final String organizationId;
  final VisitRepository visitRepo;

  const VisitManagementScreen({
    super.key,
    required this.organizationId,
    required this.visitRepo,
  });

  @override
  State<VisitManagementScreen> createState() => _VisitManagementScreenState();
}

class _VisitManagementScreenState extends State<VisitManagementScreen> {
  List<VisitModel> _visits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    widget.visitRepo.streamVisits(widget.organizationId).listen((visits) {
      if (mounted) {
        setState(() {
          _visits = visits;
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _visits.isEmpty
              ? const EmptyStateView(
                  icon: Icons.verified_outlined,
                  title: 'No Visits Recorded Today',
                  description: 'Completed employee shop visits with GPS photo proofs will show here.',
                )
              : ListView.separated(
                  padding: AppSpacing.paddingPage,
                  itemCount: _visits.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final visit = _visits[index];

                    return DepthCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                visit.shopName,
                                style: AppTypography.headingSmall(isDark: isDark),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.liveGreenSubtle,
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusFull),
                                ),
                                child: Text(
                                  'VERIFIED (${visit.durationMinutes} min)',
                                  style: AppTypography.badge(
                                      color: AppColors.liveGreenDark),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Field Executive: ${visit.employeeName}',
                            style: AppTypography.bodySmall(isDark: isDark),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.access_time,
                                  size: 14, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(
                                'In: ${DateTimeUtils.formatTime(visit.checkInTime)}'
                                '${visit.checkOutTime != null ? ' | Out: ${DateTimeUtils.formatTime(visit.checkOutTime!)}' : ''}',
                                style: AppTypography.bodySmall(isDark: isDark),
                              ),
                            ],
                          ),
                          if (visit.notes != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.surfaceElevatedDark
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusSm),
                              ),
                              child: Text(
                                '📝 Note: ${visit.notes!}',
                                style: AppTypography.bodySmall(isDark: isDark),
                              ),
                            ),
                          ],
                          if (visit.orderValue != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              '💰 Order Booked: ₹${visit.orderValue!.toStringAsFixed(0)}',
                              style: AppTypography.headingSmall(isDark: isDark)
                                  .copyWith(color: AppColors.liveGreenDark),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
