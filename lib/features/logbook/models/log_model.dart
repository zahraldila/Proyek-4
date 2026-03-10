import 'package:hive/hive.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

part 'log_model.g.dart';

@HiveType(typeId: 0)
class LogModel {
  @HiveField(0)
  final String? id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final int timestamp;

  @HiveField(4)
  final String category;

  @HiveField(5)
  final String authorId;

  @HiveField(6)
  final String teamId;

  // 🔵 Status sinkronisasi cloud
  @HiveField(7, defaultValue: false)
  final bool isSynced;

  LogModel({
    this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.category,
    required this.authorId,
    required this.teamId,
    required this.isSynced,
  });

  /// Dipakai UI lama kamu
  DateTime get date => DateTime.fromMillisecondsSinceEpoch(timestamp);

  /// Alias biar tetap cocok dengan kode log_view.dart
  DateTime get createdAt => date;

  Map<String, dynamic> toMap() {
    return {
      '_id': id != null ? ObjectId.fromHexString(id!) : ObjectId(),
      'title': title,
      'description': description,
      'timestamp': timestamp,
      'category': category,
      'authorId': authorId,
      'teamId': teamId,
      'date': date.toIso8601String(),
      'isSynced': isSynced,
    };
  }

  factory LogModel.fromMap(Map<String, dynamic> map) {
    final rawId = map['_id'];

    String? parsedId;
    if (rawId is ObjectId) {
      parsedId = rawId.oid;
    } else if (rawId is String) {
      parsedId = rawId;
    }

    DateTime parsedDate = DateTime.now();
    final rawDate = map['date'];
    if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else if (rawDate is DateTime) {
      parsedDate = rawDate;
    }

    final int parsedTimestamp = (map['timestamp'] is int)
        ? map['timestamp'] as int
        : parsedDate.millisecondsSinceEpoch;

    return LogModel(
      id: parsedId,
      title: (map['title'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      timestamp: parsedTimestamp,
      category: (map['category'] ?? 'Pribadi').toString(),
      authorId: (map['authorId'] ?? 'unknown_user').toString(),
      teamId: (map['teamId'] ?? 'no_team').toString(),
      isSynced: map['isSynced'] ?? true,
    );
  }

  LogModel copyWith({
    String? id,
    String? title,
    String? description,
    int? timestamp,
    String? category,
    String? authorId,
    String? teamId,
    bool? isSynced,
  }) {
    return LogModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      category: category ?? this.category,
      authorId: authorId ?? this.authorId,
      teamId: teamId ?? this.teamId,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}