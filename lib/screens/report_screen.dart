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
  List<Event> eventsList = [];
  Map<String, String> categoryNames = {}; // Relación de IDs con nombres

  @override
  void initState() {
    super.initState();
    userService = UserService(token: widget.token);
    _loadCategories();
  }

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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título principal
          const Text(
            'Generate Event Report',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
          const SizedBox(height: 20),

          // Sección de Fechas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        iniDate = pickedDate;
                      });
                    }
                  },
                  child: _buildDateContainer('Start Date',
                      iniDate?.toLocal().toString().split(' ')[0]),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        endDate = pickedDate;
                      });
                    }
                  },
                  child: _buildDateContainer(
                      'End Date', endDate?.toLocal().toString().split(' ')[0]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Sección de Tipos de Eventos
          const Text(
            'Event Types:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              children: selectedCategories.entries.map((entry) {
                final categoryName =
                    categoryNames[entry.key] ?? 'Unknown'; // Obtener el nombre
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  child: CheckboxListTile(
                    activeColor: Colors.blueAccent,
                    title: Text(categoryName,
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                    value: entry.value,
                    onChanged: (value) {
                      setState(() {
                        selectedCategories[entry.key] = value!;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Botones
// Botones
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(
                height: 40, // Ajustar altura del botón
                child: ElevatedButton.icon(
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
                  icon: const Icon(Icons.picture_as_pdf, size: 16),
                  label: const Text(
                    'Generate PDF',
                    style: TextStyle(fontSize: 12), // Reducir tamaño de fuente
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10), // Reducir padding
                  ),
                ),
              ),
              SizedBox(
                height: 40, // Ajustar altura del botón
                child: ElevatedButton.icon(
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
                  icon: const Icon(Icons.email, size: 16),
                  label: const Text(
                    'Send Email',
                    style: TextStyle(fontSize: 12), // Reducir tamaño de fuente
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10), // Reducir padding
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10), // Espacio adicional arriba de los botones
        ],
      ),
    );
  }

  Widget _buildDateContainer(String label, String? date) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            date ?? 'Select date',
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
