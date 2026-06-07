import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/clubs_provider.dart';
import '../../widgets/club_card.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/loading_widget.dart';

class MyClubsScreen extends ConsumerWidget {
  const MyClubsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clubs = ref.watch(myClubsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Clubs')),
      body: clubs.when(
        data: (items) {
          if (items.isEmpty) {
            return const EmptyStateWidget(
              message:
                  'You have not joined any clubs yet. Explore the clubs tab to get started.',
              icon: Icons.group_add_outlined,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (_, index) => ClubCard(
              club: items[index],
              onTap: () => context.push('/clubs/${items[index].id}'),
              onEdit: () => context.push('/clubs/${items[index].id}/edit'),
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
