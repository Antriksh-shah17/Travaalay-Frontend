import 'package:flutter/material.dart';
import 'package:traavaalay/View/Admin/AdminBookingPage.dart';
import 'package:traavaalay/View/Admin/AdminUsersPage.dart';
import 'package:traavaalay/View/Login.dart';
import 'package:traavaalay/View/Admin/AdminVerificationScreen.dart';

class AdminDashboard extends StatefulWidget {
  final Map<String, dynamic> user; // <-- define user field

  const AdminDashboard({super.key, required this.user}); // <-- store user

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = const [
      AdminUsersPage(),
      AdminBookingsPage(),
      AdminVerificationScreen()
    ];
  }

  final List<BottomNavigationBarItem> _navItems = const [
    BottomNavigationBarItem(icon: Icon(Icons.people), label: "Users"),
    BottomNavigationBarItem(icon: Icon(Icons.book_online), label: "Bookings"),
    BottomNavigationBarItem(icon: Icon(Icons.verified), label: "Verifications")
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Admin Dashboard - ${widget.user['name']}"), // <-- use widget.user
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Logout and navigate to LoginScreen
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false, // remove all previous routes
              );
            },
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: _navItems,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}
