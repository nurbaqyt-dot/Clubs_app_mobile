import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/announcement_model.dart';
import 'auth_provider.dart';

final announcementsStreamProvider = Provider<Stream<List<AnnouncementModel>>>((
  ref,
) {
  return ref.watch(firestoreServiceProvider).announcementsStream();
});

final announcementsProvider = StreamProvider<List<AnnouncementModel>>((ref) {
  return ref.watch(announcementsStreamProvider);
});

final announcementProvider = StreamProvider.family<AnnouncementModel?, String>((
  ref,
  announcementId,
) {
  return ref.watch(firestoreServiceProvider).announcementStream(announcementId);
});

final announcementControllerProvider = Provider<AnnouncementController>((ref) {
  return AnnouncementController(ref);
});

class AnnouncementController {
  AnnouncementController(this._ref);

  final Ref _ref;

  Future<String> create({
    required String title,
    required String description,
  }) async {
    final profile = await _ref.read(userProfileProvider.future);
    if (profile == null) {
      throw Exception('Please sign in again to create an announcement.');
    }
    return _ref
        .read(firestoreServiceProvider)
        .createAnnouncement(
          title: title,
          description: description,
          createdBy: profile.uid,
          creatorName: profile.fullName,
        );
  }

  Future<void> update({
    required AnnouncementModel announcement,
    required String title,
    required String description,
  }) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) {
      throw Exception('Please sign in again to update this announcement.');
    }
    await _ref
        .read(firestoreServiceProvider)
        .updateAnnouncement(
          announcement.copyWith(title: title, description: description),
          user.uid,
        );
  }

  Future<void> delete(String announcementId) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) {
      throw Exception('Please sign in again to delete this announcement.');
    }
    await _ref
        .read(firestoreServiceProvider)
        .deleteAnnouncement(announcementId, user.uid);
  }
}
