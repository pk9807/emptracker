import 'dart:async';
import 'dart:ui' as ui;
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/map_marker_item.dart';

/// High-Performance Dynamic Canvas Bitmap Renderer for Google Maps
/// Creates custom, retina-crisp markers with user initials, status halos,
/// badges, and shop store icons matching the OpenStreetMap aesthetic.
class GoogleMapMarkerRenderer {
  static final Map<String, BitmapDescriptor> _cache = {};

  /// Pre-clear cache if needed
  static void clearCache() {
    _cache.clear();
  }

  /// Create custom bitmap descriptor for a given MapMarkerItem
  static Future<BitmapDescriptor> getCustomMarker({
    required MapMarkerItem item,
    required bool isSelected,
    bool isDark = false,
  }) async {
    final statusName = item.liveStatus?.name ?? 'idle';
    final cacheKey =
        '${item.id}_${item.type.name}_${statusName}_${isSelected ? '1' : '0'}_${isDark ? 'd' : 'l'}_${item.title}';

    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      final descriptor = await _drawMarker(
        item: item,
        isSelected: isSelected,
        isDark: isDark,
      );
      _cache[cacheKey] = descriptor;
      return descriptor;
    } catch (_) {
      // Fallback to default marker if canvas generation fails
      return item.type == MarkerType.employee
          ? (item.liveStatus == TrackingLiveStatus.live
              ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
              : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow))
          : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
    }
  }

  static Future<BitmapDescriptor> _drawMarker({
    required MapMarkerItem item,
    required bool isSelected,
    required bool isDark,
  }) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);

    const double size = 160.0;
    const double centerX = size / 2;
    const double centerY = size / 2 - 12;

    final isEmployee = item.type == MarkerType.employee;
    final isLive = item.liveStatus == TrackingLiveStatus.live;

    // 1. Draw Drop Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(const Offset(centerX, centerY + 6), 44, shadowPaint);

    // 2. Draw Outer Halo / Radar Ring
    final haloColor = isEmployee
        ? (isLive ? const Color(0xFF10B981) : const Color(0xFFF59E0B))
        : const Color(0xFF6366F1);

    final haloPaint = Paint()
      ..color = haloColor.withValues(alpha: isSelected ? 0.45 : 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(centerX, centerY), isSelected ? 52 : 44, haloPaint);

    final ringPaint = Paint()
      ..color = haloColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 4.0 : 3.0;
    canvas.drawCircle(const Offset(centerX, centerY), isSelected ? 44 : 36, ringPaint);

    // 3. Draw Background Circle Pill
    final bgPaint = Paint()
      ..color = isDark ? const Color(0xFF1E293B) : Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(centerX, centerY), isSelected ? 38 : 32, bgPaint);

    // 4. Draw Center Icon or Initials
    if (isEmployee) {
      // Draw Initials
      final initials = _getInitials(item.title);
      final textPainter = TextPainter(
        text: TextSpan(
          text: initials,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontSize: isSelected ? 22 : 18,
            fontWeight: FontWeight.w800,
            fontFamily: 'Roboto',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(centerX - textPainter.width / 2, centerY - textPainter.height / 2),
      );

      // Draw Live / Online status indicator dot
      final statusDotPaint = Paint()
        ..color = isLive ? const Color(0xFF10B981) : const Color(0xFFF59E0B)
        ..style = PaintingStyle.fill;
      final statusStrokePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;

      const dotOffset = Offset(centerX + 24, centerY - 24);
      canvas.drawCircle(dotOffset, 8, statusDotPaint);
      canvas.drawCircle(dotOffset, 8, statusStrokePaint);
    } else {
      // Draw Store Front Icon / S
      final iconPainter = TextPainter(
        text: const TextSpan(
          text: '🏪',
          style: TextStyle(fontSize: 26),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      iconPainter.paint(
        canvas,
        Offset(centerX - iconPainter.width / 2, centerY - iconPainter.height / 2),
      );
    }

    // 5. Draw Title Label Bubble below Marker
    final titleText = item.title.length > 14 ? '${item.title.substring(0, 12)}..' : item.title;
    final labelPainter = TextPainter(
      text: TextSpan(
        text: titleText,
        style: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF0F172A),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final labelBgRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: const Offset(centerX, centerY + 50),
        width: labelPainter.width + 18,
        height: labelPainter.height + 8,
      ),
      const Radius.circular(10),
    );

    final labelBgPaint = Paint()
      ..color = (isDark ? const Color(0xFF0F172A) : Colors.white).withValues(alpha: 0.92)
      ..style = PaintingStyle.fill;
    final labelStrokePaint = Paint()
      ..color = haloColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRRect(labelBgRect, labelBgPaint);
    canvas.drawRRect(labelBgRect, labelStrokePaint);
    labelPainter.paint(
      canvas,
      Offset(centerX - labelPainter.width / 2, centerY + 50 - labelPainter.height / 2),
    );

    // 6. Finalize Image
    final picture = pictureRecorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt() + 10);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      return BitmapDescriptor.defaultMarker;
    }

    return BitmapDescriptor.bytes(byteData.buffer.asUint8List());
  }

  /// Create Search Point Pin
  static Future<BitmapDescriptor> getSearchPin() async {
    const cacheKey = 'search_pin_marker';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;

    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    const double size = 120.0;
    const double centerX = 60.0;
    const double centerY = 50.0;

    final haloPaint = Paint()
      ..color = const Color(0xFFEF4444).withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(centerX, centerY), 36, haloPaint);

    final pinPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(centerX, centerY), 24, pinPaint);

    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(centerX, centerY), 9, innerPaint);

    final picture = pictureRecorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    final descriptor = byteData != null
        ? BitmapDescriptor.bytes(byteData.buffer.asUint8List())
        : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);

    _cache[cacheKey] = descriptor;
    return descriptor;
  }

  static String _getInitials(String name) {
    if (name.trim().isEmpty) return 'EM';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}
