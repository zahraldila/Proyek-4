import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

import 'package:logbook_app_094/features/logbook/models/log_model.dart';
import 'package:logbook_app_094/helpers/log_helper.dart';
import 'package:logbook_app_094/services/mongo_service.dart';

class LogController {
  final ValueNotifier<List<LogModel>> logsNotifier =
      ValueNotifier<List<LogModel>>([]);

  final Box<LogModel> _myBox = Hive.box<LogModel>('offline_logs');

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  String? _activeTeamId;

  List<LogModel> get logs => logsNotifier.value;

  void startBackgroundSync(String teamId) {
    _activeTeamId = teamId;
    _connectivitySubscription?.cancel();

    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) async {
      final isOnline = !results.contains(ConnectivityResult.none);

      if (isOnline) {
        await syncPendingLogs(teamId);
      }
    });
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }

  Future<void> loadLogs(String teamId) async {
    const source = "log_controller.dart";
    _activeTeamId = teamId;

    logsNotifier.value =
        _myBox.values.where((log) => log.teamId == teamId).toList();

    try {
      final cloudData = await MongoService().getLogs(teamId);

      final localUnsynced = _myBox.values
          .where((log) => log.teamId == teamId && !log.isSynced)
          .toList();

      final allLocal = _myBox.values.toList();
      final sameTeamIndexes = <int>[];

      for (int i = 0; i < allLocal.length; i++) {
        if (allLocal[i].teamId == teamId) {
          sameTeamIndexes.add(i);
        }
      }

      for (int i = sameTeamIndexes.length - 1; i >= 0; i--) {
        await _myBox.deleteAt(sameTeamIndexes[i]);
      }

      final mergedLogs = <LogModel>[
        ...cloudData.map((log) => log.copyWith(isSynced: true)),
        ...localUnsynced,
      ];

      await _myBox.addAll(mergedLogs);

      logsNotifier.value =
          _myBox.values.where((log) => log.teamId == teamId).toList();

      await LogHelper.writeLog(
        "SYNC: Data berhasil diperbarui dari Atlas",
        source: source,
        level: 2,
      );
    } on SocketException {
      await LogHelper.writeLog(
        "OFFLINE: Menggunakan data cache lokal",
        source: source,
        level: 2,
      );
    } on TimeoutException {
      await LogHelper.writeLog(
        "OFFLINE: Menggunakan data cache lokal",
        source: source,
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: loadLogs() -> $e",
        source: source,
        level: 1,
      );
    }
  }

  Future<void> loadFromDisk(String username) async {
    logsNotifier.value = _myBox.values.toList();
  }

  Future<void> addLog(
    String title,
    String desc,
    String category,
    String authorId,
    String teamId,
    bool isPublic,
  ) async {
    const source = "log_controller.dart";

    final newLog = LogModel(
      id: ObjectId().oid,
      title: title,
      description: desc,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      category: category,
      authorId: authorId,
      teamId: teamId,
      isSynced: false,
      isPublic: isPublic,
    );

    await _myBox.add(newLog);

    logsNotifier.value =
        _myBox.values.where((log) => log.teamId == teamId).toList();

    await LogHelper.writeLog(
      "LOCAL SAVE: '${newLog.title}' tersimpan di Hive",
      source: source,
      level: 2,
    );

    try {
      await MongoService().insertLog(newLog);

      final allLocal = _myBox.values.toList();
      final hiveIndex = allLocal.indexWhere((log) => log.id == newLog.id);

      if (hiveIndex != -1) {
        await _myBox.putAt(
          hiveIndex,
          newLog.copyWith(isSynced: true),
        );
      }

      logsNotifier.value =
          _myBox.values.where((log) => log.teamId == teamId).toList();

      await LogHelper.writeLog(
        "SUCCESS: Data tersinkron ke Cloud",
        source: source,
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "WARNING: Data tersimpan lokal, akan sinkron saat online",
        source: source,
        level: 1,
      );
    }
  }

  Future<void> updateLog(
    String currentUserId,
    String currentUserRole,
    int index,
    String newTitle,
    String newDesc,
    String newCategory,
    bool newIsPublic,
  ) async {
    const source = "log_controller.dart";

    final current = List<LogModel>.from(logsNotifier.value);
    if (index < 0 || index >= current.length) return;

    final oldLog = current[index];
    final bool isOwner = oldLog.authorId == currentUserId;

    if (!isOwner) {
      await LogHelper.writeLog(
        "SECURITY BREACH: Unauthorized update attempt on '${oldLog.title}' by user=$currentUserId role=$currentUserRole",
        source: source,
        level: 1,
      );
      return;
    }

    final updatedLog = oldLog.copyWith(
      title: newTitle,
      description: newDesc,
      category: newCategory,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      isSynced: false,
      isPublic: newIsPublic,
    );

    try {
      final allLocal = _myBox.values.toList();
      final hiveIndex = allLocal.indexWhere((log) {
        if (oldLog.id != null && log.id != null) {
          return log.id == oldLog.id;
        }
        return log.title == oldLog.title &&
            log.description == oldLog.description &&
            log.timestamp == oldLog.timestamp &&
            log.authorId == oldLog.authorId;
      });

      if (hiveIndex != -1) {
        await _myBox.putAt(hiveIndex, updatedLog);
      }

      current[index] = updatedLog;
      logsNotifier.value = current;

      await LogHelper.writeLog(
        "LOCAL UPDATE: '${oldLog.title}' -> '${updatedLog.title}' tersimpan di Hive",
        source: source,
        level: 2,
      );

      try {
        await MongoService().updateLog(updatedLog);

        if (hiveIndex != -1) {
          await _myBox.putAt(
            hiveIndex,
            updatedLog.copyWith(isSynced: true),
          );
        }

        logsNotifier.value = _myBox.values
            .where((log) => log.teamId == oldLog.teamId)
            .toList();

        await LogHelper.writeLog(
          "SUCCESS: Update '${updatedLog.title}' berhasil sinkron ke Cloud",
          source: source,
          level: 2,
        );
      } on SocketException {
        await LogHelper.writeLog(
          "WARNING: Update tersimpan lokal, cloud sync pending",
          source: source,
          level: 1,
        );
      } on TimeoutException {
        await LogHelper.writeLog(
          "WARNING: Update timeout, cloud sync pending",
          source: source,
          level: 1,
        );
      }
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Gagal updateLog() - $e",
        source: source,
        level: 1,
      );
      rethrow;
    }
  }

  Future<void> removeLog(
    String currentUserId,
    String currentUserRole,
    int index,
  ) async {
    const source = "log_controller.dart";

    final current = List<LogModel>.from(logsNotifier.value);
    if (index < 0 || index >= current.length) return;

    final targetLog = current[index];
    final bool isOwner = targetLog.authorId == currentUserId;

    if (!isOwner) {
      await LogHelper.writeLog(
        "SECURITY BREACH: Unauthorized delete attempt on '${targetLog.title}' by user=$currentUserId role=$currentUserRole",
        source: source,
        level: 1,
      );
      return;
    }

    try {
      final allLocal = _myBox.values.toList();
      final hiveIndex = allLocal.indexWhere((log) {
        if (targetLog.id != null && log.id != null) {
          return log.id == targetLog.id;
        }
        return log.title == targetLog.title &&
            log.description == targetLog.description &&
            log.timestamp == targetLog.timestamp &&
            log.authorId == targetLog.authorId;
      });

      if (hiveIndex != -1) {
        await _myBox.deleteAt(hiveIndex);
      }

      current.removeAt(index);
      logsNotifier.value = current;

      await LogHelper.writeLog(
        "LOCAL DELETE: '${targetLog.title}' dihapus dari Hive",
        source: source,
        level: 2,
      );

      if (targetLog.id != null) {
        try {
          await MongoService().deleteLog(ObjectId.fromHexString(targetLog.id!));

          await LogHelper.writeLog(
            "SUCCESS: Hapus '${targetLog.title}' berhasil sinkron ke Cloud",
            source: source,
            level: 2,
          );
        } on SocketException {
          await LogHelper.writeLog(
            "WARNING: Delete lokal sukses, hapus cloud pending",
            source: source,
            level: 1,
          );
        } on TimeoutException {
          await LogHelper.writeLog(
            "WARNING: Delete timeout, hapus cloud pending",
            source: source,
            level: 1,
          );
        }
      } else {
        await LogHelper.writeLog(
          "INFO: Log belum punya id cloud, hanya dihapus lokal",
          source: source,
          level: 2,
        );
      }
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Gagal removeLog() - $e",
        source: source,
        level: 1,
      );
      rethrow;
    }
  }

  Future<void> syncPendingLogs(String teamId) async {
    const source = "log_controller.dart";

    try {
      final allLocal = _myBox.values.toList();

      for (int i = 0; i < allLocal.length; i++) {
        final log = allLocal[i];

        if (log.teamId == teamId && !log.isSynced) {
          try {
            await MongoService().insertLog(log);

            await _myBox.putAt(
              i,
              log.copyWith(isSynced: true),
            );
          } catch (_) {
            // biarkan, nanti dicoba lagi saat koneksi pulih
          }
        }
      }

      logsNotifier.value =
          _myBox.values.where((log) => log.teamId == teamId).toList();

      await LogHelper.writeLog(
        "BACKGROUND SYNC: Sinkronisasi pending logs selesai",
        source: source,
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "BACKGROUND SYNC ERROR: $e",
        source: source,
        level: 1,
      );
    }
  }

  static List<LogModel> filterVisibleLogs(
    List<LogModel> allLogs,
    String currentUserId,
  ) {
    return allLogs.where((log) {
      return log.authorId == currentUserId || log.isPublic == true;
    }).toList();
  }
}