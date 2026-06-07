import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/event_model.dart';
import 'auth_provider.dart';

final eventsProvider = StreamProvider<List<EventModel>>((ref) {
  return ref.watch(firestoreServiceProvider).eventsStream();
});

final eventsByClubProvider = StreamProvider.family<List<EventModel>, String>((
  ref,
  clubId,
) {
  return ref.watch(firestoreServiceProvider).eventsStream(clubId: clubId);
});

final eventProvider = StreamProvider.family<EventModel?, String>((
  ref,
  eventId,
) {
  return ref.watch(firestoreServiceProvider).eventStream(eventId);
});

final joinedEventsProvider = StreamProvider<List<EventModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream.value(const []);
  }
  return ref.watch(firestoreServiceProvider).joinedEventsStream(user.uid);
});
