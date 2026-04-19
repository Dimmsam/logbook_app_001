import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:logbook_app_001/features/logbook/log_controller.dart';
import 'package:logbook_app_001/features/logbook/models/log_model.dart';
import 'package:logbook_app_001/features/vision/vision_view.dart';

class LogEditorPage extends StatefulWidget {
  final LogModel? log;
  final LogController controller;
  final dynamic currentUser;

  const LogEditorPage({
    super.key,
    this.log,
    required this.controller,
    required this.currentUser,
  });

  @override
  State<LogEditorPage> createState() => _LogEditorPageState();
}

class _LogEditorPageState extends State<LogEditorPage> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  bool _isPublic = false;
  String _category = 'Software';

  // Vision & Image Capture State
  Uint8List? _capturedImage; // Original image before PCD processing
  Uint8List? _processedImage; // Image after PCD filter applied
  String? _selectedPcdFilter; // PCD filter name used

  static const List<String> _categories = [
    'Mechanical',
    'Electronic',
    'Software',
  ];

  static const List<Map<String, String>> _mdHints = [
    {'label': '**Tebal**', 'syntax': '**teks tebal**'},
    {'label': '_Miring_', 'syntax': '_teks miring_'},
    {'label': '# H1', 'syntax': '# Judul 1\n'},
    {'label': '## H2', 'syntax': '## Judul 2\n'},
    {'label': '### H3', 'syntax': '### Judul 3\n'},
    {'label': '• List', 'syntax': '- item\n'},
    {'label': '1. Nomor', 'syntax': '1. item\n'},
    {'label': '`kode`', 'syntax': '`kode`'},
    {'label': '```blok```', 'syntax': '```\nkode\n```\n'},
    {'label': '> Kutipan', 'syntax': '> kutipan\n'},
    {'label': '---', 'syntax': '---\n'},
    {'label': '[Link]', 'syntax': '[teks](https://url)'},
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.log?.title ?? '');
    _descController = TextEditingController(
      text: widget.log?.description ?? '',
    );
    _isPublic = widget.log?.isPublic ?? false;
    _category = widget.log?.category ?? 'Software';
    _descController.addListener(() {
      setState(() {});
    });
  }

  bool _isSaving = false;

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul tidak boleh kosong.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Gunakan processed image jika ada, fallback ke original
      final imageToSave = _processedImage ?? _capturedImage;

      // Tambah image info ke description jika ada captured image
      String finalDesc = desc;
      if (imageToSave != null) {
        final filterInfo = _selectedPcdFilter != null
            ? ' (Filter: $_selectedPcdFilter)'
            : '';
        finalDesc +=
            '\n\n[📷 Smart-Patrol Vision dengan Detection$filterInfo]\n';
      }

      if (widget.log == null) {
        await widget.controller.addLog(
          title,
          finalDesc,
          widget.currentUser['uid'],
          widget.currentUser['teamId'],
          isPublic: _isPublic,
          category: _category,
          imageBytes: imageToSave,
          imageFilter: _selectedPcdFilter,
        );
      } else {
        await widget.controller.updateLog(
          widget.log!.id!,
          title,
          finalDesc,
          _isPublic,
          _category,
          imageBytes: imageToSave,
          imageFilter: _selectedPcdFilter,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.log == null
                ? 'Catatan berhasil disimpan!'
                : 'Catatan berhasil diperbarui!',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan ke cloud: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _insertSnippet(String snippet) {
    final ctrl = _descController;
    final base = ctrl.selection.isValid
        ? ctrl.selection.start
        : ctrl.text.length;
    final extent = ctrl.selection.isValid
        ? ctrl.selection.end
        : ctrl.text.length;
    final newText = ctrl.text.replaceRange(base, extent, snippet);
    ctrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: base + snippet.length),
    );
  }

  /// Buka Vision untuk capture & process gambar dengan detection + PCD filter
  /// Vision always returns result from PcdResultPage: {'original', 'processed', 'filter'}
  Future<void> _openVisionCapture() async {
    final result = await Navigator.push<Map<String, dynamic>?>(
      context,
      MaterialPageRoute(builder: (_) => const VisionView()),
    );

    if (result != null && mounted) {
      final original = result['original'] as Uint8List?;
      final processed = result['processed'] as Uint8List?;
      final filter = result['filter'] as String?;

      if (original != null && processed != null && filter != null) {
        setState(() {
          _capturedImage = original; // Keep original for reference
          _processedImage = processed; // Use processed image for saving
          _selectedPcdFilter = filter;
        });
      }
    }
  }

  /// Dialog untuk pilih PCD filter
  Future<void> _showPcdFilterDialog() async {
    final filters = [
      'Grayscale',
      'Blur',
      'Sharpen',
      'Threshold',
      'CLAHE',
      'Canny Edge',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Filter PCD'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: filters.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(filters[index]),
                onTap: () {
                  Navigator.pop(context);
                  _applyPcdFilter(filters[index]);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
        ],
      ),
    );
  }

  /// Apply PCD filter ke captured image
  Future<void> _applyPcdFilter(String filter) async {
    if (_capturedImage == null) return;

    try {
      setState(() {
        _selectedPcdFilter = filter;
        // Dalam implementasi real, di sini akan dipanggil PCD processor
        // Untuk sekarang simulasi saja - image tetap sama
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Filter "$filter" diterapkan')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  /// Hapus captured image
  void _clearImage() {
    setState(() {
      _capturedImage = null;
      _selectedPcdFilter = null;
    });
  }

  /// Build image preview section
  Widget _buildImagePreviewSection() {
    if (_capturedImage == null) {
      return GestureDetector(
        onTap: _openVisionCapture,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
            borderRadius: BorderRadius.circular(12),
            color: const Color(0xFFF9FAFB),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.camera_alt, size: 48, color: const Color(0xFF9CA3AF)),
              const SizedBox(height: 12),
              const Text(
                'Tap untuk capture gambar',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Dari Smart-Patrol Vision',
                style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          // Image preview
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.memory(
              _capturedImage!,
              fit: BoxFit.cover,
              height: 180,
              width: double.infinity,
            ),
          ),
          // Filter info + actions
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFF9FAFB),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Gambar ditangkap',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      if (_selectedPcdFilter != null)
                        Text(
                          'Filter: $_selectedPcdFilter',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _showPcdFilterDialog,
                  iconSize: 20,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _clearImage,
                  iconSize: 20,
                  color: Colors.red,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1A1A2E),
          elevation: 0,
          surfaceTintColor: Colors.white,
          title: Text(
            widget.log == null ? 'Catatan Baru' : 'Edit Catatan',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          bottom: const TabBar(
            labelColor: Color(0xFF6366F1),
            unselectedLabelColor: Color(0xFF9CA3AF),
            indicatorColor: Color(0xFF6366F1),
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'Editor'),
              Tab(text: 'Pratinjau'),
            ],
          ),
          actions: [
            _isSaving
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(icon: const Icon(Icons.save), onPressed: _save),
          ],
        ),
        body: TabBarView(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Toggle visibilitas catatan
                  SwitchListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    secondary: Icon(
                      _isPublic ? Icons.public : Icons.lock_outline,
                      color: _isPublic ? Colors.blue : Colors.grey,
                    ),
                    title: Text(
                      _isPublic
                          ? 'Publik (Tim bisa melihat)'
                          : 'Privat (Hanya saya)',
                      style: const TextStyle(fontSize: 14),
                    ),
                    value: _isPublic,
                    onChanged: (val) => setState(() => _isPublic = val),
                  ),
                  const SizedBox(height: 16),
                  // Image Capture Section - Smart-Patrol Vision
                  _buildImagePreviewSection(),
                  // Dropdown kategori
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.label_outline,
                          size: 18,
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Kategori',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const Spacer(),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _category,
                            isDense: true,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111827),
                            ),
                            items: _categories
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _category = val ?? _category),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Judul Catatan',
                      labelStyle: const TextStyle(color: Color(0xFF6B7280)),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFF6366F1),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // ── Markdown Toolbar ─────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Format Markdown yang tersedia:',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9CA3AF),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _mdHints
                                .map(
                                  (h) => Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: InkWell(
                                      onTap: () => _insertSnippet(h['syntax']!),
                                      borderRadius: BorderRadius.circular(6),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFFD1D5DB),
                                          ),
                                        ),
                                        child: Text(
                                          h['label']!,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF374151),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: TextField(
                      controller: _descController,
                      maxLines: null,
                      expands: true,
                      keyboardType: TextInputType.multiline,
                      style: const TextStyle(fontSize: 14, height: 1.6),
                      decoration: InputDecoration(
                        hintText: 'Tulis laporan dengan format Markdown...',
                        hintStyle: const TextStyle(color: Color(0xFFD1D5DB)),
                        filled: true,
                        fillColor: const Color(0xFFFAFAFA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF6366F1),
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Tab Pratinjau
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: MarkdownBody(
                data: _descController.text.isEmpty
                    ? '_Belum ada teks untuk ditampilkan..._'
                    : _descController.text,
                selectable: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
