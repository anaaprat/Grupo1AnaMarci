import 'package:flutter/material.dart';
import 'package:eventify/models/event.dart';
import 'package:eventify/models/Category.dart';

class EventCard extends StatelessWidget {
  final Event event;
  final Category category;
  final String categoryName;
  final bool isMyEvent;
  final VoidCallback? onRegister;
  final VoidCallback? onUnregister;
  final VoidCallback? onShowDetails;
  final String token;

  const EventCard({
    super.key,
    required this.event,
    required this.category,
    required this.categoryName,
    required this.isMyEvent,
    this.onRegister,
    this.onUnregister,
    this.onShowDetails,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = _getCategoryColor(category.name);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: borderColor, width: 2),
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
              if (onShowDetails != null)
                IconButton(
                  icon: const Icon(Icons.info, color: Colors.blue),
                  onPressed: onShowDetails,
                ),
              IconButton(
                icon: Icon(
                  isMyEvent ? Icons.remove_circle : Icons.add_circle,
                  color: isMyEvent ? Colors.red : Colors.green,
                ),
                onPressed: isMyEvent ? onUnregister : onRegister,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String categoryName) {
    switch (categoryName) {
      case 'Music':
        return const Color(0xFFFFD700);
      case 'Sport':
        return const Color(0xFFFF4500);
      case 'Technology':
        return const Color(0xFF4CAF50);
      case 'Cultural':
        return const Color.fromARGB(255, 170, 60, 190);
      default:
        return Colors.grey;
    }
  }
}
