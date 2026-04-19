import 'package:flutter/material.dart';
import 'detection_result.dart';

/// DamagePainter - Logika Kanvas Grafis untuk Overlay Visual
///
/// Langkah 4: Konstruksi DamagePainter (Digital Overlay Logic)
/// TASK 3: Dynamic Interface Overlay (MOTS)
/// HOMEWORK: Detection Style & Color Branding
///
/// Konsep:
/// - Menggunakan CustomPainter untuk menggambar indikator deteksi
/// - Memisahkan logic penggambaran dari Widget Tree (rendering efficiency)
/// - Menerima list DetectionResult dan mengubahnya menjadi visual cues
/// - BARU (Task 3): Menambahkan crosshair & label di tengah
/// - HOMEWORK: Skema warna dinamis berdasarkan tipe kerusakan RDD-2022
///
/// Tujuan:
/// - Menampilkan bounding box dengan warna sesuai severity level
/// - Menampilkan crosshair + label "Searching for Road Damage..." di tengah
/// - Memberikan panduan visual kepada pengguna saat patroli jalan
/// - Menstandarisasi visualisasi hasil deteksi berdasarkan RDD-2022
class DamagePainter extends CustomPainter {
  // Daftar hasil deteksi yang akan digambar
  final List<DetectionResult> results;

  // Task 3: Flag untuk menampilkan searching overlay
  final bool showSearchingOverlay;

  DamagePainter(this.results, {this.showSearchingOverlay = true});

  // ── HOMEWORK: Color Branding Function ─────────────────────────────────
  /// Tentukan warna kotak berdasarkan tipe kerusakan RDD-2022
  /// Homework Requirement: "Gunakan warna Merah untuk tipe kerusakan berat
  /// dan warna Kuning untuk kerusakan ringan"
  Color _getDetectionColor(String label) {
    switch (label) {
      // Berat (Merah) - Lubang/Polished Stone Aggregate Loss
      case 'D40': // Pothole
      case 'D44': // Polished Stone Aggregate Loss
        return Colors.redAccent;

      // Sedang (Orange) - Retak
      case 'D20': // Longitudinal Crack
      case 'D50': // Transverse Crack
        return Colors.orangeAccent;

      // Ringan (Kuning) - Permukaan normal/minor
      case 'D00': // Asphalt Pavement (normal)
      default:
        return Colors.yellowAccent;
    }
  }

