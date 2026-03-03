import 'dart:async';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logbook_app_094/features/logbook/models/log_model.dart';
import 'package:logbook_app_094/helpers/log_helper.dart';
import 'package:mongo_dart/mongo_dart.dart';

class MongoService {
  static final MongoService _instance = MongoService._internal();
  factory MongoService() => _instance;
  MongoService._internal();

  Db? _db;
  DbCollection? _collection;

  final String _source = "mongo_service.dart";

  /// ==============================
  /// SAFE COLLECTION (anti null error)
  /// ==============================
  Future<DbCollection> _getSafeCollection() async {
    if (_db == null || !_db!.isConnected || _collection == null) {
      await LogHelper.writeLog(
        "INFO: Koleksi belum siap, mencoba koneksi ulang...",
        source: _source,
        level: 3,
      );
      await connect();
    }
    return _collection!;
  }

  /// ==============================
  /// CONNECT (dengan timeout & guard)
  /// ==============================
  Future<void> connect() async {
    try {
      if (_db != null && _db!.isConnected) return;

      final uri = dotenv.env['MONGODB_URI'];
      if (uri == null || uri.isEmpty) {
        throw Exception("MONGODB_URI tidak ditemukan di .env");
      }

      _db = await Db.create(uri);

      await _db!.open().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException(
          "Koneksi timeout. Cek IP Whitelist (0.0.0.0/0) atau jaringan.",
        ),
      );

      _collection = _db!.collection('logs');

      await LogHelper.writeLog(
        "DATABASE: Terhubung & Koleksi Siap",
        source: _source,
        level: 2,
      );
    } on SocketException {
      await LogHelper.writeLog(
        "DATABASE: Gagal koneksi - SocketException (offline)",
        source: _source,
        level: 1,
      );
      rethrow;
    } on TimeoutException catch (e) {
      await LogHelper.writeLog(
        "DATABASE: Gagal koneksi - TimeoutException ($e)",
        source: _source,
        level: 1,
      );
      rethrow;
    } catch (e) {
      await LogHelper.writeLog(
        "DATABASE: Gagal koneksi - $e",
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }

  /// ==============================
  /// READ
  /// ==============================
  Future<List<LogModel>> getLogs() async {
    try {
      final collection = await _getSafeCollection();

      final List<Map<String, dynamic>> data = await collection
          .find()
          .toList()
          .timeout(const Duration(seconds: 15));

      await LogHelper.writeLog(
        "DATABASE: Fetch ${data.length} data dari Cloud",
        source: _source,
        level: 3,
      );

      return data.map((e) => LogModel.fromMap(e)).toList();
    } on SocketException {
      await LogHelper.writeLog(
        "ERROR: Fetch gagal - SocketException (offline)",
        source: _source,
        level: 1,
      );
      rethrow; // PENTING: biar UI bisa tampilkan warning offline
    } on TimeoutException {
      await LogHelper.writeLog(
        "ERROR: Fetch gagal - TimeoutException",
        source: _source,
        level: 1,
      );
      rethrow;
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Fetch gagal - $e",
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }

  /// ==============================
  /// CREATE
  /// ==============================
  Future<void> insertLog(LogModel log) async {
    try {
      final collection = await _getSafeCollection();
      await collection
          .insertOne(log.toMap())
          .timeout(const Duration(seconds: 15));

      await LogHelper.writeLog(
        "SUCCESS: '${log.title}' disimpan ke Cloud",
        source: _source,
        level: 2,
      );
    } on SocketException {
      await LogHelper.writeLog(
        "ERROR: Insert gagal - SocketException (offline)",
        source: _source,
        level: 1,
      );
      rethrow;
    } on TimeoutException {
      await LogHelper.writeLog(
        "ERROR: Insert gagal - TimeoutException",
        source: _source,
        level: 1,
      );
      rethrow;
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Insert gagal - $e",
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }

  /// ==============================
  /// UPDATE
  /// ==============================
  Future<void> updateLog(LogModel log) async {
    try {
      if (log.id == null) throw Exception("ID null, tidak bisa update.");

      final collection = await _getSafeCollection();
      await collection
          .replaceOne(where.id(log.id!), log.toMap())
          .timeout(const Duration(seconds: 15));

      await LogHelper.writeLog(
        "SUCCESS: Update '${log.title}' berhasil",
        source: _source,
        level: 2,
      );
    } on SocketException {
      await LogHelper.writeLog(
        "ERROR: Update gagal - SocketException (offline)",
        source: _source,
        level: 1,
      );
      rethrow;
    } on TimeoutException {
      await LogHelper.writeLog(
        "ERROR: Update gagal - TimeoutException",
        source: _source,
        level: 1,
      );
      rethrow;
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Update gagal - $e",
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }

  /// ==============================
  /// DELETE
  /// ==============================
  Future<void> deleteLog(ObjectId id) async {
    try {
      final collection = await _getSafeCollection();
      await collection
          .remove(where.id(id))
          .timeout(const Duration(seconds: 15));

      await LogHelper.writeLog(
        "SUCCESS: Hapus ID $id berhasil",
        source: _source,
        level: 2,
      );
    } on SocketException {
      await LogHelper.writeLog(
        "ERROR: Delete gagal - SocketException (offline)",
        source: _source,
        level: 1,
      );
      rethrow;
    } on TimeoutException {
      await LogHelper.writeLog(
        "ERROR: Delete gagal - TimeoutException",
        source: _source,
        level: 1,
      );
      rethrow;
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Delete gagal - $e",
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }

  Future<void> close() async {
    if (_db != null && _db!.isConnected) {
      await _db!.close();
      await LogHelper.writeLog(
        "DATABASE: Koneksi ditutup",
        source: _source,
        level: 2,
      );
    }
  }
}