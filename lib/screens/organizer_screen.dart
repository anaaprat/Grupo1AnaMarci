import 'package:eventify/screens/graphic_screen.dart';
import 'package:flutter/material.dart';
import 'package:eventify/services/organizer_service.dart';
import 'package:eventify/services/user_service.dart';
import 'package:eventify/screens/add_event_screen.dart';
import 'package:eventify/models/Event.dart';
import 'package:eventify/providers/user_provider.dart';
import 'package:eventify/widgets/event_card_organizer.dart';
import 'package:image_picker/image_picker.dart';

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
  List<dynamic> categories = [];
  String? selectedCategoryName;

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
          categories: categories,
        ),
      ),
    );

    if (result == true) {
      _loadEvents();
    }
  }

  Future<void> _initializeData() async {
    try {
      organizer_id = await _fetchUserId(); // Obtiene el organizer_id
      if (organizer_id == null) {
        throw Exception('Organizer ID not found');
      }
      categories = await userService.getCategories(); // Carga las categorías
      if (categories.isEmpty) {
        throw Exception('No categories found');
      }
      await _loadEvents(); // Carga los eventos
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing data: $e')),
        );
      }
    }
  }

  Future<int?> _fetchUserId() async {
    try {
      final users =
          await userService.getAllUsers(); // Obtiene todos los usuarios
      final user = users.firstWhere(
        (u) => u['email'] == widget.userEmail,
        orElse: () => null, // Si no se encuentra, devuelve null
      );
      return user != null ? user['id'] : null; // Devuelve el ID si existe
    } catch (e) {
      return null; // Maneja cualquier error devolviendo null
    }
  }

  Future<void> _loadEvents() async {
    setState(() => isLoading = true);
    try {
      final fetchedEvents =
          await organizerService.getEventsByOrganizer(organizer_id!);
      setState(() {
        events = fetchedEvents
            .map((e) => Event.fromJson(e))
            .where((event) => event.deleted == 0)
            .toList();
      });
      print('Eventos cargados: $events');
    } catch (e) {
      print('Error loading events: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading events: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<int?> _getCategoryIdByName(String categoryName) async {
    try {
      final category = categories.firstWhere(
        (c) => c['name'] == categoryName,
        orElse: () => null,
      );
      return category != null ? category['id'] : null;
    } catch (e) {
      print('Error finding category ID: $e');
      return null;
    }
  }

  Future<void> _editEvent(Event event) async {
    final TextEditingController titleController =
        TextEditingController(text: event.title);
    final TextEditingController descriptionController =
        TextEditingController(text: event.description ?? '');
    final TextEditingController locationController =
        TextEditingController(text: event.location ?? '');
    final TextEditingController priceController =
        TextEditingController(text: event.price?.toString() ?? '0');
    final TextEditingController startTimeController =
        TextEditingController(text: event.start_time.toIso8601String());
    final TextEditingController endTimeController =
        TextEditingController(text: event.end_time?.toIso8601String() ?? '');
    String? selectedCategoryName = event.category_name;
    XFile? selectedImage;

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
                TextField(
                  controller: startTimeController,
                  decoration: const InputDecoration(
                      labelText: 'Start Time (YYYY-MM-DDTHH:MM:SS)'),
                ),
                TextField(
                  controller: endTimeController,
                  decoration: const InputDecoration(
                      labelText: 'End Time (YYYY-MM-DDTHH:MM:SS)'),
                ),
                DropdownButtonFormField<String>(
                  value: selectedCategoryName,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: categories
                      .map((category) => DropdownMenuItem<String>(
                            value: category['name'],
                            child: Text(category['name']),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCategoryName = value;
                    });
                  },
                ),
                ElevatedButton(
                  onPressed: () async {
                    final picker = ImagePicker();
                    selectedImage =
                        await picker.pickImage(source: ImageSource.gallery);
                    setState(() {});
                  },
                  child: const Text('Select Image'),
                ),
                if (selectedImage != null)
                  Text('Selected Image: ${selectedImage!.name}'),
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
                  final categoryId =
                      await _getCategoryIdByName(selectedCategoryName ?? '');
                  if (categoryId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invalid category name')),
                    );
                    return;
                  }

                  final updatedEvent = Event(
                    id: event.id,
                    organizer_id: event.organizer_id,
                    title: titleController.text,
                    description: descriptionController.text,
                    category_id: categoryId,
                    start_time: DateTime.parse(startTimeController.text),
                    end_time: endTimeController.text.isNotEmpty
                        ? DateTime.parse(endTimeController.text)
                        : null,
                    location: locationController.text,
                    price: int.tryParse(priceController.text) ?? 0,
                    image_url: selectedImage?.path ?? event.image_url,
                    category_name: selectedCategoryName,
                    deleted: event.deleted,
                  );

                  print('Datos enviados al servidor: ${updatedEvent.toJson()}');

                  await organizerService.updateEvent(updatedEvent);
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

  Future<void> _deleteEvent(int eventId) async {
    print('Evento a borrar: $eventId');
    try {
      await organizerService.deleteEvent(eventId);
      setState(() {
        events.removeWhere((event) => event.id == eventId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting event: $e')),
      );
    }
  }

  Widget _buildGraphicsTab() {
    if (organizer_id == null) {
      return const Center(
        child: Text(
          'No organizer data available',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    return GraphicsScreen(
      token: widget.token,
      organizerId: organizer_id!,
    );
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
