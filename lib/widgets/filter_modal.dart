import 'package:flutter/material.dart';

class FilterModal extends StatelessWidget {
  final Function(String) onCategorySelected;

  const FilterModal({
    Key? key,
    required this.onCategorySelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.all_inclusive, color: Colors.purple[800]),
            title: Text('All'),
            onTap: () {
              onCategorySelected('All');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.music_note, color: Color(0xFFFFD700)),
            title: Text('Music'),
            onTap: () {
              onCategorySelected('Music');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.sports, color: Color(0xFFFF4500)),
            title: Text('Sport'),
            onTap: () {
              onCategorySelected('Sport');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.computer, color: Color(0xFF4CAF50)),
            title: Text('Technology'),
            onTap: () {
              onCategorySelected('Technology');
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
