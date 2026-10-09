import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:models/models.dart';

/// High-Fidelity Google Maps Style Place Details Panel
/// Matching exact Google Maps UI: Hero photo, Dual-language name, 4.8 star rating,
/// 5 circular action buttons (Directions, Save, Nearby, Send to phone, Share),
/// service tags, opening hours, and geofence parameters.
class GooglePlaceDetailsPanel extends StatefulWidget {
  final ShopModel shop;
  final String? hindiTitle;
  final double rating;
  final int reviewsCount;
  final String categoryName;
  final String? heroImageUrl;
  final VoidCallback? onDirectionsTap;
  final VoidCallback? onNearbyTap;
  final VoidCallback? onSendToPhoneTap;
  final VoidCallback? onClose;

  const GooglePlaceDetailsPanel({
    super.key,
    required this.shop,
    this.hindiTitle = 'वर्कआउट जिम & जिम मशीन सप्लायर्स',
    this.rating = 4.8,
    this.reviewsCount = 348,
    this.categoryName = 'Exercise equipment store',
    this.heroImageUrl,
    this.onDirectionsTap,
    this.onNearbyTap,
    this.onSendToPhoneTap,
    this.onClose,
  });

  @override
  State<GooglePlaceDetailsPanel> createState() => _GooglePlaceDetailsPanelState();
}

class _GooglePlaceDetailsPanelState extends State<GooglePlaceDetailsPanel> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleSave() {
    setState(() {
      _isSaved = !_isSaved;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(_isSaved ? Icons.bookmark : Icons.bookmark_border, color: AppColors.liveGreen, size: 20),
            const SizedBox(width: 10),
            Text(_isSaved ? 'Saved to Your Places' : 'Removed from Saved Places'),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _shareLocation() {
    final text = '${widget.shop.name}\n${widget.shop.address}\nhttps://maps.google.com/?q=${widget.shop.latitude},${widget.shop.longitude}';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.liveGreen, size: 20),
            SizedBox(width: 10),
            Text('Shop location link copied to clipboard!'),
          ],
        ),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 400,
      constraints: const BoxConstraints(maxWidth: 420),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Hero Photo Header with Treadmills / Gym Equipment
              Stack(
                children: [
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      image: DecorationImage(
                        image: NetworkImage(
                          widget.heroImageUrl ??
                              'https://images.unsplash.com/photo-1540497077202-7c8a3999166f?q=80&w=800&auto=format&fit=crop',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // Top Gradient & Close Button
                  Positioned(
                    top: 10,
                    right: 10,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.black.withValues(alpha: 0.6),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 16),
                        padding: EdgeInsets.zero,
                        onPressed: widget.onClose,
                      ),
                    ),
                  ),
                ],
              ),

              // 2. Title, Hindi Subtitle & Rating
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.shop.name,
                      style: AppTypography.headingMedium(isDark: isDark).copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 19,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (widget.hindiTitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.hindiTitle!,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    // Rating & Category Row
                    Row(
                      children: [
                        Text(
                          '${widget.rating}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Star icons
                        ...List.generate(
                          5,
                          (i) => const Icon(Icons.star, size: 15, color: Color(0xFFF59E0B)),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '(${widget.reviewsCount})',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '•  ${widget.categoryName}',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 3. Overview | Reviews | About Tab Bar
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                    ),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF2563EB),
                  unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  indicatorColor: const Color(0xFF2563EB),
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Reviews'),
                    Tab(text: 'About'),
                  ],
                ),
              ),

              // 4. 5 Circular Action Buttons (Matching Screenshot Exactly)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildCircularAction(
                      icon: Icons.directions,
                      label: 'Directions',
                      isPrimary: true,
                      onTap: widget.onDirectionsTap,
                    ),
                    _buildCircularAction(
                      icon: _isSaved ? Icons.bookmark : Icons.bookmark_border,
                      label: 'Save',
                      isActive: _isSaved,
                      onTap: _toggleSave,
                    ),
                    _buildCircularAction(
                      icon: Icons.explore_outlined,
                      label: 'Nearby',
                      onTap: widget.onNearbyTap,
                    ),
                    _buildCircularAction(
                      icon: Icons.phone_android_rounded,
                      label: 'Send to phone',
                      onTap: widget.onSendToPhoneTap,
                    ),
                    _buildCircularAction(
                      icon: Icons.share_outlined,
                      label: 'Share',
                      onTap: _shareLocation,
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // 5. Service Attributes Checklist (In-store shopping, Delivery, etc.)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildServiceCheckItem('In-store shopping', isDark),
                    const SizedBox(height: 6),
                    _buildServiceCheckItem('In-store pick-up', isDark),
                    const SizedBox(height: 6),
                    _buildServiceCheckItem('Delivery', isDark),
                  ],
                ),
              ),

              const Divider(height: 1),

              // 6. Address, Hours & Phone Info Rows
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInfoRow(
                      icon: Icons.location_on_outlined,
                      title: widget.shop.address,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.access_time_rounded,
                      title: 'Open • Closes 9:00 PM',
                      subtitle: 'Monday - Sunday (6:00 AM - 9:00 PM)',
                      isDark: isDark,
                    ),
                    if (widget.shop.phone != null) ...[
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        icon: Icons.phone_outlined,
                        title: widget.shop.phone!,
                        isDark: isDark,
                      ),
                    ],
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.shield_outlined,
                      title: 'Geofence Perimeter: ${widget.shop.radius.round()} meters',
                      subtitle: 'Auto-verification active for field staff attendance',
                      isDark: isDark,
                      accentColor: AppColors.liveGreen,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircularAction({
    required IconData icon,
    required String label,
    bool isPrimary = false,
    bool isActive = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isPrimary
                    ? const Color(0xFF007BFF)
                    : (isActive ? const Color(0xFF007BFF).withValues(alpha: 0.15) : const Color(0xFFF1F5F9)),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isPrimary
                      ? const Color(0xFF007BFF)
                      : (isActive ? const Color(0xFF007BFF) : const Color(0xFFCBD5E1)),
                ),
              ),
              child: Icon(
                icon,
                color: isPrimary ? Colors.white : const Color(0xFF007BFF),
                size: 20,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF007BFF),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCheckItem(String label, bool isDark) {
    return Row(
      children: [
        const Icon(Icons.check, size: 16, color: Color(0xFF10B981)),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool isDark,
    Color? accentColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: accentColor ?? (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: accentColor ?? (isDark ? Colors.white : const Color(0xFF0F172A)),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
