import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:traavaalay/config/api_config.dart';
import 'package:traavaalay/theme/app_colors.dart';
import 'package:image_picker/image_picker.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> user;

  const EditProfilePage({super.key, required this.user});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _cityController;
  late final TextEditingController _phoneController;
  bool _saving = false;
  File? _selectedImage;
  late String _profileImage;
  late List<String> _languages;
  final TextEditingController _languageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: (widget.user['name'] ?? '').toString(),
    );
    _cityController = TextEditingController(
      text: (widget.user['city'] ?? '').toString(),
    );
    _phoneController = TextEditingController(
      text: (widget.user['phone'] ?? '').toString(),
    );
    _profileImage = (widget.user['profileImage'] ?? '').toString();
    _languages =
        ((widget.user['languages'] as List?) ?? const [])
            .map((language) => language.toString().trim())
            .where((language) => language.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _languageController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final pendingLanguage = _languageController.text.trim();
    final languagesToSave = [
      ..._languages,
      if (pendingLanguage.isNotEmpty) pendingLanguage,
    ].toSet().toList()..sort();

    setState(() => _saving = true);

    try {
      final uploadedImage = await _uploadImageIfNeeded();

      final response = await http
          .put(
            Uri.parse('${ApiConfig.usersBaseUrl}/${widget.user['id']}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': _nameController.text.trim(),
              'city': _cityController.text.trim(),
              'phone': _phoneController.text.trim(),
              'profileImage': uploadedImage,
              'languages': languagesToSave,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      final data = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body);
      if (response.statusCode == 200) {
        final responseUser = Map<String, dynamic>.from(
          data['user'] as Map? ?? <String, dynamic>{},
        );
        Navigator.pop(context, {
          ...widget.user,
          ...responseUser,
          'name': _nameController.text.trim(),
          'city': _cityController.text.trim(),
          'phone': _phoneController.text.trim(),
          'profileImage': uploadedImage,
          'languages': languagesToSave,
        });
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            (data['message'] ?? 'Failed to update profile').toString(),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() {
      _selectedImage = File(pickedFile.path);
    });
  }

  Future<String> _uploadImageIfNeeded() async {
    if (_selectedImage == null) {
      return _profileImage;
    }

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
      throw Exception('Profile image upload failed');
    }

    final data = jsonDecode(body) as Map<String, dynamic>;
    final imagePath = (data['imagePath'] ?? '').toString().replaceFirst(
      '/uploads/',
      '',
    );
    _profileImage = imagePath;
    return imagePath;
  }

  String? _resolveProfileImage(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('http')) return trimmed;
    return '${ApiConfig.rootUrl}/uploads/$trimmed';
  }

  void _addLanguage() {
    final language = _languageController.text.trim();
    if (language.isEmpty) return;
    if (_languages.any(
      (item) => item.toLowerCase() == language.toLowerCase(),
    )) {
      _languageController.clear();
      return;
    }

    setState(() {
      _languages = [..._languages, language]..sort();
      _languageController.clear();
    });
  }

  void _removeLanguage(String language) {
    setState(() {
      _languages = _languages.where((item) => item != language).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final role = (widget.user['role'] ?? 'user').toString();
    final initials = _nameController.text.trim().isEmpty
        ? 'U'
        : _nameController.text
              .trim()
              .split(' ')
              .where((part) => part.isNotEmpty)
              .take(2)
              .map((part) => part[0].toUpperCase())
              .join();
    final networkImage = _resolveProfileImage(_profileImage);
    final ImageProvider<Object>? avatarImage = _selectedImage != null
        ? FileImage(_selectedImage!)
        : (networkImage != null ? NetworkImage(networkImage) : null);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: AppColors.surface,
                      backgroundImage: avatarImage,
                      child: avatarImage == null
                          ? Text(
                              initials.isEmpty ? 'U' : initials,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            )
                          : null,
                    ),
                    Material(
                      color: AppColors.secondary,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _saving ? null : _pickImage,
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(
                            Icons.camera_alt_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Update your ${role.toLowerCase()} details',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cityController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Home Base Location',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final trimmed = (value ?? '').trim();
                  if (trimmed.isEmpty) return 'Please enter your phone number';
                  if (trimmed.length < 8) return 'Enter a valid phone number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _languageController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Add Language',
                        border: OutlineInputBorder(),
                      ),
                      onFieldSubmitted: (_) => _addLanguage(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _addLanguage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Add'),
                    ),
                  ),
                ],
              ),
              if (_languages.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _languages
                      .map(
                        (language) => Chip(
                          label: Text(language),
                          onDeleted: _saving
                              ? null
                              : () => _removeLanguage(language),
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: _saving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
