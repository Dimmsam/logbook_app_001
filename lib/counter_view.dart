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
        backgroundColor: Color(0xfff4f1de),
        foregroundColor: Color(0xffe07a5f),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text("Total Hitungan:"),
            Text('${_controller.value}', style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 20),
            SizedBox(
              width: 200,
              height: 80,
              child: TextField(
                controller: _stepController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  labelText: 'Atur Langkah',
                  labelStyle: TextStyle(fontSize: 12),
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(fontSize: 14),
                onChanged: (value) => setState(() {
                  final int? newStep = int.tryParse(value);
                  if (newStep != null && newStep > 0) {
                    _controller.setStep(newStep);
                  }
                }),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Riwayat Aktivitas",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            SizedBox(
              height: 223,
              child: ListView.builder(
                itemCount: _controller.history.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Center(
                      child: Text(
                        _controller.history[index],
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    dense: true,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        spacing: 12,
        mainAxisAlignment: MainAxisAlignment.end,
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
              child: const Text("Restart"),
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
