import 'package:flutter/material.dart';

class FilterFloatingButton extends StatelessWidget {
  final Function(String category) onFilter;

  const FilterFloatingButton({super.key, required this.onFilter});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        // Mostrar un menú de filtros
        showModalBottomSheet(
          context: context,
          builder: (context) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.all_inclusive, color: Colors.blue),
                  title: const Text('All'),
                  onTap: () {
                    onFilter('All');
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.music_note, color: Colors.purple),
                  title: const Text('Music'),
                  onTap: () {
                    onFilter('Music');
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.sports, color: Colors.orange),
                  title: const Text('Sport'),
                  onTap: () {
                    onFilter('Sport');
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.computer, color: Colors.green),
                  title: const Text('Technology'),
                  onTap: () {
                    onFilter('Technology');
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          },
        );
      },
      child: const Icon(Icons.filter_alt),
    );
  }
}
