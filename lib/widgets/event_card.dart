import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/event_model.dart';

class EventCard extends StatelessWidget {
  const EventCard({super.key, required this.event, required this.onTap});

  final EventModel event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: double.infinity,
                  height: 160,
                  child: event.photoURL.isEmpty
                      ? Container(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.16),
                          child: const Icon(
                            Icons.event_available_rounded,
                            size: 42,
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: event.photoURL,
                          fit: BoxFit.cover,
                          placeholder: (_, _) =>
                              const Center(child: CircularProgressIndicator()),
                          errorWidget: (_, _, _) =>
                              const Icon(Icons.broken_image_outlined),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Text(event.title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(event.clubName),
              const SizedBox(height: 8),
              Text(
                event.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      event.date == null
                          ? 'Date TBD'
                          : DateFormat('MMM d, y • HH:mm').format(event.date!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 18),
                  const SizedBox(width: 6),
                  Expanded(child: Text(event.location)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
