import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:logbook_app_001/features/auth/login_view.dart';
import 'package:logbook_app_001/features/logbook/log_controller.dart';
import 'package:logbook_app_001/features/logbook/log_editor_page.dart';
import 'package:logbook_app_001/features/vision/vision_view.dart';
import './models/log_model.dart';

class LogView extends StatefulWidget {
  final dynamic currentUser;

  const LogView({super.key, required this.currentUser});

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  late final LogController _controller;
  final ValueNotifier<String> _searchQuery = ValueNotifier('');

  @override
  void initState() {
    super.initState();
    _controller = LogController(
      userId: widget.currentUser['uid'],
      userRole: widget.currentUser['role'],
    );
    _controller.loadLogs(widget.currentUser['teamId']);
  }

  @override
  void dispose() {
    _searchQuery.dispose();
    _controller.dispose();
    super.dispose();
  }

  // Warna indikator berdasarkan kategori
  Color _categoryColor(String category) {
    switch (category) {
      case 'Mechanical':
        return Colors.green;
      case 'Electronic':
        return Colors.blue;
      case 'Software':
        return Colors.deepPurple;
      default:
        return Colors.grey;
    }
  }

  void _goToEditor({LogModel? log}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LogEditorPage(
          log: log,
          controller: _controller,
          currentUser: widget.currentUser,
        ),
      ),
    );
  }

  void _openVisionCapture() async {
    final result = await Navigator.push<Map<String, dynamic>?>(
      context,
      MaterialPageRoute(builder: (context) => const VisionView()),
    );

    // User tapped "Gunakan" di VisionPcdResultPage
    if (result != null && mounted) {
      try {
        final original = result['original'] as Uint8List?;
        final processed = result['processed'] as Uint8List?;
        final filter = result['filter'] as String?;

        if (original != null && processed != null && filter != null) {
          // Convert Uint8List to Base64 untuk penyimpanan di camera_pcd
          final originalBase64 = LogModel.encodeImageToBase64(original);
          final processedBase64 = LogModel.encodeImageToBase64(processed);

          // Save ke collection camera_pcd
          await _controller.saveCameraPcd(
            originalImageBase64: originalBase64,
            processedImageBase64: processedBase64,
            filterName: filter,
            teamId: widget.currentUser['teamId'] as String,
          );

          if (mounted) {
            // ignore: use_build_context_synchronously
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Capture Camera PCD disimpan!'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Gagal menyimpan: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.currentUser['username'],
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: widget.currentUser['role'] == 'Ketua'
                    ? const Color(0xFF6366F1)
                    : const Color(0xFF0D9488),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color:
                        (widget.currentUser['role'] == 'Ketua'
                                ? const Color(0xFF6366F1)
                                : const Color(0xFF0D9488))
                            .withValues(alpha: 0.30),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                widget.currentUser['role'],
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        surfaceTintColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.loadLogs(widget.currentUser['teamId']),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Konfirmasi Logout"),
                  content: const Text("Apakah Anda yakin ingin keluar?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Batal"),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginView(),
                          ),
                          (route) => false,
                        );
                      },
                      child: const Text(
                        "Ya, Keluar",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Smart Search Bar ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari judul atau isi catatan...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF6366F1),
                    width: 1.5,
                  ),
                ),
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (val) => _searchQuery.value = val,
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: Listenable.merge([
                _controller.logsNotifier,
                _controller.pendingIdsNotifier,
                _searchQuery,
              ]),
              builder: (context, child) {
                final currentLogs = _controller.logsNotifier.value;
                final pendingIds = _controller.pendingIdsNotifier.value;
                final currentUserId = widget.currentUser['uid'] as String;
                final query = _searchQuery.value.toLowerCase().trim();

                // Visibility + search filter
                final displayLogs = currentLogs.where((log) {
                  final visibleToMe =
                      log.authorId == currentUserId || log.isPublic;
                  if (!visibleToMe) return false;
                  if (query.isEmpty) return true;
                  return log.title.toLowerCase().contains(query) ||
                      log.description.toLowerCase().contains(query);
                }).toList();

                // ── Informative Empty State ──────────────────────
                if (displayLogs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'images/null.gif',
                          width: 180,
                          height: 180,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          query.isEmpty
                              ? 'Belum ada aktivitas hari ini?'
                              : 'Tidak ada catatan untuk "$query"',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          query.isEmpty
                              ? 'Mulai catat kemajuan proyek Anda!'
                              : 'Coba kata kunci lain.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (query.isEmpty) ...[
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () => _goToEditor(),
                            icon: const Icon(Icons.add),
                            label: const Text('Buat Catatan Pertama'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: displayLogs.length,
                  itemBuilder: (context, index) {
                    final log = displayLogs[index];
                    final bool isOwner = log.authorId == currentUserId;
                    final bool isPending =
                        log.id != null && pendingIds.contains(log.id);
                    final Color catColor = _categoryColor(log.category);

                    // ── Category-Color Coded Card ─────────────────
                    return Card(
                      clipBehavior: Clip.hardEdge,
                      elevation: 2,
                      shadowColor: Colors.black12,
                      surfaceTintColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Aksen warna kategori (strip kiri)
                            Container(width: 5, color: catColor),
                            Expanded(
                              child: ListTile(
                                leading: Tooltip(
                                  message: isPending
                                      ? 'Menunggu sinkronisasi...'
                                      : 'Tersinkron ke Cloud',
                                  child: Icon(
                                    isPending
                                        ? Icons.cloud_upload_outlined
                                        : Icons.cloud_done,
                                    color: isPending
                                        ? Colors.orange
                                        : Colors.green,
                                  ),
                                ),
                                title: Text(
                                  log.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      log.description,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        // Badge kategori berwarna
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: catColor.withValues(
                                              alpha: 0.12,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            border: Border.all(
                                              color: catColor.withValues(
                                                alpha: 0.4,
                                              ),
                                              width: 0.8,
                                            ),
                                          ),
                                          child: Text(
                                            log.category,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: catColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Icon(
                                          log.isPublic
                                              ? Icons.public
                                              : Icons.lock_outline,
                                          size: 11,
                                          color: log.isPublic
                                              ? Colors.blue
                                              : Colors.grey,
                                        ),
                                        Text(
                                          log.isPublic ? ' Publik' : ' Privat',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: log.isPublic
                                                ? Colors.blue
                                                : Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                isThreeLine: true,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isOwner)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.blue,
                                        ),
                                        onPressed: () => _goToEditor(log: log),
                                      ),
                                    if (isOwner)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () => showDialog(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('Hapus Catatan'),
                                            content: Text(
                                              'Yakin ingin menghapus "${log.title}"? Tindakan ini tidak dapat dibatalkan.',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx),
                                                child: const Text('Batal'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(ctx);
                                                  _controller.removeLog(
                                                    log.id!,
                                                  );
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        '"${log.title}" berhasil dihapus.',
                                                      ),
                                                      backgroundColor:
                                                          Colors.red,
                                                    ),
                                                  );
                                                },
                                                child: const Text(
                                                  'Hapus',
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── FAB 1: Ambil Gambar dengan Vision Camera ──
          FloatingActionButton.small(
            onPressed: _openVisionCapture,
            tooltip: 'Ambil Gambar (PCD)',
            backgroundColor: const Color(0xFFF59E0B),
            foregroundColor: Colors.white,
            child: const Icon(Icons.camera_alt),
          ),
          const SizedBox(height: 12),
          // ── FAB 2: Buat Catatan Baru ──
          FloatingActionButton(
            onPressed: () => _goToEditor(),
            tooltip: 'Buat Catatan Baru',
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
