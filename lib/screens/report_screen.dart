import 'package:flutter/material.dart';
import 'package:eventify/services/email_service.dart';
import 'package:eventify/models/event.dart';

class ReportScreen extends StatefulWidget {
  final List<Event> allEvents;
  final EmailService emailService;
  final String userEmail;

  const ReportScreen({
    super.key,
    required this.allEvents,
    required this.emailService,
    required this.userEmail,
  });

  @override
  _ReportScreenState createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  DateTime? startDate;
  DateTime? endDate;
  Map<String, bool> selectedCategories = {
    'Music': false,
    'Sport': false,
    'Technology': false,
  };

  Future<List<Event>> _fetchFilteredEvents() async {
    return widget.allEvents.where((event) {
      final withinDateRange = (startDate == null || event.start_time.isAfter(startDate!)) &&
          (endDate == null || event.start_time.isBefore(endDate!));
      final matchesCategory = selectedCategories.entries.any((entry) =>
          entry.value && event.category.toLowerCase() == entry.key.toLowerCase());
      return withinDateRange && matchesCategory;
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
            'Start Date:',
            style: TextStyle(fontSize: 16),
          ),
          GestureDetector(
            onTap: () async {
              final pickedDate = await showDatePicker(
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
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                startDate != null
                    ? '${startDate!.toLocal()}'.split(' ')[0]
                    : 'Select start date',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'End Date:',
            style: TextStyle(fontSize: 16),
          ),
          GestureDetector(
            onTap: () async {
              final pickedDate = await showDatePicker(
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
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                endDate != null
                    ? '${endDate!.toLocal()}'.split(' ')[0]
                    : 'Select end date',
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
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: () async {
                  final filteredEvents = await _fetchFilteredEvents();
                  await widget.emailService.generateFilteredPdf(
                    context,
                    filteredEvents,
                    openAfterGeneration: true,
                    saveToDownloads: true,
                  );
                },
                child: const Text('Generate and Save PDF'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final filteredEvents = await _fetchFilteredEvents();
                  await widget.emailService.sendFilteredPdfEmail(
                      context, filteredEvents, widget.userEmail);
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
