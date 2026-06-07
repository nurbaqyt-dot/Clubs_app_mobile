import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/clubs_provider.dart';
import '../../providers/events_provider.dart';
import '../../widgets/club_card.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/event_card.dart';
import '../../widgets/loading_widget.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _queryController = TextEditingController();

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clubsAsync = ref.watch(clubsProvider);
    final eventsAsync = ref.watch(eventsProvider);
    final query = _queryController.text.trim().toLowerCase();

    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _queryController,
              decoration: const InputDecoration(
                hintText: 'Search clubs and events',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: clubsAsync.when(
                data: (clubs) => eventsAsync.when(
                  data: (events) {
                    final filteredClubs = clubs.where((club) {
                      return query.isEmpty ||
                          club.name.toLowerCase().contains(query) ||
                          club.category.toLowerCase().contains(query) ||
                          club.description.toLowerCase().contains(query);
                    }).toList();
                    final filteredEvents = events.where((event) {
                      return query.isEmpty ||
                          event.title.toLowerCase().contains(query) ||
                          event.clubName.toLowerCase().contains(query) ||
                          event.location.toLowerCase().contains(query);
                    }).toList();
                    if (filteredClubs.isEmpty && filteredEvents.isEmpty) {
                      return const EmptyStateWidget(
                        message: 'No clubs or events matched your search.',
                        icon: Icons.search_off_rounded,
                      );
                    }
                    return ListView(
                      children: [
                        if (filteredClubs.isNotEmpty) ...[
                          Text(
                            'Clubs',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          ...filteredClubs.map(
                            (club) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: ClubCard(
                                club: club,
                                onTap: () => context.push('/clubs/${club.id}'),
                                onEdit: () =>
                                    context.push('/clubs/${club.id}/edit'),
                              ),
                            ),
                          ),
                        ],
                        if (filteredEvents.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Events',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          ...filteredEvents.map(
                            (event) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: EventCard(
                                event: event,
                                onTap: () =>
                                    context.push('/events/${event.id}'),
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                  loading: () => const LoadingWidget(),
                  error: (error, _) => Center(child: Text(error.toString())),
                ),
                loading: () => const LoadingWidget(),
                error: (error, _) => Center(child: Text(error.toString())),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
