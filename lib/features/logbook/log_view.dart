import 'package:flutter/material.dart';
import 'package:logbook_app_001/features/auth/login_view.dart';
import 'package:logbook_app_001/features/logbook/log_controller.dart';
import 'package:logbook_app_001/features/logbook/log_editor_page.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.currentUser['username']),
            const SizedBox(width: 8),
            Chip(
              label: Text(
                widget.currentUser['role'],
                style: const TextStyle(fontSize: 11, color: Colors.white),
              ),
              backgroundColor: widget.currentUser['role'] == 'Ketua'
                  ? Colors.indigo
                  : Colors.teal,
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
                filled: true,
                fillColor: Colors.grey[100],
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
                                title: Text(log.title),
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
                                            color: catColor.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            border: Border.all(
                                              color: catColor.withOpacity(0.4),
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
                                        onPressed: () =>
                                            _controller.removeLog(log.id!),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _goToEditor(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
