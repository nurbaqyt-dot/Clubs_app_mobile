import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/gold_button.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: ListTile(
                title: const Text('Theme Accent'),
                subtitle: const Text(
                  'Golden yellow is applied throughout the app.',
                ),
                trailing: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.bookmark_outline_rounded),
                    title: const Text('Saved Clubs'),
                    onTap: () => context.push('/clubs/saved'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.event_note_outlined),
                    title: const Text('Joined Events'),
                    onTap: () => context.push('/events/joined'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.info_outline_rounded),
                    title: const Text('About'),
                    onTap: () => context.push('/profile/about'),
                  ),
                ],
              ),
            ),
            const Spacer(),
            GoldButton(
              label: 'Logout',
              onPressed: () async {
                try {
                  await ref.read(authServiceProvider).signOut();
                  if (context.mounted) context.go('/auth/login');
                } catch (error) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(error.toString())));
                }
              },
              icon: Icons.logout_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
