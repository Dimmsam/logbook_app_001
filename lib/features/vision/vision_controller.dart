import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'detection_result.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// PCD Operations: Enum untuk pilihan operasi Pengolahan Citra Digital
enum PcdOperation {
  grayscale,
  contrastClahe,
  contrastLinear,
  equalizeHistogram,
  gaussianBlur,
  sharpen,
  canny,
  medianBlur,
  otsuThreshold,
  adaptiveThreshold,
}

extension PcdOperationLabel on PcdOperation {
  String get label {
    switch (this) {
      case PcdOperation.grayscale:
        return 'Grayscale';
      case PcdOperation.contrastClahe:
        return 'Kontras CLAHE';
      case PcdOperation.contrastLinear:
        return 'Kontras Linear';
      case PcdOperation.equalizeHistogram:
        return 'Ekualisasi Histogram';
      case PcdOperation.gaussianBlur:
        return 'Gaussian Blur';
      case PcdOperation.sharpen:
        return 'Sharpening';
      case PcdOperation.canny:
        return 'Deteksi Tepi (Canny)';
      case PcdOperation.medianBlur:
        return 'Median Blur';
      case PcdOperation.otsuThreshold:
        return 'Threshold Otsu';
      case PcdOperation.adaptiveThreshold:
        return 'Adaptive Threshold';
    }
  }

  IconData get icon {
    switch (this) {
      case PcdOperation.grayscale:
        return Icons.filter_b_and_w;
      case PcdOperation.contrastClahe:
      case PcdOperation.contrastLinear:
        return Icons.contrast;
      case PcdOperation.equalizeHistogram:
        return Icons.bar_chart;
      case PcdOperation.gaussianBlur:
      case PcdOperation.medianBlur:
        return Icons.blur_on;
      case PcdOperation.sharpen:
        return Icons.auto_fix_high;
      case PcdOperation.canny:
        return Icons.details;
      case PcdOperation.otsuThreshold:
      case PcdOperation.adaptiveThreshold:
        return Icons.tonality;
    }
  }
}

/// VisionController - Pengendali Pusat untuk Sistem Penglihatan Aplikasi
///
/// Now integrated with PCD (Photo/Image Processing) capabilities
/// Menggabungkan Detection (Smart-Patrol) + Filter Processing (PCD)
class VisionController extends ChangeNotifier with WidgetsBindingObserver {
  // ── STATE MANAGEMENT ──────────────────────────────────────────────────
  CameraController? controller;
  bool isInitialized = false;
  String? errorMessage;

  // ── DETECTION & PERFORMANCE ───────────────────────────────────────────
  /// List hasil deteksi kerusakan jalan terkini
  List<DetectionResult> currentResults = [];

  /// Flag untuk mencegah buffer-bloat saat AI masih processing
  /// (Prinsip: Frame-per-Second & Performance Budgeting)
  bool isProcessing = false;

  // ── TASK 4: MOCK DETECTION SIMULATION ─────────────────────────────────
  Timer? _mockDetectionTimer;
  final Random _random = Random();

  // ── HOMEWORK: FLASHLIGHT & UI CONTROLS ────────────────────────────────
  /// Flashlight (torch) state
  bool _isFlashlightOn = false;

  bool get isFlashlightOn => _isFlashlightOn;

  // ── CONSTRUCTOR ───────────────────────────────────────────────────────
  VisionController() {
    // Langkah 2.1: Mendaftarkan observer agar bisa memantau status aplikasi
    WidgetsBinding.instance.addObserver(this);
    initCamera();

    // TASK 4: Start mock detection simulation
    _startMockDetectionSimulation();
  }

