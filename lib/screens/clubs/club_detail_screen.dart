import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/clubs_provider.dart';
import '../../providers/events_provider.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/event_card.dart';
import '../../widgets/gold_button.dart';
import '../../widgets/loading_widget.dart';

class ClubDetailScreen extends ConsumerWidget {
  const ClubDetailScreen({super.key, required this.clubId});

  final String clubId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clubAsync = ref.watch(clubProvider(clubId));
    final user = ref.watch(currentUserProvider);
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final eventsAsync = ref.watch(eventsByClubProvider(clubId));

    return Scaffold(
      appBar: AppBar(title: const Text('Club Details')),
      body: clubAsync.when(
        data: (club) {
          if (club == null) {
            return const EmptyStateWidget(
              message: 'This club could not be found.',
              icon: Icons.search_off_rounded,
            );
          }
          final isMember = user != null && club.memberUids.contains(user.uid);
          final isAdmin = user != null && club.adminUid == user.uid;
          final isSaved =
              profile != null && profile.savedClubs.contains(club.id);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (isAdmin)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.tonalIcon(
                      onPressed: () => context.push('/clubs/${club.id}/edit'),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit Club'),
                    ),
                  ),
                ),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  height: 220,
                  child: club.photoURL.isEmpty
                      ? Container(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.18),
                          child: const Icon(Icons.groups_rounded, size: 60),
                        )
                      : CachedNetworkImage(
                          imageUrl: club.photoURL,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => const LoadingWidget(),
                          errorWidget: (_, _, _) =>
                              const Icon(Icons.broken_image_outlined),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              Text(club.name, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  Chip(label: Text(club.category)),
                  Chip(label: Text('${club.memberCount} members')),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                club.description,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              GoldButton(
                label: isMember ? 'Leave Club' : 'Join Club',
                onPressed: user == null
                    ? null
                    : () async {
                        try {
                          final service = ref.read(firestoreServiceProvider);
                          if (isMember) {
                            await service.leaveClub(
                              clubId: club.id,
                              uid: user.uid,
                            );
                          } else {
                            await service.joinClub(
                              clubId: club.id,
                              uid: user.uid,
                            );
                          }
                        } catch (error) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error.toString())),
                          );
                        }
                      },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: user == null
                    ? null
                    : () async {
                        try {
                          await ref
                              .read(firestoreServiceProvider)
                              .toggleSavedClub(
                                clubId: club.id,
                                uid: user.uid,
                                save: !isSaved,
                              );
                        } catch (error) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error.toString())),
                          );
                        }
                      },
                icon: Icon(
                  isSaved
                      ? Icons.bookmark_added_rounded
                      : Icons.bookmark_add_outlined,
                ),
                label: Text(isSaved ? 'Remove from Saved' : 'Save Club'),
              ),
              if (isAdmin) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.tonal(
                      onPressed: () => context.push('/clubs/${club.id}/edit'),
                      child: const Text('Edit club'),
                    ),
                    FilledButton.tonal(
                      onPressed: () =>
                          context.push('/clubs/${club.id}/members'),
                      child: const Text('Members'),
                    ),
                    FilledButton.tonal(
                      onPressed: () =>
                          context.push('/clubs/${club.id}/create-event'),
                      child: const Text('Create event'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete club?'),
                        content: const Text(
                          'This removes the club, its events, and its announcements.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirm != true) return;
                    try {
                      await ref
                          .read(firestoreServiceProvider)
                          .deleteClub(club.id, user.uid);
                      if (context.mounted) context.pop();
                    } catch (error) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(error.toString())));
                    }
                  },
                  child: const Text('Delete club'),
                ),
              ],
              const SizedBox(height: 28),
              Text(
                'Upcoming Events',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              eventsAsync.when(
                data: (events) {
                  if (events.isEmpty) {
                    return const EmptyStateWidget(
                      message: 'No events scheduled for this club yet.',
                      icon: Icons.event_busy_outlined,
                    );
                  }
                  return Column(
                    children: events
                        .map(
                          (event) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: EventCard(
                              event: event,
                              onTap: () => context.push('/events/${event.id}'),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
                loading: () => const LoadingWidget(),
                error: (error, _) => const EmptyStateWidget(
                  message: 'No upcoming events yet',
                  icon: Icons.event_busy_outlined,
                ),
              ),
            ],
          );
        },
        loading: () => const LoadingWidget(),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not load this club.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
