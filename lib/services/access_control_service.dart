import 'package:flutter_dotenv/flutter_dotenv.dart';

class AccessControlService {
  static List<String> get availableRoles =>
      dotenv.env['APP_ROLES']?.split(',') ?? ['Anggota'];

  static const String actionCreate = 'create';
  static const String actionRead = 'read';
  static const String actionUpdate = 'update';
  static const String actionDelete = 'delete';

  static final Map<String, List<String>> _rolePermissions = {
    'Ketua': [actionCreate, actionRead],
    'Anggota': [actionCreate, actionRead],
    'Asisten': [actionRead],
  };

  static bool canPerform(String role, String action, {bool isOwner = false}) {
    // Edit/hapus: hanya diizinkan bagi pemilik data, tanpa pengecualian peran
    if (action == actionUpdate || action == actionDelete) return isOwner;

    return (_rolePermissions[role] ?? []).contains(action);
  }
}
