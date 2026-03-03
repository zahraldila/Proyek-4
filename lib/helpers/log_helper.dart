import 'dart:developer' as dev;
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LogHelper {
  static Future<void> writeLog(
    String message, {
    String source = "Unknown",
    int level = 2,
  }) async {
    final int configLevel = int.tryParse(dotenv.env['LOG_LEVEL'] ?? '2') ?? 2;

    final muteRaw = (dotenv.env['LOG_MUTE'] ?? '').trim();
    final muted = muteRaw.isEmpty
        ? <String>{}
        : muteRaw
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toSet();

    if (level > configLevel) return;
    if (muted.any((m) => source.contains(m))) return;

    try {
      final now = DateTime.now();
      final timestamp = DateFormat('HH:mm:ss').format(now);
      final label = _getLabel(level);
      final color = _getColor(level);

      final line = '[$timestamp][$label][$source] -> $message';

      // dev console
      dev.log(line, name: source, time: now, level: level * 100);

      // === FILE LOG ke folder project: logs/dd-mm-yyyy.log ===
      final fileName = DateFormat('dd-MM-yyyy').format(now) + '.log';
      final dir = Directory('logs');
      if (!dir.existsSync()) dir.createSync(recursive: true);

      final file = File('${dir.path}/$fileName');
      file.writeAsStringSync('$line\n', mode: FileMode.append, flush: true);

      // === Terminal hanya kalau LOG_LEVEL==3 (sesuai task) ===
      if (configLevel == 3) {
        // ignore: avoid_print
        print('$color$line\x1B[0m');
      }
    } catch (e) {
      dev.log("Logging failed: $e", name: "SYSTEM", level: 1000);
    }
  }

  static String _getLabel(int level) {
    switch (level) {
      case 1:
        return "ERROR";
      case 2:
        return "INFO";
      case 3:
        return "VERBOSE";
      default:
        return "LOG";
    }
  }

  static String _getColor(int level) {
    switch (level) {
      case 1:
        return '\x1B[31m';
      case 2:
        return '\x1B[32m';
      case 3:
        return '\x1B[34m';
      default:
        return '\x1B[0m';
    }
  }
}