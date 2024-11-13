import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../models/Event.dart';
import '../models/Category.dart';
import 'login_screen.dart';

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
  String selectedCategory = 'All';
  Map<int, Category> categoryMap = {};
  List<Event> events = [];
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

  // Ordena los eventos por fecha (ascendente)
  List<Event> get filteredEvents {
    final DateTime now = DateTime.now();
    return events
        .where((event) {
          final categoryMatches =
              selectedCategory == 'All' || event.category == selectedCategory;
          final isUpcoming = event.start_time.isAfter(now);
          return categoryMatches && isUpcoming;
        })
        .toList()
      ..sort((a, b) => a.start_time.compareTo(b.start_time)); // Ordena por fecha
  }

  void selectCategory(String category) {
    setState(() {
      selectedCategory = category;
    });
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Wait'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Cancel
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(true), // Confirm logout
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }

  Widget _buildEventCard(Event event) {
    Color borderColor;
    switch (event.category) {
      case 'Music':
        borderColor = Color(0xFFFFD700); // Amarillo
        break;
      case 'Sport':
        borderColor = Color(0xFFFF4500); // Naranja
        break;
      case 'Technology':
        borderColor = Color(0xFF4CAF50); // Verde
        break;
      default:
        borderColor = Colors.grey;
    }

    return Card(
      elevation: 10,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
        side: BorderSide(color: borderColor, width: 3.0),
      ),
      child: ListTile(
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
            color: Colors.purple[800],
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          'Date: ${event.start_time}\nCategory: ${event.category}',
          style: TextStyle(color: Colors.purple[600]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Welcome, ${widget.userEmail}',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.purple[800],
        iconTheme: IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _confirmLogout,
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.purple[800]))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 20.0),
                    decoration: BoxDecoration(
                      color: Colors.purple[700],
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Text(
                      'Find your next exciting event here!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Upcoming Events',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple[600],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: filteredEvents.isEmpty
                        ? Center(
                            child: Text(
                              'No events available in this category.',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredEvents.length,
                            itemBuilder: (context, index) {
                              return _buildEventCard(filteredEvents[index]);
                            },
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.purple[800],
        child: Icon(Icons.filter_list, color: Colors.white),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (context) {
              return Container(
                color: Colors.white,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading:
                          Icon(Icons.all_inclusive, color: Colors.purple[800]),
                      title: Text('All'),
                      onTap: () {
                        selectCategory('All');
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.music_note, color: Color(0xFFFFD700)),
                      title: Text('Music'),
                      onTap: () {
                        selectCategory('Music');
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.sports, color: Color(0xFFFF4500)),
                      title: Text('Sport'),
                      onTap: () {
                        selectCategory('Sport');
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.computer, color: Color(0xFF4CAF50)),
                      title: Text('Technology'),
                      onTap: () {
                        selectCategory('Technology');
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
