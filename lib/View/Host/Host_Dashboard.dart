import 'package:flutter/material.dart';
import 'package:traavaalay/View/Host/BookingScreen.dart';
import 'package:traavaalay/View/Host/ContentSceen.dart';
import 'package:traavaalay/View/Host/HostProfilePage.dart';
import 'package:traavaalay/View/Host/PackageScreen.dart';
import 'package:traavaalay/theme/app_colors.dart';

class HostDashboard extends StatefulWidget {
  final Map<String, dynamic>? user;

  const HostDashboard({super.key, this.user});

  @override
  _HostDashboardState createState() => _HostDashboardState();
}

class _HostDashboardState extends State<HostDashboard> {
  int _selectedIndex = 0;

  final List<BottomNavigationBarItem> _navItems = const [
    BottomNavigationBarItem(icon: Icon(Icons.card_travel), label: "Packages"),
    BottomNavigationBarItem(icon: Icon(Icons.book_online), label: "Bookings"),
    BottomNavigationBarItem(icon: Icon(Icons.article), label: "Content"),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
  ];

  Widget _buildCurrentScreen() {
    switch (_selectedIndex) {
      case 0:
        return PackageScreen(user: widget.user);
      case 1:
        return BookingScreen(user: widget.user ?? {});
      case 2:
        return const CreateBlogScreen();
      case 3:
        return HostProfilePage(
          user: widget.user ?? {},
          onProfileUpdated: (updatedUser) {
            setState(() {
              widget.user?.addAll(updatedUser);
            });
          },
        );
      default:
        return PackageScreen(user: widget.user);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: KeyedSubtree(
          key: ValueKey(_selectedIndex),
          child: _buildCurrentScreen(),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: _navItems,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}
