import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:mongo_dart/mongo_dart.dart';

import 'package:logbook_app_094/features/logbook/models/log_model.dart';
import 'package:logbook_app_094/helpers/log_helper.dart';
import 'package:logbook_app_094/services/mongo_service.dart';

class LogController {
  final ValueNotifier<List<LogModel>> logsNotifier =
      ValueNotifier<List<LogModel>>([]);

  List<LogModel> get logs => logsNotifier.value;

  /// Ambil data dari Cloud (MongoDB Atlas) lalu update Notifier.
  /// NOTE: Namanya masih loadFromDisk biar kompatibel dengan LogView kamu,
  /// tapi fungsinya sebenarnya load dari Cloud.
  Future<void> loadFromDisk(String username) async {
    const source = "log_controller.dart";

    try {
      // Optional guard: batasi waktu ambil data biar UX enak
      final cloudData = await MongoService()
          .getLogs()
          .timeout(const Duration(seconds: 15));

      logsNotifier.value = cloudData;

      await LogHelper.writeLog(
        "CONTROLLER: loadFromDisk() -> ${cloudData.length} data dari Cloud",
        source: source,
        level: 3,
      );
    } on SocketException {
      await LogHelper.writeLog(
        "ERROR: loadFromDisk() -> SocketException (offline)",
        source: source,
        level: 1,
      );
      rethrow;
    } on TimeoutException {
      await LogHelper.writeLog(
        "ERROR: loadFromDisk() -> TimeoutException",
        source: source,
        level: 1,
      );
      rethrow;
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: loadFromDisk() -> $e",
        source: source,
        level: 1,
      );
      rethrow;
    }
  }

  Future<void> addLog(
    String username,
    String title,
    String desc,
    String category,
  ) async {
    const source = "log_controller.dart";

    final newLog = LogModel(
      id: ObjectId(),
      title: title,
      description: desc,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      category: category,
    );

    try {
      await MongoService()
          .insertLog(newLog)
          .timeout(const Duration(seconds: 15));

      // Update state lokal setelah cloud sukses
      final current = List<LogModel>.from(logsNotifier.value);
      current.add(newLog);
      logsNotifier.value = current;

      await LogHelper.writeLog(
        "SUCCESS: Tambah '${newLog.title}' berhasil",
        source: source,
        level: 2,
      );
    } on SocketException {
      await LogHelper.writeLog(
        "ERROR: Add -> SocketException (offline)",
        source: source,
        level: 1,
      );
      rethrow;
    } on TimeoutException {
      await LogHelper.writeLog(
        "ERROR: Add -> TimeoutException",
        source: source,
        level: 1,
      );
      rethrow;
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Gagal sinkronisasi Add - $e",
        source: source,
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
    const source = "log_controller.dart";

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
      await MongoService()
          .updateLog(updatedLog)
          .timeout(const Duration(seconds: 15));

      // Sukses cloud -> baru update UI
      current[index] = updatedLog;
      logsNotifier.value = current;

      await LogHelper.writeLog(
        "SUCCESS: Update '${oldLog.title}' -> '${updatedLog.title}'",
        source: source,
        level: 2,
      );
    } on SocketException {
      await LogHelper.writeLog(
        "ERROR: Update -> SocketException (offline)",
        source: source,
        level: 1,
      );
      rethrow;
    } on TimeoutException {
      await LogHelper.writeLog(
        "ERROR: Update -> TimeoutException",
        source: source,
        level: 1,
      );
      rethrow;
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Gagal sinkronisasi Update - $e",
        source: source,
        level: 1,
      );
      rethrow;
    }
  }

  Future<void> removeLog(String username, int index) async {
    const source = "log_controller.dart";

    final current = List<LogModel>.from(logsNotifier.value);
    if (index < 0 || index >= current.length) return;

    final targetLog = current[index];

    try {
      if (targetLog.id == null) {
        throw Exception("ID Log tidak ditemukan, tidak bisa delete di Cloud.");
      }

      await MongoService()
          .deleteLog(targetLog.id!)
          .timeout(const Duration(seconds: 15));

      // Sukses cloud -> baru hapus di UI
      current.removeAt(index);
      logsNotifier.value = current;

      await LogHelper.writeLog(
        "SUCCESS: Hapus '${targetLog.title}' berhasil",
        source: source,
        level: 2,
      );
    } on SocketException {
      await LogHelper.writeLog(
        "ERROR: Delete -> SocketException (offline)",
        source: source,
        level: 1,
      );
      rethrow;
    } on TimeoutException {
      await LogHelper.writeLog(
        "ERROR: Delete -> TimeoutException",
        source: source,
        level: 1,
      );
      rethrow;
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Gagal sinkronisasi Hapus - $e",
        source: source,
        level: 1,
      );
      rethrow;
    }
  }
}