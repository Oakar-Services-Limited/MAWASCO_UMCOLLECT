import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'package:um_collect/components/Utils.dart';
import 'package:um_collect/services/connectivity_helper.dart';
import 'package:um_collect/services/database_helper.dart';
import 'package:um_collect/services/offline_image_store.dart';
import 'package:um_collect/services/offline_queue_notifier.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  static const Map<String, String> _multipartPathFields = {
    'photoPath': 'photo',
    'photoIssuePath': 'photoIssue',
    'photoMeterRemovedPath': 'photoMeterRemoved',
    'photoNewMeterPath': 'photoNewMeter',
  };

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
      OfflineQueueNotifier.instance.refresh();
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
        final body = Map<String, dynamic>.from(
          (responses['_body'] ?? const {}) as Map<String, dynamic>,
        );
        final queuedImagePath = body['imagePath']?.toString();
        final isMultipart = responses['_multipart'] == true;

        await _attachQueuedImage(body);

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
        if (method == 'POST' && isMultipart) {
          final missingFilesError = await _validateMultipartFiles(
            endpoint: endpoint,
            body: body,
          );
          if (missingFilesError != null) {
            await _db.updateSubmissionSyncStatus(
              id: id,
              synced: false,
              syncStatus: 'failed',
              syncError: missingFilesError,
            );
            continue;
          }

          final multipart = http.MultipartRequest('POST', uri);
          if (token != null && token.isNotEmpty) {
            multipart.headers['Authorization'] = 'Bearer $token';
          }
          final skipKeys = _multipartPathFields.keys.toSet();
          for (final entry in body.entries) {
            if (skipKeys.contains(entry.key)) continue;
            multipart.fields[entry.key] = entry.value?.toString() ?? '';
          }
          for (final entry in _multipartPathFields.entries) {
            final path = body[entry.key]?.toString();
            if (path == null || path.isEmpty) continue;
            final part = await OfflineImageStore.multipartFile(
              fieldName: entry.value,
              imagePath: path,
            );
            if (part != null) {
              multipart.files.add(part);
            }
          }

          if (endpoint.contains('meter-replacement')) {
            final canBeReplaced =
                body['canBeReplaced']?.toString().toLowerCase() == 'true';
            final cannotBeReplaced =
                body['canBeReplaced']?.toString().toLowerCase() == 'false';
            final expectedFiles = cannotBeReplaced
                ? 1
                : canBeReplaced
                    ? 2
                    : 0;
            if (expectedFiles > 0 && multipart.files.length < expectedFiles) {
              await _db.updateSubmissionSyncStatus(
                id: id,
                synced: false,
                syncStatus: 'failed',
                syncError:
                    'Could not attach meter photos for upload. Delete this entry and submit again.',
              );
              continue;
            }
          }

          final streamed = await multipart.send();
          response = await http.Response.fromStream(streamed);
        } else if (method == 'POST') {
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
            response.statusCode == 203 ||
            response.statusCode == 204) {
          await _db.deleteSubmission(id);

          // Best-effort: delete any local files referenced explicitly
          for (final key in _multipartPathFields.keys) {
            final path = body[key]?.toString();
            if (path == null || path.isEmpty) continue;
            try {
              final file = File(path);
              if (await file.exists()) {
                await file.delete();
              }
            } catch (_) {}
          }
          if (queuedImagePath != null && queuedImagePath.isNotEmpty) {
            try {
              final file = File(queuedImagePath);
              if (await file.exists()) {
                await file.delete();
              }
            } catch (_) {}
          }
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

    OfflineQueueNotifier.instance.refresh();
    return 'Sync completed.';
  }

  Future<String?> _validateMultipartFiles({
    required String endpoint,
    required Map<String, dynamic> body,
  }) async {
    bool? parseBoolish(dynamic value) {
      if (value is bool) return value;
      if (value == null) return null;
      final s = value.toString().trim().toLowerCase();
      if (s == 'true' || s == 'yes' || s == '1') return true;
      if (s == 'false' || s == 'no' || s == '0') return false;
      return null;
    }

    Future<bool> fileExists(String? path) async {
      if (path == null || path.isEmpty) return false;
      return File(path).exists();
    }

    if (endpoint.contains('meter-replacement')) {
      final canBeReplaced = parseBoolish(body['canBeReplaced']);
      if (canBeReplaced == false) {
        if (!await fileExists(body['photoIssuePath']?.toString())) {
          return 'Issue photo missing on device. Delete this entry and submit again.';
        }
      } else if (canBeReplaced == true) {
        if (!await fileExists(body['photoMeterRemovedPath']?.toString())) {
          return 'Removed-meter photo missing on device. Delete this entry and submit again.';
        }
        if (!await fileExists(body['photoNewMeterPath']?.toString())) {
          return 'New-meter photo missing on device. Delete this entry and submit again.';
        }
      }
      return null;
    }

    if (endpoint.contains('dormant-survey')) {
      final path = body['photoPath']?.toString();
      if (path != null && path.isNotEmpty && !await fileExists(path)) {
        return 'Survey photo missing on device. Delete this entry and submit again.';
      }
    }

    return null;
  }

  Future<void> _attachQueuedImage(Map<String, dynamic> body) async {
    final imagePath = body['imagePath']?.toString();
    if (imagePath == null || imagePath.isEmpty) return;
    final base64 = await OfflineImageStore.readBase64(imagePath);
    if (base64 != null && base64.isNotEmpty) {
      body['image'] = base64;
    }
    body.remove('imagePath');
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

