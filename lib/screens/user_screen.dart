import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../models/Event.dart';
import '../models/Category.dart';
import '../widgets/event_card.dart';
import '../services/email_service.dart';

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
  late EmailService emailService;

  String selectedCategory = 'All';
  String currentSection = 'All Events';
  Map<int, Category> categoryMap = {};

  List<Event> events = [];
  Map<String, dynamic> eventsByUser = {};
  List<Event> userRegisteredEvents = [];
  int? userId;

  bool isLoading = true;

  // Variables para la pestaña "Report"
  DateTime? startDate;
  DateTime? endDate;
  Map<String, bool> selectedCategories = {
    'Music': false,
    'Sport': false,
    'Technology': false,
  };

  @override
  void initState() {
    super.initState();
    userService = UserService(token: widget.token);
    emailService = EmailService(
      smtpEmail: 'anaprat26@gmail.com',
      smtpPassword: 'mkxv hldp bxbd aneb',
    );
  }

  Future<void> loadCategoriesAndEvents() async {
    try {
      final userData =
          await userService.fetchUserData(widget.token, widget.userEmail);

      if (userData == null || !userData.containsKey('id')) {
        throw Exception('No se encontró el usuario o falta el ID.');
      }

      userId = userData['id'];

      final categories = await userService.fetchCategories();
      final userRegisteredEvents = await userService.fetchEventsByUser(userId!);

      if (!mounted) return;

      setState(() {
        categoryMap = {for (var category in categories) category.id: category};
        eventsByUser = userRegisteredEvents;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos: ${e.toString()}')),
      );
    }
  }

  List<Event> get filteredEvents {
    final now = DateTime.now();
    List<Event> filtered;

    if (currentSection == 'My Events') {
      // Eventos en los que el usuario está registrado
      filtered = userRegisteredEvents
          .where((event) => event.start_time.isAfter(now))
          .toList();
    } else {
      // Eventos en los que el usuario NO está registrado
      final registeredIds =
          userRegisteredEvents.map((event) => event.id).toSet();
      filtered = events
          .where((event) =>
              event.start_time.isAfter(now) &&
              !registeredIds.contains(event.id))
          .toList();
    }

    // Filtrar por categoría seleccionada
    if (selectedCategory != 'All') {
      filtered = filtered
          .where((event) => event.category == selectedCategory)
          .toList();
    }

    return filtered;
  }

  Future<List<Event>> fetchFilteredEvents() async {
    final filtered = events.where((event) {
      final withinDateRange =
          (startDate == null || event.start_time.isAfter(startDate!)) &&
              (endDate == null || event.start_time.isBefore(endDate!));
      final matchesCategory = selectedCategories.entries.any((entry) =>
          entry.value &&
          event.category.toLowerCase() == entry.key.toLowerCase());
      return withinDateRange && matchesCategory;
    }).toList();

    return filtered;
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

  void showFilterModal() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          children: [
            ListTile(
              leading: Icon(Icons.music_note, color: Color(0xFFFFD700)),
              title: Text('Music'),
              onTap: () {
                setState(() {
                  selectedCategory = 'Music';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.sports, color: Color(0xFFFF4500)),
              title: Text('Sport'),
              onTap: () {
                setState(() {
                  selectedCategory = 'Sport';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.computer, color: Color(0xFF4CAF50)),
              title: Text('Technology'),
              onTap: () {
                setState(() {
                  selectedCategory = 'Technology';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.all_inclusive, color: Colors.purple[800]),
              title: Text('All'),
              onTap: () {
                setState(() {
                  selectedCategory = 'All';
                });
                Navigator.pop(context);
              },
            ),
          ],
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
          style: TextStyle(color: Colors.white),
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
              onTap: () async {
                setState(() {
                  currentSection = 'All Events';
                  selectedCategory = 'All';
                });
                await loadCategoriesAndEvents(); // Recargar eventos
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('My Events'),
              onTap: () async {
                setState(() {
                  currentSection = 'My Events';
                  selectedCategory = 'All';
                });
                await loadCategoriesAndEvents(); // Recargar eventos
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Report'),
              onTap: () {
                setState(() {
                  currentSection = 'Report';
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.purple[800]))
          : currentSection == 'Report'
              ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Generate Event Report',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple[800],
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Start Date:',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 5),
                      GestureDetector(
                        onTap: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (pickedDate != null) {
                            setState(() {
                              startDate = pickedDate;
                            });
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              vertical: 10, horizontal: 15),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            startDate != null
                                ? '${startDate!.toLocal()}'.split(' ')[0]
                                : 'Select start date',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'End Date:',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 5),
                      GestureDetector(
                        onTap: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (pickedDate != null) {
                            setState(() {
                              endDate = pickedDate;
                            });
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              vertical: 10, horizontal: 15),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            endDate != null
                                ? '${endDate!.toLocal()}'.split(' ')[0]
                                : 'Select end date',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Event Types:',
                        style: TextStyle(fontSize: 16),
                      ),
                      Column(
                        children: selectedCategories.keys.map((key) {
                          return CheckboxListTile(
                            title: Text(key),
                            value: selectedCategories[key],
                            onChanged: (value) {
                              setState(() {
                                selectedCategories[key] = value!;
                              });
                            },
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 20),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                final filteredEvents =
                                    await fetchFilteredEvents();
                                await emailService.generateFilteredPdf(
                                  context,
                                  filteredEvents,
                                  openAfterGeneration: true,
                                  saveToDownloads: true,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple[800],
                              ),
                              child: Text('Generate and Save PDF'),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                final filteredEvents =
                                    await fetchFilteredEvents();
                                await emailService.sendFilteredPdfEmail(
                                    context, filteredEvents, widget.userEmail);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple[800],
                              ),
                              child: Text('Send PDF via Email'),
                            ),
                          ]),
                    ],
                  ),
                )
              : currentSection == 'All Events' || currentSection == 'My Events'
                  ? ListView.builder(
                      itemCount: filteredEvents.length,
                      itemBuilder: (context, index) {
                        final event = filteredEvents[index];

                        return EventCard(
                          event: event,
                          contextSection: currentSection,
                          onRegister: currentSection == 'All Events'
                              ? () async {
                                  try {
                                    await userService.registerEvent(
                                        userId!, event.id);
                                    setState(() {
                                      userRegisteredEvents.add(event);
                                      events.remove(event);
                                    });
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Error al registrar el evento: $e')),
                                    );
                                  }
                                }
                              : null,
                          onSuspend: currentSection == 'My Events'
                              ? () async {
                                  try {
                                    await userService.unregisterEvent(
                                        userId!, event.id);
                                    setState(() {
                                      events.add(event);
                                      userRegisteredEvents.remove(event);
                                    });
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Error al desregistrar el evento: $e')),
                                    );
                                  }
                                }
                              : null,
                          onShowDetails: () {
                            showEventDetails(event);
                          },
                        );
                      },
                    )
                  : Center(
                      child: Text(
                        'No data available.',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
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
