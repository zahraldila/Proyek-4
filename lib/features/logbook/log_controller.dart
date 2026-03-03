import 'package:flutter/foundation.dart';
import 'package:mongo_dart/mongo_dart.dart';

import 'package:logbook_app_094/features/logbook/models/log_model.dart';
import 'package:logbook_app_094/services/mongo_service.dart';
import 'package:logbook_app_094/helpers/log_helper.dart';

class LogController {
  final ValueNotifier<List<LogModel>> logsNotifier =
      ValueNotifier<List<LogModel>>([]);

  List<LogModel> get logs => logsNotifier.value;

  // (opsional) biar mirip modul dosen: auto-load saat controller dibuat
  // tapi karena LogView kamu sudah memanggil loadFromDisk(username), ini boleh dimatikan.
  // LogController();

  Future<void> loadFromDisk(String username) async {
    final cloudData = await MongoService().getLogs();
    logsNotifier.value = cloudData;

    await LogHelper.writeLog(
      "CONTROLLER: loadFromDisk() -> ${cloudData.length} data dari Cloud",
      source: "log_controller.dart",
      level: 3,
    );
  }

  Future<void> addLog(
    String username,
    String title,
    String desc,
    String category,
  ) async {
    final newLog = LogModel(
      id: ObjectId(),
      title: title,
      description: desc,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      category: category,
    );

    try {
      await MongoService().insertLog(newLog);

      // mirip modul dosen: update state lokal setelah cloud sukses
      final current = List<LogModel>.from(logsNotifier.value);
      current.add(newLog);
      logsNotifier.value = current;

      await LogHelper.writeLog(
        "SUCCESS: Tambah '${newLog.title}' berhasil",
        source: "log_controller.dart",
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Gagal sinkronisasi Add - $e",
        source: "log_controller.dart",
        level: 1,
      );
      rethrow;
    }
  }

  Future<void> updateLog(
    String username,
    int index,
    String newTitle,
    String newDesc,
    String newCategory,
  ) async {
    final current = List<LogModel>.from(logsNotifier.value);
    if (index < 0 || index >= current.length) return;

    final oldLog = current[index];

    final updatedLog = oldLog.copyWith(
      // ID harus tetap sama
      title: newTitle,
      description: newDesc,
      category: newCategory,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    try {
      await MongoService().updateLog(updatedLog);

      // sukses cloud -> baru update UI
      current[index] = updatedLog;
      logsNotifier.value = current;

      await LogHelper.writeLog(
        "SUCCESS: Update '${oldLog.title}' -> '${updatedLog.title}'",
        source: "log_controller.dart",
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Gagal sinkronisasi Update - $e",
        source: "log_controller.dart",
        level: 1,
      );
      rethrow;
    }
  }

  Future<void> removeLog(String username, int index) async {
    final current = List<LogModel>.from(logsNotifier.value);
    if (index < 0 || index >= current.length) return;

    final targetLog = current[index];

    try {
      if (targetLog.id == null) {
        throw Exception("ID Log tidak ditemukan, tidak bisa delete di Cloud.");
      }

      await MongoService().deleteLog(targetLog.id!);

      // sukses cloud -> baru hapus di UI
      current.removeAt(index);
      logsNotifier.value = current;

      await LogHelper.writeLog(
        "SUCCESS: Hapus '${targetLog.title}' berhasil",
        source: "log_controller.dart",
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Gagal sinkronisasi Hapus - $e",
        source: "log_controller.dart",
        level: 1,
      );
      rethrow;
    }
  }
}