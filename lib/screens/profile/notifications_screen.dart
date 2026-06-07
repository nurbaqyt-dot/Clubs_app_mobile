import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/announcements_provider.dart';
import '../../providers/clubs_provider.dart';
import '../../providers/events_provider.dart';
import '../../widgets/announcement_card.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/loading_widget.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementsAsync = ref.watch(announcementsProvider);
    final myClubsAsync = ref.watch(myClubsProvider);
    final eventsAsync = ref.watch(eventsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: announcementsAsync.when(
        data: (announcements) => myClubsAsync.when(
          data: (clubs) {
            final clubIds = clubs.map((club) => club.id).toSet();
            return eventsAsync.when(
              data: (events) {
                final joinedEvents = events
                    .where((event) => clubIds.contains(event.clubId))
                    .take(5)
                    .toList();
                final latestAnnouncements = announcements.take(5).toList();
                if (joinedEvents.isEmpty && latestAnnouncements.isEmpty) {
                  return const EmptyStateWidget(
                    message:
                        'No notifications yet. Join clubs to receive event and announcement updates.',
                    icon: Icons.notifications_off_outlined,
                  );
                }
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    ...joinedEvents.map(
                      (event) => Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const Icon(Icons.event_outlined),
                          title: Text(event.title),
                          subtitle: Text(
                            '${event.clubName} • ${event.location}',
                          ),
                        ),
                      ),
                    ),
                    ...latestAnnouncements.map(
                      (announcement) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AnnouncementCard(
                          announcement: announcement,
                          onTap: () =>
                              context.push('/announcements/${announcement.id}'),
                        ),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const LoadingWidget(),
              error: (error, _) => Center(child: Text(error.toString())),
            );
          },
          loading: () => const LoadingWidget(),
          error: (error, _) => Center(child: Text(error.toString())),
        ),
        loading: () => const LoadingWidget(),
        error: (error, _) => Center(child: Text(error.toString())),
      ),
    );
  }
}
