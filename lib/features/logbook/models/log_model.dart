import 'package:mongo_dart/mongo_dart.dart';

class LogModel {
  final ObjectId? id; // tambahan untuk MongoDB
  final String title;
  final String description;
  final int timestamp;
  final String category;

  LogModel({
    this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.category,
  });

  DateTime get date => DateTime.fromMillisecondsSinceEpoch(timestamp);

factory LogModel.fromMap(Map<String, dynamic> map) {
  final rawId = map['_id'];

  ObjectId? parsedId;
  if (rawId is ObjectId) {
    parsedId = rawId;
  } else if (rawId is String) {
    parsedId = ObjectId.tryParse(rawId);
  }

  DateTime parsedDate = DateTime.now();
  final rawDate = map['date'];
  if (rawDate is String) {
    parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
  } else if (rawDate is DateTime) {
    parsedDate = rawDate;
  }

  final int parsedTimestamp =
      (map['timestamp'] is int) ? map['timestamp'] as int : parsedDate.millisecondsSinceEpoch;

  return LogModel(
    id: parsedId,
    title: (map['title'] ?? '').toString(),
    description: (map['description'] ?? '').toString(),
    timestamp: parsedTimestamp,
    category: (map['category'] ?? 'Pribadi').toString(),
  );
}

  Map<String, dynamic> toMap() {
    return {
      '_id': id ?? ObjectId(), // WAJIB untuk MongoDB
      'title': title,
      'description': description,
      'timestamp': timestamp,
      'category': category,
      'date': date.toIso8601String(), // sesuai modul
    };
  }

  LogModel copyWith({
    ObjectId? id,
    String? title,
    String? description,
    int? timestamp,
    String? category,
  }) {
    return LogModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      category: category ?? this.category,
    );
  }
}