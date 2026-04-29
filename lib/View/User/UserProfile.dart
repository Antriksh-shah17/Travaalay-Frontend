import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:traavaalay/View/Login.dart';
import 'package:traavaalay/View/User/MyBookingsPage.dart';
import 'package:traavaalay/config/api_config.dart';
import 'package:traavaalay/theme/app_colors.dart';

class UserProfilePage extends StatefulWidget {
  final String userId;

  const UserProfilePage({super.key, required this.userId});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  Map<String, dynamic>? user;
  bool _isLoading = true;
  final String baseUrl = ApiConfig.usersBaseUrl;

  @override
  void initState() {
    super.initState();
    fetchUser();
  }

  Future<void> fetchUser() async {
    try {
      final response = await http
          .get(Uri.parse("$baseUrl/${widget.userId}"))
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          user = data;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching user: $e");
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("My Profile")),
        body: const Center(child: Text("User not found")),
      );
    }

    final profile = user!;
    final name = (profile["name"] ?? "Traveler").toString();
    final email = (profile["email"] ?? "No email added").toString();
    final city = (profile["city"] ?? "Unknown destination").toString();
    final role = _formatRole(profile["role"]);
    final initials = _buildInitials(name);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 300,
            backgroundColor: AppColors.surface,
            foregroundColor: Colors.white,
            title: const Text("My Journey"),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primaryLight,
                      AppColors.accent,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 90,
                      right: -20,
                      child: _buildGlowCircle(
                        size: 160,
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                    ),
                    Positioned(
                      top: 40,
                      left: -30,
                      child: _buildGlowCircle(
                        size: 120,
                        color: Colors.amber.withValues(alpha: 0.12),
                      ),
                    ),
                    Positioned.fill(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  24,
                                  110,
                                  24,
                                  28,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    CircleAvatar(
                                      radius: 42,
                                      backgroundColor: Colors.white,
                                      child: CircleAvatar(
                                        radius: 38,
                                        backgroundColor: AppColors.secondary,
                                        child: Text(
                                          initials,
                                          style: const TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "$role • $city",
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.9,
                                        ),
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 10,
                                      children: [
                                        _buildHeroChip(
                                          Icons.email_outlined,
                                          email,
                                        ),
                                        _buildHeroChip(
                                          Icons.travel_explore_outlined,
                                          "Ready for your next trip",
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          "Traveler Type",
                          role,
                          Icons.luggage_outlined,
                          AppColors.accent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          "Home Base",
                          city,
                          Icons.location_on_outlined,
                          AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _buildSectionCard(
                    title: "Traveler Details",
                    subtitle:
                        "A clean profile card styled for a modern tourism app.",
                    child: Column(
                      children: [
                        _buildInfoRow(Icons.person_outline, "Full Name", name),
                        _buildInfoRow(Icons.email_outlined, "Email", email),
                        _buildInfoRow(
                          Icons.location_city_outlined,
                          "City",
                          city,
                        ),
                        _buildInfoRow(
                          Icons.badge_outlined,
                          "Account Role",
                          role,
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildSectionCard(
                    title: "Travel Mood",
                    subtitle:
                        "A little personality goes a long way on a travel profile.",
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _buildTag("City escapes"),
                        _buildTag("Food trails"),
                        _buildTag("Weekend plans"),
                        _buildTag("Culture lover"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildSectionCard(
                    title: "Quick Actions",
                    subtitle:
                        "Useful actions presented like a travel dashboard, not a plain settings page.",
                    child: Column(
                      children: [
                        _buildActionTile(
                          icon: Icons.edit_outlined,
                          title: "Edit Profile",
                          subtitle: "Update your public traveler details",
                          accent: AppColors.accent,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Edit profile coming soon"),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildActionTile(
                          icon: Icons.book_online_outlined,
                          title: "My Bookings",
                          subtitle: "See your upcoming and past bookings",
                          accent: AppColors.secondary,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    MyBookingsPage(userId: widget.userId),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildActionTile(
                          icon: Icons.logout,
                          title: "Logout",
                          subtitle: "End your session safely",
                          accent: AppColors.danger,
                          onTap: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                              (route) => false,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatRole(dynamic roleValue) {
    final role = (roleValue ?? 'user').toString().trim();
    if (role.isEmpty) return 'Traveler';
    return "${role[0].toUpperCase()}${role.substring(1).toLowerCase()}";
  }

  String _buildInitials(String name) {
    final parts = name
        .split(' ')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return "T";
    if (parts.length == 1) return parts.first[0].toUpperCase();

    return "${parts.first[0]}${parts.last[0]}".toUpperCase();
  }

  Widget _buildGlowCircle({required double size, required Color color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  Widget _buildHeroChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color accent,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Color(0x3D000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(height: 14),
          Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Color(0x38000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.mutedSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: AppColors.secondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.mutedSurface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.secondary,
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
