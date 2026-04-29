import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:traavaalay/config/api_config.dart';
import 'package:traavaalay/theme/app_colors.dart';

class CreateBlogScreen extends StatefulWidget {
  const CreateBlogScreen({super.key});

  @override
  State<CreateBlogScreen> createState() => _CreateBlogScreenState();
}

class _CreateBlogScreenState extends State<CreateBlogScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  File? selectedImage;
  bool loading = false;

  final String baseUrl = ApiConfig.blogsBaseUrl;

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => selectedImage = File(pickedFile.path));
    }
  }

  Future<void> submitBlog() async {
    if (titleController.text.isEmpty || descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Title and Description required")),
      );
      return;
    }

    if (selectedImage == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please select an image")));
      return;
    }

    setState(() => loading = true);

    try {
      final uploadRequest = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.apiBaseUrl}/upload'),
      );
      uploadRequest.files.add(
        await http.MultipartFile.fromPath('image', selectedImage!.path),
      );
      final uploadResponse = await uploadRequest.send();
      final uploadResponseBody = await uploadResponse.stream.bytesToString();

      if (uploadResponse.statusCode != 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Image upload failed: ${uploadResponse.statusCode}"),
          ),
        );
        setState(() => loading = false);
        return;
      }

      final uploadedData = jsonDecode(uploadResponseBody);
      final imagePath = (uploadedData['imagePath'] ?? '').toString();

      // Prepare blog data
      final blogData = {
        "title": titleController.text,
        "description": descriptionController.text,
        "image": imagePath,
        "date": DateTime.now().toIso8601String(),
      };

      // POST to the same backend used by the user blog feed
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(blogData),
      );

      if (response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Blog created successfully!")),
        );

        titleController.clear();
        descriptionController.clear();
        setState(() => selectedImage = null);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed: ${response.statusCode}")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Blog", style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "Blog Title",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: "Blog Description",
                border: OutlineInputBorder(),
              ),
            ),
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
                child: selectedImage != null
                    ? Image.file(selectedImage!, fit: BoxFit.cover)
                    : const Center(child: Text("Tap to select image")),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : submitBlog,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.primary,
              ),
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Submit Blog"),
            ),
          ],
        ),
      ),
    );
  }
}
