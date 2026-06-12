enum HebrewEventType { yahrzeit, birthday, anniversary, other }

extension HebrewEventTypeLabel on HebrewEventType {
  String get label => switch (this) {
        HebrewEventType.yahrzeit => 'יארצייט',
        HebrewEventType.birthday => 'יום הולדת עברי',
        HebrewEventType.anniversary => 'יום נישואין',
        HebrewEventType.other => 'תאריך עברי',
      };

  String get emoji => switch (this) {
        HebrewEventType.yahrzeit => '🕯️',
        HebrewEventType.birthday => '🎂',
        HebrewEventType.anniversary => '💍',
        HebrewEventType.other => '📅',
      };
}

/// A recurring Hebrew-calendar date (yahrzeit, Hebrew birthday, etc.).
/// Stored by Jewish month/day; the next Gregorian occurrence is computed.
class HebrewEvent {
  final String id;
  final String name;
  final HebrewEventType type;

  /// kosher_dart month constant (NISSAN=1 … ADAR=12, ADAR_II=13).
  final int jewishMonth;
  final int jewishDay;

  const HebrewEvent({
    required this.id,
    required this.name,
    required this.type,
    required this.jewishMonth,
    required this.jewishDay,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'jewishMonth': jewishMonth,
        'jewishDay': jewishDay,
      };

  factory HebrewEvent.fromJson(Map<String, dynamic> json) => HebrewEvent(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        type: HebrewEventType.values.asNameMap()[json['type']] ??
            HebrewEventType.other,
        jewishMonth: json['jewishMonth'] as int? ?? 1,
        jewishDay: json['jewishDay'] as int? ?? 1,
      );
}
