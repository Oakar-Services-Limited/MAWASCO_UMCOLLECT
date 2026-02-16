// ignore_for_file: file_names
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:um_collect/components/Utils.dart';

class UtilityCacheService {
  static final UtilityCacheService _instance = UtilityCacheService._internal();
  factory UtilityCacheService() => _instance;
  UtilityCacheService._internal();

  final storage = const FlutterSecureStorage();
  static const String _schemesKey = 'cached_schemes';
  static const String _subzonesKey = 'cached_subzones';
  static const String _wardsKey = 'cached_wards';
  static const String _constituenciesKey = 'cached_constituencies';
  static const String _lastSyncKey = 'utilities_last_sync';

  // Cache duration: 7 days (in milliseconds)
  static const int cacheDurationMs = 7 * 24 * 60 * 60 * 1000;

  /// Initialize and fetch utilities if cache is expired or missing
  Future<void> initializeCache({bool forceRefresh = false}) async {
    try {
      final lastSync = await storage.read(key: _lastSyncKey);
      final now = DateTime.now().millisecondsSinceEpoch;

      // Check if cache is expired or missing
      bool shouldRefresh = forceRefresh;
      if (lastSync == null) {
        shouldRefresh = true;
      } else {
        final lastSyncTime = int.tryParse(lastSync) ?? 0;
        final timeDiff = now - lastSyncTime;
        if (timeDiff > cacheDurationMs) {
          shouldRefresh = true;
        }
      }

      if (shouldRefresh) {
        await _fetchAndCacheAll();
      }
    } catch (e) {
      // If fetch fails, try to use cached data if available
      print('Error initializing cache: $e');
    }
  }

  /// Fetch all utilities from API and cache them
  Future<void> _fetchAndCacheAll() async {
    try {
      final token = await storage.read(key: "mwstaffjwt");
      if (token == null || token.isEmpty) {
        // If not logged in, skip fetching
        return;
      }

      // Fetch all utilities in parallel
      await Future.wait([
        _fetchAndCacheSchemes(token),
        _fetchAndCacheSubzones(token),
        _fetchAndCacheWards(token),
      ]);

      // Update last sync time
      await storage.write(
        key: _lastSyncKey,
        value: DateTime.now().millisecondsSinceEpoch.toString(),
      );
    } catch (e) {
      print('Error fetching utilities: $e');
      // Don't throw - allow using cached data if available
    }
  }

  /// Fetch schemes from API
  Future<void> _fetchAndCacheSchemes(String token) async {
    try {
      final response = await http.get(
        Uri.parse("${getUrl()}schemes?limit=1000"),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> schemesList = [];
        
        // Handle different response formats
        if (data['success'] == true && data['data'] != null) {
          schemesList = data['data'] as List;
        } else if (data is List) {
          schemesList = data;
        } else if (data['data'] != null) {
          schemesList = data['data'] as List;
        }
        
        if (schemesList.isNotEmpty) {
          final schemes = schemesList
              .map((item) => {
                    'id': item['id']?.toString() ?? '',
                    'name': item['name']?.toString() ?? '',
                  })
              .toList();

          await storage.write(
            key: _schemesKey,
            value: jsonEncode(schemes),
          );
        }
      }
    } catch (e) {
      print('Error fetching schemes: $e');
    }
  }

  /// Fetch subzones from API
  Future<void> _fetchAndCacheSubzones(String token) async {
    try {
      final response = await http.get(
        Uri.parse("${getUrl()}subzones?limit=1000"),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> subzonesList = [];
        
        // Handle different response formats
        if (data['success'] == true && data['data'] != null) {
          subzonesList = data['data'] as List;
        } else if (data is List) {
          subzonesList = data;
        } else if (data['data'] != null) {
          subzonesList = data['data'] as List;
        }
        
        if (subzonesList.isNotEmpty) {
          final subzones = subzonesList
              .map((item) => {
                    'id': item['id']?.toString() ?? '',
                    'name': item['name']?.toString() ?? '',
                    'code': item['code']?.toString() ?? '',
                    'schemeId': item['schemeId']?.toString() ?? '',
                    'wardId': item['wardId']?.toString() ?? '',
                  })
              .toList();

          await storage.write(
            key: _subzonesKey,
            value: jsonEncode(subzones),
          );
        }
      }
    } catch (e) {
      print('Error fetching subzones: $e');
    }
  }

  /// Fetch wards from API (includes constituencies)
  Future<void> _fetchAndCacheWards(String token) async {
    try {
      final response = await http.get(
        Uri.parse("${getUrl()}wards?limit=1000"),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> wardsList = [];
        
        // Handle different response formats
        if (data['success'] == true && data['data'] != null) {
          wardsList = data['data'] as List;
        } else if (data is List) {
          wardsList = data;
        } else if (data['data'] != null) {
          wardsList = data['data'] as List;
        }
        
        if (wardsList.isNotEmpty) {
          final wards = wardsList
              .map((item) => {
                    'id': item['id']?.toString() ?? '',
                    'name': item['name']?.toString() ?? '',
                    'constituency': item['constituen']?.toString() ?? '',
                  })
              .toList();

          await storage.write(
            key: _wardsKey,
            value: jsonEncode(wards),
          );

          // Extract unique constituencies
          final constituencies = wards
              .where((ward) =>
                  ward['constituency'] != null &&
                  ward['constituency']!.isNotEmpty)
              .map((ward) => ward['constituency']!)
              .toSet()
              .toList()
            ..sort();

          await storage.write(
            key: _constituenciesKey,
            value: jsonEncode(constituencies),
          );
        }
      }
    } catch (e) {
      print('Error fetching wards: $e');
    }
  }

