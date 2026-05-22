import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:traavaalay/config/api_config.dart';
import 'package:traavaalay/theme/app_colors.dart';
import 'package:traavaalay/theme/app_tokens.dart';
import 'ItineraryPage.dart';

class TravAIPage extends StatefulWidget {
  const TravAIPage({super.key});

  @override
  State<TravAIPage> createState() => _TravAIPageState();
}

class _TravAIPageState extends State<TravAIPage> {
  final TextEditingController cityController = TextEditingController();
  final TextEditingController daysController = TextEditingController();

  bool loading = false;

  // ✅ Using HTTPS for DevTunnels
  final String baseUrl = ApiConfig.apiBaseUrl;

  // 🔥 FALLBACK (ONLY USED IF API FAILS)
  final Map fallbackItinerary = {
    "destination_summary": {
      "city": "Pune",
      "vibe": "Pleasant city mix of history, food, and urban culture",
      "best_for": "Short heritage trips and casual food exploration",
      "general_must_carry": [
        "Water bottle",
        "Comfortable walking shoes",
        "Light cotton clothes",
      ],
    },
    "days": [
      {
        "day": 1,
        "theme": "Heritage and local food",
        "places": [
          {
            "name": "Shaniwar Wada",
            "description": "Historic fort of Pune",
            "best_time_to_visit": "Morning or late afternoon",
            "must_carry": ["Cap", "Water bottle"],
          },
          {
            "name": "Aga Khan Palace",
            "description": "Beautiful palace",
            "best_time_to_visit": "Morning",
            "must_carry": ["Comfortable footwear", "Phone/camera"],
          },
        ],
        "food": [
          {
            "name": "Vaishali",
            "cuisine": "South Indian",
            "description": "Famous dosa",
          },
        ],
        "tips": "Start early",
        "must_carry": ["Sunscreen", "Power bank", "Cash for small shops"],
      },
    ],
  };

