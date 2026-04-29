import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:traavaalay/config/api_config.dart';

class TourForm extends StatefulWidget {
  final Map<String, dynamic> user;

  const TourForm({super.key, required this.user});

  @override
  State<TourForm> createState() => _TourFormState();
}

class _TourFormState extends State<TourForm> {
  final TextEditingController eventName = TextEditingController();
  final TextEditingController description = TextEditingController();
  final TextEditingController price = TextEditingController();
  final TextEditingController location = TextEditingController();
  final TextEditingController duration = TextEditingController();
  final TextEditingController highlights = TextEditingController();

  final List<String> _citySuggestions = const [
    'Delhi',
    'Mumbai',
    'Jaipur',
    'Pune',
    'Bangalore',
  ];

  bool _isSubmitting = false;
  File? _selectedImage;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  @override
  void initState() {
    super.initState();
    final initialCity = (widget.user['city'] ?? '').toString().trim();
    if (initialCity.isNotEmpty) {
      location.text = initialCity;
    }
  }

  @override
  void dispose() {
    eventName.dispose();
    description.dispose();
    price.dispose();
    location.dispose();
    duration.dispose();
    highlights.dispose();
    super.dispose();
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  Future<void> pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => selectedTime = picked);
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  Future<String> _uploadImage() async {
    if (_selectedImage == null) return '';

    final uploadRequest = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.apiBaseUrl}/upload'),
    );
    uploadRequest.files.add(
      await http.MultipartFile.fromPath('image', _selectedImage!.path),
    );

    final response = await uploadRequest.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      throw Exception('Image upload failed');
    }

    final data = jsonDecode(body) as Map<String, dynamic>;
    return (data['imagePath'] ?? '').toString().replaceFirst('/uploads/', '');
  }

  Future<void> submitForm() async {
    if (eventName.text.isEmpty ||
        description.text.isEmpty ||
        price.text.isEmpty ||
        location.text.isEmpty ||
        _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final eventTime = selectedTime?.format(context) ?? "";
      final imagePath = await _uploadImage();
      final extraDetails = [
        if (duration.text.trim().isNotEmpty)
          "Duration: ${duration.text.trim()}",
        if (highlights.text.trim().isNotEmpty)
          "Highlights: ${highlights.text.trim()}",
      ].join(" | ");

      final mergedDescription = extraDetails.isEmpty
          ? description.text.trim()
          : "${description.text.trim()}\n\n$extraDetails";

      final package = {
        "host_id": widget.user['id'],
        "category": "Tour",
        "title": eventName.text.trim(),
        "description": mergedDescription,
        "price": price.text.trim(),
        "location": location.text.trim(),
        "event_date": selectedDate?.toIso8601String(),
        "event_time": eventTime,
        "imageUrl": imagePath,
      };

      final response = await http.post(
        Uri.parse(ApiConfig.packagesBaseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(package),
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tour package submitted!")),
        );
        eventName.clear();
        description.clear();
        price.clear();
        duration.clear();
        highlights.clear();
        location.text = (widget.user['city'] ?? '').toString();
        setState(() {
          _selectedImage = null;
          selectedDate = null;
          selectedTime = null;
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed: ${response.body}")));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hostCity = (widget.user['city'] ?? '').toString().trim();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Tour Package Details",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _textField("Tour Name", eventName),
          _textField("Description", description, maxLines: 3),
          _textField("Price", price),
          _textField(
            "Location / Meeting Point / Landmark",
            location,
            helperText: "Add a city and an easy meeting point for travelers.",
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (hostCity.isNotEmpty)
                ActionChip(
                  label: Text("Use $hostCity"),
                  onPressed: () => setState(() => location.text = hostCity),
                ),
              ..._citySuggestions.map(
                (city) => ActionChip(
                  label: Text(city),
                  onPressed: () => setState(() => location.text = city),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _textField("Duration", duration),
          _textField("Highlights", highlights, maxLines: 2),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: pickImage,
            child: Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_selectedImage!, fit: BoxFit.cover),
                    )
                  : const Center(child: Text("Tap to upload package image")),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: pickDate,
                  child: Text(
                    selectedDate == null
                        ? "Pick Date"
                        : "${selectedDate!.day}-${selectedDate!.month}-${selectedDate!.year}",
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: pickTime,
                  child: Text(
                    selectedTime == null
                        ? "Pick Time"
                        : selectedTime!.format(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : submitForm,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text("Submit Tour Package"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _textField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    String? helperText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
