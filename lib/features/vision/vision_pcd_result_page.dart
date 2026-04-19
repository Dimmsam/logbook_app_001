import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Vision PCD Result Page - menampilkan perbandingan gambar asli (detection)
/// dengan gambar hasil olahan PCD secara berdampingan.
/// Adapted from pcd_result_page.dart untukintegración dengan Vision module
class VisionPcdResultPage extends StatefulWidget {
  final Uint8List original;
  final Uint8List processed;
  final String operationLabel;

  const VisionPcdResultPage({
    super.key,
    required this.original,
    required this.processed,
    required this.operationLabel,
  });

  @override
  State<VisionPcdResultPage> createState() => _VisionPcdResultPageState();
}

class _VisionPcdResultPageState extends State<VisionPcdResultPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Mode tampilan: side-by-side atau tab tunggal
  bool _isSideBySide = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hasil Pengolahan PCD',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Text(
              widget.operationLabel,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF818CF8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          // Toggle mode tampilan
          IconButton(
            icon: Icon(
              _isSideBySide ? Icons.view_agenda : Icons.view_column,
              color: Colors.white,
            ),
            tooltip: _isSideBySide ? 'Mode Tab' : 'Mode Berdampingan',
            onPressed: () => setState(() => _isSideBySide = !_isSideBySide),
          ),
        ],
        bottom: _isSideBySide
            ? null
            : TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF818CF8),
                unselectedLabelColor: Colors.white38,
                indicatorColor: const Color(0xFF6366F1),
                tabs: const [
                  Tab(text: 'Original'),
                  Tab(text: 'Hasil PCD'),
                ],
              ),
      ),
      body: _isSideBySide ? _buildSideBySide() : _buildTabView(),
      bottomNavigationBar: _buildInfoBar(),
    );
  }

  // ── Mode Tab ────────────────────────────────────────────────────────────
  Widget _buildTabView() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildImageViewer(widget.original, 'Gambar Asli'),
        _buildImageViewer(widget.processed, 'Hasil: ${widget.operationLabel}'),
      ],
    );
  }

  // ── Mode Berdampingan ────────────────────────────────────────────────────
  Widget _buildSideBySide() {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              _buildLabel('Asli'),
              Expanded(child: _buildImageViewer(widget.original, 'Asli')),
            ],
          ),
        ),
        Container(width: 1, color: Colors.white12),
        Expanded(
          child: Column(
            children: [
              _buildLabel(widget.operationLabel),
              Expanded(
                child: _buildImageViewer(
                  widget.processed,
                  widget.operationLabel,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      color: const Color(0xFF1A1A2E),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white60,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildImageViewer(Uint8List bytes, String heroTag) {
    return InteractiveViewer(
      panEnabled: true,
      minScale: 0.5,
      maxScale: 4.0,
      child: Center(
        child: Hero(
          tag: heroTag,
          child: Image.memory(bytes, fit: BoxFit.contain),
        ),
      ),
    );
  }

  // ── Info Bar Bawah ───────────────────────────────────────────────────────
  Widget _buildInfoBar() {
    final origKB = (widget.original.lengthInBytes / 1024).toStringAsFixed(1);
    final procKB = (widget.processed.lengthInBytes / 1024).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFF1A1A2E),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildInfoChip(Icons.image, 'Asli: ${origKB}KB'),
            const SizedBox(width: 12),
            _buildInfoChip(Icons.auto_fix_high, widget.operationLabel),
            const SizedBox(width: 12),
            _buildInfoChip(Icons.save_alt, 'Hasil: ${procKB}KB'),
            const SizedBox(width: 16),
            // Use This button
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context, {
                  'original': widget.original,
                  'processed': widget.processed,
                  'filter': widget.operationLabel,
                });
              },
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Gunakan'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF818CF8)),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 11),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
