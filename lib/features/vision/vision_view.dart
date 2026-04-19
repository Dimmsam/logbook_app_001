import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:typed_data';
import 'vision_controller.dart';
import 'damage_painter.dart';
import 'vision_pcd_result_page.dart';
import 'package:logbook_app_001/features/pcd/pcd_processor.dart';

/// VisionView - Integrated Smart-Patrol Detection + PCD Processing
///
/// Menggabungkan:
/// 1. Detection overlay dengan bounding boxes (Smart-Patrol)
/// 2. PCD Filter operations (Grayscale, Blur, Sharpen, dll)
/// 3. Unified camera interface seperti CameraView
/// 4. Result display dengan before/after comparison
class VisionView extends StatefulWidget {
  const VisionView({super.key});

  @override
  State<VisionView> createState() => _VisionViewState();
}

class _VisionViewState extends State<VisionView> {
  late VisionController _visionController;

  // ── UI State ──────────────────────────────────────────────────────────
  bool _showSearchingOverlay = true;

  // ── PCD Operation State ───────────────────────────────────────────────
  PcdOperation _selectedPcdOp = PcdOperation.grayscale;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _visionController = VisionController();
    _visionController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _visionController.dispose();
    super.dispose();
  }

  // ── Toggle Overlay ───────────────────────────────────────────────────
  void _toggleSearchingOverlay() {
    setState(() {
      _showSearchingOverlay = !_showSearchingOverlay;
    });
  }

  // ── Apply PCD Operation ───────────────────────────────────────────────
  Future<void> _captureAndProcess() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    final bytes = await _visionController.captureFrame();

    if (bytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengambil gambar dari kamera.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isProcessing = false);
      return;
    }

    // Apply PCD operation
    Uint8List processed;
    try {
      processed = await _applyPcdOperation(bytes, _selectedPcdOp);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memproses gambar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isProcessing = false);
      return;
    }

    setState(() => _isProcessing = false);

    if (mounted) {
      // Always show result page untuk confirmation (baik LogView maupun LogEditorPage)
      final result = await Navigator.push<Map<String, dynamic>?>(
        context,
        MaterialPageRoute(
          builder: (_) => VisionPcdResultPage(
            original: bytes,
            processed: processed,
            operationLabel: _selectedPcdOp.label,
          ),
        ),
      );

      // User tapped "Gunakan" di VisionPcdResultPage
      if (result != null && mounted) {
        // Return result ke caller (LogView atau LogEditorPage)
        Navigator.pop(context, result);
      }
    }
  }

  /// Apply PCD operation dan return processed bytes
  Future<Uint8List> _applyPcdOperation(Uint8List bytes, PcdOperation op) async {
    return Future(() {
      switch (op) {
        case PcdOperation.grayscale:
          return PcdProcessor.toGrayscale(bytes);
        case PcdOperation.contrastClahe:
          return PcdProcessor.enhanceContrastCLAHE(bytes);
        case PcdOperation.contrastLinear:
          return PcdProcessor.enhanceContrastLinear(bytes);
        case PcdOperation.equalizeHistogram:
          return PcdProcessor.equalizeHistogram(bytes);
        case PcdOperation.gaussianBlur:
          return PcdProcessor.applyGaussianBlur(bytes);
        case PcdOperation.sharpen:
          return PcdProcessor.applySharpening(bytes);
        case PcdOperation.canny:
          return PcdProcessor.applyCanny(bytes);
        case PcdOperation.medianBlur:
          return PcdProcessor.applyMedianBlur(bytes);
        case PcdOperation.otsuThreshold:
          return PcdProcessor.applyOtsuThreshold(bytes);
        case PcdOperation.adaptiveThreshold:
          return PcdProcessor.applyAdaptiveThreshold(bytes);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          'Smart-Patrol Vision',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          // Flashlight toggle
          IconButton(
            icon: Icon(
              _visionController.isFlashlightOn
                  ? Icons.flashlight_on
                  : Icons.flashlight_off,
              color: _visionController.isFlashlightOn
                  ? Colors.yellowAccent
                  : Colors.white,
            ),
            tooltip: 'Toggle Flashlight',
            onPressed: () async {
              await _visionController.toggleFlashlight();
              setState(() {});
            },
          ),
          // Toggle overlay
          IconButton(
            icon: Icon(
              _showSearchingOverlay ? Icons.visibility : Icons.visibility_off,
            ),
            tooltip: 'Toggle Overlay',
            onPressed: _toggleSearchingOverlay,
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _visionController,
        builder: (context, child) {
          if (!_visionController.isInitialized) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 16),
                  const Text(
                    'Menginisialisasi kamera...',
                    style: TextStyle(color: Colors.white70),
                  ),
                  if (_visionController.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        _visionController.errorMessage!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }

          return Column(
            children: [
              // ── Camera Preview (Flex 7) ──────────────────────────────
              Expanded(flex: 7, child: _buildCameraPreview()),

              // ── Controls Panel (Flex 3) - Unified Detection + PCD ─────
              Expanded(flex: 3, child: _buildUnifiedControls()),
            ],
          );
        },
      ),
    );
  }

  /// Build camera preview dengan detection overlay (always visible)
  Widget _buildCameraPreview() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera preview
        SizedBox.expand(child: CameraPreview(_visionController.controller!)),

        // Detection overlay (always visible)
        Positioned.fill(
          child: CustomPaint(
            painter: DamagePainter(
              _visionController.currentResults,
              showSearchingOverlay: _showSearchingOverlay,
            ),
          ),
        ),

        // Processing indicator
        if (_visionController.isProcessing)
          Positioned.fill(child: CustomPaint(painter: LoadingOverlayPainter())),
      ],
    );
  }

  /// Unified Controls Panel - Shows Detection info + PCD filter selector
  Widget _buildUnifiedControls() {
    return Container(
      color: const Color(0xFF1A1A2E),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Detection status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Deteksi: ${_visionController.currentResults.length} kerusakan',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    'Filter: ${_selectedPcdOp.label}',
                    style: TextStyle(color: Colors.grey[400], fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // PCD Filter selector
          const Text(
            'Pilih Operasi PCD',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),

          // Scrollable filter chips
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: PcdOperation.values
                  .map((op) => _buildPcdOperationChip(op))
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Capture button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : _captureAndProcess,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.camera_alt),
              label: Text(
                _isProcessing ? 'Memproses...' : 'Ambil & Proses',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build PCD operation chip
  Widget _buildPcdOperationChip(PcdOperation op) {
    final isSelected = _selectedPcdOp == op;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              op.icon,
              size: 14,
              color: isSelected ? Colors.white : Colors.white60,
            ),
            const SizedBox(width: 4),
            Text(
              op.label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontSize: 12,
              ),
            ),
          ],
        ),
        onSelected: (_) => setState(() => _selectedPcdOp = op),
        selectedColor: const Color(0xFF6366F1),
        backgroundColor: const Color(0xFF2D2D44),
        checkmarkColor: Colors.white,
        side: BorderSide(
          color: isSelected ? const Color(0xFF6366F1) : Colors.white24,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
