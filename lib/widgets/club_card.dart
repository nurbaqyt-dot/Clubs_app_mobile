import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/club_model.dart';
import '../providers/auth_provider.dart';

class ClubCard extends ConsumerWidget {
  const ClubCard({
    super.key,
    required this.club,
    required this.onTap,
    this.onEdit,
  });

  final ClubModel club;
  final VoidCallback onTap;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final canEdit = onEdit != null && currentUser?.uid == club.adminUid;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  height: 72,
                  width: 72,
                  child: club.photoURL.isEmpty
                      ? Container(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.2),
                          child: const Icon(Icons.groups_rounded),
                        )
                      : CachedNetworkImage(
                          imageUrl: club.photoURL,
                          fit: BoxFit.cover,
                          placeholder: (_, _) =>
                              const Center(child: CircularProgressIndicator()),
                          errorWidget: (_, _, _) =>
                              const Icon(Icons.broken_image_outlined),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      club.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      club.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        Chip(label: Text(club.category)),
                        Chip(label: Text('${club.memberCount} members')),
                      ],
                    ),
                  ],
                ),
              ),
              if (canEdit) ...[
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: onEdit,
                  tooltip: 'Edit club',
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
