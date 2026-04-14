import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

@immutable
class CustomerDbEntry {
  /// This is the **account number** in our `customer_db.csv`.
  ///
  /// Historically the CSV header used `name` for this value, so we support both
  /// `account_number` and `name` when parsing.
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

  static CustomerDbEntry fromCsvRow(Map<String, String> row) {
    return CustomerDbEntry(
      accountNumber: (row['account_number'] ?? '').trim(),
      connectionNumber: (row['connection_number'] ?? '').trim(),
      customerName: (row['customer_name'] ?? '').trim(),
      meterNo: (row['meter_no'] ?? '').trim(),
      scheme: (row['scheme'] ?? '').trim(),
      zone: (row['zone'] ?? '').trim(),
      route: (row['route'] ?? '').trim(),
      routeId: (row['route_id'] ?? '').trim(),
      label: (row['label'] ?? '').trim(),
    );
  }
}

/// Loads `customer_db.csv` shipped with the app and exposes helpers for
/// scheme/zone/route/account filtering similar to Customer Supply Feedback.
class CustomerDbService {
  CustomerDbService._();

  static final CustomerDbService instance = CustomerDbService._();

  List<CustomerDbEntry> _entries = const [];
  bool _loaded = false;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final raw = await rootBundle.loadString('assets/customer_db.csv');
    _entries = _parseCsv(raw);
    _loaded = true;
  }

  List<CustomerDbEntry> get entries => _entries;

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

  // Minimal CSV parser (comma-separated, no quoted commas expected for this dataset).
  static List<CustomerDbEntry> _parseCsv(String raw) {
    final lines = const LineSplitter().convert(raw);
    if (lines.isEmpty) return const [];

    final header = lines.first.split(',').map((s) => s.trim()).toList();
    final out = <CustomerDbEntry>[];

    for (var i = 1; i < lines.length; i++) {
      final line = lines[i];
      if (line.trim().isEmpty) continue;
      final parts = line.split(',');
      if (parts.length < header.length) continue;

      final row = <String, String>{};
      for (var c = 0; c < header.length; c++) {
        row[header[c]] = c < parts.length ? parts[c] : '';
      }
      out.add(CustomerDbEntry.fromCsvRow(row));
    }
    return out;
  }
}
