import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:traavaalay/config/api_config.dart';

class AstroForm extends StatefulWidget {
  final Map<String, dynamic> user;

  const AstroForm({super.key, required this.user});

  @override
  State<AstroForm> createState() => _AstroFormState();
}

class _AstroFormState extends State<AstroForm> {
  final TextEditingController eventName = TextEditingController();
  final TextEditingController description = TextEditingController();
  final TextEditingController price = TextEditingController();
  final TextEditingController location = TextEditingController();
  final TextEditingController bestViewingTime = TextEditingController();
  final TextEditingController weatherDep = TextEditingController();

  final List<String> _citySuggestions = const [
    'Delhi',
    'Mumbai',
    'Jaipur',
    'Pune',
    'Bangalore',
  ];

  bool telescopeProvided = false;
  bool _isSubmitting = false;
  List<File> _selectedImages = [];
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  StargazingStatus _status = StargazingStatus.good;

  @override
  void initState() {
    super.initState();
    final initialCity = (widget.user['city'] ?? '').toString().trim();
    if (initialCity.isNotEmpty) {
      location.text = initialCity;
    }
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

  Future<void> pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _selectedImages = pickedFiles.map((file) => File(file.path)).toList();
      });
    }
  }

  Future<List<String>> _uploadImages() async {
    if (_selectedImages.isEmpty) return [];

    final uploadedPaths = <String>[];
    for (final image in _selectedImages) {
      final uploadRequest = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.apiBaseUrl}/upload'),
      );
      uploadRequest.files.add(
        await http.MultipartFile.fromPath('image', image.path),
      );

      final response = await uploadRequest.send();
      final body = await response.stream.bytesToString();

      if (response.statusCode != 200) {
        throw Exception('Image upload failed');
      }

      final data = jsonDecode(body) as Map<String, dynamic>;
      uploadedPaths.add(
        (data['imagePath'] ?? '').toString().replaceFirst('/uploads/', ''),
      );
    }

    return uploadedPaths;
  }

  Future<void> submitForm() async {
    if (eventName.text.isEmpty ||
        description.text.isEmpty ||
        price.text.isEmpty ||
        location.text.isEmpty ||
        _selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final eventTime = selectedTime?.format(context) ?? "";
      final imagePaths = await _uploadImages();
      final package = {
        "host_id": widget.user['id'],
        "category": "Astro",
        "title": eventName.text.trim(),
        "description": description.text.trim(),
        "price": price.text.trim(),
        "location": location.text.trim(),
        "bestViewingTime": bestViewingTime.text.trim(),
        "weatherDep": weatherDep.text.trim(),
        "telescopeProvided": telescopeProvided,
        "event_date": selectedDate?.toIso8601String(),
        "event_time": eventTime,
        "stargazingStatus": _status.name,
        "imageUrl": jsonEncode(imagePaths),
      };

      final response = await http.post(
        Uri.parse(ApiConfig.packagesBaseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(package),
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Astro package submitted!")),
        );
        eventName.clear();
        description.clear();
        price.clear();
        bestViewingTime.clear();
        weatherDep.clear();
        location.text = (widget.user['city'] ?? '').toString();
        setState(() {
          _selectedImages = [];
          selectedDate = null;
          selectedTime = null;
          telescopeProvided = false;
          _status = StargazingStatus.good;
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
            "Astro Package Details",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          customTextField("Event Name", eventName),
          customTextField("Description", description, maxLines: 3),
          customTextField("Price", price),
          customTextField(
            "Location / Address / Landmark",
            location,
            helperText:
                "Use city plus a nearby landmark so users can find the venue easily.",
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
          GestureDetector(
            onTap: pickImages,
            child: Container(
              height: 190,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _selectedImages.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(10),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedImages
                            .map(
                              (image) => ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  image,
                                  width: 94,
                                  height: 78,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    )
                  : const Center(child: Text("Tap to upload package images")),
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
          CheckboxListTile(
            title: const Text("Telescope Provided"),
            value: telescopeProvided,
            onChanged: (val) =>
                setState(() => telescopeProvided = val ?? false),
          ),
          customTextField("Best Viewing Time", bestViewingTime),
          customTextField("Weather Dependencies", weatherDep),
          const SizedBox(height: 10),
          const Text(
            "Stargazing Signal",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          StargazingSignal(status: _status),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () =>
                    setState(() => _status = StargazingStatus.good),
                child: const Text("Good"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow),
                onPressed: () =>
                    setState(() => _status = StargazingStatus.moderate),
                child: const Text("Moderate"),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : submitForm,
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Submit"),
            ),
          ),
        ],
      ),
    );
  }

  Widget customTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    String? helperText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

enum StargazingStatus { good, moderate }

class StargazingSignal extends StatelessWidget {
  final StargazingStatus status;

  const StargazingSignal({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;

    switch (status) {
      case StargazingStatus.good:
        color = Colors.green;
        text = "Great visibility - Perfect for stargazing!";
        break;
      case StargazingStatus.moderate:
        color = Colors.yellow;
        text = "Moderate visibility - Stargazing is still possible.";
        break;
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.circle, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
