import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'package:um_collect/components/Utils.dart';

@immutable
class CustomerDbEntry {
  /// Account number from dormant_meters.
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

/// Lazy dormant-meters catalog (zones/routes/accounts on demand — no 14k preload).
class CustomerDbService {
  CustomerDbService._();

  static final CustomerDbService instance = CustomerDbService._();

  final _storage = const FlutterSecureStorage();

  final Map<String, List<String>> _zonesByScheme = {};
  final Map<String, List<String>> _routesBySchemeZone = {};
  final Map<String, List<CustomerDbEntry>> _accountsCache = {};

  Future<Map<String, String>> _authHeaders() async {
    final token = await _storage.read(key: 'mwstaffjwt');
    if (token == null || token.isEmpty) {
      throw Exception('Not authenticated');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<dynamic>> _getJsonList(Uri uri) async {
    if (kDebugMode) debugPrint('[CustomerDbService] GET $uri');
    final response = await http.get(uri, headers: await _authHeaders());
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to load dormant meters (${response.statusCode})',
      );
    }
    final body = json.decode(response.body);
    if (body is Map && body['data'] is List) {
      return body['data'] as List<dynamic>;
    }
    if (body is List) return body;
    return const [];
  }

  Future<List<String>> fetchZones(String scheme) async {
    final key = scheme.trim();
    if (key.isEmpty) return const [];
    final cached = _zonesByScheme[key];
    if (cached != null) return List<String>.from(cached);

    final uri = Uri.parse('${getUrl()}dormant-meters/zones').replace(
      queryParameters: {'scheme': key},
    );
    final list = await _getJsonList(uri);
    final zones = list
        .map((e) => e?.toString().trim() ?? '')
        .where((e) => e.isNotEmpty)
        .toList()
      ..sort();
    _zonesByScheme[key] = zones;
    return List<String>.from(zones);
  }

  Future<List<String>> fetchRoutes(String scheme, String zone) async {
    final s = scheme.trim();
    final z = zone.trim();
    if (s.isEmpty || z.isEmpty) return const [];
    final key = '$s|$z';
    final cached = _routesBySchemeZone[key];
    if (cached != null) return List<String>.from(cached);

    final uri = Uri.parse('${getUrl()}dormant-meters/routes').replace(
      queryParameters: {'scheme': s, 'zone': z},
    );
    final list = await _getJsonList(uri);
    final routes = list
        .map((e) => e?.toString().trim() ?? '')
        .where((e) => e.isNotEmpty)
        .toList()
      ..sort();
    _routesBySchemeZone[key] = routes;
    return List<String>.from(routes);
  }

  Future<List<CustomerDbEntry>> fetchAccounts({
    required String scheme,
    required String zone,
    required String route,
    String query = '',
    int limit = 200,
  }) async {
    final s = scheme.trim();
    final z = zone.trim();
    final r = route.trim();
    if (s.isEmpty || z.isEmpty || r.isEmpty) return const [];

    final q = query.trim();
    final cacheKey = '$s|$z|$r|${q.toLowerCase()}|$limit';
    final cached = _accountsCache[cacheKey];
    if (cached != null) return List<CustomerDbEntry>.from(cached);

    final params = <String, String>{
      'scheme': s,
      'zone': z,
      'route': r,
      'limit': '$limit',
      'offset': '0',
    };
    if (q.isNotEmpty) params['q'] = q;

    final uri = Uri.parse('${getUrl()}dormant-meters').replace(
      queryParameters: params,
    );
    final list = await _getJsonList(uri);
    final accounts = list
        .whereType<Map>()
        .map((e) => CustomerDbEntry.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.accountNumber.isNotEmpty)
        .toList();
    _accountsCache[cacheKey] = accounts;
    return List<CustomerDbEntry>.from(accounts);
  }

  /// Clears caches (e.g. after force refresh).
  void clearCache() {
    _zonesByScheme.clear();
    _routesBySchemeZone.clear();
    _accountsCache.clear();
  }
}
