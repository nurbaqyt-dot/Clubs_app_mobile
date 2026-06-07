import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/gold_button.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key, required this.step});

  final int step;

  static const _slides = [
    (
      'Discover clubs at JIHC',
      'Explore student communities, find your interests, and connect with classmates.',
    ),
    (
      'Join & attend events',
      'RSVP to club activities, stay updated, and never miss what matters.',
    ),
    (
      'Track your activity',
      'See your joined clubs, upcoming events, and your involvement in one place.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final index = step.clamp(1, 3) - 1;
    final slide = _slides[index];
    final isLast = step >= 3;

    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton(
            onPressed: () => context.go('/auth/login'),
            child: const Text('Skip'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(),
            Container(
              height: 240,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: [Color(0xFFE9C46A), Color(0xFFF4E7AF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(
                [
                  Icons.explore_rounded,
                  Icons.event_available_rounded,
                  Icons.query_stats_rounded,
                ][index],
                size: 100,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 32),
            Text(slide.$1, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text(slide.$2, style: Theme.of(context).textTheme.bodyLarge),
            const Spacer(),
            Row(
              children: List.generate(
                3,
                (dotIndex) => Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: dotIndex == index
                        ? Theme.of(context).colorScheme.primary
                        : Colors.black12,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            GoldButton(
              label: isLast ? 'Start Now' : 'Next',
              onPressed: () => isLast
                  ? context.go('/auth/login')
                  : context.go('/auth/onboarding/${step + 1}'),
            ),
            if (step > 1) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.go('/auth/onboarding/${step - 1}'),
                child: const Text('Back'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
