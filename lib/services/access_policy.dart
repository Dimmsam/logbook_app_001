/// Mengelola izin aksi berdasarkan peran pengguna dalam tim.
///
/// Peran:
/// - 'Ketua'  : dapat melakukan semua aksi pada seluruh log tim.
/// - 'Anggota': dapat membuat dan membaca semua log; hanya
///              dapat mengubah/menghapus log miliknya sendiri.
class AccessPolicy {
  AccessPolicy._(); // Kelas statis, tidak perlu diinstansiasi.

  // ── Konstanta aksi ────────────────────────────────────────
  static const String create = 'create';
  static const String read = 'read';
  static const String update = 'update';
  static const String delete = 'delete';

  // ── Matriks izin per peran ───────────────────────────────
  static const Map<String, List<String>> _permissions = {
    'Ketua': [create, read, update, delete],
    'Anggota': [create, read],
  };

  /// Mengembalikan `true` apabila [role] diizinkan melakukan [action].
  ///
  /// Parameter [isOwner] diaktifkan ketika pengguna adalah pemilik
  /// data yang akan diubah. Anggota dapat mengubah/menghapus HANYA
  /// data miliknya sendiri (isOwner == true).
  static bool canPerform(String role, String action, {bool isOwner = false}) {
    if (role == 'Ketua') return true; // Ketua bisa semua aksi

    final allowed = _permissions[role] ?? [];

    // Anggota: update/delete hanya boleh jika pemilik data
    if (role == 'Anggota' && (action == update || action == delete)) {
      return isOwner;
    }

    return allowed.contains(action);
  }
}
