class LogModel {
  final String title;
  final String date;
  final String description;

  LogModel({
    required this.title,
    required this.date,
    required this.description,
  });

  // Konversi Map (JSON) -> Object
  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      title: map['title'],
      date: map['date'],
      description: map['description'],
    );
  }

  // Konversi Object -> Map (JSON)
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'date': date,
      'description': description,
    };
  }
}