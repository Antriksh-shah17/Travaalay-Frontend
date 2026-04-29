import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:traavaalay/theme/app_colors.dart';

class ItineraryPage extends StatelessWidget {
  final Map itinerary;

  const ItineraryPage({super.key, required this.itinerary});

  @override
  Widget build(BuildContext context) {
    final days = (itinerary['days'] as List? ?? const []);
    final summary = itinerary['destination_summary'] as Map?;
    final generalMustCarry = _stringList(summary?['general_must_carry']);

    return Scaffold(
      appBar: AppBar(title: const Text("Your Trip ✈️")),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: days.length + (summary != null ? 1 : 0),
        itemBuilder: (context, index) {
          if (summary != null && index == 0) {
            return _buildSummaryCard(summary, generalMustCarry);
          }

          final dayIndex = summary != null ? index - 1 : index;
          final day = days[dayIndex] as Map;
          final dayMustCarry = _stringList(day['must_carry']);
          final places = (day['places'] as List? ?? const []);
          final foodItems = (day['food'] as List? ?? const []);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              Text(
                "Day ${day['day']}",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if ((day['theme'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  day['theme'].toString(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],

              const SizedBox(height: 10),

              // 📍 PLACES
              const Text(
                "📍 Places",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              ...places.map<Widget>((place) {
                final placeMap = place as Map;
                final placeMustCarry = _stringList(placeMap['must_carry']);
                return GestureDetector(
                  onTap: () => _openGooglePage(placeMap['name'].toString()),
                  child: Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: AppColors.accent,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  placeMap['name'].toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.open_in_new,
                                size: 18,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(placeMap['description']?.toString() ?? ''),
                          if ((placeMap['best_time_to_visit'] ?? '')
                              .toString()
                              .isNotEmpty) ...[
                            const SizedBox(height: 10),
                            _buildInfoRow(
                              Icons.schedule,
                              "Best time to visit: ${placeMap['best_time_to_visit']}",
                            ),
                          ],
                          if (placeMustCarry.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            const Text(
                              "Must carry",
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: placeMustCarry
                                  .map((item) => _buildChip(item))
                                  .toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),

              const SizedBox(height: 10),

              // 🍽️ FOOD
              const Text(
                "🍽️ Food",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              ...foodItems.map<Widget>((food) {
                final foodMap = food as Map;
                return GestureDetector(
                  onTap: () => _openGooglePage(foodMap['name'].toString()),
                  child: Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 2,
                    child: ListTile(
                      leading: const Icon(
                        Icons.restaurant,
                        color: Colors.orange,
                      ),
                      title: Text(
                        foodMap['name'].toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(foodMap['cuisine']?.toString() ?? ''),
                          const SizedBox(height: 4),
                          Text(
                            foodMap['description']?.toString() ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      trailing: const Icon(
                        Icons.open_in_new,
                        size: 18,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                );
              }).toList(),

              if (dayMustCarry.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text(
                  "🎒 Must Carry For The Day",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: dayMustCarry
                      .map((item) => _buildChip(item))
                      .toList(),
                ),
                const SizedBox(height: 10),
              ],

              const SizedBox(height: 10),

              // 💡 TIPS
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1C2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE3B341)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb, color: Color(0xFF9A6700)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        day['tips']?.toString() ?? '',
                        style: const TextStyle(
                          color: Color(0xFF5C3B00),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(Map summary, List<String> generalMustCarry) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              summary['city']?.toString() ?? 'Destination',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            if ((summary['vibe'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(summary['vibe'].toString()),
            ],
            if ((summary['best_for'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildInfoRow(
                Icons.travel_explore,
                summary['best_for'].toString(),
              ),
            ],
            if (generalMustCarry.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text(
                "🎒 General Must Carry",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: generalMustCarry
                    .map((item) => _buildChip(item))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.secondary),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }

  List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .where((item) => item != null && item.toString().trim().isNotEmpty)
        .map((item) => item.toString())
        .toList();
  }

  Future<void> _openGooglePage(String placeName) async {
    final uri = Uri.parse(
      "https://www.google.com/search?q=${Uri.encodeComponent(placeName)}",
    );

    try {
      if (await supportsLaunchMode(LaunchMode.inAppBrowserView)) {
        await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
        return;
      }

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint("Failed to open Google page for $placeName: $e");
    }
  }
}
