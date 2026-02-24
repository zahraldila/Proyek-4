class LogModel {
  final String title;
  final String description;
  final int timestamp; // epoch milliseconds

  LogModel({
    required this.title,
    required this.description,
    required this.timestamp,
  });

  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      timestamp: map['timestamp'] is int
          ? map['timestamp']
          : int.tryParse(map['timestamp'].toString()) ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'timestamp': timestamp,
    };
  }
}