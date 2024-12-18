import 'package:flutter/material.dart';
import 'package:eventify/services/organizer_service.dart';
import 'package:intl/intl.dart';

class AddEventScreen extends StatefulWidget {
  final String token;
  final int organizer_id;

  const AddEventScreen({
    super.key,
    required this.token,
    required this.organizer_id,
  });

  @override
  _AddEventScreenState createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  late OrganizerService organizerService;

  // Controladores de los campos
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _categoryIdController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();

  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();

  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    organizerService = OrganizerService(token: widget.token);
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // Llamar al servicio
      await organizerService.createEvent(
        organizer_id: widget.organizer_id,
        title: _titleController.text,
        description: _descriptionController.text,
        category_id: int.parse(_categoryIdController.text),
        start_time: _startTimeController.text,
        end_time: _endTimeController.text,
        location: _locationController.text,
        price: double.parse(_priceController.text),
        image_url: _imageUrlController.text,
      );

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event created successfully!')),
      );
      Navigator.of(context).pop(true); // Volver a la pantalla anterior
    } catch (e) {
      // Mostrar mensaje de error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create event: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _pickDate(TextEditingController controller, bool isStart) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: isStart
          ? _selectedStartDate ?? DateTime.now()
          : _selectedEndDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        if (isStart) {
          _selectedStartDate = pickedDate;
        } else {
          _selectedEndDate = pickedDate;
        }
        controller.text = pickedDate.toLocal().toString().split(' ')[0];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Event'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter a title' : null,
                ),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter a description' : null,
                ),
                TextFormField(
                  controller: _categoryIdController,
                  decoration: const InputDecoration(labelText: 'Category ID'),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter a category ID' : null,
                ),
                TextFormField(
                  readOnly: true,
                  controller: _startTimeController,
                  decoration: const InputDecoration(
                    labelText: 'Start Time',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () async {
                    final DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );

                    if (pickedDate != null) {
                      final TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );

                      if (pickedTime != null) {
                        final DateTime fullDateTime = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );

                        // Formatear al formato correcto
                        _startTimeController.text =
                            DateFormat("yyyy-MM-dd HH:mm:ss.SSS")
                                .format(fullDateTime);
                      }
                    }
                  },
                ),
                TextFormField(
                  readOnly: true,
                  controller: _endTimeController,
                  decoration: const InputDecoration(
                    labelText: 'End Time',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () async {
                    final DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );

                    if (pickedDate != null) {
                      final TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );

                      if (pickedTime != null) {
                        final DateTime fullDateTime = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );

                        // Formatear al formato correcto
                        _endTimeController.text =
                            DateFormat("yyyy-MM-dd HH:mm:ss.SSS")
                                .format(fullDateTime);
                      }
                    }
                  },
                ),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(labelText: 'Location'),
                ),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(labelText: 'Image URL'),
                ),
                const SizedBox(height: 20),
                _isSubmitting
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _submitForm,
                        child: const Text('Create Event'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
