import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final firestoreServiceProvider = Provider<FirestoreService>(
  (ref) => FirestoreService(),
);

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).currentUser;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateChangesProvider).valueOrNull ??
      ref.watch(authServiceProvider).activeUser;
});

final userProfileProvider = StreamProvider<AppUser?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream.value(null);
  }
  return ref.watch(firestoreServiceProvider).userStream(user.uid);
});
