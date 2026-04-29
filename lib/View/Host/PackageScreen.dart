import 'package:flutter/material.dart';
import 'package:traavaalay/View/Host/AgroForm.dart';
import 'package:traavaalay/View/Host/AstroForm.dart';
import 'package:traavaalay/View/Host/TourForm.dart';
import 'package:traavaalay/theme/app_colors.dart';

class PackageScreen extends StatefulWidget {
  final Map<String, dynamic>? user;

  const PackageScreen({super.key, this.user});

  @override
  State<PackageScreen> createState() => _PackageScreenState();
}

class _PackageScreenState extends State<PackageScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    _tabController = TabController(length: 3, vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Create Package",
          style: TextStyle(color: AppColors.textPrimary),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Column(
        children: [
          // ✅ TabBar below AppBar
          Material(
            color: AppColors.surface,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.secondary,
              labelColor: AppColors.secondary,
              unselectedLabelColor: AppColors.textMuted,
              tabs: const [
                Tab(text: "Tour"),
                Tab(text: "Agro"),
                Tab(text: "Astro"),
              ],
            ),
          ),
          // ✅ Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                TourForm(user: widget.user ?? const {}),
                AgroForm(user: widget.user ?? const {}),
                AstroForm(user: widget.user ?? const {}),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
