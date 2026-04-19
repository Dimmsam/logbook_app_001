import 'package:flutter/material.dart';

/// Data Transfer Object (DTO) untuk hasil deteksi kerusakan jalan
///
/// Konsep (Langkah 4.1 Pengayaan):
/// - Memisahkan logika deteksi dari UI rendering (Single Responsibility Principle)
/// - Menyimpan koordinat, label, dan confidence score dari model AI
/// - Digunakan oleh DamagePainter untuk menggambar bounding box
class DetectionResult {
  /// Koordinat bounding box dalam ruang normalitas (0.0 - 1.0)
  /// Sebagai contoh: box.left = 0.2 berarti 20% dari lebar layar
  final Rect box;

  /// Label tipe kerusakan sesuai dataset RDD-2022 (D00, D20, D40, D44, D50)
  /// Contoh: "D40" = Pothole, "D20" = Crack, dll
  final String label;

  /// Persentase keyakinan AI (0.0 - 1.0)
  /// Contoh: 0.92 = 92% confidence
  final double score;

  DetectionResult({
    required this.box,
    required this.label,
    required this.score,
  });

  /// Metode helper untuk scaling koordinat ke ruang fisik (pixels)
  ///
  /// Input: size = ukuran layar HP (Logical Pixels)
  /// Output: Rect dengan koordinat dalam pixels yang siap digambar
  Rect getScaledRect(Size canvasSize) {
    return Rect.fromLTWH(
      box.left * canvasSize.width,
      box.top * canvasSize.height,
      box.width * canvasSize.width,
      box.height * canvasSize.height,
    );
  }

  @override
  String toString() => 'DetectionResult(label: $label, score: $score)';
}
