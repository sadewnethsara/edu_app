class LiveEvent {
  final String title;
  final String description;
  final String link;
  final DateTime startTime;
  final DateTime? linkEnableTime;
  final bool isLive;

  LiveEvent({
    required this.title,
    required this.description,
    required this.link,
    required this.startTime,
    this.linkEnableTime,
    this.isLive = false,
  });
}
