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
      appBar: AppBar(title: const Text("LogBook: Versi SRP")),
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
            child: const Icon(Icons.add),
          ),
          FloatingActionButton(
            onPressed: () => setState(() => _controller.decrement()),
            child: const Icon(Icons.remove),
          ),
          FloatingActionButton(
            onPressed: () => setState(() => _controller.reset()),
            child: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }
}
