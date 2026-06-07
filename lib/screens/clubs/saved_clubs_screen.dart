import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/clubs_provider.dart';
import '../../widgets/club_card.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/loading_widget.dart';

class SavedClubsScreen extends ConsumerWidget {
  const SavedClubsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allClubs = ref.watch(allClubsProvider);
    final savedClubs = ref.watch(savedClubsProvider);
    final user = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Saved Clubs')),
      body: allClubs.when(
        data: (_) {
          if (user.isLoading) return const LoadingWidget();
          if (savedClubs.isEmpty) {
            return const EmptyStateWidget(
              message:
                  'No saved clubs yet. Save clubs you want to revisit later.',
              icon: Icons.bookmark_border_rounded,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (_, index) => ClubCard(
              club: savedClubs[index],
              onTap: () => context.push('/clubs/${savedClubs[index].id}'),
              onEdit: () => context.push('/clubs/${savedClubs[index].id}/edit'),
            ),
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemCount: savedClubs.length,
          );
        },
        loading: () => const LoadingWidget(),
        error: (error, _) => Center(child: Text(error.toString())),
      ),
    );
  }
}
