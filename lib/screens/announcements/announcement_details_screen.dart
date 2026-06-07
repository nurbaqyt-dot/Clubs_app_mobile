import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/announcements_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/loading_widget.dart';

class AnnouncementDetailsScreen extends ConsumerWidget {
  const AnnouncementDetailsScreen({super.key, required this.announcementId});

  final String announcementId;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete announcement?'),
        content: const Text(
          'This announcement will be removed for all members.',
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

    if (confirm != true || !context.mounted) return;

    try {
      await ref.read(announcementControllerProvider).delete(announcementId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Announcement deleted successfully.')),
      );
      context.go('/announcements');
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Announcement could not be deleted: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementAsync = ref.watch(announcementProvider(announcementId));
    final user = ref.watch(currentUserProvider);
    final profile = ref.watch(userProfileProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Announcement Details')),
      body: announcementAsync.when(
        data: (announcement) {
          if (announcement == null) {
            return const EmptyStateWidget(
              message: 'This announcement could not be found.',
              icon: Icons.search_off_rounded,
            );
          }

          final canManage =
              profile?.isHead == true && user?.uid == announcement.createdBy;
          final createdLabel = announcement.createdAt == null
              ? 'Just now'
              : DateFormat(
                  'EEEE, MMM d, y • HH:mm',
                ).format(announcement.createdAt!);

          return ListView(
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
                    const Icon(
                      Icons.campaign_rounded,
                      color: AppColors.textDark,
                      size: 34,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      announcement.title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _MetaChip(
                          icon: Icons.person_outline,
                          label: announcement.creatorName,
                        ),
                        _MetaChip(
                          icon: Icons.schedule_outlined,
                          label: createdLabel,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                announcement.description,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(height: 1.6),
              ),
              if (canManage) ...[
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.tonal(
                      onPressed: () => context.push(
                        '/announcements/${announcement.id}/edit',
                      ),
                      child: const Text('Edit'),
                    ),
                    OutlinedButton(
                      onPressed: () => _delete(context, ref),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
        loading: () => const LoadingWidget(),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not load announcement.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.textDark),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
