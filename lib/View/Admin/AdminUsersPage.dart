import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:traavaalay/config/api_config.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  List<dynamic> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('${ApiConfig.apiBaseUrl}/admin/users'));
      if (response.statusCode == 200) {
        setState(() {
          _users = jsonDecode(response.body);
        });
      }
    } catch (e) {
      print("Error fetching users: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchUsers,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  final user = _users[index];
                  final role = (user['role'] ?? 'user').toString().toUpperCase();
                  final bool isVerified = user['verified'] == 1 || user['verified'] == true;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: Icon(
                          role == 'HOST' ? Icons.home : role == 'TRANSLATOR' ? Icons.translate : Icons.person,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      title: Row(
                        children: [
                          Text(user['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                          if (isVerified) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.verified, color: Theme.of(context).colorScheme.secondary, size: 18),
                          ]
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(user['email'] ?? 'No email'),
                          Text("City: ${user['city'] ?? 'Unknown'}"),
                        ],
                      ),
                      trailing: Chip(label: Text(role, style: const TextStyle(fontSize: 10))),
                    ),
                  );
                },
              ),
            ),
    );
  }
}