  /// Get cached schemes
  Future<List<String>> getSchemes() async {
    try {
      final cached = await storage.read(key: _schemesKey);
      if (cached != null) {
        final schemes = (jsonDecode(cached) as List)
            .map((item) => item['name']?.toString() ?? '')
            .where((name) => name.isNotEmpty)
            .toList();
        return ['--Select--', ...schemes];
      }
    } catch (e) {
      print('Error reading cached schemes: $e');
    }
    // Fallback to default values
    return ['--Select--', 'Rural', 'Urban'];
  }

  /// Get cached subzones
  Future<List<String>> getSubzones() async {
    try {
      final cached = await storage.read(key: _subzonesKey);
      if (cached != null) {
        final subzones = (jsonDecode(cached) as List)
            .map((item) => item['name']?.toString() ?? '')
            .where((name) => name.isNotEmpty)
            .toList();
        return ['--Select--', ...subzones];
      }
    } catch (e) {
      print('Error reading cached subzones: $e');
    }
    return ['--Select--'];
  }

  /// Get cached wards
  Future<List<String>> getWards() async {
    try {
      final cached = await storage.read(key: _wardsKey);
      if (cached != null) {
        final wards = (jsonDecode(cached) as List)
            .map((item) => item['name']?.toString() ?? '')
            .where((name) => name.isNotEmpty)
            .toList();
        return ['--Select--', ...wards];
      }
    } catch (e) {
      print('Error reading cached wards: $e');
    }
    return ['--Select--'];
  }

  /// Get cached constituencies
  Future<List<String>> getConstituencies() async {
    try {
      final cached = await storage.read(key: _constituenciesKey);
      if (cached != null) {
        final constituencies = (jsonDecode(cached) as List)
            .map((item) => item.toString())
            .where((name) => name.isNotEmpty)
            .toList();
        return ['--Select--', ...constituencies];
      }
    } catch (e) {
      print('Error reading cached constituencies: $e');
    }
    return ['--Select--'];
  }

  /// Get subzones filtered by scheme
  Future<List<String>> getSubzonesByScheme(String? schemeName) async {
    if (schemeName == null || schemeName.isEmpty || schemeName == '--Select--') {
      return await getSubzones();
    }

    try {
      final schemesCached = await storage.read(key: _schemesKey);
      final subzonesCached = await storage.read(key: _subzonesKey);

      if (schemesCached != null && subzonesCached != null) {
        final schemes = jsonDecode(schemesCached) as List;
        final subzones = jsonDecode(subzonesCached) as List;

        // Find scheme ID
        final scheme = schemes.firstWhere(
          (s) => s['name'] == schemeName,
          orElse: () => null,
        );

        if (scheme != null) {
          final schemeId = scheme['id'];
          final filteredSubzones = subzones
              .where((sz) => sz['schemeId'] == schemeId)
              .map((sz) => sz['name']?.toString() ?? '')
              .where((name) => name.isNotEmpty)
              .toList();

          return ['--Select--', ...filteredSubzones];
        }
      }
    } catch (e) {
      print('Error filtering subzones by scheme: $e');
    }

    return await getSubzones();
  }

  /// Get subzones filtered by ward
  Future<List<String>> getSubzonesByWard(String? wardName) async {
    if (wardName == null || wardName.isEmpty || wardName == '--Select--') {
      return await getSubzones();
    }

    try {
      final wardsCached = await storage.read(key: _wardsKey);
      final subzonesCached = await storage.read(key: _subzonesKey);

      if (wardsCached != null && subzonesCached != null) {
        final wards = jsonDecode(wardsCached) as List;
        final subzones = jsonDecode(subzonesCached) as List;

        // Find ward ID
        final ward = wards.firstWhere(
          (w) => w['name'] == wardName,
          orElse: () => null,
        );

        if (ward != null) {
          final wardId = ward['id'];
          final filteredSubzones = subzones
              .where((sz) => sz['wardId'] == wardId)
              .map((sz) => sz['name']?.toString() ?? '')
              .where((name) => name.isNotEmpty)
              .toList();

          return ['--Select--', ...filteredSubzones];
        }
      }
    } catch (e) {
      print('Error filtering subzones by ward: $e');
    }

    return await getSubzones();
  }

  /// Force refresh the cache
  Future<void> refreshCache() async {
    await initializeCache(forceRefresh: true);
  }

  /// Clear all cached utilities
  Future<void> clearCache() async {
    await Future.wait([
      storage.delete(key: _schemesKey),
      storage.delete(key: _subzonesKey),
      storage.delete(key: _wardsKey),
      storage.delete(key: _constituenciesKey),
      storage.delete(key: _lastSyncKey),
    ]);
  }
}
