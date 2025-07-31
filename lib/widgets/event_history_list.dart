import 'package:flutter/material.dart';
import '../models/event_model.dart';

class EventHistoryList extends StatelessWidget {
  final List<EventModel> events;
  const EventHistoryList({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Center(child: Text('Пока событий нет'));
    }
    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              '${event.time.toString().substring(0, 19)} — ${event.source}',
            ),
          ),
        );
      },
    );
  }
}