  /// Tentukan severity level berdasarkan tipe kerusakan
  String _getSeverityLabel(String label) {
    switch (label) {
      case 'D40':
      case 'D44':
        return 'BERAT';
      case 'D20':
      case 'D50':
        return 'SEDANG';
      default:
        return 'RINGAN';
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Task 3: STATIC ANCHOR - Gambar crosshair di tengah layar
    if (showSearchingOverlay) {
      _drawSearchingCrosshair(canvas, size);
    }

    // Iterasi setiap hasil deteksi dan gambar
    for (var detection in results) {
      // Langkah 4.2: Logika Penempatan Bounding Box (Anchoring)
      // Scaling koordinat dari ruang normalitas (0.0-1.0) ke ruang fisik
      final rect = detection.getScaledRect(size);

      // HOMEWORK: Color Branding - Tentukan warna berdasarkan tipe kerusakan
      final detectionColor = _getDetectionColor(detection.label);

      // Gambar kotak border dengan warna dinamis
      final boxPaint = Paint()
        ..color = detectionColor
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke;

      canvas.drawRect(rect, boxPaint);

      // HOMEWORK: Tambahkan shadow pada kotak untuk depth effect
      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.3)
        ..strokeWidth = 4.0
        ..style = PaintingStyle.stroke;
      canvas.drawRect(rect.inflate(1), shadowPaint);

      // Langkah 4.3: Rendering Label Intelijen (Text Painting)
      // Format label: "[D40] POTHOLE - 92%"
      final labelText =
          '[${detection.label}] - ${(detection.score * 100).toStringAsFixed(0)}%';
      final severityLabel = _getSeverityLabel(detection.label);

      final textStyle = TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            color: Colors.black87,
            offset: const Offset(1, 1),
            blurRadius: 2,
          ),
        ],
      );

      final textSpan = TextSpan(
        text: ' $labelText [$severityLabel] ',
        style: textStyle,
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );

      // Layout teks sebelum bisa digambar
      textPainter.layout();

      // Tentukan posisi label (di atas kotak, atau di bawah jika tidak fit)
      double labelX = rect.left;
      double labelY = rect.top - 25;

      // Jika label akan keluar dari atas layar, pindahkan ke bawah kotak
      if (labelY < 0) {
        labelY = rect.bottom + 5;
      }

      // Limit label agar tidak keluar dari sisi kanan layar
      if (labelX + textPainter.width > size.width) {
        labelX = size.width - textPainter.width - 5;
      }

      // Konfigurasi untuk background label (semi-transparent, sesuai warna deteksi)
      final labelBackgroundPaint = Paint()
        ..color = detectionColor.withValues(alpha: 0.8)
        ..style = PaintingStyle.fill;

      // Gambar background label (untuk kontras dengan video)
      final labelBackground = Rect.fromLTWH(
        labelX - 2,
        labelY - 2,
        textPainter.width + 4,
        textPainter.height + 4,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(labelBackground, const Radius.circular(4)),
        labelBackgroundPaint,
      );

      // Gambar teks label
      textPainter.paint(canvas, Offset(labelX, labelY));

      // Opsional: Gambar corner indicators untuk emphasis (warna dinamis)
      _drawCornerIndicators(canvas, rect, detectionColor);
    }

    // Jika tidak ada deteksi, gambar placeholder
    if (results.isEmpty && !showSearchingOverlay) {
      _drawIdleState(canvas, size);
    }
  }

  /// TASK 3: STATIC ANCHOR - Crosshair di tengah layar
  /// Ini adalah anchor visual untuk memandu pengguna menempatkan objek
  void _drawSearchingCrosshair(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Paint untuk crosshair (kuning untuk visibility)
    final crosshairPaint = Paint()
      ..color = Colors.yellowAccent
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Paint untuk circle di tengah
    final circlePaint = Paint()
      ..color = Colors.yellowAccent.withValues(alpha: 0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const crosshairSize = 30.0;
    const circleRadius = 50.0;

    // TASK 3: Crosshair lines (rigid positioning di tengah)
    // Vertikal line
    canvas.drawLine(
      Offset(centerX, centerY - crosshairSize),
      Offset(centerX, centerY + crosshairSize),
      crosshairPaint,
    );

    // Horizontal line
    canvas.drawLine(
      Offset(centerX - crosshairSize, centerY),
      Offset(centerX + crosshairSize, centerY),
      crosshairPaint,
    );

    // Center dot
    canvas.drawCircle(
      Offset(centerX, centerY),
      5,
      Paint()..color = Colors.yellowAccent,
    );

    // Outer circle (scanning area)
    canvas.drawCircle(Offset(centerX, centerY), circleRadius, circlePaint);

    // TASK 3: VISION LABEL - "Searching for Road Damage..."
    _drawSearchingLabel(canvas, size, centerX, centerY + circleRadius + 30);
  }

  /// TASK 3: VISION LABEL dengan TextPainter
  /// Label informatif "Searching for Road Damage..."
  void _drawSearchingLabel(Canvas canvas, Size size, double x, double y) {
    const textStyle = TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      shadows: [
        Shadow(color: Colors.black87, offset: Offset(2, 2), blurRadius: 4),
      ],
    );

    final textSpan = const TextSpan(
      text: '◌ Searching for Road Damage...',
      style: textStyle,
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.layout();

    // Center text horizontally, use provided y
    final offset = Offset((size.width - textPainter.width) / 2, y);

    textPainter.paint(canvas, offset);
  }

  /// Gambar indikator sudut pada bounding box untuk emphasis
  /// HOMEWORK: Warna dinamis berdasarkan deteksi
  void _drawCornerIndicators(Canvas canvas, Rect rect, Color color) {
    final cornerPaint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    const cornerLength = 15.0;

    // Top-left corner
    canvas.drawLine(
      Offset(rect.left, rect.top),
      Offset(rect.left + cornerLength, rect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.top),
      Offset(rect.left, rect.top + cornerLength),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(rect.right, rect.top),
      Offset(rect.right - cornerLength, rect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.top),
      Offset(rect.right, rect.top + cornerLength),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(rect.left, rect.bottom),
      Offset(rect.left + cornerLength, rect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.bottom),
      Offset(rect.left, rect.bottom - cornerLength),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(rect.right, rect.bottom),
      Offset(rect.right - cornerLength, rect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.bottom),
      Offset(rect.right, rect.bottom - cornerLength),
      cornerPaint,
    );
  }

  /// Gambar pesan idle state saat belum ada deteksi
  void _drawIdleState(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: const TextSpan(
        text: '○ Arahkan kamera ke jalan untuk deteksi kerusakan',
        style: TextStyle(
          color: Colors.white70,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Posisikan di tengah bawah layar
    textPainter.paint(
      canvas,
      Offset((size.width - textPainter.width) / 2, size.height - 60),
    );
  }

  // Langkah 4.4: Optimasi Repaint Logic
  @override
  bool shouldRepaint(covariant DamagePainter oldDelegate) {
    // Repaint jika list hasil deteksi berubah atau searching flag berubah
    return oldDelegate.results != results ||
        oldDelegate.showSearchingOverlay != showSearchingOverlay;
  }
}

/// Painter khusus untuk menampilkan overlay saat loading/processing
class LoadingOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Semi-transparent dark overlay
    final darkOverlay = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), darkOverlay);

    // Teks "Processing..."
    const textStyle = TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.bold,
    );

    final textPainter = TextPainter(
      text: const TextSpan(text: '⟳ Memproses...', style: textStyle),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
