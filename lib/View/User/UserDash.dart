// lib/View/User/UserDash.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:traavaalay/Model/event.dart';
import 'package:traavaalay/config/api_config.dart';
import 'package:traavaalay/theme/app_colors.dart';
import 'package:traavaalay/theme/app_tokens.dart';

import 'package:traavaalay/View/User/Blog.dart';
import 'package:traavaalay/View/User/Packages.dart';
import 'package:traavaalay/View/User/TranslatorMatching.dart';
import 'package:traavaalay/View/User/UserProfile.dart';
import 'package:traavaalay/View/User/TravAIPage.dart';
import '../../event_slider.dart';

class HomePage extends StatefulWidget {
  final Map<String, dynamic> user;

  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Event> upcomingEvents = [];
  bool loading = true;

  // ✅ LOCAL BACKEND (IMPORTANT)
  final String baseUrl = ApiConfig.apiBaseUrl;
  //

  @override
  void initState() {
    super.initState();
    fetchEvents();
  }

  Future<void> fetchEvents() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/events"));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);

        setState(() {
          upcomingEvents = data.map((json) => Event.fromJson(json)).toList();
          loading = false;
        });
      } else {
        setState(() => loading = false);
      }
    } catch (e) {
      setState(() => loading = false);
      debugPrint("Error fetching events: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = [
      {
        "title": "Translator",
        "image": "assets/Language Translation Animation.gif",
        "icon": Icons.translate_rounded,
      },
      {
        "title": "Packages",
        "image": "assets/Travel the world.gif",
        "icon": Icons.luggage_rounded,
      },
      {
        "title": "TravAI",
        "image": "https://images.unsplash.com/photo-1498050108023-c5249f4df085",
        "icon": Icons.auto_awesome_rounded,
      },
      {
        "title": "Blog",
        "image": "https://images.unsplash.com/photo-1486312338219-ce68d2c6f44d",
        "icon": Icons.menu_book_rounded,
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroHeader(context),

            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
                0,
              ),
              child: Text(
                "Our Motive",
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            EventSlider(
              events: const [],
              defaultMedia: const [
                "assets/astro.mp4",
                "assets/agro.mp4",
                "assets/translator.mp4",
              ],
            ),

            const SizedBox(height: AppSpacing.xl),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Discover",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    "Built for your next trip",
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: categories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.95,
                ),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return _buildCategoryCard(
                    context,
                    category["title"]! as String,
                    category["image"]! as String,
                    category["icon"]! as IconData,
                  );
                },
              ),
            ),

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    final username = (widget.user['name'] ?? 'Traveler').toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl + 18,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hi, $username",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    // const SizedBox(height: AppSpacing.xs),
                    // Text(
                    //   "Curated trips, local stories, and smarter planning in one place.",
                    //   style: TextStyle(
                    //     color: Colors.white.withValues(alpha: 0.88),
                    //     fontSize: 14,
                    //     height: 1.45,
                    //   ),
                    // ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Material(
                color: Colors.white.withValues(alpha: 0.14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserProfilePage(
                          userId: widget.user['id'].toString(),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.person_rounded, color: Colors.white),
                ),
              ),
            ],
          ),
          // const SizedBox(height: AppSpacing.lg),
          // Container(
          //   padding: const EdgeInsets.all(AppSpacing.md),
          //   decoration: BoxDecoration(
          //     color: Colors.white.withValues(alpha: 0.12),
          //     borderRadius: BorderRadius.circular(20),
          //     border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          //   ),
          //   child: const Row(
          //     children: [
          //       Icon(Icons.explore_rounded, color: Colors.white),
          //       SizedBox(width: AppSpacing.sm),
          //       Expanded(
          //         child: Text(
          //           "Search translators, book curated experiences, and track your travel plans.",
          //           style: TextStyle(
          //             color: Colors.white,
          //             fontSize: 13.5,
          //             height: 1.4,
          //           ),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    String title,
    String imageUrl,
    IconData icon,
  ) {
    return GestureDetector(
      onTap: () {
        switch (title) {
          case "Translator":
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TranslatorMatchingPage(user: widget.user),
              ),
            );
            break;

          case "Packages":
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PackagesPage(user: widget.user),
              ),
            );
            break;

          case "TravAI":
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TravAIPage()),
            );
            break;

          case "Blog":
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BlogScreen()),
            );
            break;

          default:
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Page for $title not implemented")),
            );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 18,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 108,
                width: double.infinity,
                child: imageUrl.startsWith('assets/')
                    ? Image.asset(imageUrl, fit: BoxFit.cover)
                    : Image.network(imageUrl, fit: BoxFit.cover),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
