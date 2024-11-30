import 'package:flutter/material.dart';
import 'package:eventify/services/user_service.dart';
import 'package:eventify/services/email_service.dart';
import 'package:eventify/screens/report_screen.dart';
import 'package:eventify/widgets/event_card.dart';
import 'package:eventify/widgets/FilterFloatingButton.dart';
import 'package:eventify/models/event.dart';
import 'package:eventify/models/category.dart';
import 'login_screen.dart';

class UserScreen extends StatefulWidget {
  final String token;
  final String userEmail;

  const UserScreen({super.key, required this.token, required this.userEmail});

  @override
  _UserScreenState createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen>
    with SingleTickerProviderStateMixin {
  late UserService userService;
  late EmailService emailService;
  late TabController _tabController;
  List<Event> originalAllEvents = [];
  List<Event> originalMyEvents = [];
  List<Event> allEvents = [];
  List<Event> myEvents = [];
  List<Category> categories = [];
  bool isLoading = true;
  int? userId;

  @override
  void initState() {
    super.initState();
    userService = UserService(token: widget.token);
    emailService = EmailService(
      smtpEmail: 'anaprat26@gmail.com',
      smtpPassword: 'mkxv hldp bxbd aneb',
    );
    _tabController = TabController(length: 3, vsync: this);
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() => isLoading = true);

    try {
      // Load categories first
      final categoriesData = await userService.getCategories();
      categories = categoriesData.map((cat) => Category.fromJson(cat)).toList();

      // Fetch user ID
      userId = await _fetchUserId();
      if (userId == null) {
        throw Exception('User ID not found');
      }

      // Fetch events
      final allEventsData = await userService.getAllEvents();
      final userEventsData = await userService.getUserEvents(userId!);

      setState(() {
        final now = DateTime.now();

        // Process "All Events"
        originalAllEvents = allEventsData
            .map((event) => Event.fromJson(event))
            .where((event) =>
                event.start_time.isAfter(now) && // Only future events
                !userEventsData.any((userEvent) =>
                    userEvent['id'] == event.id)) // Exclude registered events
            .toList()
          ..sort(
              (a, b) => b.start_time.compareTo(a.start_time)); // Newest first

        allEvents = List.from(originalAllEvents);

        // Process "My Events"
        originalMyEvents = userEventsData
            .map((event) => Event.fromJson(event))
            .where(
                (event) => event.start_time.isAfter(now)) // Only future events
            .toList()
          ..sort(
              (a, b) => a.start_time.compareTo(b.start_time)); // Oldest first

        myEvents = List.from(originalMyEvents);
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<int?> _fetchUserId() async {
    try {
      final users = await userService.getAllUsers();
      final matchingUser = users.firstWhere(
        (user) => user['email'] == widget.userEmail,
        orElse: () => null,
      );

      return matchingUser?['id'];
    } catch (e) {
      print('Error fetching user ID: $e');
      return null;
    }
  }

  Future<void> _registerEvent(Event event) async {
    try {
      // Register event
      await userService.registerEvent(userId!, event.id);

      setState(() {
        allEvents.remove(event);
        myEvents.add(event);

        // Sort both lists
        allEvents.sort((a, b) => b.start_time.compareTo(a.start_time));
        myEvents.sort((a, b) => a.start_time.compareTo(b.start_time));
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${event.title} successfully registered.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error registering event: $e')),
      );
    }
  }

  Future<void> _unregisterEvent(Event event) async {
    try {
      // Unregister event
      await userService.unregisterEvent(userId!, event.id);

      setState(() {
        myEvents.remove(event);
        allEvents.add(event);

        // Sort both lists
        allEvents.sort((a, b) => b.start_time.compareTo(a.start_time));
        myEvents.sort((a, b) => a.start_time.compareTo(b.start_time));
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${event.title} successfully unregistered.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error unregistering event: $e')),
      );
    }
  }

  void _filterEventsByCategory(String? category) {
    setState(() {
      if (category == null) {
        // Reset filters
        allEvents = List.from(originalAllEvents);
        myEvents = List.from(originalMyEvents);
      } else {
        // Apply filters
        allEvents = originalAllEvents
            .where((event) => event.category == category)
            .toList()
          ..sort((a, b) => b.start_time.compareTo(a.start_time));

        myEvents = originalMyEvents
            .where((event) => event.category == category)
            .toList()
          ..sort((a, b) => a.start_time.compareTo(b.start_time));
      }
    });
  }

  void _showEventDetailsDialog(BuildContext context, Event event) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(event.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Category: ${event.category}'),
              Text('Date: ${event.start_time.toLocal()}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEventsList(List<Event> events, {required bool isMyEvent}) {
    if (events.isEmpty) {
      return Center(
        child: Text(
          isMyEvent
              ? 'You are not registered for any upcoming events.'
              : 'No events available for registration.',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];

        final category = categories.firstWhere(
          (cat) => cat.name == event.category,
          orElse: () => Category(id: 0, name: 'Uncategorized'),
        );

        return EventCard(
          event: event,
          category: category,
          isMyEvent: isMyEvent,
          onRegister: isMyEvent ? null : () => _registerEvent(event),
          onUnregister: isMyEvent ? () => _unregisterEvent(event) : null,
          onShowDetails: isMyEvent
              ? () =>
                  _showEventDetailsDialog(context, event) // Mostrar detalles
              : null,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Event Manager'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'All Events'),
              Tab(text: 'My Events'),
              Tab(text: 'Report'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _confirmLogout(context),
            ),
          ],
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildEventsList(allEvents, isMyEvent: false),
                  _buildEventsList(myEvents, isMyEvent: true),
                  ReportScreen(
                    allEvents: originalAllEvents,
                    emailService: emailService,
                    userEmail: widget.userEmail,
                  ),
                ],
              ),
        floatingActionButton: FilterFloatingButton(
          onFilter: (category) => _filterEventsByCategory(category),
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Logout')),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }
}
