import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/announcement_model.dart';
import '../../providers/announcements_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/announcement_card.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/loading_widget.dart';

class AnnouncementsScreen extends ConsumerWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementsAsync = ref.watch(announcementsProvider);
    final profile = ref.watch(userProfileProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Announcements')),
      floatingActionButton: profile?.isHead == true
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/announcements/create'),
              icon: const Icon(Icons.add_comment_outlined),
              label: const Text('Create Announcement'),
            )
          : null,
      body: announcementsAsync.when(
        data: (announcements) =>
            _AnnouncementsList(announcements: announcements),
        loading: () => const LoadingWidget(),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not load announcements.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class _AnnouncementsList extends StatelessWidget {
  const _AnnouncementsList({required this.announcements});

  final List<AnnouncementModel> announcements;

  @override
  Widget build(BuildContext context) {
    if (announcements.isEmpty) {
      return const EmptyStateWidget(
        message:
            'No announcements yet. Heads can post updates here for everyone.',
        icon: Icons.campaign_outlined,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: announcements.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final announcement = announcements[index];
        return AnnouncementCard(
          announcement: announcement,
          onTap: () => context.push('/announcements/${announcement.id}'),
        );
      },
    );
  }
}
