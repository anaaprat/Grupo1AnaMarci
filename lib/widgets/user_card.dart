import 'package:flutter/material.dart';

class UserCard extends StatelessWidget {
  final dynamic user;
  final VoidCallback onEdit;

  const UserCard({required this.user, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(
                user.profilePicture ?? 'https://via.placeholder.com/150',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Name: ${user.name}'),
                  Text('Role: ${user.role}'),
                  Text(
                      'Status: ${user.actived ? 'Activated' : 'Deactivated'}'),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: onEdit,
            ),
          ],
        ),
      ),
    );
  }
}
