// login_view.dart
import 'package:flutter/material.dart';
// Import Controller milik sendiri (masih satu folder)
import 'package:logbook_app_001/features/auth/login_controller.dart';
// Import View dari fitur lain (Logbook) untuk navigasi
import 'package:logbook_app_001/features/logbook/log_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});
  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  // Inisialisasi Otak dan Controller Input
  final LoginController _controller = LoginController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _isPasswordHidden = true;

  void _handleLogin() {
    String user = _userController.text;
    String pass = _passController.text;

    LoginResult result = _controller.login(user, pass);

    String message = "";

    switch (result) {
      case LoginResult.success:
        Navigator.pushReplacement(
          context,
            MaterialPageRoute(builder: (context) => const LogView()),
        );
        return;

      case LoginResult.emptyField:
        message = "Username dan Password tidak boleh kosong!";
        break;

      case LoginResult.wrongCredential:
        int sisa = 3 - _controller.failedAttempts;
        message = "Login gagal! Sisa percobaan: $sisa";
        break;

      case LoginResult.locked:
        int detik = _controller.getRemainingSeconds();
        message = "Terlalu banyak percobaan! Coba lagi dalam $detik detik.";
        break;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login Gatekeeper")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _userController,
              decoration: const InputDecoration(labelText: "Username"),
            ),
            TextField(
              controller: _passController,
              obscureText: _isPasswordHidden, // Menyembunyikan teks password
              decoration: InputDecoration(
                labelText: "Password",
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordHidden ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordHidden = !_isPasswordHidden;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _handleLogin, child: const Text("Masuk")),
          ],
        ),
      ),
    );
  }
}
