import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:traavaalay/config/api_config.dart';
import 'package:traavaalay/theme/app_colors.dart';

class BookingScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const BookingScreen({super.key, required this.user});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  bool _isLoading = true;
  List<dynamic> _bookings = [];

  String _normalizeStatus(dynamic statusValue) {
    final status = (statusValue ?? '').toString().trim().toLowerCase();

    if (status == 'approved' || status == 'confirmed') return 'Approved';
    if (status == 'rejected' || status == 'reject' || status == 'cancelled') {
      return 'Rejected';
    }

    return 'Pending';
  }

  Color _statusColor(String status) {
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
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    setState(() => _isLoading = true);

    try {
      final userId = widget.user['id'];
      final response = await http.get(
        Uri.parse('${ApiConfig.apiBaseUrl}/bookings/host/$userId'),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          _bookings = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception("Failed to load host bookings");
      }
    } catch (e) {
      debugPrint("Error fetching host bookings: $e");
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(int bookingId, String status) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.apiBaseUrl}/bookings/host/$bookingId/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': widget.user['id'], 'status': status}),
      );

      if (response.statusCode == 200) {
        await _fetchBookings();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking marked as $status'),
            backgroundColor: status == 'Approved'
                ? AppColors.success
                : AppColors.danger,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error updating host booking status: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _bookings
        .where((booking) => _normalizeStatus(booking['status']) == 'Pending')
        .length;

    return Scaffold(
      appBar: AppBar(title: const Text("Booking Requests")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bookings.isEmpty
          ? const Center(child: Text("No package booking requests yet."))
          : RefreshIndicator(
              onRefresh: _fetchBookings,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _bookings.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          pendingCount > 0
                              ? "You have $pendingCount new booking request${pendingCount == 1 ? '' : 's'} to review."
                              : "All booking requests are up to date.",
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                  }

                  final booking = _bookings[index - 1];
                  final status = _normalizeStatus(booking['status']);

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  (booking["traveler_name"] ?? 'Traveler')
                                      .toString(),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Chip(
                                label: Text(
                                  status,
                                  style: TextStyle(color: _statusColor(status)),
                                ),
                                backgroundColor: _statusColor(
                                  status,
                                ).withValues(alpha: 0.12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text("Package: ${booking['package_name'] ?? 'N/A'}"),
                          Text(
                            "Category: ${booking['package_category'] ?? 'N/A'}",
                          ),
                          Text("Email: ${booking['traveler_email'] ?? 'N/A'}"),
                          Text("Phone: ${booking['traveler_phone'] ?? 'N/A'}"),
                          Text(
                            "Booking Date: ${(booking['booking_date'] ?? '').toString().split('T').first}",
                          ),
                          if ((booking['package_location'] ?? '')
                              .toString()
                              .isNotEmpty)
                            Text("Location: ${booking['package_location']}"),
                          if ((booking['package_price'] ?? '')
                              .toString()
                              .isNotEmpty)
                            Text("Price: ${booking['package_price']}"),
                          if ((booking['package_description'] ?? '')
                              .toString()
                              .isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text("Details: ${booking['package_description']}"),
                          ],
                          if ((booking['event_time'] ?? '')
                              .toString()
                              .isNotEmpty)
                            Text("Event Time: ${booking['event_time']}"),
                          if ((booking['bestViewingTime'] ?? '')
                              .toString()
                              .isNotEmpty)
                            Text(
                              "Best Viewing Time: ${booking['bestViewingTime']}",
                            ),
                          if (status == 'Pending') ...[
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _updateStatus(
                                      booking['id'],
                                      'Rejected',
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.danger,
                                      side: const BorderSide(
                                        color: AppColors.danger,
                                      ),
                                    ),
                                    child: const Text("Reject"),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.secondary,
                                      foregroundColor: AppColors.primary,
                                    ),
                                    onPressed: () => _updateStatus(
                                      booking['id'],
                                      'Approved',
                                    ),
                                    child: const Text("Approve"),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
