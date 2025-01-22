import 'package:eventify/screens/show_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:eventify/services/user_service.dart';
import 'package:eventify/services/email_service.dart';
import 'package:eventify/screens/report_screen.dart';
import 'package:eventify/screens/map_screen.dart';
import 'package:eventify/widgets/event_card.dart';
import 'package:eventify/widgets/filter_floating_button.dart';
import 'package:eventify/models/event.dart';
import 'package:eventify/models/Category.dart';
import 'package:eventify/providers/user_provider.dart';

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
  late UserProvider userProvider;
  List<Event> originalAllEvents = [];
  List<Event> originalMyEvents = [];
  List<Event> allEvents = [];
  List<Event> myEvents = [];
  List<Category> categories = [];
  bool isLoading = true;
  bool showFloatingButton = true;
  int? userId;

  @override
  void initState() {
    super.initState();
    userService = UserService(token: widget.token);
    emailService = EmailService(
      smtpEmail: 'anaprat26@gmail.com',
      smtpPassword: 'mkxv hldp bxbd aneb',
    );
    _tabController = TabController(length: 4, vsync: this);
    userProvider = UserProvider();
    _tabController.addListener(() {
      setState(() {
        showFloatingButton = _tabController.index == 0;
      });
    });

    _initializeData();
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
      return null;
    }
  }

  Future<void> _initializeData() async {
    setState(() => isLoading = true);

    try {
      final categoriesData = await userService.getCategories();
      categories = categoriesData.map((cat) => Category.fromJson(cat)).toList();

      userId = await _fetchUserId();
      if (userId == null) {
        throw Exception('User ID not found');
      }

      final allEventsData = await userService.getAllEvents();
      final userEventsData = await userService.getUserEvents(userId!);

      setState(() {
        final now = DateTime.now();

        originalAllEvents = allEventsData
            .map((event) => Event.fromJson(event))
            .where((event) =>
                event.start_time.isAfter(now) &&
                !userEventsData.any((userEvent) => userEvent['id'] == event.id))
            .toList()
          ..sort((a, b) => b.start_time.compareTo(a.start_time));

        allEvents = List.from(originalAllEvents);

        originalMyEvents = userEventsData
            .map((event) => Event.fromJson(event))
            .where((event) => event.start_time.isAfter(now))
            .toList()
          ..sort((a, b) => a.start_time.compareTo(b.start_time));

        myEvents = List.from(originalMyEvents);
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _registerEvent(Event event) async {
    try {
      await userService.registerEvent(userId!, event.id);

      setState(() {
        allEvents.remove(event);
        myEvents.add(event);

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
      await userService.unregisterEvent(userId!, event.id);

      setState(() {
        myEvents.remove(event);
        allEvents.add(event);

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
      if (category == null || category == "All") {
        allEvents = List.from(originalAllEvents);
        myEvents = List.from(originalMyEvents);
      } else {
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
          categoryName: category.name,
          isMyEvent: isMyEvent,
          onRegister: isMyEvent ? null : () => _registerEvent(event),
          onUnregister: isMyEvent ? () => _unregisterEvent(event) : null,
          onShowDetails: isMyEvent
              ? () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return Dialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: ShowDetailsScreen(
                          eventId: event.id,
                          token: widget.token,
                          userId: userId!,
                        ),
                      );
                    },
                  );
                }
              : null,
          token: widget.token,
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
              Tab(text: 'Map'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => userProvider.confirmLogout(context),
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
                    token: widget.token,
                    emailService: emailService,
                    userEmail: widget.userEmail,
                  ),
                  MapScreen(token: widget.token),
                ],
              ),
        floatingActionButton: showFloatingButton
            ? FilterFloatingButton(
                onFilter: (category) => _filterEventsByCategory(category),
              )
            : null,
      ),
    );
  }
}
