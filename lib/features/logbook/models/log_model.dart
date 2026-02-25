class LogModel {
  final String title;
  final String description;
  final DateTime timestamp;
  final String category;

  LogModel({
    required this.title,
    required this.description,
    required this.timestamp,
    this.category = 'Pribadi',
  });

  // Untuk Tugas HOTS: Konversi Map (JSON) ke Object
  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      title: map['title'],
      description: map['description'],
      timestamp: DateTime.parse(map['timestamp']),
      category: map['category'] ?? 'Pribadi',
    );
  }

  // Konversi Object ke Map (JSON) untuk disimpan
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'category': category,
    };
  }
}
