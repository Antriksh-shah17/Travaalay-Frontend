import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:traavaalay/config/api_config.dart';
import 'package:traavaalay/theme/app_colors.dart';
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("TravAI Itinerary Planner")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🌍 CITY INPUT
            TextField(
              controller: cityController,
              decoration: const InputDecoration(
                labelText: "Enter City",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            // 📅 DAYS INPUT
            TextField(
              controller: daysController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Number of Days",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            // 🚀 BUTTON
            ElevatedButton(
              onPressed: loading ? null : generateItinerary,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.primary,
              ),
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Generate Itinerary"),
            ),
          ],
        ),
      ),
    );
  }
}
