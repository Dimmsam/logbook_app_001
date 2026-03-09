// login_controller.dart
class LoginController {
  final Map<String, String> _users = {
    'user1': 'password1',
    'user2': 'password2',
  };

  static const Map<String, Map<String, dynamic>> _userProfiles = {
    'user1': {
      'uid': 'user1',
      'username': 'User Satu',
      'role': 'Ketua',
      'teamId': 'team_001',
    },
    'user2': {
      'uid': 'user2',
      'username': 'User Dua',
      'role': 'Anggota',
      'teamId': 'team_001',
    },
  };

  Map<String, dynamic> getProfile(String username) {
    return Map<String, dynamic>.from(
      _userProfiles[username] ??
          {
            'uid': username,
            'username': username,
            'role': 'Anggota',
            'teamId': 'team_001',
          },
    );
  }

  int failedAttempts = 0;
  bool isLocked = false;
  DateTime? lockEndTime;

  LoginResult login(String username, String password) {
    if (username.trim().isEmpty || password.trim().isEmpty) {
      return LoginResult.emptyField;
    }

    if (isLocked) {
      if (DateTime.now().isBefore(lockEndTime!)) {
        return LoginResult.locked;
      } else {
        isLocked = false;
        failedAttempts = 0;
      }
    }

    if (_users.containsKey(username) && _users[username] == password) {
      failedAttempts = 0;
      isLocked = false;
      return LoginResult.success;
    } else {
      failedAttempts++;

      if (failedAttempts >= 3) {
        isLocked = true;
        lockEndTime = DateTime.now().add(const Duration(seconds: 10));
        return LoginResult.locked;
      }

      return LoginResult.wrongCredential;
    }
  }

  int getRemainingSeconds() {
    if (!isLocked || lockEndTime == null) return 0;

    int sisa = lockEndTime!.difference(DateTime.now()).inSeconds;
    return sisa > 0 ? sisa : 0;
  }
}

enum LoginResult { success, wrongCredential, emptyField, locked }