  // ── INITIALIZATION ───────────────────────────────────────────────────
  /// Langkah 2.2: Inisialisasi kamera belakang dengan resolusi medium
  ///
  /// ResolutionPreset.medium dipilih karena:
  /// - Keseimbangan antara akurasi AI & performa perangkat mobile
  /// - Cukup detail untuk deteksi kerusakan jalan (dataset RDD-2022)
  /// - Tidak membebani GPU/RAM pada perangkat entry-level
  Future<void> initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        errorMessage = "Tidak ada kamera yang terdeteksi pada perangkat.";
        notifyListeners();
        return;
      }

      // Pilih kamera belakang (Index 0)
      controller = CameraController(
        cameras[0],
        ResolutionPreset.medium, // Keseimbangan akurasi AI & performa
        enableAudio: false, // Kita hanya butuh visual untuk deteksi jalan
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller!.initialize();
      isInitialized = true;
      errorMessage = null;
    } catch (e) {
      errorMessage = "Gagal menginisialisasi kamera: $e";
      isInitialized = false;
    }
    notifyListeners();
  }

  // ── TASK 4: MOCK DETECTION SIMULATION ─────────────────────────────────
  /// Mock Detection Logic: Menggerakkan kotak deteksi ke posisi random
  /// setiap 3 detik sebagai simulasi output YOLO
  void _startMockDetectionSimulation() {
    // Cancel existing timer jika ada
    _mockDetectionTimer?.cancel();

    // Start timer yang trigger setiap 3 detik
    _mockDetectionTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _updateMockDetections();
    });
    debugPrint('[Vision] Mock detection simulation started');
  }

  /// Update mock detections dengan posisi random
  /// TASK 4: Scaling Calibration - kotak proporsional terhadap layar width
  void _updateMockDetections() {
    // Simulasi 1-3 deteksi acak
    final detectionCount = _random.nextInt(3) + 1;
    final newResults = <DetectionResult>[];

    for (int i = 0; i < detectionCount; i++) {
      // TASK 4: SCALING CALIBRATION
      // Gunakan normalized coordinates (0.0 - 1.0)
      // Ukuran box proporsional: 15-40% dari screen width
      final boxSize = 0.15 + (_random.nextDouble() * 0.25);

      // Posisi random, tapi hindari edge screen (padding 10%)
      final left = 0.05 + (_random.nextDouble() * (0.9 - boxSize));
      final top = 0.1 + (_random.nextDouble() * (0.8 - boxSize));

      // Tipe kerusakan random dari RDD-2022 dataset
      final damageTypes = ['D00', 'D20', 'D40', 'D44', 'D50'];
      final label = damageTypes[_random.nextInt(damageTypes.length)];

      // Confidence score 70-99%
      final score = 0.7 + (_random.nextDouble() * 0.29);

      newResults.add(
        DetectionResult(
          box: Rect.fromLTWH(left, top, boxSize, boxSize),
          label: label,
          score: score,
        ),
      );
    }

    currentResults = newResults;
    debugPrint(
      '[Vision] Mock detection updated: ${newResults.map((r) => '${r.label}(${(r.score * 100).toStringAsFixed(0)}%)').join(', ')}',
    );
    notifyListeners();
  }

  // ── LIFECYCLE MANAGEMENT ──────────────────────────────────────────────
  /// Langkah 2.3: Manajemen Siklus Hidup (Lifecycle Handling)
  ///
  /// Override didChangeAppLifecycleState untuk:
  /// - Melepaskan resource kamera saat app di-background (inactive)
  /// - Menginisialisasi ulang saat pengguna kembali ke app (resumed)
  /// - Mencegah memory leak dan konsumsi daya berlebihan
  /// - TASK 4: Resource Guard - ensure cleanup
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = controller;

    // Jika controller belum ada atau belum siap, abaikan
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      // Melepaskan resource kamera saat aplikasi tidak terlihat
      cameraController.dispose();
      isInitialized = false;
      notifyListeners();
      debugPrint('[Vision] Kamera di-dispose (app inactive)');
    } else if (state == AppLifecycleState.resumed) {
      // Menginisialisasi ulang saat pengguna kembali ke aplikasi
      debugPrint('[Vision] Re-inisialisasi kamera (app resumed)');
      initCamera();
    }
  }

  // ── AI PROCESSING SIMULATION ──────────────────────────────────────────
  /// Metode untuk update hasil deteksi (akan dipanggil dari model AI)
  ///
  /// Langkah 4.1 Pengayaan: Asynchronous Processing
  /// Simulasi hasil inferensi dari model YOLO (akan diintegrasikan di Module 7)
  void updateDetectionResults(List<DetectionResult> results) {
    currentResults = results;
    isProcessing = false;
    notifyListeners();
  }

  /// Mulai proses deteksi (set flag, notify UI untuk loading)
  void startProcessing() {
    isProcessing = true;
    notifyListeners();
  }

  // ── HOMEWORK: HARDWARE CONTROL ────────────────────────────────────────
  /// Toggle flashlight (torch) pada perangkat
  /// Fitur: Smart Vision Toggle & Flashlight (Hardware Control Practice)
  Future<void> toggleFlashlight() async {
    try {
      final cameraController = controller;
      if (cameraController == null || !cameraController.value.isInitialized) {
        errorMessage = "Kamera belum siap untuk mengaktifkan flashlight";
        notifyListeners();
        return;
      }

      if (_isFlashlightOn) {
        // Matikan flashlight
        await cameraController.setFlashMode(FlashMode.off);
        _isFlashlightOn = false;
        debugPrint('[Vision] Flashlight OFF');
      } else {
        // Nyalakan flashlight
        await cameraController.setFlashMode(FlashMode.torch);
        _isFlashlightOn = true;
        debugPrint('[Vision] Flashlight ON');
      }

      notifyListeners();
    } catch (e) {
      errorMessage = "Gagal mengontrol flashlight: $e";
      debugPrint('[Vision] Flashlight error: $e');
      notifyListeners();
    }
  }

  // ── PCD CAPTURE CAPABILITY (from CameraControllerPCD) ──────────────────
  /// Mengambil foto dari kamera untuk diproses dengan PCD
  /// Mengembalikan [Uint8List] bytes gambar atau null jika gagal
  Future<Uint8List?> captureFrame() async {
    if (controller == null || !controller!.value.isInitialized) {
      errorMessage = 'Kamera belum siap.';
      notifyListeners();
      return null;
    }

    try {
      // Jeda preview sejenak agar frame stabil
      await controller!.pausePreview();
      await Future.delayed(const Duration(milliseconds: 80));

      final XFile xfile = await controller!.takePicture();
      await controller!.resumePreview();

      // Baca bytes dari file yang di-capture
      final bytes = await xfile.readAsBytes();
      debugPrint('[Vision] Captured frame: ${bytes.lengthInBytes} bytes');
      notifyListeners();
      return bytes;
    } catch (e) {
      errorMessage = 'Gagal mengambil gambar: $e';
      debugPrint('[Vision] Capture error: $e');
      notifyListeners();
      return null;
    }
  }

  /// Simpan bytes gambar ke direktori temporary perangkat
  /// Mengembalikan path file yang tersimpan
  Future<String?> saveTempImage(Uint8List bytes, String filename) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes);
      debugPrint('[Vision] Saved temp image: ${file.path}');
      return file.path;
    } catch (e) {
      debugPrint('[Vision] Save temp image error: $e');
      return null;
    }
  }

  // ── CLEANUP ───────────────────────────────────────────────────────────
  /// Langkah 2.4: Cleanup (Dispose)
  ///
  /// Pastikan semua "kabel" diputus saat halaman Vision ditutup
  /// agar tidak ada resource yang bocor ke memory
  /// TASK 4: Resource Guard - proper cleanup
  @override
  void dispose() {
    // TASK 4: Cancel mock detection timer
    _mockDetectionTimer?.cancel();
    debugPrint('[Vision] Mock detection timer cancelled');

    // Homework: Turn off flashlight on dispose
    if (_isFlashlightOn) {
      controller?.setFlashMode(FlashMode.off);
      debugPrint('[Vision] Flashlight turned OFF on dispose');
    }

    // Menghapus observer agar tidak terjadi memory leak
    WidgetsBinding.instance.removeObserver(this);
    controller?.dispose();
    debugPrint('[Vision] VisionController disposed');
    super.dispose();
  }
}
