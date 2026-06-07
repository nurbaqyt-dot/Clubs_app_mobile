import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../screens/announcements/announcement_details_screen.dart';
import '../../screens/announcements/announcements_screen.dart';
import '../../screens/announcements/create_announcement_screen.dart';
import '../../screens/auth/forgot_password_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/onboarding_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/auth/splash_screen.dart';
import '../../screens/clubs/club_detail_screen.dart';
import '../../screens/clubs/clubs_list_screen.dart';
import '../../screens/clubs/create_club_screen.dart';
import '../../screens/clubs/edit_club_screen.dart';
import '../../screens/clubs/members_screen.dart';
import '../../screens/clubs/my_clubs_screen.dart';
import '../../screens/clubs/saved_clubs_screen.dart';
import '../../screens/events/create_event_screen.dart';
import '../../screens/events/edit_event_screen.dart';
import '../../screens/events/event_detail_screen.dart';
import '../../screens/events/events_list_screen.dart';
import '../../screens/events/joined_events_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/home/main_screen.dart';
import '../../screens/profile/about_screen.dart';
import '../../screens/profile/edit_profile_screen.dart';
import '../../screens/profile/notifications_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/profile/settings_screen.dart';
import '../../screens/search/search_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authServiceProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(auth.currentUser),
    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;
      final location = state.matchedLocation;
      final isAuthRoute = location.startsWith('/auth');
      final isOnboarding = location.startsWith('/auth/onboarding');
      final isSplash = location == '/splash';

      if (isSplash) return null;
      if (user == null && !isAuthRoute && !isOnboarding) return '/auth/login';
      if (user != null && (isAuthRoute || isOnboarding)) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth/onboarding/:step',
        name: 'onboarding',
        builder: (context, state) => OnboardingScreen(
          step: int.tryParse(state.pathParameters['step'] ?? '1') ?? 1,
        ),
      ),
      GoRoute(
        path: '/auth/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            MainScreen(location: state.uri.toString(), child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/clubs',
            name: 'clubs',
            builder: (context, state) => const ClubsListScreen(),
          ),
          GoRoute(
            path: '/events',
            name: 'events',
            builder: (context, state) => const EventsListScreen(),
          ),
          GoRoute(
            path: '/search',
            name: 'search',
            builder: (context, state) => const SearchScreen(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/clubs/my',
        name: 'my-clubs',
        builder: (context, state) => const MyClubsScreen(),
      ),
      GoRoute(
        path: '/clubs/saved',
        name: 'saved-clubs',
        builder: (context, state) => const SavedClubsScreen(),
      ),
      GoRoute(
        path: '/clubs/create',
        name: 'create-club',
        builder: (context, state) => const CreateClubScreen(),
      ),
      GoRoute(
        path: '/clubs/:clubId',
        name: 'club-detail',
        builder: (context, state) =>
            ClubDetailScreen(clubId: state.pathParameters['clubId']!),
      ),
      GoRoute(
        path: '/clubs/:clubId/edit',
        name: 'edit-club',
        builder: (context, state) =>
            EditClubScreen(clubId: state.pathParameters['clubId']!),
      ),
      GoRoute(
        path: '/clubs/:clubId/members',
        name: 'members',
        builder: (context, state) =>
            MembersScreen(clubId: state.pathParameters['clubId']!),
      ),
      GoRoute(
        path: '/clubs/:clubId/create-event',
        name: 'club-create-event',
        builder: (context, state) =>
            CreateEventScreen(initialClubId: state.pathParameters['clubId']),
      ),
      GoRoute(
        path: '/events/create',
        name: 'create-event',
        builder: (context, state) => const CreateEventScreen(),
      ),
      GoRoute(
        path: '/events/:eventId',
        name: 'event-detail',
        builder: (context, state) =>
            EventDetailScreen(eventId: state.pathParameters['eventId']!),
      ),
      GoRoute(
        path: '/events/:eventId/edit',
        name: 'edit-event',
        builder: (context, state) =>
            EditEventScreen(eventId: state.pathParameters['eventId']!),
      ),
      GoRoute(
        path: '/events/joined',
        name: 'joined-events',
        builder: (context, state) => const JoinedEventsScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        name: 'edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/profile/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/profile/about',
        name: 'about',
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: '/profile/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/announcements',
        name: 'announcements',
        builder: (context, state) => const AnnouncementsScreen(),
      ),
      GoRoute(
        path: '/announcements/create',
        name: 'create-announcement',
        builder: (context, state) => const CreateAnnouncementScreen(),
      ),
      GoRoute(
        path: '/announcements/:announcementId',
        name: 'announcement-details',
        builder: (context, state) => AnnouncementDetailsScreen(
          announcementId: state.pathParameters['announcementId']!,
        ),
      ),
      GoRoute(
        path: '/announcements/:announcementId/edit',
        name: 'edit-announcement',
        builder: (context, state) => CreateAnnouncementScreen(
          announcementId: state.pathParameters['announcementId']!,
        ),
      ),
    ],
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
