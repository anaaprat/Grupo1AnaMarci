import 'package:flutter/material.dart';
import 'package:eventify/services/organizer_service.dart';
import 'package:image_picker/image_picker.dart';

class AddEventScreen extends StatefulWidget {
  final String token;
  final int organizer_id;
  final List<dynamic> categories;

  const AddEventScreen({
    super.key,
    required this.token,
    required this.organizer_id,
    required this.categories,
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
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();

  String? _selectedCategoryName;
  XFile? _selectedImage;
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
      final category = widget.categories.firstWhere(
        (c) => c['name'] == _selectedCategoryName,
        orElse: () => null,
      );

      if (category == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid category selection')),
        );
        return;
      }

      final category_id = category['id'];
      final image_url = _selectedImage?.path ?? '';

      // Llamar al servicio
      await organizerService.createEvent(
        organizer_id: widget.organizer_id,
        title: _titleController.text,
        description: _descriptionController.text,
        category_id: category_id,
        start_time: _startTimeController.text,
        end_time: _endTimeController.text,
        location: _locationController.text,
        price: double.parse(_priceController.text),
        image_url: image_url,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event created successfully!')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create event: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _pickDateTime(TextEditingController controller) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        final dateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        controller.text = dateTime.toIso8601String();
      }
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
                  decoration:
                      const InputDecoration(labelText: 'Description'),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter a description' : null,
                ),
                DropdownButtonFormField<String>(
                  value: _selectedCategoryName,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: widget.categories
                      .map((category) => DropdownMenuItem<String>(
                            value: category['name'],
                            child: Text(category['name']),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategoryName = value;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Please select a category' : null,
                ),
                TextFormField(
                  readOnly: true,
                  controller: _startTimeController,
                  decoration: const InputDecoration(
                    labelText: 'Start Time',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () => _pickDateTime(_startTimeController),
                ),
                TextFormField(
                  readOnly: true,
                  controller: _endTimeController,
                  decoration: const InputDecoration(
                    labelText: 'End Time',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () => _pickDateTime(_endTimeController),
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
                ElevatedButton(
                  onPressed: () async {
                    final picker = ImagePicker();
                    final pickedImage =
                        await picker.pickImage(source: ImageSource.gallery);
                    if (pickedImage != null) {
                      setState(() {
                        _selectedImage = pickedImage;
                      });
                    }
                  },
                  child: const Text('Select Image'),
                ),
                if (_selectedImage != null)
                  Text('Selected Image: ${_selectedImage!.name}'),
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
