import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/announcement_model.dart';
import '../../providers/announcements_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/clubs_provider.dart';
import '../../widgets/announcement_card.dart';
import '../../widgets/club_card.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/jihc_logo.dart';
import '../../widgets/loading_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featuredClubs = ref.watch(featuredClubsProvider);
    final announcementsStream = ref.watch(announcementsStreamProvider);
    final profile = ref.watch(userProfileProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            JihcLogo(size: 28),
            SizedBox(width: 8),
            Text('JIHC Clubs'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => context.push('/announcements'),
            icon: const Icon(Icons.campaign_outlined),
          ),
          IconButton(
            onPressed: () => context.push('/profile/notifications'),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [Color(0xFFE9C46A), Color(0xFFF5E6B7)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Find your community',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Browse clubs, join events, and keep track of everything happening at JIHC.',
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.tonal(
                      onPressed: () => context.go('/clubs'),
                      child: const Text('Browse clubs'),
                    ),
                    FilledButton.tonal(
                      onPressed: () => context.go('/events'),
                      child: const Text('See events'),
                    ),
                    FilledButton.tonal(
                      onPressed: () => context.push('/announcements'),
                      child: const Text('Announcements'),
                    ),
                    if (profile?.isHead ?? false)
                      FilledButton.tonal(
                        onPressed: () => context.push('/clubs/create'),
                        child: const Text('Create club'),
                      ),
                    if (profile?.isHead ?? false)
                      FilledButton.tonal(
                        onPressed: () => context.push('/announcements/create'),
                        child: const Text('Create Announcement'),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Announcements',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (profile?.isHead ?? false)
                    TextButton(
                      onPressed: () => context.push('/announcements/create'),
                      child: const Text('Create'),
                    ),
                  TextButton(
                    onPressed: () => context.push('/announcements'),
                    child: const Text('View all'),
                  ),
                ],
              ),
            ],
          ),
          StreamBuilder<List<AnnouncementModel>>(
            stream: announcementsStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Card(
                  child: ListTile(
                    title: const Text('Could not load announcements'),
                    subtitle: Text(snapshot.error.toString()),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const SizedBox(height: 120, child: LoadingWidget());
              }
              final items = snapshot.data!;
              if (items.isEmpty) {
                return const SizedBox(
                  height: 160,
                  child: EmptyStateWidget(
                    message:
                        'No announcements yet. Check back soon for campus updates.',
                    icon: Icons.campaign_outlined,
                  ),
                );
              }
              return Column(
                children: items.take(3).map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AnnouncementCard(
                      announcement: item,
                      onTap: () => context.push('/announcements/${item.id}'),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Featured clubs',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton(
                onPressed: () => context.go('/clubs'),
                child: const Text('Explore'),
              ),
            ],
          ),
          featuredClubs.when(
            data: (clubs) {
              if (clubs.isEmpty) {
                return const SizedBox(
                  height: 180,
                  child: EmptyStateWidget(
                    message: 'No clubs yet — be the first to create one!',
                    icon: Icons.groups_2_outlined,
                  ),
                );
              }
              return Column(
                children: clubs
                    .map(
                      (club) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ClubCard(
                          club: club,
                          onTap: () => context.push('/clubs/${club.id}'),
                          onEdit: () => context.push('/clubs/${club.id}/edit'),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
            loading: () => const SizedBox(height: 120, child: LoadingWidget()),
            error: (error, _) => Card(
              child: ListTile(
                title: const Text('Could not load clubs'),
                subtitle: Text(error.toString()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
