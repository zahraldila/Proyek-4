import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:logbook_app_094/features/onboarding/onboarding_view.dart';
import 'package:logbook_app_094/services/mongo_service.dart';
import 'package:logbook_app_094/helpers/log_helper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Load ENV
  await dotenv.load(fileName: ".env");

  // 2) Handshake MongoDB (connect sebelum UI)
const source = "main.dart";

// LEVEL 3 (VERBOSE)
await LogHelper.writeLog(
  "Boot: (Level 3) Mulai proses handshake MongoDB...",
  source: source,
  level: 3,
);

try {
  await MongoService().connect();

  // LEVEL 2 (INFO)
  await LogHelper.writeLog(
    "Boot: (Level 2) MongoDB CONNECTED ✅",
    source: source,
    level: 2,
  );

} catch (e) {

  // LEVEL 1 (ERROR)
  await LogHelper.writeLog(
    "Boot: (Level 1) MongoDB FAILED ❌ -> $e",
    source: source,
    level: 1,
  );
  }

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