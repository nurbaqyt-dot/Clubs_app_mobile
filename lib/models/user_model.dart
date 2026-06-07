import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  member,
  head;

  String get value => name;

  static UserRole fromString(String? value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.member,
    );
  }
}

class AppUser {
  const AppUser({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.studentId,
    required this.role,
    required this.profileImage,
    required this.joinedClubs,
    required this.savedClubs,
    required this.createdAt,
  });

  final String uid;
  final String fullName;
  final String email;
  final String studentId;
  final UserRole role;
  final String profileImage;
  final List<String> joinedClubs;
  final List<String> savedClubs;
  final DateTime? createdAt;

  String get displayName => fullName;
  String get photoURL => profileImage;
  bool get isHead => role == UserRole.head;
  bool get isMember => role == UserRole.member;

  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return AppUser(
      uid: data['uid'] as String? ?? doc.id,
      fullName:
          data['fullName'] as String? ?? data['displayName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      studentId: data['studentId'] as String? ?? '',
      role: UserRole.fromString(data['role'] as String?),
      profileImage:
          data['profileImage'] as String? ?? data['photoURL'] as String? ?? '',
      joinedClubs: List<String>.from(data['joinedClubs'] as List? ?? const []),
      savedClubs: List<String>.from(data['savedClubs'] as List? ?? const []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'studentId': studentId,
      'role': role.value,
      'profileImage': profileImage,
      'joinedClubs': joinedClubs,
      'savedClubs': savedClubs,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
    };
  }

  AppUser copyWith({
    String? fullName,
    String? email,
    String? studentId,
    UserRole? role,
    String? profileImage,
    List<String>? joinedClubs,
    List<String>? savedClubs,
    DateTime? createdAt,
  }) {
    return AppUser(
      uid: uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      studentId: studentId ?? this.studentId,
      role: role ?? this.role,
      profileImage: profileImage ?? this.profileImage,
      joinedClubs: joinedClubs ?? this.joinedClubs,
      savedClubs: savedClubs ?? this.savedClubs,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
