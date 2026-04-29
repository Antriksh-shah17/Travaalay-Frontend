import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:traavaalay/config/api_config.dart';

class AdminVerificationScreen extends StatefulWidget {
  const AdminVerificationScreen({super.key});

  @override
  State<AdminVerificationScreen> createState() => _AdminVerificationScreenState();
}

class _AdminVerificationScreenState extends State<AdminVerificationScreen> {
  List<dynamic> _requests = [];
  bool _isLoading = true;
  
  // Helper to dynamically get the root URL to load images 
  String get rootUrl {
    if (ApiConfig.translatorsBaseUrl.contains('/api')) {
      return ApiConfig.translatorsBaseUrl.split('/api')[0];
    }
    return 'http://localhost:5000';
  }

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('${ApiConfig.translatorsBaseUrl}/requests'));
      if (response.statusCode == 200) {
        setState(() {
          _requests = jsonDecode(response.body);
        });
      }
    } catch (e) {
      print('Error fetching requests: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _viewDocuments(int translatorId, int requestId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await http.get(Uri.parse('${ApiConfig.translatorsBaseUrl}/documents/$translatorId'));
      
      if (!mounted) return;
      Navigator.pop(context); // Close loading

      if (response.statusCode == 200) {
        final List<dynamic> documents = jsonDecode(response.body);
        _showReviewDialog(documents, requestId);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load documents.')));
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      print('Error fetching documents: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error loading documents.')));
    }
  }

  void _showReviewDialog(List<dynamic> documents, int requestId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Review Documents'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: documents.isEmpty
                ? const Center(child: Text("No documents uploaded by this user."))
                : ListView.builder(
                    itemCount: documents.length,
                    itemBuilder: (context, index) {
                      final doc = documents[index];
                      final imageUrl = "$rootUrl${doc['file_url']}";
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                doc['document_type'] ?? 'Document',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  imageUrl,
                                  height: 250,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    height: 250,
                                    width: double.infinity,
                                    color: Colors.grey[200],
                                    child: const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                        SizedBox(height: 8),
                                        Text('Image not available', style: TextStyle(color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(context);
                _updateStatus(requestId, 'rejected');
              },
              child: const Text('Reject', style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () {
                Navigator.pop(context);
                _updateStatus(requestId, 'approved');
              },
              child: const Text('Approve', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateStatus(int requestId, String status) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.translatorsBaseUrl}/requests/$requestId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request $status successfully!'),
            backgroundColor: status == 'approved' ? Colors.green : Colors.red,
          ),
        );
        _fetchRequests();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update status.')));
      }
    } catch (e) {
      print('Error updating status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Verifications'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? const Center(child: Text("No verification requests found."))
              : RefreshIndicator(
                  onRefresh: _fetchRequests,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _requests.length,
                    itemBuilder: (context, index) {
                      final req = _requests[index];
                      final status = req['status'] ?? 'pending';
                      final isPending = status == 'pending';

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(
                            req['name'] ?? 'Unknown Translator',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                "Role: ${(req['role'] ?? 'Translator').toString().toUpperCase()}",
                                style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                              ),
                              const SizedBox(height: 4),
                              Text("Email: ${req['email'] ?? 'N/A'}"),
                              Text("City: ${req['city'] ?? 'N/A'}"),
                              const SizedBox(height: 8),
                              Chip(
                                label: Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                    color: isPending
                                        ? Colors.orange.shade800
                                        : status == 'approved'
                                            ? Colors.green.shade800
                                            : Colors.red.shade800,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                backgroundColor: isPending
                                    ? Colors.orange.shade100
                                    : status == 'approved'
                                        ? Colors.green.shade100
                                        : Colors.red.shade100,
                                side: BorderSide.none,
                              ),
                            ],
                          ),
                          trailing: ElevatedButton.icon(
                            onPressed: () => _viewDocuments(req['translator_id'], req['id']),
                            icon: const Icon(Icons.folder_shared, size: 18),
                            label: Text(isPending ? "Review" : "View Docs"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              foregroundColor: Theme.of(context).colorScheme.primary,
                              elevation: 0,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}