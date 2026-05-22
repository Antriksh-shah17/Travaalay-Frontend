import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:traavaalay/config/api_config.dart';
import 'package:traavaalay/theme/app_colors.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  List<dynamic> _users = [];
  int _totalBookings = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final usersResponse = await http.get(
        Uri.parse('${ApiConfig.apiBaseUrl}/admin/users'),
      );
      final translatorBookingsResponse = await http.get(
        Uri.parse('${ApiConfig.apiBaseUrl}/admin/bookings/translators'),
      );
      final hostBookingsResponse = await http.get(
        Uri.parse('${ApiConfig.apiBaseUrl}/admin/bookings/hosts'),
      );

      if (usersResponse.statusCode == 200) {
        final users = jsonDecode(usersResponse.body) as List<dynamic>;
        final translatorBookings = translatorBookingsResponse.statusCode == 200
            ? jsonDecode(translatorBookingsResponse.body) as List<dynamic>
            : const <dynamic>[];
        final hostBookings = hostBookingsResponse.statusCode == 200
            ? jsonDecode(hostBookingsResponse.body) as List<dynamic>
            : const <dynamic>[];

        if (!mounted) return;
        setState(() {
          _users = users;
          _totalBookings = translatorBookings.length + hostBookings.length;
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
    final int userCount = _users.where((user) {
      final role = (user['role'] ?? 'user').toString().trim().toLowerCase();
      return role == 'user';
    }).length;
    final int translatorCount = _users.where((user) {
      final role = (user['role'] ?? '').toString().trim().toLowerCase();
      return role == 'translator';
    }).length;
    final int hostCount = _users.where((user) {
      final role = (user['role'] ?? '').toString().trim().toLowerCase();
      return role == 'host';
    }).length;
    final int overallUsersCount = _users.length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchUsers,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildStatCard(
                        label: "Users",
                        value: userCount.toString(),
                        icon: Icons.person,
                      ),
                      _buildStatCard(
                        label: "Translators",
                        value: translatorCount.toString(),
                        icon: Icons.translate,
                      ),
                      _buildStatCard(
                        label: "Host",
                        value: hostCount.toString(),
                        icon: Icons.home,
                      ),
                      _buildStatCard(
                        label: "Overall Users",
                        value: overallUsersCount.toString(),
                        icon: Icons.groups,
                      ),
                      _buildStatCard(
                        label: "Total Bookings",
                        value: _totalBookings.toString(),
                        icon: Icons.book_online,
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return SizedBox(
      width: 160,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.secondary),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
