import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:traavaalay/config/api_config.dart';
import 'package:traavaalay/theme/app_colors.dart';

class AdminBookingsPage extends StatefulWidget {
  const AdminBookingsPage({super.key});

  @override
  State<AdminBookingsPage> createState() => _AdminBookingsPageState();
}

class _AdminBookingsPageState extends State<AdminBookingsPage> {
  List<dynamic> _translatorBookings = [];
  List<dynamic> _hostBookings = [];
  bool _isLoading = true;

  String _normalizeStatus(dynamic statusValue) {
    final status = (statusValue ?? '').toString().trim().toLowerCase();

    if (status == 'approved' || status == 'confirmed') return 'Approved';
    if (status == 'rejected' || status == 'reject' || status == 'cancelled') {
      return 'Rejected';
    }
    return 'Pending';
  }

  Color _statusBackground(String status) {
    switch (status) {
      case 'Approved':
        return AppColors.success.withValues(alpha: 0.18);
      case 'Rejected':
        return AppColors.danger.withValues(alpha: 0.18);
      default:
        return AppColors.warning.withValues(alpha: 0.18);
    }
  }

  Color _statusForeground(String status) {
    switch (status) {
      case 'Approved':
        return AppColors.success;
      case 'Rejected':
        return AppColors.danger;
      default:
        return AppColors.warning;
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchAllBookings();
  }

  Future<void> _fetchAllBookings() async {
    setState(() => _isLoading = true);
    try {
      final transRes = await http.get(
        Uri.parse('${ApiConfig.apiBaseUrl}/admin/bookings/translators'),
      );
      final hostRes = await http.get(
        Uri.parse('${ApiConfig.apiBaseUrl}/admin/bookings/hosts'),
      );

      if (transRes.statusCode == 200 && hostRes.statusCode == 200) {
        setState(() {
          _translatorBookings = jsonDecode(transRes.body);
          _hostBookings = jsonDecode(hostRes.body);
        });
      }
    } catch (e) {
      debugPrint("Error fetching admin bookings: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: const PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: Material(
            color: AppColors.surface,
            elevation: 0,
            child: TabBar(
              labelColor: AppColors.secondary,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: AppColors.secondary,
              tabs: [
                Tab(text: "Translator Bookings"),
                Tab(text: "Host Bookings"),
              ],
            ),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildBookingList(_translatorBookings, isTranslator: true),
                  _buildBookingList(_hostBookings, isTranslator: false),
                ],
              ),
      ),
    );
  }

  Widget _buildBookingList(
    List<dynamic> bookings, {
    required bool isTranslator,
  }) {
    if (bookings.isEmpty) {
      return const Center(child: Text("No bookings found."));
    }

    return RefreshIndicator(
      onRefresh: _fetchAllBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          final status = _normalizeStatus(booking['status']);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isTranslator
                            ? "Tourist: ${booking['tourist_name']}"
                            : "Traveler: ${booking['traveler_name']}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Chip(
                        label: Text(
                          status,
                          style: TextStyle(
                            fontSize: 12,
                            color: _statusForeground(status),
                          ),
                        ),
                        backgroundColor: _statusBackground(status),
                      ),
                    ],
                  ),
                  const Divider(),
                  if (isTranslator) ...[
                    Text("Translator: ${booking['translator_name']}"),
                    Text("Language: ${booking['language']}"),
                  ] else ...[
                    Text("Host: ${booking['host_name']}"),
                    Text("Package: ${booking['package_name']}"),
                    if ((booking['package_category'] ?? '')
                        .toString()
                        .isNotEmpty)
                      Text("Category: ${booking['package_category']}"),
                    if ((booking['package_location'] ?? '')
                        .toString()
                        .isNotEmpty)
                      Text("Location: ${booking['package_location']}"),
                    if ((booking['package_price'] ?? '').toString().isNotEmpty)
                      Text("Price: ${booking['package_price']}"),
                    if ((booking['traveler_email'] ?? '').toString().isNotEmpty)
                      Text("Email: ${booking['traveler_email']}"),
                    if ((booking['traveler_phone'] ?? '').toString().isNotEmpty)
                      Text("Phone: ${booking['traveler_phone']}"),
                    if ((booking['package_description'] ?? '')
                        .toString()
                        .isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text("Details: ${booking['package_description']}"),
                    ],
                    if ((booking['event_date'] ?? '').toString().isNotEmpty)
                      Text(
                        "Event Date: ${booking['event_date'].toString().split('T')[0]}",
                      ),
                    if ((booking['event_time'] ?? '').toString().isNotEmpty)
                      Text("Event Time: ${booking['event_time']}"),
                    if (booking['telescopeProvided'] != null)
                      Text(
                        "Telescope: ${booking['telescopeProvided'] == 1 || booking['telescopeProvided'] == true ? 'Provided' : 'Not provided'}",
                      ),
                    if ((booking['bestViewingTime'] ?? '')
                        .toString()
                        .isNotEmpty)
                      Text("Best Viewing Time: ${booking['bestViewingTime']}"),
                    if ((booking['weatherDep'] ?? '').toString().isNotEmpty)
                      Text("Weather Dependency: ${booking['weatherDep']}"),
                    if ((booking['stargazingStatus'] ?? '')
                        .toString()
                        .isNotEmpty)
                      Text("Sky Status: ${booking['stargazingStatus']}"),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        booking['booking_date']?.split('T')[0] ?? 'N/A',
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
