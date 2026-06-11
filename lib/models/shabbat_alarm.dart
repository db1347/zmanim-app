/// One preset Shabbat alarm: time-of-day plus ring duration.
class ShabbatAlarm {
  final int hour;
  final int minute;
  final int ringMinutes;

  const ShabbatAlarm({
    required this.hour,
    required this.minute,
    this.ringMinutes = 2,
  });

  Map<String, dynamic> toJson() =>
      {'hour': hour, 'minute': minute, 'ringMinutes': ringMinutes};

  factory ShabbatAlarm.fromJson(Map<String, dynamic> json) => ShabbatAlarm(
        hour: json['hour'] as int? ?? 8,
        minute: json['minute'] as int? ?? 0,
        ringMinutes: json['ringMinutes'] as int? ?? 2,
      );

  /// 24-hour label (Hebrew locale convention).
  String get label =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
