import 'package:flutter/material.dart';
import 'package:eventify/models/Event.dart';

class EventCardOrganizer extends StatelessWidget {
  final Event event;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const EventCardOrganizer({
    super.key,
    required this.event,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Colors.purple, width: 2),
      ),
      elevation: 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (event.image_url != null && event.image_url!.isNotEmpty)
            Image.network(
              event.image_url!,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Text(
              event.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Text(
              'Date: ${event.start_time.toLocal()}',
              style: const TextStyle(fontSize: 14, color: Colors.purpleAccent),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.orange),
                onPressed: onEdit,
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
