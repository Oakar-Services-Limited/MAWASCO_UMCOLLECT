import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:um_collect/components/Utils.dart';

/// Thrown when the API rejects the staff token.
class AssignedReportsAuthException implements Exception {}

/// Fetches assigned O&M reports from the API with proper pagination.
class AssignedReportsService {
  AssignedReportsService._();

  static const int _apiPageSize = 50;

  /// Total count for a user + report status (uses API `total`, not page length).
  static Future<int> fetchCount({
    required String userId,
    required String status,
    required String token,
  }) async {
    final uri = Uri.parse(
      '${getUrl()}om/assigned-reports?userId=$userId&status=$status&limit=1&offset=0',
    );
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 401 ||
        (response.statusCode == 400 &&
            _responseIndicatesInvalidToken(response.body))) {
      throw AssignedReportsAuthException();
    }
    if (response.statusCode != 200) return 0;

    final data = json.decode(response.body) as Map<String, dynamic>;
    final total = data['total'];
    if (total is int) return total;
    if (total is num) return total.toInt();
    return (data['data'] as List?)?.length ?? 0;
  }

  /// Loads every assigned report for the user and status.
  static Future<List<dynamic>> fetchAll({
    required String userId,
    required String status,
    required String token,
  }) async {
    final all = <dynamic>[];
    var offset = 0;
    var total = 0;

    while (true) {
      final uri = Uri.parse(
        '${getUrl()}om/assigned-reports?userId=$userId&status=$status&limit=$_apiPageSize&offset=$offset',
      );
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 401 ||
          (response.statusCode == 400 &&
              _responseIndicatesInvalidToken(response.body))) {
        throw AssignedReportsAuthException();
      }
      if (response.statusCode != 200) break;

      final data = json.decode(response.body) as Map<String, dynamic>;
      if (offset == 0) {
        total = _asInt(data['total']);
      }
      final rows = data['data'] as List<dynamic>? ?? [];
      all.addAll(rows);

      if (rows.isEmpty) break;
      if (total > 0 && all.length >= total) break;
      if (rows.length < _apiPageSize) break;
      offset += _apiPageSize;
    }

    return all;
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  static bool _responseIndicatesInvalidToken(String body) {
    try {
      final data = json.decode(body);
      if (data is Map && data['error'] == 'Invalid token') return true;
    } catch (_) {}
    return false;
  }
}
