import 'package:flutter/material.dart';
import 'package:traavaalay/View/Translator/TranslatorBookingScreen.dart';
import 'package:traavaalay/View/Translator/TranslatorProfile.dart';
import 'package:traavaalay/theme/app_colors.dart';
import 'package:traavaalay/theme/app_tokens.dart';

class TranslatorDashboard extends StatefulWidget {
  final Map<String, dynamic> user;

  const TranslatorDashboard({super.key, required this.user});

  @override
  State<TranslatorDashboard> createState() => _TranslatorDashboardState();
}

class _TranslatorDashboardState extends State<TranslatorDashboard> {
  int _selectedIndex = 0;

  final List<BottomNavigationBarItem> _navItems = const [
    BottomNavigationBarItem(icon: Icon(Icons.book_online), label: "Bookings"),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
  ];

  Widget _buildCurrentScreen() {
    switch (_selectedIndex) {
      case 0:
        return TranslatorBookingsPage(user: widget.user);
      case 1:
        return TranslatorProfilePage(user: widget.user);
      default:
        return TranslatorBookingsPage(user: widget.user);
    }
  }

  @override
  Widget build(BuildContext context) {
    final translatorName = (widget.user['name'] ?? 'Translator').toString();

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
                  "Translator Workspace",
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  "Manage booking requests and keep your profile polished, $translatorName.",
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
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
