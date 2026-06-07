import 'package:cloud_firestore/cloud_firestore.dart';

class ClubModel {
  const ClubModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.photoURL,
    required this.adminUid,
    required this.memberCount,
    required this.memberUids,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String description;
  final String category;
  final String photoURL;
  final String adminUid;
  final int memberCount;
  final List<String> memberUids;
  final DateTime? createdAt;

  factory ClubModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return ClubModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      category: data['category'] as String? ?? '',
      photoURL: data['photoURL'] as String? ?? '',
      adminUid: data['adminUid'] as String? ?? '',
      memberCount: data['memberCount'] as int? ?? 0,
      memberUids: List<String>.from(data['memberUids'] as List? ?? const []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'photoURL': photoURL,
      'adminUid': adminUid,
      'memberCount': memberCount,
      'memberUids': memberUids,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
    };
  }

  ClubModel copyWith({
    String? name,
    String? description,
    String? category,
    String? photoURL,
    String? adminUid,
    int? memberCount,
    List<String>? memberUids,
    DateTime? createdAt,
  }) {
    return ClubModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      photoURL: photoURL ?? this.photoURL,
      adminUid: adminUid ?? this.adminUid,
      memberCount: memberCount ?? this.memberCount,
      memberUids: memberUids ?? this.memberUids,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
