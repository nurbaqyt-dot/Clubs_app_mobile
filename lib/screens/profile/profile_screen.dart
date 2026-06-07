import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/clubs_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/club_card.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/loading_widget.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider);
    final myClubs = ref.watch(myClubsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            onPressed: () => context.push('/profile/notifications'),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          IconButton(
            onPressed: () => context.push('/profile/about'),
            icon: const Icon(Icons.info_outline_rounded),
          ),
          IconButton(
            onPressed: () => context.push('/profile/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const EmptyStateWidget(
              message: 'No profile data found.',
              icon: Icons.person_off_outlined,
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundImage: user.photoURL.isEmpty
                            ? null
                            : NetworkImage(user.photoURL),
                        child: user.photoURL.isEmpty
                            ? Text(
                                user.displayName.isEmpty
                                    ? '?'
                                    : user.displayName[0],
                              )
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.displayName,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 6),
                      Text(user.email),
                      const SizedBox(height: 6),
                      Text(
                        "Student ID: ${user.studentId.isEmpty ? 'Not set' : user.studentId}",
                      ),
                      const SizedBox(height: 6),
                      Text('Role: ${user.role.value.toUpperCase()}'),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: [
                          FilledButton.tonal(
                            onPressed: () => context.push('/profile/edit'),
                            child: const Text('Edit Profile'),
                          ),
                          FilledButton.tonal(
                            onPressed: () => context.push('/clubs/saved'),
                            child: const Text('Saved Clubs'),
                          ),
                          FilledButton.tonal(
                            onPressed: () => context.push('/events/joined'),
                            child: const Text('Joined Events'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Joined Clubs',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              myClubs.when(
                data: (clubs) {
                  if (clubs.isEmpty) {
                    return const EmptyStateWidget(
                      message: 'You have not joined any clubs yet.',
                      icon: Icons.group_add_outlined,
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
                              onEdit: () =>
                                  context.push('/clubs/${club.id}/edit'),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
                loading: () => const LoadingWidget(),
                error: (error, _) => Text(error.toString()),
              ),
            ],
          );
        },
        loading: () => const LoadingWidget(),
        error: (error, _) => Center(child: Text(error.toString())),
      ),
    );
  }
}
