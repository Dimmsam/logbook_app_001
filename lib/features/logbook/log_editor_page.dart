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
        appBar: AppBar(
          title: Text(widget.log == null ? "Catatan Baru" : "Edit Catatan"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Editor"),
              Tab(text: "Pratinjau"),
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
                  Row(
                    children: [
                      const Icon(
                        Icons.label_outline,
                        size: 20,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      const Text('Kategori:', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 12),
                      DropdownButton<String>(
                        value: _category,
                        isDense: true,
                        underline: const SizedBox(),
                        items: _categories
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _category = val ?? _category),
                      ),
                    ],
                  ),
                  const Divider(height: 8),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: "Judul"),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: TextField(
                      controller: _descController,
                      maxLines: null,
                      expands: true,
                      keyboardType: TextInputType.multiline,
                      decoration: const InputDecoration(
                        hintText: "Tulis laporan dengan format Markdown...",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Tab Pratinjau: MarkdownBody di dalam SingleChildScrollView
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
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
