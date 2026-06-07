import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  const EventModel({
    required this.id,
    required this.clubId,
    required this.clubName,
    required this.title,
    required this.description,
    required this.date,
    required this.location,
    required this.photoURL,
    required this.attendeeUids,
    required this.createdBy,
    required this.createdAt,
  });

  final String id;
  final String clubId;
  final String clubName;
  final String title;
  final String description;
  final DateTime? date;
  final String location;
  final String photoURL;
  final List<String> attendeeUids;
  final String createdBy;
  final DateTime? createdAt;

  factory EventModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return EventModel(
      id: doc.id,
      clubId: data['clubId'] as String? ?? '',
      clubName: data['clubName'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      date: (data['date'] as Timestamp?)?.toDate(),
      location: data['location'] as String? ?? '',
      photoURL: data['photoURL'] as String? ?? '',
      attendeeUids: List<String>.from(
        data['attendeeUids'] as List? ?? const [],
      ),
      createdBy: data['createdBy'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clubId': clubId,
      'clubName': clubName,
      'title': title,
      'description': description,
      'date': date == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(date!),
      'location': location,
      'photoURL': photoURL,
      'attendeeUids': attendeeUids,
      'createdBy': createdBy,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
    };
  }

  EventModel copyWith({
    String? clubId,
    String? clubName,
    String? title,
    String? description,
    DateTime? date,
    String? location,
    String? photoURL,
    List<String>? attendeeUids,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return EventModel(
      id: id,
      clubId: clubId ?? this.clubId,
      clubName: clubName ?? this.clubName,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      location: location ?? this.location,
      photoURL: photoURL ?? this.photoURL,
      attendeeUids: attendeeUids ?? this.attendeeUids,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
