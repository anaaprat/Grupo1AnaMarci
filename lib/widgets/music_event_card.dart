import 'package:flutter/material.dart';

// Widget para eventos de música
class MusicEventCard extends StatelessWidget {
  final String imageUrl;
  final String eventName;
  final String eventDate;

  const MusicEventCard({
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
        side: const BorderSide(color: Color(0xFFFFD700), width: 2),
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