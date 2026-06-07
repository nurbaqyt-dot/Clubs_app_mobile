import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'App: JIHC Clubs',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  const Text('Developer: Dosmakhanbet Altynay'),
                  const SizedBox(height: 10),
                  const Text('Student ID: 091211654123'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Accent color: #E9C46A'),
                      const SizedBox(width: 12),
                      Container(
                        width: 56,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.black12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Version: 1.0.0'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
