import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/log_model.dart';

class LogController {
  final ValueNotifier<List<LogModel>> logsNotifier =
      ValueNotifier<List<LogModel>>([]);

  // key per user (nyambung modul 2)
  String _storageKey(String username) => 'user_logs_data_$username';

  // ==============================
  // LOAD & SAVE PER USER
  // ==============================
  Future<void> loadFromDisk(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey(username));

    if (data == null || data.isEmpty) {
      logsNotifier.value = [];
      return;
    }

    final decoded = jsonDecode(data) as List<dynamic>;
    logsNotifier.value = decoded
        .map((e) => LogModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> saveToDisk(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final mapped = logsNotifier.value.map((e) => e.toMap()).toList();
    await prefs.setString(_storageKey(username), jsonEncode(mapped));
  }

  Future<void> clearUserData(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey(username));
    logsNotifier.value = [];
  }

  // ==============================
  // CRUD LOGBOOK
  // ==============================
  Future<void> addLog(
    String username,
    String title,
    String desc,
    String category,
  ) async {
    final newLog = LogModel(
      title: title,
      description: desc,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      category: category,
    );

    logsNotifier.value = [...logsNotifier.value, newLog];
    await saveToDisk(username);
  }

  Future<void> updateLog(
    String username,
    int index,
    String title,
    String desc,
    String category,
  ) async {
    final current = List<LogModel>.from(logsNotifier.value);
    if (index < 0 || index >= current.length) return;

    current[index] = LogModel(
      title: title,
      description: desc,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      category: category,
    );

    logsNotifier.value = current;
    await saveToDisk(username);
  }

  Future<void> removeLog(String username, int index) async {
    final current = List<LogModel>.from(logsNotifier.value);
    if (index < 0 || index >= current.length) return;

    current.removeAt(index);
    logsNotifier.value = current;
    await saveToDisk(username);
  }
}