import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/clubs_provider.dart';
import '../../widgets/club_card.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/loading_widget.dart';

class ClubsListScreen extends ConsumerWidget {
  const ClubsListScreen({super.key});

  static const categories = [
    'All',
    'Academic',
    'Arts',
    'Sports',
    'Technology',
    'Service',
    'Culture',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(selectedClubCategoryProvider);
    final clubs = ref.watch(clubsProvider);
    final profile = ref.watch(userProfileProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clubs'),
        actions: [
          IconButton(
            onPressed: () => context.push('/clubs/my'),
            icon: const Icon(Icons.bookmark_outline_rounded),
          ),
          if (profile?.isHead ?? false)
            IconButton(
              onPressed: () => context.push('/clubs/create'),
              icon: const Icon(Icons.add_circle_outline_rounded),
            ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 60,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              scrollDirection: Axis.horizontal,
              itemBuilder: (_, index) {
                final category = categories[index];
                return ChoiceChip(
                  label: Text(category),
                  selected: selectedCategory == category,
                  onSelected: (_) =>
                      ref.read(selectedClubCategoryProvider.notifier).state =
                          category,
                );
              },
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemCount: categories.length,
            ),
          ),
          Expanded(
            child: clubs.when(
              data: (items) {
                if (items.isEmpty) {
                  return const EmptyStateWidget(
                    message: 'No clubs yet',
                    icon: Icons.groups_outlined,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (_, index) => ClubCard(
                    club: items[index],
                    onTap: () => context.push('/clubs/${items[index].id}'),
                    onEdit: () =>
                        context.push('/clubs/${items[index].id}/edit'),
                  ),
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemCount: items.length,
                );
              },
              loading: () => const LoadingWidget(),
              error: (error, _) => const EmptyStateWidget(
                message:
                    'Could not load clubs right now. Please try again later.',
                icon: Icons.error_outline_rounded,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
