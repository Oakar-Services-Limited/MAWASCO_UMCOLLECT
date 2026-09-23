import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Zone → routes catalog for Feedback when Active meters do not cover every route.
class ZoneRoutesService {
  ZoneRoutesService._();
  static final ZoneRoutesService _instance = ZoneRoutesService._();
  static ZoneRoutesService get instance => _instance;

  /// Rural Institutions — manual customer entry allowed when not in meters DB.
  static const String ruralInstitutionsZone = '023 82';

  Map<String, List<String>> _byZone = {};
  bool _loaded = false;

  bool get isLoaded => _loaded;

  /// Call from main() when app starts.
  static Future<void> load() async {
    if (_instance._loaded) return;
    try {
      final String jsonString =
          await rootBundle.loadString('assets/config/zone_routes.json');
      final Map<String, dynamic> map =
          json.decode(jsonString) as Map<String, dynamic>;
      final parsed = <String, List<String>>{};
      for (final entry in map.entries) {
        final routes = (entry.value as List<dynamic>)
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();
        parsed[entry.key] = routes;
      }
      _instance._byZone = parsed;
      _instance._loaded = true;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('ZoneRoutesService.load failed: $e');
        debugPrint('$st');
      }
      _instance._byZone = {};
      _instance._loaded = true;
    }
  }

  List<String> routesForZone(String zone) {
    if (zone.isEmpty) return [];
    return List<String>.from(_byZone[zone] ?? const []);
  }

  bool hasConfiguredRoutes(String zone) =>
      (_byZone[zone]?.isNotEmpty ?? false);

  /// Merge config + API routes. Case-insensitive; prefer [preferred] casing (API).
  static List<String> mergeRoutes(
    List<String> configRoutes,
    List<String> preferred,
  ) {
    final byLower = <String, String>{};
    for (final r in configRoutes) {
      final t = r.trim();
      if (t.isEmpty) continue;
      byLower[t.toLowerCase()] = t;
    }
    for (final r in preferred) {
      final t = r.trim();
      if (t.isEmpty) continue;
      byLower[t.toLowerCase()] = t;
    }
    return byLower.values.toList()..sort();
  }
}
