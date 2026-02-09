import 'package:flutter/material.dart';
import 'counter_controller.dart';

class CounterView extends StatefulWidget {
  const CounterView({super.key});
  @override
  State<CounterView> createState() => _CounterViewState();
}

class _CounterViewState extends State<CounterView> {
  final CounterController _controller = CounterController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("LogBook: Versi SRP")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Total Hitungan:"),
            Text('${_controller.value}', style: const TextStyle(fontSize: 40)),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          FloatingActionButton(onPressed: () => setState(() => _controller.increment()),
            child: const Icon(Icons.add),
          ),
          FloatingActionButton(onPressed: () => setState(() => _controller.decrement()),
            child: const Icon(Icons.remove),
          ),
          FloatingActionButton(onPressed: () => setState(() => _controller.reset()),
            child: const Icon(Icons.refresh),
          ),
        ]
      ),
    );
  }
}
