import 'package:flutter/material.dart';

// Widget para eventos de tecnología
class TechEventCard extends StatelessWidget {
  final String imageUrl;
  final String eventName;
  final String eventDate;

  const TechEventCard({
    Key? key,
    required this.imageUrl,
    required this.eventName,
    required this.eventDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: const BorderSide(color: Color(0xFF4CAF50), width: 2),
      ),
      child: ListTile(
        leading: Image.network(imageUrl, fit: BoxFit.cover),
        title: Text(
          eventName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(eventDate),
      ),
    );
  }
}
