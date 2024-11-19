import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../models/Event.dart';
import '../models/Category.dart';
import '../widgets/event_card.dart';
import '../widgets/filter_modal.dart';

class UserScreen extends StatefulWidget {
  final String token;
  final String userEmail;

  const UserScreen({Key? key, required this.token, required this.userEmail})
      : super(key: key);

  @override
  _UserScreenState createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  late UserService userService;
  String currentSection = 'All Events';
  Map<int, Category> categoryMap = {};
  List<Event> events = [];
  String selectedCategory = 'All';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    userService = UserService(token: widget.token);
    loadCategoriesAndEvents();
  }

  Future<void> loadCategoriesAndEvents() async {
    try {
      final categories = await userService.fetchCategories();
      final eventsData = await userService.fetchEvents();

      setState(() {
        categoryMap = {for (var category in categories) category.id: category};
        events = eventsData;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  List<Event> get filteredEvents {
    final now = DateTime.now();
    List<Event> filtered =
        events.where((event) => event.start_time.isAfter(now)).toList();

    if (selectedCategory != 'All') {
      filtered = filtered
          .where((event) => event.category == selectedCategory)
          .toList();
    }

    if (currentSection == 'All Events') {
      filtered.sort((a, b) => b.start_time.compareTo(a.start_time));
    } else if (currentSection == 'My Events') {
      filtered.sort((a, b) => a.start_time.compareTo(b.start_time));
    }

    return filtered;
  }

  void selectCategory(String category) {
    setState(() {
      selectedCategory = category;
    });
  }

  void resetCategoryFilter() {
    setState(() {
      selectedCategory = 'All'; // Restablecer filtro
    });
  }

  void showFilterModal() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return FilterModal(onCategorySelected: selectCategory);
      },
    );
  }

  void changeSection(String section) {
    setState(() {
      currentSection = section;
      resetCategoryFilter(); // Restablecer el filtro al cambiar de sección
    });
    Navigator.pop(context); // Cerrar el Drawer
  }

  void showEventDetails(Event event) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    event.title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 15),
                if (event.image_url != null && event.image_url!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15.0),
                    child: Image.network(
                      event.image_url!,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(height: 15),
                Divider(color: Colors.grey),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.purple[800]),
                    const SizedBox(width: 8),
                    Text(
                      'Date: ${event.start_time}',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.category, color: Colors.purple[800]),
                    const SizedBox(width: 8),
                    Text(
                      'Category: ${event.category}',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.purple[800]),
                    const SizedBox(width: 8),
                    Text(
                      'Location: ${event.location ?? "Not provided"}',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (event.description != null && event.description!.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Divider(color: Colors.grey),
                      const SizedBox(height: 10),
                      Text(
                        'Description:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple[800],
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        event.description!,
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Close'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Eventify',
          style: TextStyle(color: Colors.white), // Texto en blanco
        ),
        backgroundColor: Colors.purple[800],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.purple[800]),
              child: Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              title: Text('All Events'),
              onTap: () => changeSection('All Events'),
            ),
            ListTile(
              title: Text('My Events'),
              onTap: () => changeSection('My Events'),
            ),
            ListTile(
              title: Text('Report'),
              onTap: () => changeSection('Report'),
            ),
          ],
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.purple[800]))
          : currentSection == 'All Events' || currentSection == 'My Events'
              ? ListView.builder(
                  itemCount: filteredEvents.length,
                  itemBuilder: (context, index) {
                    return EventCard(
                      event: filteredEvents[index],
                      onSuspend: currentSection == 'My Events'
                          ? () {
                              // Logic to suspend registration
                            }
                          : null,
                      onShowDetails: () {
                        showEventDetails(filteredEvents[index]);
                      },
                      showButtons: currentSection == 'My Events',
                    );
                  },
                )
              : Center(
                  child: Text(
                    'Here goes the report functionality!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
      floatingActionButton: currentSection != 'Report'
          ? FloatingActionButton(
              backgroundColor: Colors.purple[800],
              child: Icon(Icons.filter_list, color: Colors.white),
              onPressed: showFilterModal,
            )
          : null,
    );
  }
}
