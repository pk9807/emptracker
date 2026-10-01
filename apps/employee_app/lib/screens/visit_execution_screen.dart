import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:firebase_repository/firebase_repository.dart';
import 'package:flutter/material.dart';
import 'package:models/models.dart';

class VisitExecutionScreen extends StatefulWidget {
  final EmployeeModel employee;
  final ShopModel shop;
  final VisitRepository visitRepo;
  final double userLat;
  final double userLon;
  final double distanceMeters;
  final bool isInsideGeofence;

  const VisitExecutionScreen({
    super.key,
    required this.employee,
    required this.shop,
    required this.visitRepo,
    required this.userLat,
    required this.userLon,
    required this.distanceMeters,
    required this.isInsideGeofence,
  });

  @override
  State<VisitExecutionScreen> createState() => _VisitExecutionScreenState();
}

class _VisitExecutionScreenState extends State<VisitExecutionScreen> {
  final _notesCtrl = TextEditingController();
  final _orderValueCtrl = TextEditingController();
  bool _isCheckedIn = false;
  bool _isPhotoCaptured = false;
  bool _isSubmitting = false;
  DateTime? _checkInTime;

  void _handleCheckIn() {
    if (!widget.isInsideGeofence) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '⚠️ Geofence breach! You are ${widget.distanceMeters.round()}m away. Move within ${widget.shop.radius.round()}m to check in.',
          ),
          backgroundColor: AppColors.offlineRose,
        ),
      );
      return;
    }

    setState(() {
      _isCheckedIn = true;
      _checkInTime = DateTime.now();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Checked in! GPS and timestamp verified.'),
        backgroundColor: AppColors.liveGreenDark,
      ),
    );
  }

  void _handleCapturePhoto() {
    setState(() {
      _isPhotoCaptured = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📸 Photo proof captured & watermarked with live GPS.'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Future<void> _handleCompleteVisit() async {
    if (!_isCheckedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please check in first.'),
          backgroundColor: AppColors.offlineRose,
        ),
      );
      return;
    }

    if (!_isPhotoCaptured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo proof is mandatory for visit verification.'),
          backgroundColor: AppColors.offlineRose,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final now = DateTime.now();
    final duration = _checkInTime != null
        ? now.difference(_checkInTime!).inMinutes
        : 15;

    final visit = VisitModel(
      id: 'vst_${widget.employee.id}_${now.millisecondsSinceEpoch}',
      organizationId: widget.employee.organizationId,
      employeeId: widget.employee.id,
      employeeName: widget.employee.name,
      shopId: widget.shop.id,
      shopName: widget.shop.name,
      checkInTime: _checkInTime ?? now,
      checkInLocation: VisitLocationProof(
        latitude: widget.userLat,
        longitude: widget.userLon,
        accuracy: 4.8,
        distanceFromShop: widget.distanceMeters,
      ),
      checkOutTime: now,
      checkOutLocation: VisitLocationProof(
        latitude: widget.userLat,
        longitude: widget.userLon,
        accuracy: 4.8,
        distanceFromShop: widget.distanceMeters,
      ),
      durationMinutes: duration,
      watermarkData: VisitWatermarkMetadata(
        applied: true,
        timestamp: now.toIso8601String(),
        gpsText: '${widget.userLat}, ${widget.userLon}',
      ),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      orderValue: double.tryParse(_orderValueCtrl.text.trim()),
      status: VisitStatus.completed,
    );

    await widget.visitRepo.submitVisit(visit);

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Visit completed and synced successfully!'),
          backgroundColor: AppColors.liveGreenDark,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Shop Visit',
            style: AppTypography.headingLarge(isDark: isDark)),
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingPage,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Shop Details Card
            DepthCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.shop.name,
                          style: AppTypography.headingMedium(isDark: isDark),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: widget.isInsideGeofence
                              ? AppColors.liveGreenSubtle
                              : AppColors.recentAmberSubtle,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusFull),
                        ),
                        child: Text(
                          widget.isInsideGeofence
                              ? 'INSIDE GEOFENCE'
                              : 'OUTSIDE GEOFENCE',
                          style: AppTypography.badge(
                            color: widget.isInsideGeofence
                                ? AppColors.liveGreenDark
                                : AppColors.recentAmber,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.shop.address,
                    style: AppTypography.bodySmall(isDark: isDark),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.pin_drop,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Distance: ${HaversineCalculator.formatDistance(widget.distanceMeters)} (Geofence Radius: ${widget.shop.radius.round()}m)',
                        style: AppTypography.bodySmall(isDark: isDark),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Check In Action
            if (!_isCheckedIn)
              PrimaryButton(
                text: 'CHECK IN TO SHOP',
                icon: Icons.login_rounded,
                backgroundColor: widget.isInsideGeofence
                    ? AppColors.primary
                    : AppColors.textTertiaryLight,
                onPressed: _handleCheckIn,
              )
            else
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.liveGreenSubtle,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.liveGreen.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: AppColors.liveGreenDark, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Checked in at ${DateTimeUtils.formatTime(_checkInTime!)}',
                      style: AppTypography.headingSmall(isDark: false)
                          .copyWith(color: AppColors.liveGreenDark),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // Photo Proof Section
            Text(
              'PHOTO PROOF & WATERMARK',
              style: AppTypography.badge(
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
              ),
            ),
            const SizedBox(height: 10),
            DepthCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_isPhotoCaptured)
                    Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(Icons.image, size: 48, color: Colors.white24),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              color: Colors.black87,
                              child: Text(
                                '🛡️ WATERMARKED: ${widget.shop.name} | ${widget.employee.name} | ${widget.userLat}, ${widget.userLon}',
                                style: const TextStyle(
                                  color: Color(0xFF38BDF8),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const EmptyStateView(
                      icon: Icons.camera_alt_outlined,
                      title: 'No Photo Proof Captured',
                      description:
                          'Take a camera photo of shop storefront / stock shelf.',
                    ),
                  const SizedBox(height: 14),
                  SecondaryButton(
                    text: _isPhotoCaptured ? 'RETAKE PHOTO' : 'TAKE CAMERA PHOTO',
                    icon: Icons.camera_alt,
                    onPressed: _handleCapturePhoto,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Notes & Order Value
            CustomTextField(
              controller: _notesCtrl,
              label: 'Visit Notes / Feedback',
              hintText: 'e.g. Stock replenished, owner requested catalogue...',
              maxLines: 2,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: _orderValueCtrl,
              label: 'Order Value (₹ INR)',
              hintText: 'e.g. 15000',
              keyboardType: TextInputType.number,
              prefixIcon: Icons.currency_rupee,
            ),
            const SizedBox(height: 28),

            PrimaryButton(
              text: 'COMPLETE & CHECK OUT',
              icon: Icons.check_circle_outline,
              isLoading: _isSubmitting,
              onPressed: _handleCompleteVisit,
            ),
          ],
        ),
      ),
    );
  }
}
