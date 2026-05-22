import 'dart:convert';
import 'dart:math' as math;
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
      {"title": "Translator", "icon": Icons.translate_rounded},
      {"title": "Packages", "icon": Icons.luggage_rounded},
      {"title": "TravAI", "icon": Icons.auto_awesome_rounded},
      {"title": "Blog", "icon": Icons.menu_book_rounded},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopHeroSection(context),

              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "Discover",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      "Your travel essentials",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: categories.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.12,
                  ),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return _buildCategoryCard(
                      context,
                      category["title"]! as String,
                      category["icon"]! as IconData,
                      index,
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeroSection(BuildContext context) {
    return SizedBox(
      height: 374,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 6,
            right: 6,
            top: 0,
            child: EventSlider(
              events: const [],
              defaultMedia: const [
                "assets/astro.mp4",
                "assets/agro.mp4",
                "assets/translator.mp4",
                "assets/travai.mp4",
              ],
              onSlideTap: _handleVideoTap,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: _buildHeroHeader(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.16),
            const Color(0xFF1D2330).withValues(alpha: 0.10),
            AppColors.primaryLight.withValues(alpha: 0.1),
          ],
          stops: const [0.0, 0.48, 1.0],
        ),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.04)),
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              "Welcome to Travaalay",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 1.0,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserProfilePage(
                    userId: widget.user['id'].toString(),
                    onProfileUpdated: (updatedUser) {
                      setState(() {
                        widget.user.addAll(updatedUser);
                      });
                    },
                  ),
                ),
              );
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minHeight: 30, minWidth: 30),
            icon: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    String title,
    IconData icon,
    int index,
  ) {
    final accent = _accentForTitle(title);

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
      child: _AnimatedDashboardCard(
        title: title,
        icon: icon,
        accent: accent,
        index: index,
      ),
    );
  }

  Color _accentForTitle(String title) {
    switch (title) {
      case "Translator":
        return const Color(0xFFFF7A8A);
      case "Packages":
        return const Color(0xFFF6C35B);
      case "TravAI":
        return const Color(0xFF6D9BFF);
      case "Blog":
        return const Color(0xFF68E0C2);
      default:
        return AppColors.secondary;
    }
  }

  void _handleVideoTap(Event slide) {
    switch (slide.mediaPath) {
      case "assets/astro.mp4":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                PackagesPage(user: widget.user, initialCategory: 'Astro'),
          ),
        );
        break;
      case "assets/agro.mp4":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                PackagesPage(user: widget.user, initialCategory: 'Agro'),
          ),
        );
        break;
      case "assets/translator.mp4":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TranslatorMatchingPage(user: widget.user),
          ),
        );
        break;
      case "assets/travai.mp4":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TravAIPage()),
        );
        break;
      default:
        break;
    }
  }
}

class _AnimatedDashboardCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color accent;
  final int index;

  const _AnimatedDashboardCard({
    required this.title,
    required this.icon,
    required this.accent,
    required this.index,
  });

  @override
  State<_AnimatedDashboardCard> createState() => _AnimatedDashboardCardState();
}

class _AnimatedDashboardCardState extends State<_AnimatedDashboardCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2500 + (widget.index * 160)),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final wave = math.sin((_controller.value * math.pi * 2) + widget.index);
        final drift = wave * 4;
        final tilt = wave * 0.03;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF2B2F37),
                const Color(0xFF17191F),
                widget.accent.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Positioned(
                  top: -18,
                  right: -10,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          widget.accent.withValues(alpha: 0.34),
                          widget.accent.withValues(alpha: 0.02),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Transform.translate(
                          offset: Offset(0, drift),
                          child: Transform.rotate(
                            angle: tilt,
                            child: Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    widget.accent.withValues(alpha: 0.28),
                                    widget.accent.withValues(alpha: 0.08),
                                  ],
                                ),
                                border: Border.all(
                                  color: widget.accent.withValues(alpha: 0.24),
                                ),
                              ),
                              child: Icon(
                                widget.icon,
                                size: 40,
                                color: widget.accent,
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          width: 22,
                          height: 2.5,
                          decoration: BoxDecoration(
                            color: widget.accent.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
