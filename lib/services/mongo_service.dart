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

  /// READ: Ambil data dari Cloud berdasarkan teamId
  Future<List<LogModel>> getLogs(String teamId) async {
    try {
      final collection = await _getSafeCollection();

      await LogHelper.writeLog(
        "INFO: Fetching data for Team: $teamId",
        source: _source,
        level: 3,
      );

      final List<Map<String, dynamic>> data = await collection
          .find(where.eq('teamId', teamId))
          .toList()
          .timeout(const Duration(seconds: 15));

      return data.map((json) => LogModel.fromMap(json)).toList();
    } on SocketException {
      await LogHelper.writeLog(
        "ERROR: Fetch gagal - SocketException (offline)",
        source: _source,
        level: 1,
      );
      rethrow;
    } on TimeoutException {
      await LogHelper.writeLog(
        "ERROR: Fetch gagal - TimeoutException",
        source: _source,
        level: 1,
      );
      rethrow;
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Fetch Failed - $e",
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }

  /// CREATE / UPSERT
  /// Mencegah duplikasi saat background sync dijalankan ulang
  Future<void> insertLog(LogModel log) async {
    try {
      final collection = await _getSafeCollection();

      final map = log.toMap();
      final objectId = map['_id'] as ObjectId;

      await collection.updateOne(
        where.id(objectId),
        ModifierBuilder()
          ..set('title', map['title'])
          ..set('description', map['description'])
          ..set('timestamp', map['timestamp'])
          ..set('category', map['category'])
          ..set('authorId', map['authorId'])
          ..set('teamId', map['teamId'])
          ..set('date', map['date']),
        upsert: true,
      ).timeout(const Duration(seconds: 15));

      await LogHelper.writeLog(
        "SUCCESS: '${log.title}' disimpan / diupdate ke Cloud",
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

  /// UPDATE
  Future<void> updateLog(LogModel log) async {
    try {
      if (log.id == null || log.id!.isEmpty) {
        throw Exception("ID null/kosong, tidak bisa update.");
      }

      final collection = await _getSafeCollection();
      final objectId = ObjectId.fromHexString(log.id!);

      await collection
          .replaceOne(where.id(objectId), log.toMap())
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

  /// DELETE
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