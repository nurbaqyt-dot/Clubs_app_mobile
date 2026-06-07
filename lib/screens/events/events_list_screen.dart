import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/events_provider.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/event_card.dart';
import '../../widgets/loading_widget.dart';

class EventsListScreen extends ConsumerWidget {
  const EventsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(eventsProvider);
    final profile = ref.watch(userProfileProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        actions: [
          if (profile?.isHead ?? false)
            IconButton(
              onPressed: () => context.push('/events/create'),
              icon: const Icon(Icons.add_circle_outline_rounded),
            ),
          IconButton(
            onPressed: () => context.push('/events/joined'),
            icon: const Icon(Icons.event_note_outlined),
          ),
        ],
      ),
      body: events.when(
        data: (items) {
          if (items.isEmpty) {
            return const EmptyStateWidget(
              message: 'No events yet — create the first one for your club.',
              icon: Icons.event_busy_outlined,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (_, index) => EventCard(
              event: items[index],
              onTap: () => context.push('/events/${items[index].id}'),
            ),
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemCount: items.length,
          );
        },
        loading: () => const LoadingWidget(),
        error: (error, _) => Center(child: Text(error.toString())),
      ),
    );
  }
}
