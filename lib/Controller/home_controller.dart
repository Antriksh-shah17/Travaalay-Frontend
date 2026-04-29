
import 'package:traavaalay/Model/event.dart';

class HomeController {
  // Sample upcoming events
  List<Event> getUpcomingEvents() {
    // You can fetch from API or database
    return [
      Event(
        title: "Lunar Eclipse",
        description: "Enjoy the sun and sand",
        date: DateTime.now().add(const Duration(days: 2)),
        mediaPath: "assets/lunar.jpeg",
      ),
      Event(
        title: "Stargazing",
        description: "Adventure awaits",
        date: DateTime.now().add(const Duration(days: 5)),
        mediaPath: "assets/astro.jpeg",
      ),
    ];
  }

  // Default images if no events
  final List<String> defaultMedia = [
    "assets/download.jpeg",
    "assets/download.jpeg",
  ];
}
