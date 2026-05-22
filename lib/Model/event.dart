import 'package:traavaalay/config/api_config.dart';

class Event {
  final String title;
  final String description;
  final DateTime date;
  final String mediaPath;

  Event({
    required this.title,
    required this.description,
    required this.date,
    required this.mediaPath,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      title: json['title'],
      description: json['description'],
      date: DateTime.parse(json['event_date']),
      mediaPath: "${ApiConfig.rootUrl}/uploads/${json['mediaPath']}",
    );
  }
}
