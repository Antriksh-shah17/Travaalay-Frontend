import 'package:flutter/material.dart';
import 'package:traavaalay/View/Host/BookingScreen.dart';
import 'package:traavaalay/View/Host/ContentSceen.dart';
import 'package:traavaalay/View/Host/HostProfilePage.dart';
import 'package:traavaalay/View/Host/PackageScreen.dart';
import 'package:traavaalay/theme/app_colors.dart';
import 'package:traavaalay/theme/app_tokens.dart';

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
        return HostProfilePage(user: widget.user ?? {});
      default:
        return PackageScreen(user: widget.user);
    }
  }

  @override
  Widget build(BuildContext context) {
    String username = widget.user?['name'] ?? 'Host';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xl + 18,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryLight],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Host Studio",
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  "Create experiences, review bookings, and grow your presence, $username.",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.86),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: KeyedSubtree(
                key: ValueKey(_selectedIndex),
                child: _buildCurrentScreen(),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: _navItems,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}
