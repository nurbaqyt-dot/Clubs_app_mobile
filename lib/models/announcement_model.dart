import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementModel {
  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.createdBy,
    required this.creatorName,
  });

  final String id;
  final String title;
  final String description;
  final DateTime? createdAt;
  final String createdBy;
  final String creatorName;

  factory AnnouncementModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return AnnouncementModel(
      id: data['id'] as String? ?? doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      createdBy: data['createdBy'] as String? ?? '',
      creatorName: data['creatorName'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
      'createdBy': createdBy,
      'creatorName': creatorName,
    };
  }

  AnnouncementModel copyWith({
    String? title,
    String? description,
    DateTime? createdAt,
    String? createdBy,
    String? creatorName,
  }) {
    return AnnouncementModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      creatorName: creatorName ?? this.creatorName,
    );
  }
}
