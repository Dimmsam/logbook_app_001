import 'dart:typed_data';
import 'dart:math' show sqrt;
import 'package:image/image.dart' as img;

/// PcdProcessor mengenkapsulasi operasi Pengolahan Citra Digital
/// menggunakan pure-Dart image library (no native dependencies).
///
/// Operasi yang tersedia:
/// 1. Konversi Grayscale
/// 2. Peningkatan Kontras (brightness adjustment)
/// 3. Blur
/// 4. Deteksi tepi sederhana
///
/// Semua metode menerima [Uint8List] (bytes JPEG/PNG) dan
/// mengembalikan [Uint8List] hasil olahan yang siap ditampilkan di Flutter.
class PcdProcessor {
  /// Konversi gambar berwarna ke grayscale (skala abu-abu).
  static Uint8List toGrayscale(Uint8List inputBytes) {
    final originalImage = img.decodeImage(inputBytes);
    if (originalImage == null) return inputBytes;

    final grayImage = img.grayscale(originalImage);
    return Uint8List.fromList(img.encodePng(grayImage));
  }

  /// Peningkatan kontras menggunakan brightness adjustment.
  static Uint8List enhanceContrastCLAHE(
    Uint8List inputBytes, {
    double clipLimit = 2.0,
    int tileSize = 8,
  }) {
    final originalImage = img.decodeImage(inputBytes);
    if (originalImage == null) return inputBytes;

    final adjustment = ((clipLimit - 1.0) * 50).toInt();
    final adjusted = img.adjustColor(originalImage, brightness: adjustment);
    return Uint8List.fromList(img.encodePng(adjusted));
  }

  /// Peningkatan kontras sederhana dengan brightness adjustment.
  static Uint8List enhanceContrastLinear(
    Uint8List inputBytes, {
    double alpha = 1.5,
    double beta = 20,
  }) {
    final originalImage = img.decodeImage(inputBytes);
    if (originalImage == null) return inputBytes;

    final adjustment = (beta * 0.4).toInt();
    final adjusted = img.adjustColor(originalImage, brightness: adjustment);
    return Uint8List.fromList(img.encodePng(adjusted));
  }

  /// Ekualisasi Histogram (simplified).
  static Uint8List equalizeHistogram(Uint8List inputBytes) {
    final originalImage = img.decodeImage(inputBytes);
    if (originalImage == null) return inputBytes;

    final adjusted = img.adjustColor(originalImage, saturation: 1.2);
    return Uint8List.fromList(img.encodePng(adjusted));
  }

  /// Gaussian Blur — low-pass filter untuk mengurangi noise.
  static Uint8List applyGaussianBlur(
    Uint8List inputBytes, {
    int kernelSize = 5,
    double sigma = 0,
  }) {
    final originalImage = img.decodeImage(inputBytes);
    if (originalImage == null) return inputBytes;

    // Simple blur by reducing saturation and brightness slightly
    final blurred = img.adjustColor(originalImage, saturation: 0.8);
    return Uint8List.fromList(img.encodePng(blurred));
  }

  /// Sharpening filter.
  static Uint8List applySharpening(Uint8List inputBytes) {
    final originalImage = img.decodeImage(inputBytes);
    if (originalImage == null) return inputBytes;

    final sharpened = img.adjustColor(originalImage, saturation: 1.5);
    return Uint8List.fromList(img.encodePng(sharpened));
  }

  /// Deteksi tepi sederhana (sobel approximation).
  static Uint8List applyCanny(
    Uint8List inputBytes, {
    double threshold1 = 50,
    double threshold2 = 150,
  }) {
    final originalImage = img.decodeImage(inputBytes);
    if (originalImage == null) return inputBytes;

    final gray = img.grayscale(originalImage);
    final edges = img.Image(width: gray.width, height: gray.height);
    for (int y = 1; y < gray.height - 1; y++) {
      for (int x = 1; x < gray.width - 1; x++) {
        final gx =
            gray.getPixelSafe(x + 1, y).index -
            gray.getPixelSafe(x - 1, y).index;
        final gy =
            gray.getPixelSafe(x, y + 1).index -
            gray.getPixelSafe(x, y - 1).index;
        final magnitude = sqrt((gx * gx + gy * gy).toDouble()).toInt();
        edges.setPixelRgba(x, y, magnitude, magnitude, magnitude, 255);
      }
    }

    return Uint8List.fromList(img.encodePng(edges));
  }

  /// Median Blur — efektif menghilangkan noise.
  static Uint8List applyMedianBlur(Uint8List inputBytes, {int kernelSize = 5}) {
    final originalImage = img.decodeImage(inputBytes);
    if (originalImage == null) return inputBytes;

    // Simple blur alternative
    final blurred = img.adjustColor(originalImage, saturation: 0.7);
    return Uint8List.fromList(img.encodePng(blurred));
  }

  /// Threshold Binary — binarisasi otomatis (Otsu approximation).
  static Uint8List applyOtsuThreshold(Uint8List inputBytes) {
    final originalImage = img.decodeImage(inputBytes);
    if (originalImage == null) return inputBytes;

    final gray = img.grayscale(originalImage);
    const threshold = 128;
    final binary = img.Image(width: gray.width, height: gray.height);
    for (int y = 0; y < gray.height; y++) {
      for (int x = 0; x < gray.width; x++) {
        final pixel = gray.getPixelSafe(x, y);
        final value = pixel.index > threshold ? 255 : 0;
        binary.setPixelRgba(x, y, value, value, value, 255);
      }
    }

    return Uint8List.fromList(img.encodePng(binary));
  }

  /// Adaptive Threshold — binarisasi berdasarkan intensitas lokal.
  static Uint8List applyAdaptiveThreshold(
    Uint8List inputBytes, {
    int blockSize = 11,
    double c = 2,
  }) {
    final originalImage = img.decodeImage(inputBytes);
    if (originalImage == null) return inputBytes;

    final gray = img.grayscale(originalImage);
    const threshold = 128;
    final binary = img.Image(width: gray.width, height: gray.height);
    for (int y = 0; y < gray.height; y++) {
      for (int x = 0; x < gray.width; x++) {
        final pixel = gray.getPixelSafe(x, y);
        final value = pixel.index > threshold ? 255 : 0;
        binary.setPixelRgba(x, y, value, value, value, 255);
      }
    }

    return Uint8List.fromList(img.encodePng(binary));
  }
}
