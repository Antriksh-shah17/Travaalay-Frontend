import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:traavaalay/config/api_config.dart';
import 'package:traavaalay/theme/app_colors.dart';

class TranslatorBookingsPage extends StatefulWidget {
  final Map<String, dynamic> user;

  const TranslatorBookingsPage({super.key, required this.user});

  @override
  State<TranslatorBookingsPage> createState() => _TranslatorBookingsPageState();
}

class _TranslatorBookingsPageState extends State<TranslatorBookingsPage> {
  bool _isLoading = true;
  List<dynamic> _bookings = [];
  final String baseUrl = ApiConfig.translatorsBaseUrl;
  Timer? _refreshTimer;

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
    _fetchBookings();
    _refreshTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (mounted) {
        _fetchBookings(showLoader: false);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchBookings({bool showLoader = true}) async {
    if (showLoader) {
      setState(() => _isLoading = true);
    }
    try {
      final userId = widget.user['id'];
      final response = await http.get(Uri.parse('$baseUrl/$userId/bookings'));

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _bookings = jsonDecode(response.body);
            _isLoading = false;
          });
        }
      } else {
        throw Exception("Failed to load bookings");
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      debugPrint("Error fetching bookings: $e");
    }
  }

  Future<void> _updateStatus(int bookingId, String status) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/bookings/$bookingId/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode == 200) {
        _fetchBookings();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Booking $status successfully'),
              backgroundColor: status == 'Approved'
                  ? AppColors.success
                  : AppColors.danger,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error updating status: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _bookings
        .where((booking) => _normalizeStatus(booking['status']) == 'Pending')
        .length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bookings.isEmpty
          ? const Center(child: Text("No booking requests yet."))
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
                              ? "You have $pendingCount new translator booking request${pendingCount == 1 ? '' : 's'}."
                              : "No new translator booking requests right now.",
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
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 16),
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
                                booking['tourist_name'] ?? 'Unknown Tourist',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Chip(
                                label: Text(
                                  status,
                                  style: TextStyle(
                                    color: _statusForeground(status),
                                  ),
                                ),
                                backgroundColor: _statusBackground(status),
                                side: BorderSide.none,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Date: ${booking['booking_date']?.split('T')[0] ?? 'N/A'}",
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.language,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text("Language: ${booking['language'] ?? 'N/A'}"),
                            ],
                          ),
                          if (status == 'Pending') ...[
                            const Divider(height: 24),
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
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _updateStatus(
                                      booking['id'],
                                      'Approved',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      foregroundColor: Colors.white,
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
