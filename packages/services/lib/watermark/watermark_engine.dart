import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WatermarkEngine {
  /// Renders a dynamic legal verification watermark overlay directly onto an image byte buffer using Flutter Canvas.
  static Future<Uint8List> applyWatermark({
    required Uint8List originalBytes,
    required String employeeName,
    required String employeeCode,
    required String shopName,
    required double latitude,
    required double longitude,
    required double accuracy,
    required DateTime timestamp,
    String appTitle = 'FIELDFORCE PRO - VISIT VERIFICATION PROOF',
  }) async {
    final codec = await ui.instantiateImageCodec(originalBytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final width = image.width.toDouble();
    final height = image.height.toDouble();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, height));

    // 1. Draw original base image
    canvas.drawImage(image, Offset.zero, Paint());

    // 2. Draw watermark bottom overlay card
    final bannerHeight = height * 0.22;
    final bannerRect = Rect.fromLTWH(0, height - bannerHeight, width, bannerHeight);

    final bannerPaint = Paint()
      ..color = const Color(0xCC0B0F19) // 80% opacity dark slate
      ..style = PaintingStyle.fill;
    canvas.drawRect(bannerRect, bannerPaint);

    // Draw top accent border on banner
    final borderPaint = Paint()
      ..color = const Color(0xFF2563EB) // Electric Indigo
      ..strokeWidth = height * 0.006
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(0, height - bannerHeight),
      Offset(width, height - bannerHeight),
      borderPaint,
    );

    // 3. Compose structured text lines
    final formattedTime = DateFormat('dd MMM yyyy, hh:mm:ss a').format(timestamp);
    final gpsCoords =
        'GPS: ${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)} (±${accuracy.toStringAsFixed(1)}m)';

    final scaleFactor = width / 1000.0;
    final titleFontSize = 18.0 * scaleFactor;
    final bodyFontSize = 15.0 * scaleFactor;
    final metaFontSize = 13.0 * scaleFactor;

    double currentY = height - bannerHeight + (16.0 * scaleFactor);
    final leftMargin = 20.0 * scaleFactor;

    // Line 1: Header
    _drawText(
      canvas: canvas,
      text: '🛡️ $appTitle',
      offset: Offset(leftMargin, currentY),
      fontSize: titleFontSize,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF38BDF8), // Cyan Accent
    );
    currentY += titleFontSize * 1.5;

    // Line 2: Shop & Employee
    _drawText(
      canvas: canvas,
      text: '📍 Shop: $shopName   |   👤 Employee: $employeeName ($employeeCode)',
      offset: Offset(leftMargin, currentY),
      fontSize: bodyFontSize,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    );
    currentY += bodyFontSize * 1.4;

    // Line 3: Timestamp & Live Coords
    _drawText(
      canvas: canvas,
      text: '🕒 Time: $formattedTime   |   🌐 $gpsCoords',
      offset: Offset(leftMargin, currentY),
      fontSize: metaFontSize,
      fontWeight: FontWeight.w500,
      color: const Color(0xFFE2E8F0),
    );

    // 4. Export as PNG bytes
    final picture = recorder.endRecording();
    final watermarkedImage =
        await picture.toImage(image.width, image.height);
    final byteData =
        await watermarkedImage.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  static void _drawText({
    required Canvas canvas,
    required String text,
    required Offset offset,
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
  }) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        fontFamily: 'Roboto',
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, offset);
  }
}
