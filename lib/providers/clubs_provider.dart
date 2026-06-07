import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/club_model.dart';
import 'auth_provider.dart';

final selectedClubCategoryProvider = StateProvider<String>((ref) => 'All');

final allClubsProvider = StreamProvider<List<ClubModel>>((ref) {
  return ref.watch(firestoreServiceProvider).clubsStream();
});

final clubsProvider = Provider<AsyncValue<List<ClubModel>>>((ref) {
  final category = ref.watch(selectedClubCategoryProvider);
  final clubsAsync = ref.watch(allClubsProvider);

  return clubsAsync.whenData((clubs) {
    if (category == 'All') {
      return clubs;
    }
    return clubs.where((club) => club.category == category).toList();
  });
});

final featuredClubsProvider = StreamProvider<List<ClubModel>>((ref) {
  return ref.watch(firestoreServiceProvider).featuredClubsStream();
});

final clubProvider = StreamProvider.family<ClubModel?, String>((ref, clubId) {
  return ref.watch(firestoreServiceProvider).clubStream(clubId);
});

final myClubsProvider = StreamProvider<List<ClubModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream.value(const []);
  }
  return ref.watch(firestoreServiceProvider).clubsForUserStream(user.uid);
});

final adminClubsProvider = StreamProvider<List<ClubModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream.value(const []);
  }
  return ref.watch(firestoreServiceProvider).clubsForAdminStream(user.uid);
});

final savedClubsProvider = Provider<List<ClubModel>>((ref) {
  final user = ref.watch(userProfileProvider).valueOrNull;
  final clubs = ref.watch(allClubsProvider).valueOrNull ?? const <ClubModel>[];
  if (user == null) return const [];
  return clubs.where((club) => user.savedClubs.contains(club.id)).toList();
});
