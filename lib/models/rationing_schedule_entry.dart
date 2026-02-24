/// Single entry from rationing_schedule.json.
class RationingScheduleEntry {
  final String zone;
  final String area;
  final List<String> days;

  const RationingScheduleEntry({
    required this.zone,
    required this.area,
    required this.days,
  });

  factory RationingScheduleEntry.fromJson(Map<String, dynamic> json) {
    final daysList = json['days'];
    return RationingScheduleEntry(
      zone: json['zone'] as String,
      area: json['area'] as String,
      days: daysList is List
          ? (daysList).map((e) => e.toString()).toList()
          : <String>[],
    );
  }
}
