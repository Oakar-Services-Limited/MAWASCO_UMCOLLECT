import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'package:um_collect/components/Utils.dart';

@immutable
class CustomerDbEntry {
  /// Account number from dormant_meters (formerly customer_db.csv).
  final String accountNumber;
  final String connectionNumber;
  final String customerName;
  final String meterNo;
  final String scheme;
  final String zone;
  final String route;
  final String routeId;
  final String label;

  const CustomerDbEntry({
    required this.accountNumber,
    required this.connectionNumber,
    required this.customerName,
    required this.meterNo,
    required this.scheme,
    required this.zone,
    required this.route,
    required this.routeId,
    required this.label,
  });

  static CustomerDbEntry fromJson(Map<String, dynamic> json) {
    String s(dynamic v) => v == null ? '' : v.toString().trim();
    return CustomerDbEntry(
      accountNumber: s(json['account_number'] ?? json['accountNumber']),
      connectionNumber:
          s(json['connection_number'] ?? json['connectionNumber']),
      customerName: s(json['customer_name'] ?? json['customerName']),
      meterNo: s(json['meter_no'] ?? json['meterNo']),
      scheme: s(json['scheme'] ?? json['schemeName']),
      zone: s(json['zone']),
      route: s(json['route']),
      routeId: s(json['route_id'] ?? json['routeId']),
      label: s(json['label']),
    );
  }
}

/// Loads dormant survey accounts from GET /dormant-meters and exposes the same
/// scheme/zone/route/account helpers used by the Dormant Survey form.
class CustomerDbService {
  CustomerDbService._();

  static final CustomerDbService instance = CustomerDbService._();

  final _storage = const FlutterSecureStorage();

  List<CustomerDbEntry> _entries = const [];
  bool _loaded = false;

  List<CustomerDbEntry> get entries => _entries;
  bool get isLoaded => _loaded;

  /// Fetch catalog from API (once per app session). Same filtering UX as CSV.
  Future<void> ensureLoaded({bool forceRefresh = false}) async {
    if (_loaded && !forceRefresh) return;

    final token = await _storage.read(key: 'mwstaffjwt');
    if (token == null || token.isEmpty) {
      throw Exception('Not authenticated');
    }

    final uri = Uri.parse(
      '${getUrl()}dormant-meters?limit=20000&offset=0',
    );
    if (kDebugMode) {
      debugPrint('[CustomerDbService] GET $uri');
    }

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to load dormant meters (${response.statusCode})',
      );
    }

    final body = json.decode(response.body);
    List<dynamic> list = [];
    if (body is Map && body['data'] is List) {
      list = body['data'] as List<dynamic>;
    } else if (body is List) {
      list = body;
    }

    _entries = list
        .whereType<Map>()
        .map((e) => CustomerDbEntry.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.accountNumber.isNotEmpty)
        .toList();
    _loaded = true;

    if (kDebugMode) {
      debugPrint('[CustomerDbService] loaded ${_entries.length} accounts');
    }
  }

  List<String> schemes() {
    final set = <String>{};
    for (final e in _entries) {
      if (e.scheme.isNotEmpty) set.add(e.scheme);
    }
    final list = set.toList();
    list.sort();
    return list;
  }

  List<String> zonesForScheme(String scheme) {
    final set = <String>{};
    for (final e in _entries) {
      if (scheme.isNotEmpty && e.scheme != scheme) continue;
      if (e.zone.isNotEmpty) set.add(e.zone);
    }
    final list = set.toList();
    list.sort();
    return list;
  }

  List<String> routesForZone(String scheme, String zone) {
    final set = <String>{};
    for (final e in _entries) {
      if (scheme.isNotEmpty && e.scheme != scheme) continue;
      if (zone.isNotEmpty && e.zone != zone) continue;
      if (e.route.isNotEmpty) set.add(e.route);
    }
    final list = set.toList();
    list.sort();
    return list;
  }

  List<CustomerDbEntry> accounts({
    required String scheme,
    required String zone,
    required String route,
    String query = '',
    int limit = 200,
  }) {
    final q = query.trim().toLowerCase();
    final out = <CustomerDbEntry>[];
    for (final e in _entries) {
      if (scheme.isNotEmpty && e.scheme != scheme) continue;
      if (zone.isNotEmpty && e.zone != zone) continue;
      if (route.isNotEmpty && e.route != route) continue;

      if (q.isNotEmpty) {
        final hay =
            '${e.customerName} ${e.accountNumber} ${e.connectionNumber} ${e.label}'
                .toLowerCase();
        if (!hay.contains(q)) continue;
      }

      out.add(e);
      if (out.length >= limit) break;
    }
    return out;
  }
}
