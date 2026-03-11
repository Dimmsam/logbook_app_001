import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:logbook_app_001/features/logbook/log_controller.dart';
import 'package:logbook_app_001/features/logbook/models/log_model.dart';

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
      if (widget.log == null) {
        await widget.controller.addLog(
          title,
          desc,
          widget.currentUser['uid'],
          widget.currentUser['teamId'],
          isPublic: _isPublic,
          category: _category,
        );
      } else {
        await widget.controller.updateLog(
          widget.log!.id!,
          title,
          desc,
          _isPublic,
          _category,
        );
      }

      if (context.mounted) {
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
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan ke cloud: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
