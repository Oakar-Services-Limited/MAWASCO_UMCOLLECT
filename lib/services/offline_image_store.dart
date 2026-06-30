import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Persists photos for offline submission queues (avoids huge base64 in SQLite).
class OfflineImageStore {
  static Future<Directory> _dir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'offline_images'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Copy camera/gallery file into app storage for reliable sync later.
  static Future<String?> persistFromFile({
    required String sourcePath,
    required String submissionId,
  }) async {
    try {
      final source = File(sourcePath);
      if (!await source.exists()) return null;
      final dest = File(
        p.join((await _dir()).path, '$submissionId.jpg'),
      );
      await source.copy(dest.path);
      return dest.path;
    } catch (_) {
      return null;
    }
  }

  /// Write base64 image bytes to app storage when no file path is available.
  static Future<String?> persistFromBase64({
    required String base64Image,
    required String submissionId,
  }) async {
    if (base64Image.isEmpty) return null;
    try {
      final dest = File(
        p.join((await _dir()).path, '$submissionId.jpg'),
      );
      await dest.writeAsBytes(base64Decode(base64Image));
      return dest.path;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> readBase64(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) return null;
      return base64Encode(await file.readAsBytes());
    } catch (_) {
      return null;
    }
  }
}
