import 'package:flutter/material.dart';
import 'counter_controller.dart';

class CounterView extends StatefulWidget {
  const CounterView({super.key});
  @override
  State<CounterView> createState() => _CounterViewState();
}

class _CounterViewState extends State<CounterView> {
  final CounterController _controller = CounterController();
  final TextEditingController _stepController = TextEditingController(
    text: '1',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "LogBook: Versi SRP",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xfff2cc8f),
        foregroundColor: Color(0xff3d405b),
        scrolledUnderElevation: 0,
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
              const SizedBox(height: 70),
              const Text(
                "Total Hitungan:",
                style: TextStyle(color: Color(0xff3d405b)),
              ),
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
                    onPressed: () => setState(() => _controller.increment()),
                    backgroundColor: Color(0xff8ABB6C),
                    foregroundColor: Colors.white,
                    elevation: 6,
                    child: const Icon(Icons.add),
                  ),
                  FloatingActionButton(
                    onPressed: () => setState(() => _controller.decrement()),
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
              onPressed: () {
                Navigator.of(context).pop();
                setState(() => _controller.reset());
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
