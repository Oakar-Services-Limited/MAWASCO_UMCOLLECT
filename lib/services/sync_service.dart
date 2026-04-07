import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'package:um_collect/components/Utils.dart';
import 'package:um_collect/services/connectivity_helper.dart';
import 'package:um_collect/services/database_helper.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final _db = DatabaseHelper();
  final _storage = const FlutterSecureStorage();

  Future<String> syncAllUnsynced() async {
    final isOnline = await ConnectivityHelper().checkConnectivity();
    if (!isOnline) {
      return 'No internet connection. Sync skipped.';
    }

    final staffToken = await _storage.read(key: 'mwstaffjwt');
    final publicToken = await _storage.read(key: 'mwjwt');

    final submissions = await _db.getUnsyncedSubmissions();
    if (submissions.isEmpty) {
      return 'Nothing to sync.';
    }

    for (final row in submissions) {
      final id = row['id'] as String;
      try {
        await _db.updateSubmissionSyncStatus(
          id: id,
          synced: false,
          syncStatus: 'syncing',
          syncError: null,
        );

        final responsesJson = row['responses'] as String;
        final responses = jsonDecode(responsesJson) as Map<String, dynamic>;

        final endpoint = responses['_endpoint']?.toString();
        final method = (responses['_method'] ?? 'POST').toString().toUpperCase();
        final body = (responses['_body'] ?? const {}) as Map<String, dynamic>;

        if (endpoint == null || endpoint.isEmpty) {
          await _db.updateSubmissionSyncStatus(
            id: id,
            synced: false,
            syncStatus: 'failed',
            syncError: 'Missing endpoint in offline payload.',
          );
          continue;
        }

        final uri = Uri.parse('${getUrl()}$endpoint');
        final requiresAuth = _requiresAuth(endpoint);
        final token = _tokenForEndpoint(
          endpoint: endpoint,
          staffToken: staffToken,
          publicToken: publicToken,
        );
        if (requiresAuth && (token == null || token.isEmpty)) {
          await _db.updateSubmissionSyncStatus(
            id: id,
            synced: false,
            syncStatus: 'failed',
            syncError: 'Authentication token not found. Please login to sync.',
          );
          continue;
        }

        http.Response response;
        if (method == 'POST') {
          response = await http.post(
            uri,
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              if (token != null && token.isNotEmpty)
                'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          );
        } else if (method == 'PUT') {
          final repairedImagePath = body['repairedImagePath']?.toString();
          if (repairedImagePath != null && repairedImagePath.isNotEmpty) {
            final multipart = http.MultipartRequest('PUT', uri);
            if (token != null && token.isNotEmpty) {
              multipart.headers['Authorization'] = 'Bearer $token';
            }
            final file = File(repairedImagePath);
            if (await file.exists()) {
              multipart.files
                  .add(await http.MultipartFile.fromPath('image', file.path));
            }
            for (final entry in body.entries) {
              if (entry.key == 'repairedImagePath') continue;
              multipart.fields[entry.key] = entry.value?.toString() ?? '';
            }
            final streamed = await multipart.send();
            response = await http.Response.fromStream(streamed);
          } else {
            response = await http.put(
              uri,
              headers: {
                'Content-Type': 'application/json; charset=UTF-8',
                if (token != null && token.isNotEmpty)
                  'Authorization': 'Bearer $token',
              },
              body: jsonEncode(body),
            );
          }
        } else {
          await _db.updateSubmissionSyncStatus(
            id: id,
            synced: false,
            syncStatus: 'failed',
            syncError: 'Unsupported HTTP method: $method',
          );
          continue;
        }

        if (response.statusCode == 200 ||
            response.statusCode == 201 ||
            response.statusCode == 204) {
          await _db.deleteSubmission(id);

          // Best-effort: delete any local files referenced explicitly
          for (final value in body.values) {
            if (value is String && _looksLikeLocalPath(value)) {
              try {
                final file = File(value);
                if (await file.exists()) {
                  await file.delete();
                }
              } catch (_) {}
            }
          }
        } else {
          String message = 'Server error (${response.statusCode})';
          try {
            final errorBody = jsonDecode(response.body);
            message = (errorBody['message'] ??
                    errorBody['error'] ??
                    message)
                .toString();
          } catch (_) {}

          await _db.updateSubmissionSyncStatus(
            id: id,
            synced: false,
            syncStatus: 'failed',
            syncError: message,
          );
        }
      } catch (e) {
        await _db.updateSubmissionSyncStatus(
          id: id,
          synced: false,
          syncStatus: 'failed',
          syncError: e.toString(),
        );
      }
    }

    return 'Sync completed.';
  }

  bool _looksLikeLocalPath(String value) {
    return value.contains(Platform.pathSeparator) &&
        !value.startsWith('http://') &&
        !value.startsWith('https://');
  }

  bool _requiresAuth(String endpoint) {
    // Public incident reporting endpoint can sync without JWT.
    if (endpoint == 'om/reports') return false;
    return true;
  }

  String? _tokenForEndpoint({
    required String endpoint,
    required String? staffToken,
    required String? publicToken,
  }) {
    if (endpoint == 'om/reports') {
      // Prefer public token, but allow staff token too.
      return (publicToken != null && publicToken.isNotEmpty)
          ? publicToken
          : staffToken;
    }
    return staffToken;
  }
}

