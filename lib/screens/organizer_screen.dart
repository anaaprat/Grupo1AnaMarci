import 'package:flutter/material.dart';
import 'package:eventify/services/organizer_service.dart';
import 'package:eventify/services/user_service.dart';
import 'package:eventify/screens/add_event_screen.dart';
import 'package:eventify/models/Event.dart';
import 'package:eventify/providers/user_provider.dart';
import 'package:eventify/widgets/event_card_organizer.dart';
import 'package:eventify/widgets/GraphicsTab.dart';

class OrganizerScreen extends StatefulWidget {
  final String token;
  final String userEmail;

  const OrganizerScreen({
    super.key,
    required this.token,
    required this.userEmail,
  });

  @override
  _OrganizerScreenState createState() => _OrganizerScreenState();
}

class _OrganizerScreenState extends State<OrganizerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late UserProvider userProvider;

  List<Event> events = [];
  bool isLoading = true;
  int? organizer_id;
  late OrganizerService organizerService;
  late UserService userService;

  @override
  void initState() {
    super.initState();
    organizerService = OrganizerService(token: widget.token);
    userService = UserService(token: widget.token);
    _tabController = TabController(length: 2, vsync: this);
    userProvider = UserProvider();
    _initializeData();
  }

  void _createEvent() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEventScreen(
          token: widget.token,
          organizer_id: organizer_id!,
        ),
      ),
    );

    if (result == true) {
      _loadEvents(); // Recargar los eventos después de crear uno nuevo
    }
  }

  Future<int?> _fetchUserId() async {
    try {
      final users = await userService.getAllUsers();
      final user = users.firstWhere(
        (u) => u['email'] == widget.userEmail,
        orElse: () => null,
      );
      return user?['id'];
    } catch (e) {
      print('Error fetching user ID: $e');
      return null;
    }
  }

  Future<void> _initializeData() async {
    try {
      organizer_id = await _fetchUserId();
      await _loadEvents();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing data: $e')),
        );
      }
    }
  }

  Future<void> _loadEvents() async {
    setState(() => isLoading = true);
    try {
      final fetchedEvents =
          await organizerService.getEventsByOrganizer(organizer_id!);
      setState(() {
        // Filtra los eventos que no están eliminados (deleted == 0)
        events = fetchedEvents
            .map((e) => Event.fromJson(e))
            .where((event) => event.deleted == 0) // Solo eventos no eliminados
            .toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading events: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _deleteEvent(int eventId) async {
    print('Evento a borrar: $eventId'); // Log del evento a borrar
    try {
      await organizerService.deleteEvent(eventId);

      // Eliminar localmente el evento de la lista antes de recargar
      setState(() {
        events.removeWhere((event) => event.id == eventId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event deleted successfully')),
      );

      // Luego recargar los eventos desde la API
      //  _loadEvents();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting event: $e')),
      );
    }
  }

  Future<void> _editEvent(Event event) async {
    print(event.toString());

    final TextEditingController titleController =
        TextEditingController(text: event.title);
    final TextEditingController descriptionController =
        TextEditingController(text: event.description ?? '');
    final TextEditingController locationController =
        TextEditingController(text: event.location ?? '');
    final TextEditingController priceController =
        TextEditingController(text: event.price?.toString() ?? '0');

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Event'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(labelText: 'Location'),
                ),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await organizerService.updateEvent(
                    id: event.id,
                    organizer_id: organizer_id!,
                    title: titleController.text,
                    description: descriptionController.text,
                    category_id: event.category_id ?? 0,
                    start_time: event.start_time.toString(),
                    end_time: event.end_time?.toString(),
                    location: locationController.text,
                    price: double.tryParse(priceController.text) ?? 0.0,
                    image_url: event.image_url ?? '',
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Event updated successfully')),
                  );
                  Navigator.of(context).pop();
                  _loadEvents();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating event: $e')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEventsTab() {
    if (events.isEmpty) {
      return const Center(
        child: Text(
          'No events available',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return EventCardOrganizer(
          event: event,
          onEdit: () => _editEvent(event),
          onDelete: () => _deleteEvent(event.id),
        );
      },
    );
  }

  Widget _buildGraphicsTab() {
    return GraphicsTab(token: widget.token);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Organizer Panel'),
          backgroundColor: const Color.fromARGB(255, 160, 52, 189),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(icon: Icon(Icons.event), text: 'Events'),
              Tab(icon: Icon(Icons.bar_chart), text: 'Graphics'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () => userProvider.confirmLogout(context),
            ),
          ],
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildEventsTab(),
            _buildGraphicsTab(),
          ],
        ),
        floatingActionButton: _tabController.index == 0
            ? FloatingActionButton(
                onPressed: _createEvent,
                backgroundColor: Colors.purple[400],
                child: const Icon(Icons.add, color: Colors.white),
              )
            : null,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
