import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:traavaalay/config/api_config.dart';
import 'package:traavaalay/theme/app_colors.dart';

class BlogScreen extends StatefulWidget {
  const BlogScreen({super.key});

  @override
  State<BlogScreen> createState() => _BlogScreenState();
}

class _BlogScreenState extends State<BlogScreen> {
  List<Map<String, dynamic>> blogs = [];
  bool _isLoading = true;

  final String baseUrl = ApiConfig.blogsBaseUrl;

  @override
  void initState() {
    super.initState();
    fetchBlogs();
  }

  Future<void> fetchBlogs() async {
    try {
      final response = await http
          .get(Uri.parse(baseUrl))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        if (!mounted) return;

        setState(() {
          blogs = data.map((b) {
            final img = _resolveBlogImage(b['image']);
            return {
              "id": b['id'],
              "title": b['title'],
              "description": b['description'],
              "date": b['blog_date'] ?? b['date'] ?? "",
              "image": img,
            };
          }).toList();
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching blogs: $e");
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  String _resolveBlogImage(dynamic imageValue) {
    final imagePath = (imageValue ?? '').toString().trim();

    if (imagePath.isEmpty) {
      return '';
    }

    if (imagePath.startsWith('http') || imagePath.startsWith('data:image')) {
      return imagePath;
    }

    if (imagePath.startsWith('/uploads/')) {
      return "${ApiConfig.rootUrl}$imagePath";
    }

    return "${ApiConfig.rootUrl}/uploads/$imagePath";
  }

  String _formatDate(dynamic rawDate) {
    final value = (rawDate ?? '').toString().trim();
    if (value.isEmpty) return '';

    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;

    final day = parsed.day.toString().padLeft(2, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    final year = (parsed.year % 100).toString().padLeft(2, '0');
    return '$day $month $year';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Blogs"),
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: blogs.length,
        itemBuilder: (context, index) {
          final post = blogs[index];
          final preview = post["description"]!.length > 100
              ? post["description"]!.substring(0, 100) + "..."
              : post["description"];

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post["image"] != null)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: Image.network(
                      post["image"]!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 180,
                        color: AppColors.mutedSurface,
                        child: const Center(
                          child: Icon(Icons.image_not_supported),
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post["title"]!,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(preview!),
                      const SizedBox(height: 8),
                      Text(
                        _formatDate(post["date"]),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.secondary,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FullBlogScreen(post: post),
                              ),
                            );
                          },
                          child: const Text(
                            "Read More",
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class FullBlogScreen extends StatelessWidget {
  final Map<String, dynamic> post;
  const FullBlogScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final paragraphs = post["description"]!.split(". ");

    return Scaffold(
      appBar: AppBar(title: Text(post["title"]!)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post["image"] != null)
              Image.network(
                post["image"]!,
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 250,
                  color: AppColors.mutedSurface,
                  child: const Center(child: Icon(Icons.image_not_supported)),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: paragraphs.map<Widget>((p) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      p.trim() + ".",
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
