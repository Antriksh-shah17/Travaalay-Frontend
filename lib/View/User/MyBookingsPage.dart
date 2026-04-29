import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:traavaalay/config/api_config.dart';

class MyBookingsPage extends StatefulWidget {
  final String userId;

  const MyBookingsPage({super.key, required this.userId});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> {
  bool _isLoading = true;
  List<dynamic> _bookings = [];

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.usersBaseUrl}/${widget.userId}/bookings'),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          _bookings = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching user bookings: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  String _normalizeStatus(dynamic statusValue) {
    final status = (statusValue ?? '').toString().trim().toLowerCase();

    if (status == 'approved' || status == 'confirmed') return 'Approved';
    if (status == 'rejected' || status == 'reject' || status == 'cancelled') {
      return 'Rejected';
    }

    return 'Pending';
  }

  bool _isPastBooking(dynamic bookingDate) {
    final raw = (bookingDate ?? '').toString();
    if (raw.isEmpty) return false;

    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return false;

    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final normalizedBooking = DateTime(parsed.year, parsed.month, parsed.day);
    return normalizedBooking.isBefore(normalizedToday);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Approved':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _formatType(dynamic bookingType) {
    final type = (bookingType ?? '').toString().toLowerCase();
    return type == 'translator' ? 'Translator' : 'Package';
  }

  Widget _buildBookingCard(dynamic booking) {
    final status = _normalizeStatus(booking['status']);
    final bookingDate = (booking['booking_date'] ?? '')
        .toString()
        .split('T')
        .first;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                    (booking['title'] ?? 'Booking').toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    status,
                    style: TextStyle(color: _statusColor(status)),
                  ),
                  backgroundColor: _statusColor(status).withValues(alpha: 0.12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Type: ${_formatType(booking['booking_type'])}'),
            if ((booking['counterpart_name'] ?? '').toString().isNotEmpty)
              Text('With: ${booking['counterpart_name']}'),
            if ((booking['category'] ?? '').toString().isNotEmpty)
              Text('Category: ${booking['category']}'),
            if ((booking['location'] ?? '').toString().isNotEmpty)
              Text('Location: ${booking['location']}'),
            if ((booking['price'] ?? '').toString().isNotEmpty)
              Text('Price: ${booking['price']}'),
            const SizedBox(height: 6),
            Text(
              'Date: ${bookingDate.isEmpty ? 'N/A' : bookingDate}',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final upcomingBookings = _bookings
        .where((booking) => !_isPastBooking(booking['booking_date']))
        .toList();
    final pastBookings = _bookings
        .where((booking) => _isPastBooking(booking['booking_date']))
        .toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Bookings'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Upcoming'),
              Tab(text: 'Past'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildBookingList(
                    upcomingBookings,
                    'No upcoming bookings yet.',
                  ),
                  _buildBookingList(pastBookings, 'No past bookings yet.'),
                ],
              ),
      ),
    );
  }

  Widget _buildBookingList(List<dynamic> bookings, String emptyText) {
    if (bookings.isEmpty) {
      return Center(child: Text(emptyText));
    }

    return RefreshIndicator(
      onRefresh: _fetchBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) => _buildBookingCard(bookings[index]),
      ),
    );
  }
}
