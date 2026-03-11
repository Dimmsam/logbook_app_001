/// Mengelola izin aksi berdasarkan peran pengguna dalam tim.
///
/// Aturan visibilitas & aksi:
/// - Log Privat  : hanya pemilik (authorId) yang bisa melihat.
/// - Log Publik  : semua anggota tim bisa melihat.
/// - Edit/Hapus  : hanya pemilik, tidak peduli perannya (Ketua sekalipun).
class AccessPolicy {
  AccessPolicy._(); // Kelas statis, tidak perlu diinstansiasi.

  // ── Konstanta aksi ────────────────────────────────────────
  static const String create = 'create';
  static const String read = 'read';
  static const String update = 'update';
  static const String delete = 'delete';

  // ── Matriks izin dasar per peran ─────────────────────────
  // Update dan delete memerlukan syarat tambahan: isOwner == true.
  static const Map<String, List<String>> _permissions = {
    'Ketua': [create, read],
    'Anggota': [create, read],
  };

  /// Mengembalikan `true` apabila [role] diizinkan melakukan [action].
  ///
  /// [isOwner] harus `true` apabila pengguna adalah pemilik data.
  /// Update dan delete **hanya** diizinkan bagi pemilik data,
  /// tanpa pengecualian berdasarkan peran.
  static bool canPerform(String role, String action, {bool isOwner = false}) {
    // Edit/hapus: siapapun hanya boleh pada data miliknya sendiri
    if (action == update || action == delete) return isOwner;

    return (_permissions[role] ?? []).contains(action);
  }
}
