import 'package:flutter/material.dart';
import 'package:logbook_app_001/features/logbook/counter_controller.dart';
import 'package:logbook_app_001/features/onboarding/onboarding_view.dart';

class CounterView extends StatefulWidget {
  final String username;

  const CounterView({super.key, required this.username});

  @override
  State<CounterView> createState() => _CounterViewState();
}

class _CounterViewState extends State<CounterView> {
  final CounterController _controller = CounterController();
  final TextEditingController _stepController = TextEditingController(
    text: '1',
  );

String getGreeting() {
  final hour = DateTime.now().hour;

  if (hour >= 5 && hour < 11) return "Selamat Pagi";
  if (hour >= 11 && hour < 15) return "Selamat Siang";
  if (hour >= 15 && hour < 18) return "Selamat Sore";
  return "Selamat Malam";
}

  @override
  void initState() {
    super.initState();
    _controller.setUser(widget.username);
    _controller.loadData().then((_) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Logbook: ${widget.username}"),
        backgroundColor: Color(0xfff2cc8f),
        foregroundColor: Color(0xff3d405b),
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // 1. Munculkan Dialog Konfirmasi
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("Konfirmasi Logout"),
                    content: const Text(
                      "Apakah Anda yakin? Data yang belum disimpan mungkin akan hilang.",
                    ),
                    actions: [
                      // Tombol Batal
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(context), // Menutup dialog saja
                        child: const Text("Batal"),
                      ),
                      // Tombol Ya, Logout
                      TextButton(
                        onPressed: () {
                          // Menutup dialog
                          Navigator.pop(context);

                          // 2. Navigasi kembali ke Onboarding (Membersihkan Stack)
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const OnboardingView(),
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
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomRight,
            colors: [Color(0xfff2cc8f), Color(0xfff4f1de)],
          ),
        ),

        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 40),
              Text("${getGreeting()}, ${widget.username}!"),
              const SizedBox(height: 30),
              const Text("Total Hitungan Anda:"),
              Text(
                '${_controller.value}',
                style: const TextStyle(
                  fontSize: 80,
                  color: Color(0xff3d405b),
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 5),
              SizedBox(
                width: 200,
                height: 60,
                child: TextField(
                  controller: _stepController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    labelText: 'Atur Langkah',
                    labelStyle: TextStyle(
                      fontSize: 12,
                      color: Color(0xff3d405b),
                    ),
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xff3d405b),
                  ),
                  onChanged: (value) => setState(() {
                    final int? newStep = int.tryParse(value);
                    if (newStep != null && newStep > 0) {
                      _controller.setStep(newStep);
                    }
                  }),
                ),
              ),

              const SizedBox(height: 45),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 12,
                children: [
                  FloatingActionButton(
                    onPressed: () async {
                      await _controller.increment();
                      setState(() {});
                    },
                    backgroundColor: Color(0xff8ABB6C),
                    foregroundColor: Colors.white,
                    elevation: 6,
                    child: const Icon(Icons.add),
                  ),
                  FloatingActionButton(
                    onPressed: () async {
                      await _controller.decrement();
                      setState(() {});
                    },
                    backgroundColor: Color(0xffFF8989),
                    foregroundColor: Colors.white,
                    elevation: 6,
                    child: const Icon(Icons.remove),
                  ),
                  FloatingActionButton(
                    onPressed: () => _showRestartDialog(context),
                    backgroundColor: Color(0xff7FA9C0),
                    foregroundColor: Colors.white,
                    elevation: 6,
                    child: const Icon(Icons.refresh),
                  ),
                ],
              ),

              const SizedBox(height: 60),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Divider(color: Color(0xff3d405b), thickness: 1.5),
              ),

              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.history, size: 20, color: Color(0xff3d405b)),
                        SizedBox(width: 8),
                        Text(
                          "Riwayat Aktivitas",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff3d405b),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    _controller.history.isEmpty
                        ? const Text(
                            "Belum ada aktivitas",
                            style: TextStyle(color: Color(0xff3d405b)),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _controller.history.length,
                            itemBuilder: (context, index) {
                              final historyItem = _controller.history[index];

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Text(
                                  historyItem,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xff3d405b),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 209),
            ],
          ),
        ),
      ),
    );
  }

  void _showRestartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Konfirmasi Restart"),
          content: const Text("Apakah Anda yakin ingin mereset counter ke 0?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Batal"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _controller.reset();
                setState(() {});
                _showSuccessRestart("Berhasil mereset counter!", context);
              },
              child: const Text("Restart", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessRestart(String message, BuildContext context) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
      backgroundColor: Colors.green,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
