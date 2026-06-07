import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../providers/auth_provider.dart';
import '../../providers/events_provider.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/gold_button.dart';
import '../../widgets/loading_widget.dart';

class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventProvider(eventId));
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Event Details')),
      body: eventAsync.when(
        data: (event) {
          if (event == null) {
            return const EmptyStateWidget(
              message: 'This event could not be found.',
              icon: Icons.search_off_rounded,
            );
          }
          final isAttending =
              user != null && event.attendeeUids.contains(user.uid);
          final isCreator = user != null && event.createdBy == user.uid;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  height: 220,
                  child: event.photoURL.isEmpty
                      ? Container(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.18),
                          child: const Icon(Icons.event_rounded, size: 60),
                        )
                      : CachedNetworkImage(
                          imageUrl: event.photoURL,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => const LoadingWidget(),
                          errorWidget: (_, _, _) =>
                              const Icon(Icons.broken_image_outlined),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                event.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                event.clubName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.schedule),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event.date == null
                          ? 'Date TBD'
                          : DateFormat(
                              'EEEE, MMM d, y • HH:mm',
                            ).format(event.date!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined),
                  const SizedBox(width: 8),
                  Expanded(child: Text(event.location)),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                event.description,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              GoldButton(
                label: isAttending ? 'Cancel RSVP' : 'RSVP to Event',
                onPressed: user == null
                    ? null
                    : () async {
                        try {
                          await ref
                              .read(firestoreServiceProvider)
                              .toggleRsvp(
                                eventId: event.id,
                                uid: user.uid,
                                attend: !isAttending,
                              );
                        } catch (error) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error.toString())),
                          );
                        }
                      },
              ),
              const SizedBox(height: 12),
              Text('${event.attendeeUids.length} students attending'),
              if (isCreator) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  children: [
                    FilledButton.tonal(
                      onPressed: () => context.push('/events/${event.id}/edit'),
                      child: const Text('Edit event'),
                    ),
                    OutlinedButton(
                      onPressed: () async {
                        try {
                          await ref
                              .read(firestoreServiceProvider)
                              .deleteEvent(event.id, user.uid);
                          if (context.mounted) context.pop();
                        } catch (error) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error.toString())),
                          );
                        }
                      },
                      child: const Text('Delete event'),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
        loading: () => const LoadingWidget(),
        error: (error, _) => Center(child: Text(error.toString())),
      ),
    );
  }
}
