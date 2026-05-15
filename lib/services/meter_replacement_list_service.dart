import 'package:flutter/services.dart';
import 'package:um_collect/models/meter_replacement_entry.dart';

/// Loads the scheduled meter replacement exercise list from bundled CSV.
class MeterReplacementListService {
  MeterReplacementListService._();

  static final MeterReplacementListService instance =
      MeterReplacementListService._();

  List<MeterReplacementEntry> _entries = const [];
  List<String> _routes = const [];
  bool _loaded = false;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    const assetPath = 'assets/Meters Replacement Exercise.csv';
    final raw = await rootBundle.loadString(assetPath);
    _entries = _parseCsv(raw);
    final routeSet = <String>{};
    for (final e in _entries) {
      if (e.route.isNotEmpty) routeSet.add(e.route);
    }
    _routes = routeSet.toList()..sort();
    _loaded = true;
  }

  List<MeterReplacementEntry> get entries => _entries;

  List<String> get routes => _routes;

  MeterReplacementEntry? findByAccountNumber(String accountNumber) {
    final q = accountNumber.trim();
    if (q.isEmpty) return null;
    final normalized = q.replaceFirst(RegExp(r'^0+'), '');
    for (final e in _entries) {
      if (e.accountNumber == q) return e;
      final entryNorm = e.accountNumber.replaceFirst(RegExp(r'^0+'), '');
      if (entryNorm.isNotEmpty && entryNorm == normalized) return e;
    }
    return null;
  }

  List<MeterReplacementEntry> searchAccounts(String query, {int limit = 50}) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final out = <MeterReplacementEntry>[];
    for (final e in _entries) {
      final hay =
          '${e.accountNumber} ${e.customerName} ${e.meterNumber}'.toLowerCase();
      if (!hay.contains(q)) continue;
      out.add(e);
      if (out.length >= limit) break;
    }
    return out;
  }

  List<MeterReplacementEntry> _parseCsv(String raw) {
    final lines = raw.split(RegExp(r'\r?\n'));
    if (lines.isEmpty) return const [];

    final header = _splitCsvLine(lines.first);
    final out = <MeterReplacementEntry>[];
    for (var i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      final cols = _splitCsvLine(line);
      if (cols.isEmpty) continue;
      final row = <String, String>{};
      for (var c = 0; c < header.length && c < cols.length; c++) {
        row[header[c].trim()] = cols[c].trim();
      }
      out.add(MeterReplacementEntry.fromCsvRow(row));
    }
    return out;
  }

  List<String> _splitCsvLine(String line) {
    final result = <String>[];
    final buf = StringBuffer();
    var inQuotes = false;
    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        inQuotes = !inQuotes;
        continue;
      }
      if (ch == ',' && !inQuotes) {
        result.add(buf.toString());
        buf.clear();
        continue;
      }
      buf.write(ch);
    }
    result.add(buf.toString());
    return result;
  }
}
