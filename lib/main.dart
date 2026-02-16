import 'package:flutter/material.dart';
import 'package:logbook_app_094/features/onboarding/onboarding_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LogBook App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,

        // Soft pastel blue theme (punya kamu)
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7AA7FF),
          brightness: Brightness.light,
        ),

        scaffoldBackgroundColor: const Color(0xFFF6F8FF),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF6F8FF),
          elevation: 0,
          centerTitle: false,
          foregroundColor: Color(0xFF1F2A44),
        ),
      ),
      home: const OnboardingView(),
    );
  }
}
