import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/events_provider.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/event_card.dart';
import '../../widgets/loading_widget.dart';

class JoinedEventsScreen extends ConsumerWidget {
  const JoinedEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final joinedEvents = ref.watch(joinedEventsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Joined Events')),
      body: joinedEvents.when(
        data: (events) {
          if (events.isEmpty) {
            return const EmptyStateWidget(
              message: 'You have not RSVPed to any events yet.',
              icon: Icons.event_note_outlined,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (_, index) => EventCard(
              event: events[index],
              onTap: () => context.push('/events/${events[index].id}'),
            ),
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemCount: events.length,
          );
        },
        loading: () => const LoadingWidget(),
        error: (error, _) => Center(child: Text(error.toString())),
      ),
    );
  }
}
