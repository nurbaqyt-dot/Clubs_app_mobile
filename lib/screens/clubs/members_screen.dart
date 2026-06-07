import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../providers/clubs_provider.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/loading_widget.dart';

class MembersScreen extends ConsumerWidget {
  const MembersScreen({super.key, required this.clubId});

  final String clubId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clubAsync = ref.watch(clubProvider(clubId));

    return Scaffold(
      appBar: AppBar(title: const Text('Members')),
      body: clubAsync.when(
        data: (club) {
          if (club == null || club.memberUids.isEmpty) {
            return const EmptyStateWidget(
              message: 'No members found for this club yet.',
              icon: Icons.people_outline_rounded,
            );
          }
          return FutureBuilder(
            future: ref
                .read(firestoreServiceProvider)
                .fetchUsersByIds(club.memberUids),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const LoadingWidget();
              }
              if (snapshot.hasError) {
                return Center(child: Text(snapshot.error.toString()));
              }
              final members = snapshot.data ?? const [];
              if (members.isEmpty) {
                return const EmptyStateWidget(
                  message: 'No members found for this club yet.',
                  icon: Icons.people_outline_rounded,
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemBuilder: (_, index) {
                  final member = members[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: member.photoURL.isEmpty
                            ? null
                            : NetworkImage(member.photoURL),
                        child: member.photoURL.isEmpty
                            ? Text(
                                member.displayName.isEmpty
                                    ? '?'
                                    : member.displayName[0],
                              )
                            : null,
                      ),
                      title: Text(
                        member.displayName.isEmpty
                            ? member.email
                            : member.displayName,
                      ),
                      subtitle: Text(member.email),
                    ),
                  );
                },
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemCount: members.length,
              );
            },
          );
        },
        loading: () => const LoadingWidget(),
        error: (error, _) => Center(child: Text(error.toString())),
      ),
    );
  }
}