  Future<void> generateItinerary() async {
    if (cityController.text.isEmpty || daysController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enter city & days")));
      return;
    }

    setState(() => loading = true);

    try {
      final url = Uri.parse("$baseUrl/travai");

      print("� Calling TravAI API: $url");
      print(
        "🔵 Request: city=${cityController.text}, days=${daysController.text}",
      );

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              "city": cityController.text.trim(),
              "days": int.parse(daysController.text.trim()),
            }),
          )
          .timeout(const Duration(seconds: 30));

      print("🟢 Response Status: ${response.statusCode}");
      print("🟢 Response Body: ${response.body}");

      setState(() => loading = false);

      // ✅ SUCCESS CASE (200)
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // 🔥 STRICT VALIDATION
        if (data == null ||
            data['itinerary'] == null ||
            data['itinerary']['days'] == null ||
            data['itinerary']['days'].isEmpty) {
          print("❌ Invalid itinerary structure from API");
          _showErrorSnackBar(
            "Invalid Response",
            "API returned invalid data structure",
            null,
          );
          return;
        }

        print("✅ Itinerary generated successfully");

        // 🖼️ Check for images in response
        int placesWithImages = 0;
        int placesWithoutImages = 0;

        for (var day in data['itinerary']['days']) {
          for (var place in day['places']) {
            if (place['image_url'] != null &&
                place['image_url'].toString().startsWith('http')) {
              placesWithImages++;
            } else {
              placesWithoutImages++;
            }
          }
        }

        print(
          "📊 Images: $placesWithImages with URLs, $placesWithoutImages without",
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ItineraryPage(itinerary: data['itinerary']),
          ),
        );
      }
      // 🔴 429 - RATE LIMIT ERROR
      else if (response.statusCode == 429) {
        print("⚠️ Rate limit hit (429)");
        final errorData = jsonDecode(response.body);
        final retryAfter = errorData['retryAfter'] ?? 60;

        _showErrorSnackBar(
          "Rate Limited",
          "Too many requests. Try again in ${retryAfter}s",
          response.statusCode,
        );
      }
      // 🔴 503 - SERVICE UNAVAILABLE ERROR
      else if (response.statusCode == 503) {
        print("❌ Gemini service unavailable (503)");
        final errorData = jsonDecode(response.body);
        final retryAfter = errorData['retryAfter'] ?? 300;

        _showErrorSnackBar(
          "Service Unavailable",
          "AI service temporarily down. Try again in ${_formatSeconds(retryAfter)}",
          response.statusCode,
        );
      }
      // 🔴 500 - INTERNAL SERVER ERROR
      else if (response.statusCode == 500) {
        print("❌ Server error (500)");
        final errorData = jsonDecode(response.body);
        final error = errorData['error'] ?? 'Internal server error';

        _showErrorSnackBar("Server Error", error, response.statusCode);
      }
      // 🔴 400 - BAD REQUEST
      else if (response.statusCode == 400) {
        print("❌ Bad request (400)");
        final errorData = jsonDecode(response.body);
        final error = errorData['error'] ?? 'Invalid request';

        _showErrorSnackBar("Invalid Request", error, response.statusCode);
      }
      // 🔴 OTHER ERRORS
      else {
        print("❌ Unexpected status code: ${response.statusCode}");
        final errorData = jsonDecode(response.body);
        final error = errorData['error'] ?? 'Unexpected error';

        _showErrorSnackBar(
          "Error ${response.statusCode}",
          error,
          response.statusCode,
        );
      }
    } catch (e) {
      setState(() => loading = false);

      print("🔴 Exception Type: ${e.runtimeType}");
      print("🔴 Exception: $e");

      // Handle network/timeout errors
      if (e is http.ClientException) {
        _showErrorSnackBar(
          "Network Error",
          "Failed to connect to server. Check your internet.",
          null,
        );
      } else if (e.toString().contains("TimeoutException")) {
        _showErrorSnackBar(
          "Request Timeout",
          "API took too long to respond. Please try again.",
          null,
        );
      } else {
        _showErrorSnackBar("Error", "Failed to generate itinerary: $e", null);
      }
    }
  }

  // ✅ Helper function to display errors with fallback option
  void _showErrorSnackBar(String title, String message, int? statusCode) {
    print("📢 Showing error: $title - $message (Status: $statusCode)");

    final snackBar = SnackBar(
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(message, style: const TextStyle(fontSize: 12)),
        ],
      ),
      duration: const Duration(seconds: 6),
      backgroundColor: AppColors.danger,
      action: SnackBarAction(
        label: "Use Fallback",
        textColor: AppColors.textPrimary,
        onPressed: () {
          print("📌 Using fallback itinerary after error");
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ItineraryPage(itinerary: fallbackItinerary),
            ),
          );
        },
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  // ✅ Helper function to format seconds to readable format
  String _formatSeconds(int seconds) {
    if (seconds < 60) return "${seconds}s";
    if (seconds < 3600) return "${(seconds / 60).toStringAsFixed(0)}m";
    return "${(seconds / 3600).toStringAsFixed(1)}h";
  }

  @override
  void dispose() {
    cityController.dispose();
    daysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("TravAI")),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF11141A), AppColors.background],
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroCard(context),
                const SizedBox(height: 18),
                _buildPlannerCard(),
                const SizedBox(height: 18),
                _buildTipsCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryLight, Color(0xFF233A40), AppColors.surface],
        ),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.14),
            blurRadius: 26,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, size: 16, color: AppColors.secondary),
                SizedBox(width: 8),
                Text(
                  "AI itinerary companion",
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            "Plan a sharper trip in seconds",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              height: 1.15,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Tell TravAI where you're going and how long you're staying. It will shape a day-by-day route with places, food stops, and practical carry tips.",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _MiniHighlight(label: "Places to visit", icon: Icons.place_outlined),
              _MiniHighlight(label: "Food picks", icon: Icons.restaurant_outlined),
              _MiniHighlight(label: "Carry tips", icon: Icons.backpack_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlannerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Trip Brief",
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Use a city name and a realistic trip length for better recommendations.",
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: cityController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: "Destination city",
              hintText: "Jaipur, Coorg, Varanasi...",
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: daysController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              if (!loading) generateItinerary();
            },
            decoration: const InputDecoration(
              labelText: "Trip duration",
              hintText: "2, 4, 7...",
              prefixIcon: Icon(Icons.calendar_today_outlined),
              suffixText: "days",
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickFillChip("Goa", "3"),
              _buildQuickFillChip("Mysuru", "2"),
              _buildQuickFillChip("Manali", "5"),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: loading ? null : generateItinerary,
              icon: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.explore_outlined),
              label: Text(loading ? "Crafting your route..." : "Generate Itinerary"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 54),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              Icon(Icons.tips_and_updates_outlined, color: AppColors.secondary),
              SizedBox(width: 10),
              Text(
                "How to get better plans",
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          _TipLine("Choose the city you actually want to stay in."),
          _TipLine("Keep day count close to your real travel window."),
          _TipLine("Use the fallback option if the AI service is busy."),
        ],
      ),
    );
  }

  Widget _buildQuickFillChip(String city, String days) {
    return ActionChip(
      label: Text("$city • $days days"),
      avatar: const Icon(Icons.bolt, size: 16),
      onPressed: () {
        cityController.text = city;
        daysController.text = days;
      },
    );
  }
}

class _MiniHighlight extends StatelessWidget {
  final String label;
  final IconData icon;

  const _MiniHighlight({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.secondary),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TipLine extends StatelessWidget {
  final String text;

  const _TipLine(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: const BoxDecoration(
              color: AppColors.secondary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textMuted,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
