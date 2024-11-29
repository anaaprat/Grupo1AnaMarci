import 'package:flutter/material.dart';
import '../models/Event.dart';

class EventCard extends StatelessWidget {
  final Event event;
  final Function()? onSuspend;
  final Function()? onShowDetails;
  final Function()? onRegister; 
  final String contextSection; 

  const EventCard({
    Key? key,
    required this.event,
    this.onSuspend,
    this.onShowDetails,
    this.onRegister,
    required this.contextSection,
  }) : super(key: key);

  Color _getBorderColor(String category) {
    switch (category) {
      case 'Music':
        return Color(0xFFFFD700); 
      case 'Sport':
        return Color(0xFFFF4500); 
      case 'Technology':
        return Color(0xFF4CAF50); 
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 10,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
        side: BorderSide(color: _getBorderColor(event.category), width: 3.0),
      ),
      child: Column(
        children: [
          ListTile(
            leading: event.image_url != null && event.image_url!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: Image.network(
                      event.image_url!,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  )
                : Icon(Icons.event, color: Colors.grey, size: 50),
            title: Text(
              event.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.purple[800],
              ),
            ),
            subtitle: Text(
              'Date: ${event.start_time}\nCategory: ${event.category}',
              style: TextStyle(color: Colors.purple[600]),
            ),
            onTap: onShowDetails,
          ),
          ButtonBar(
            alignment: MainAxisAlignment.end,
            children: [
              if (contextSection == 'My Events')
                ElevatedButton(
                  onPressed: onSuspend,
                  child: Text('Suspend Registration'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[400],
                  ),
                ),
              if (contextSection == 'All Events')
                ElevatedButton(
                  onPressed: onRegister,
                  child: Text('Register'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[400],
                  ),
                ),
              ElevatedButton(
                onPressed: onShowDetails,
                child: Text('Show Details'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[400],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
