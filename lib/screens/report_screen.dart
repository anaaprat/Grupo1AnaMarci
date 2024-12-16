import 'package:flutter/material.dart';
import 'package:eventify/services/email_service.dart';
import 'package:eventify/services/user_service.dart';
import 'package:eventify/models/Event.dart';

class ReportScreen extends StatefulWidget {
  final EmailService emailService;
  final String userEmail;
  final String token;

  const ReportScreen({
    super.key,
    required this.emailService,
    required this.userEmail,
    required this.token,
  });

  @override
  _ReportScreenState createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  DateTime? iniDate;
  DateTime? endDate;
  late UserService userService;
  Map<String, bool> eventsPDF = {};
  Map<String, bool> selectedCategories = {};

  @override
  void initState() {
    super.initState();
    userService = UserService(token: widget.token);
    _loadCategories();
  }

  Map<String, String> categoryNames = {}; // Relación de IDs con nombres

  Future<void> _loadCategories() async {
    try {
      final categories = await userService.getCategories();

      // Mapear categorías por ID
      final Map<String, bool> categoriesMap = {
        for (var category in categories) category['id'].toString(): false,
      };

      // Crear un mapa de IDs a nombres
      categoryNames = {
        for (var category in categories)
          category['id'].toString(): category['name'],
      };

      setState(() {
        selectedCategories = categoriesMap;
      });
      print('Category Names: $categoryNames');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading categories: $e')),
        );
      }
    }
  }

  List<Event> eventsList = [];

  Future<void> loadEvents() async {
    try {
      final events = await userService.getAllEvents();
      print('All Events: $events');

      // Obtener los nombres de las categorías seleccionadas
      final selectedCategoryNames = selectedCategories.entries
          .where((entry) => entry.value == true) // Solo casillas marcadas
          .map((entry) => categoryNames[entry.key]) // Obtener los nombres
          .where((name) => name != null) // Filtrar nulos
          .toSet();

      final filteredEvents = events.where((event) {
        final eventDate = DateTime.parse(event['start_time']);

        // Filtrado por rango de fechas
        final matchesDate = (iniDate == null || eventDate.isAfter(iniDate!)) &&
            (endDate == null || eventDate.isBefore(endDate!));

        // Filtrado por categoría (comparamos nombres)
        final eventCategory = event['category'];
        final matchesCategory = selectedCategoryNames.isEmpty ||
            selectedCategoryNames.contains(eventCategory);

        return matchesDate && matchesCategory;
      }).toList();

      if (filteredEvents.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No events match the selected filters.')),
        );
        return;
      }

      setState(() {
        eventsList =
            filteredEvents.map((event) => Event.fromJson(event)).toList();
        eventsPDF = {for (var event in eventsList) event.title: false};
      });

      print('Filtered Events with Categories: $eventsList');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading events: $e')),
        );
      }
    }
  }

  List<Event> _convertEventsMapToList(Map<String, bool> eventsMap) {
    return eventsMap.entries.map((entry) {
      return Event(
        id: 0,
        title: entry.key,
        start_time: DateTime.now(),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Generate Event Report',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Select Date Range:',
            style: TextStyle(fontSize: 16),
          ),
          GestureDetector(
            onTap: () async {
              final pickedDateRange = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
                initialDateRange: iniDate != null && endDate != null
                    ? DateTimeRange(start: iniDate!, end: endDate!)
                    : null,
              );

              if (pickedDateRange != null) {
                setState(() {
                  iniDate = pickedDateRange.start;
                  endDate = pickedDateRange.end;
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                iniDate != null && endDate != null
                    ? '${iniDate!.toLocal()} - ${endDate!.toLocal()}'
                    : 'Select date range',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Event Types:',
            style: TextStyle(fontSize: 16),
          ),
          Column(
            children: selectedCategories.entries.map((entry) {
              final categoryName =
                  categoryNames[entry.key] ?? 'Unknown'; // Obtener el nombre
              return CheckboxListTile(
                title: Text(categoryName),
                value: entry.value,
                onChanged: (value) {
                  setState(() {
                    selectedCategories[entry.key] = value!;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: () async {
                  await loadEvents();
                  if (eventsList.isNotEmpty) {
                    await widget.emailService.generateFilteredPdf(
                      context,
                      eventsList,
                      openAfterGeneration: true,
                      saveToDownloads: true,
                    );
                  }
                },
                child: const Text('Generate and Save PDF'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await loadEvents();
                  if (eventsList.isNotEmpty) {
                    await widget.emailService.sendFilteredPdfEmail(
                      context,
                      eventsList,
                      widget.userEmail,
                    );
                  }
                },
                child: const Text('Send PDF via Email'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
