import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

// Importamos los widgets personalizados
import '../widgets/music_event_card.dart';
import '../widgets/sport_event_card.dart';
import '../widgets/tech_event_card.dart';

class UserScreen extends StatefulWidget {
  final String token;
  final String userEmail;

  const UserScreen({super.key, required this.token, required this.userEmail});

  @override
  _UserScreenState createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  final ApiService apiService = ApiService();
  Map<String, dynamic> _userData = {};
  List<dynamic> _allEvents = [];
  List<dynamic> _filteredEvents = [];
  bool _isEventsLoading = true;
  bool _isUserLoading = true;
  String?
      _selectedCategory; // Almacena la categoría seleccionada para el filtro

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchFutureEvents();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isUserLoading = true;
    });

    final userData =
        await apiService.fetchUserData(widget.token, widget.userEmail);

    setState(() {
      _userData = userData;
      _isUserLoading = false;
    });

    if (_userData.isEmpty) {
      _showSnackBar('Error loading user data.');
    }
  }

  Future<void> _fetchFutureEvents() async {
    final events = await apiService.fetchEvents(widget.token);
    final now = DateTime.now();

    setState(() {
      _allEvents = (events ?? []).where((event) {
        final eventDate = DateTime.parse(event['start_time']);
        return eventDate.isAfter(now);
      }).toList()
        ..sort((a, b) => DateTime.parse(a['start_time'])
            .compareTo(DateTime.parse(b['start_time'])));
      _filteredEvents = _allEvents;
      _isEventsLoading = false;
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Log out"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel", style: TextStyle(color: Colors.purple)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _logout();
            },
            child: const Text("Log out", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _logout() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  Widget _buildEventCard(dynamic event) {
    String category = event['category'];
    String imageUrl = event['image_url'] ?? '';
    String eventName = event['title'] ?? 'No title';
    String eventDate = DateFormat('yyyy-MM-dd HH:mm')
        .format(DateTime.parse(event['start_time']));

    switch (category) {
      case 'Music':
        return MusicEventCard(
          imageUrl: imageUrl,
          eventName: eventName,
          eventDate: eventDate,
        );
      case 'Sport':
        return SportEventCard(
          imageUrl: imageUrl,
          eventName: eventName,
          eventDate: eventDate,
        );
      case 'Tech':
        return TechEventCard(
          imageUrl: imageUrl,
          eventName: eventName,
          eventDate: eventDate,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _filterEvents(String? category) {
    setState(() {
      _selectedCategory = category;
      if (category == null) {
        _filteredEvents =
            _allEvents; // Mostrar todos los eventos si no hay filtro
      } else {
        _filteredEvents =
            _allEvents.where((event) => event['category'] == category).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple[800],
        elevation: 0,
        title: const Text(
          'Eventify',
          style: TextStyle(
            fontFamily: 'Billabong',
            fontSize: 28,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _confirmLogout,
        ),
      ),
      backgroundColor: Colors.purple[50],
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _isUserLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, ${_userData['name'] ?? 'User'}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple[900],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Email: ${_userData['email'] ?? 'Not available'}',
                        style: TextStyle(color: Colors.purple[700]),
                      ),
                    ],
                  ),
            const SizedBox(height: 20),
            const Text(
              'Upcoming Events',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple),
            ),
            const SizedBox(height: 10),
            _isEventsLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredEvents.isEmpty
                    ? const Center(child: Text('No upcoming events available.'))
                    : Expanded(
                        child: ListView.builder(
                          itemCount: _filteredEvents.length,
                          itemBuilder: (context, index) {
                            final event = _filteredEvents[index];
                            return _buildEventCard(event);
                          },
                        ),
                      ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.purple,
        child: const Icon(Icons.filter_list),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (context) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.music_note, color: Colors.yellow),
                  title: const Text("Music"),
                  onTap: () {
                    _filterEvents("Music");
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  leading:
                      const Icon(Icons.sports_soccer, color: Colors.orange),
                  title: const Text("Sports"),
                  onTap: () {
                    _filterEvents("Sport");
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.computer, color: Colors.green),
                  title: const Text("Technology"),
                  onTap: () {
                    _filterEvents("Tech");
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.clear, color: Colors.red),
                  title: const Text("Clear Filter"),
                  onTap: () {
                    _filterEvents(null);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
