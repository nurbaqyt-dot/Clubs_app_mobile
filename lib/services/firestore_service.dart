import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/club_model.dart';
import '../models/announcement_model.dart';
import '../models/event_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _clubs =>
      _firestore.collection('clubs');
  CollectionReference<Map<String, dynamic>> get _events =>
      _firestore.collection('events');
  CollectionReference<Map<String, dynamic>> get _announcements =>
      _firestore.collection('announcements');

  Future<AppUser?> getUserProfile(String uid) async {
    final snapshot = await _users.doc(uid).get();
    if (!snapshot.exists) return null;
    return AppUser.fromFirestore(snapshot);
  }

  Future<void> syncUser(
    User user, {
    String? fullName,
    String? studentId,
    UserRole? role,
  }) async {
    final doc = _users.doc(user.uid);
    final snapshot = await doc.get();
    final existing = snapshot.exists ? AppUser.fromFirestore(snapshot) : null;

    final profile = AppUser(
      uid: user.uid,
      fullName: fullName ?? existing?.fullName ?? user.displayName ?? '',
      email: user.email ?? existing?.email ?? '',
      studentId: studentId ?? existing?.studentId ?? '',
      role: role ?? existing?.role ?? UserRole.member,
      profileImage: user.photoURL ?? existing?.profileImage ?? '',
      joinedClubs: existing?.joinedClubs ?? const [],
      savedClubs: existing?.savedClubs ?? const [],
      createdAt: existing?.createdAt ?? DateTime.now(),
    );

    await doc.set(profile.toMap(), SetOptions(merge: true));
  }

  Stream<AppUser?> userStream(String uid) {
    return _users
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? AppUser.fromFirestore(doc) : null);
  }

  Future<void> updateUserProfile({
    required String uid,
    required String fullName,
    required String email,
    required String studentId,
    required UserRole role,
    required String profileImage,
  }) async {
    await _users.doc(uid).set({
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'studentId': studentId,
      'role': role.value,
      'profileImage': profileImage,
    }, SetOptions(merge: true));
  }

  Future<List<AppUser>> fetchUsersByIds(List<String> uids) async {
    if (uids.isEmpty) return [];
    final users = <AppUser>[];
    for (var i = 0; i < uids.length; i += 10) {
      final chunk = uids.skip(i).take(10).toList();
      final snapshot = await _users
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      users.addAll(snapshot.docs.map(AppUser.fromFirestore));
    }
    users.sort((a, b) => a.fullName.compareTo(b.fullName));
    return users;
  }

  Stream<List<ClubModel>> clubsStream({String? category}) {
    Query<Map<String, dynamic>> query = _clubs.orderBy(
      'createdAt',
      descending: true,
    );
    if (category != null && category.isNotEmpty && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }
    return query.snapshots().map(
      (snapshot) => snapshot.docs.map(ClubModel.fromFirestore).toList(),
    );
  }

  Stream<List<ClubModel>> featuredClubsStream() {
    return _clubs
        .orderBy('memberCount', descending: true)
        .limit(5)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(ClubModel.fromFirestore).toList());
  }

  Stream<ClubModel?> clubStream(String clubId) {
    return _clubs
        .doc(clubId)
        .snapshots()
        .map((doc) => doc.exists ? ClubModel.fromFirestore(doc) : null);
  }

  Stream<List<ClubModel>> clubsForUserStream(String uid) {
    return _clubs
        .where('memberUids', arrayContains: uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(ClubModel.fromFirestore).toList());
  }

  Stream<List<ClubModel>> clubsForAdminStream(String uid) {
    return _clubs
        .where('adminUid', isEqualTo: uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(ClubModel.fromFirestore).toList());
  }

  Future<void> _ensureHeadRole(String uid) async {
    final profile = await getUserProfile(uid);
    if (profile == null || !profile.isHead) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Only heads can manage clubs and events.',
      );
    }
  }

  Future<String> createClub(ClubModel club) async {
    await _ensureHeadRole(club.adminUid);
    final doc = _clubs.doc();
    await doc.set({
      ...club.copyWith(memberCount: 1, memberUids: [club.adminUid]).toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _users.doc(club.adminUid).set({
      'joinedClubs': FieldValue.arrayUnion([doc.id]),
    }, SetOptions(merge: true));
    return doc.id;
  }

  Future<void> updateClub(ClubModel club) async {
    await _ensureHeadRole(club.adminUid);
    final snapshot = await _clubs.doc(club.id).get();
    if (!snapshot.exists) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'not-found',
        message: 'This club no longer exists.',
      );
    }
    final existingClub = ClubModel.fromFirestore(snapshot);
    if (existingClub.adminUid != club.adminUid) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Only the club creator can edit this club.',
      );
    }
    await _clubs.doc(club.id).update({
      'name': club.name,
      'description': club.description,
      'category': club.category,
      'photoURL': club.photoURL,
    });
  }

  Future<void> deleteClub(String clubId, String actingUid) async {
    await _ensureHeadRole(actingUid);
    final club = await _clubs.doc(clubId).get();
    if (!club.exists) return;
    final clubModel = ClubModel.fromFirestore(club);
    if (clubModel.adminUid != actingUid) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'You can only delete clubs you created.',
      );
    }
    final events = await _events.where('clubId', isEqualTo: clubId).get();
    final batch = _firestore.batch();
    for (final doc in events.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_clubs.doc(clubId));
    await batch.commit();
  }

  Future<void> joinClub({required String clubId, required String uid}) async {
    await _firestore.runTransaction((transaction) async {
      final clubRef = _clubs.doc(clubId);
      final userRef = _users.doc(uid);
      final clubSnapshot = await transaction.get(clubRef);
      final club = ClubModel.fromFirestore(clubSnapshot);
      if (club.memberUids.contains(uid)) return;
      transaction.update(clubRef, {
        'memberUids': FieldValue.arrayUnion([uid]),
        'memberCount': club.memberCount + 1,
      });
      transaction.set(userRef, {
        'joinedClubs': FieldValue.arrayUnion([clubId]),
      }, SetOptions(merge: true));
    });
  }

  Future<void> leaveClub({required String clubId, required String uid}) async {
    await _firestore.runTransaction((transaction) async {
      final clubRef = _clubs.doc(clubId);
      final userRef = _users.doc(uid);
      final clubSnapshot = await transaction.get(clubRef);
      final club = ClubModel.fromFirestore(clubSnapshot);
      if (!club.memberUids.contains(uid)) return;
      transaction.update(clubRef, {
        'memberUids': FieldValue.arrayRemove([uid]),
        'memberCount': club.memberCount > 0 ? club.memberCount - 1 : 0,
      });
      transaction.set(userRef, {
        'joinedClubs': FieldValue.arrayRemove([clubId]),
      }, SetOptions(merge: true));
    });
  }

  Future<void> toggleSavedClub({
    required String clubId,
    required String uid,
    required bool save,
  }) {
    return _users.doc(uid).set({
      'savedClubs': save
          ? FieldValue.arrayUnion([clubId])
          : FieldValue.arrayRemove([clubId]),
    }, SetOptions(merge: true));
  }

  Stream<List<EventModel>> eventsStream({String? clubId}) {
    Query<Map<String, dynamic>> query = _events.orderBy('date');
    if (clubId != null && clubId.isNotEmpty) {
      query = query.where('clubId', isEqualTo: clubId);
    }
    return query.snapshots().map(
      (snapshot) => snapshot.docs.map(EventModel.fromFirestore).toList(),
    );
  }

  Stream<List<EventModel>> joinedEventsStream(String uid) {
    return _events
        .where('attendeeUids', arrayContains: uid)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(EventModel.fromFirestore).toList(),
        );
  }

  Stream<EventModel?> eventStream(String eventId) {
    return _events
        .doc(eventId)
        .snapshots()
        .map((doc) => doc.exists ? EventModel.fromFirestore(doc) : null);
  }

  Future<String> createEvent(EventModel event) async {
    await _ensureHeadRole(event.createdBy);
    final club = await _clubs.doc(event.clubId).get();
    if (!club.exists ||
        ClubModel.fromFirestore(club).adminUid != event.createdBy) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Only the club creator can create events for this club.',
      );
    }
    final doc = _events.doc();
    await doc.set({
      ...event.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> updateEvent(EventModel event) async {
    await _ensureHeadRole(event.createdBy);
    await _events.doc(event.id).update({
      'clubId': event.clubId,
      'clubName': event.clubName,
      'title': event.title,
      'description': event.description,
      'date': event.date == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(event.date!),
      'location': event.location,
      'photoURL': event.photoURL,
    });
  }

  Future<void> deleteEvent(String eventId, String actingUid) async {
    await _ensureHeadRole(actingUid);
    final snapshot = await _events.doc(eventId).get();
    if (snapshot.exists &&
        EventModel.fromFirestore(snapshot).createdBy != actingUid) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'You can only delete events you created.',
      );
    }
    await _events.doc(eventId).delete();
  }

  Future<void> toggleRsvp({
    required String eventId,
    required String uid,
    required bool attend,
  }) async {
    await _events.doc(eventId).update({
      'attendeeUids': attend
          ? FieldValue.arrayUnion([uid])
          : FieldValue.arrayRemove([uid]),
    });
  }

  Stream<List<AnnouncementModel>> announcementsStream() {
    return _announcements
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(AnnouncementModel.fromFirestore).toList(),
        );
  }

  Stream<AnnouncementModel?> announcementStream(String announcementId) {
    return _announcements
        .doc(announcementId)
        .snapshots()
        .map((doc) => doc.exists ? AnnouncementModel.fromFirestore(doc) : null);
  }

  Future<void> _ensureAnnouncementCreator({
    required String announcementId,
    required String actingUid,
  }) async {
    await _ensureHeadRole(actingUid);
    final snapshot = await _announcements.doc(announcementId).get();
    if (!snapshot.exists) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'not-found',
        message: 'This announcement no longer exists.',
      );
    }
    final announcement = AnnouncementModel.fromFirestore(snapshot);
    if (announcement.createdBy != actingUid) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'You can only manage announcements you created.',
      );
    }
  }

  Future<String> createAnnouncement({
    required String title,
    required String description,
    required String createdBy,
    required String creatorName,
  }) async {
    await _ensureHeadRole(createdBy);
    final doc = _announcements.doc();
    await doc.set({
      'id': doc.id,
      'title': title,
      'description': description,
      'createdBy': createdBy,
      'creatorName': creatorName,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> updateAnnouncement(
    AnnouncementModel announcement,
    String actingUid,
  ) async {
    await _ensureAnnouncementCreator(
      announcementId: announcement.id,
      actingUid: actingUid,
    );
    await _announcements.doc(announcement.id).update({
      'title': announcement.title,
      'description': announcement.description,
    });
  }

  Future<void> deleteAnnouncement(
    String announcementId,
    String actingUid,
  ) async {
    await _ensureAnnouncementCreator(
      announcementId: announcementId,
      actingUid: actingUid,
    );
    await _announcements.doc(announcementId).delete();
  }
}
