import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:um_collect/models/rationing_schedule_entry.dart';

/// Holds rationing schedule loaded at app start. All filtering is done locally.
class RationingScheduleService {
  RationingScheduleService._();
  static final RationingScheduleService _instance =
      RationingScheduleService._();
  static RationingScheduleService get instance => _instance;

  List<RationingScheduleEntry> _entries = [];
  bool _loaded = false;

  List<RationingScheduleEntry> get entries => List.unmodifiable(_entries);
  bool get isLoaded => _loaded;

  /// Call from main() when app starts.
  static Future<void> load() async {
    if (_instance._loaded) return;
    try {
      final String jsonString =
          await rootBundle.loadString('assets/config/rationing_schedule.json');
      final List<dynamic> list = json.decode(jsonString) as List<dynamic>;
      _instance._entries = list
          .map(
              (e) => RationingScheduleEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      _instance._loaded = true;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('RationingScheduleService.load failed: $e');
        debugPrint('$st');
      }
      _instance._entries = [];
      _instance._loaded = true;
    }
  }

  /// Zones that have the given day in their schedule (local filter).
  List<String> zonesForDay(String day) {
    if (day.isEmpty) return [];
    final set = <String>{};
    for (final e in _entries) {
      if (e.days.any((d) => d.toLowerCase() == day.toLowerCase())) {
        set.add(e.zone);
      }
    }
    return set.toList()..sort();
  }

  /// Areas for the given zone and day (local filter).
  List<String> areasForZoneAndDay(String zone, String day) {
    if (zone.isEmpty || day.isEmpty) return [];
    final set = <String>{};
    for (final e in _entries) {
      if (e.zone == zone &&
          e.days.any((d) => d.toLowerCase() == day.toLowerCase())) {
        set.add(e.area);
      }
    }
    return set.toList()..sort();
  }
}
