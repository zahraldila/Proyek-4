import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logbook_app_094/features/logbook/models/log_model.dart';
import 'package:logbook_app_094/helpers/log_helper.dart';

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
      if (_db != null && _db!.isConnected) {
        return; // sudah terkoneksi
      }

      final uri = dotenv.env['MONGODB_URI'];

      if (uri == null || uri.isEmpty) {
        throw Exception("MONGODB_URI tidak ditemukan di .env");
      }

      _db = await Db.create(uri);

      await _db!.open().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception(
            "Koneksi Timeout. Cek IP Whitelist (0.0.0.0/0) atau jaringan.",
          );
        },
      );

      _collection = _db!.collection('logs');

      await LogHelper.writeLog(
        "DATABASE: Terhubung & Koleksi Siap",
        source: _source,
        level: 2,
      );
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

    // await Future.delayed(const Duration(seconds: 5));

    try {
      final collection = await _getSafeCollection();

      final List<Map<String, dynamic>> data =
          await collection.find().toList();

      await LogHelper.writeLog(
        "DATABASE: Fetch ${data.length} data dari Cloud",
        source: _source,
        level: 3,
      );

      return data.map((e) => LogModel.fromMap(e)).toList();
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Fetch gagal - $e",
        source: _source,
        level: 1,
      );
      return [];
    }
  }

  /// ==============================
  /// CREATE
  /// ==============================
  Future<void> insertLog(LogModel log) async {
    try {
      final collection = await _getSafeCollection();
      await collection.insertOne(log.toMap());

      await LogHelper.writeLog(
        "SUCCESS: '${log.title}' disimpan ke Cloud",
        source: _source,
        level: 2,
      );
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
      if (log.id == null) {
        throw Exception("ID null, tidak bisa update.");
      }

      final collection = await _getSafeCollection();
      await collection.replaceOne(where.id(log.id!), log.toMap());

      await LogHelper.writeLog(
        "SUCCESS: Update '${log.title}' berhasil",
        source: _source,
        level: 2,
      );
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
      await collection.remove(where.id(id));

      await LogHelper.writeLog(
        "SUCCESS: Hapus ID $id berhasil",
        source: _source,
        level: 2,
      );
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