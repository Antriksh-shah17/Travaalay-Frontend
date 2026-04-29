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
      mediaPath:
          "https://wnn3xmpd-5000.inc1.devtunnels.ms/uploads/${json['mediaPath']}",
    );
  }
}