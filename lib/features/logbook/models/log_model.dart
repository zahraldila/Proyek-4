class LogModel {
  final String title;
  final String description;
  final int timestamp;
  final String category; // NEW

  LogModel({
    required this.title,
    required this.description,
    required this.timestamp,
    required this.category,
  });

  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      timestamp: map['timestamp'] is int
          ? map['timestamp']
          : int.tryParse(map['timestamp'].toString()) ?? 0,
      category: map['category'] ?? 'Pribadi', // default aman
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'timestamp': timestamp,
      'category': category, // NEW
    };
  }
}