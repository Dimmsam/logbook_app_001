import 'package:flutter/material.dart';
import 'package:logbook_app_001/features/auth/login_view.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});
  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  int step = 1;

  final List<Map<String, String>> pages = [
    {
      "image": "images/onboard1.jpeg",
      "text": "Catat setiap hitungan aktivitasmu dengan mudah.",
    },
    {
      "image": "images/onboard2.jpeg",
      "text": "Riwayat aktivitas tersimpan otomatis.",
    },
    {
      "image": "images/onboard3.jpeg",
      "text": "Login dan lanjutkan hitunganmu kapan saja.",
    },
  ];

  void handleNext() {
    setState(() {
      step++;
    });

    if (step > 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginView()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Onboarding')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),

            Image.asset(pages[step - 1]["image"]!, height: 200),

            const SizedBox(height: 20),

            Text(
              pages[step - 1]["text"]!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return Container(
                  margin: const EdgeInsets.all(4),
                  width: step - 1 == index ? 12 : 8,
                  height: step - 1 == index ? 12 : 8,
                  decoration: BoxDecoration(
                    color: step - 1 == index ? Colors.blue : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),

            const SizedBox(height: 20),

            ElevatedButton(onPressed: handleNext, child: const Text('Next')),
          ],
        ),
      ),
    );
  }
}
