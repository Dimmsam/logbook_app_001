import 'package:hive/hive.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;
import 'dart:convert';
import 'dart:typed_data';

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
  final String date;

  @HiveField(4)
  final String authorId;

  @HiveField(5)
  final String teamId;

  /// true  = seluruh anggota tim bisa melihat catatan ini.
  /// false = hanya pemilik (authorId) yang bisa melihat.
  @HiveField(6)
  final bool isPublic;

  /// Kategori catatan: 'Mechanical', 'Electronic', atau 'Software'.
  @HiveField(7)
  final String category;

  /// Base64-encoded image data captured from Smart-Patrol Vision (optional)
  @HiveField(8)
  final String? imageData;

  /// PCD filter applied to captured image (optional)
  @HiveField(9)
  final String? imageFilter;

  LogModel({
    this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.authorId,
    required this.teamId,
    this.isPublic = false,
    this.category = 'Software',
    this.imageData,
    this.imageFilter,
  });

  Map<String, dynamic> toMap() => {
    '_id': id != null ? ObjectId.fromHexString(id!) : ObjectId(),
    'title': title,
    'description': description,
    'date': date,
    'authorId': authorId,
    'teamId': teamId,
    'isPublic': isPublic,
    'category': category,
    'imageData': imageData,
    'imageFilter': imageFilter,
  };

  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      id: (map['_id'] as ObjectId?)?.oid,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: map['date'] ?? '',
      authorId: map['authorId'] ?? 'unknown_user',
      teamId: map['teamId'] ?? 'no_team',
      isPublic: map['isPublic'] as bool? ?? false,
      category: map['category'] as String? ?? 'Software',
      imageData: map['imageData'] as String?,
      imageFilter: map['imageFilter'] as String?,
    );
  }

  /// Create a copy of this LogModel with optional updated fields
  LogModel copyWith({
    String? id,
    String? title,
    String? description,
    String? date,
    String? authorId,
    String? teamId,
    bool? isPublic,
    String? category,
    String? imageData,
    String? imageFilter,
  }) {
    return LogModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      authorId: authorId ?? this.authorId,
      teamId: teamId ?? this.teamId,
      isPublic: isPublic ?? this.isPublic,
      category: category ?? this.category,
      imageData: imageData ?? this.imageData,
      imageFilter: imageFilter ?? this.imageFilter,
    );
  }

  /// Convert Uint8List image to Base64 string for storage
  static String encodeImageToBase64(Uint8List imageBytes) {
    return base64Encode(imageBytes);
  }

  /// Decode Base64 string back to Uint8List
  static Uint8List decodeBase64ToImage(String base64String) {
    return base64Decode(base64String);
  }

  /// Check if this log has an attached image
  bool hasImage() => imageData != null && imageData!.isNotEmpty;

  /// Get image as Uint8List (returns null if no image)
  Uint8List? getImageBytes() {
    if (imageData == null) return null;
    try {
      return decodeBase64ToImage(imageData!);
    } catch (e) {
      return null;
    }
  }
}
