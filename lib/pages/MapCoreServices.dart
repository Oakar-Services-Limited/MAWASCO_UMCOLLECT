import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:um_collect/components/Utils.dart';
import 'package:um_collect/theme/app_theme.dart';

enum MapLayerType {
  customerMeters,
  waterPipes,
  waterTanks,
  valves,
  masterMeters,
  washouts,
  kiosks,
  dormantMeters,
  sewerLines,
  manholes,
}

enum _MeasureInputMode { currentLocation, mapTap }

class _MapFeature {
  final String id;
  final String name;
  final MapLayerType type;
  final LatLng? point;
  final List<LatLng>? line;
  final String? zoneId;
  final Map<String, dynamic> props;

  _MapFeature({
    required this.id,
    required this.name,
    required this.type,
    this.point,
    this.line,
    this.zoneId,
    Map<String, dynamic>? props,
  }) : props = props ?? const {};
}

class _ZoneFeature {
  final String? zoneId;
  final List<LatLng> points;

  _ZoneFeature({required this.zoneId, required this.points});
}

class _SearchColumn {
  final String value;
  final String label;

  const _SearchColumn({required this.value, required this.label});
}

class MapCoreServices extends StatefulWidget {
  final String staffid;

  const MapCoreServices({super.key, required this.staffid});

  @override
  State<MapCoreServices> createState() => _MapCoreServicesState();
}

class _NearbyResult {
  final _MapFeature feature;
  final double distanceMeters;

  const _NearbyResult({required this.feature, required this.distanceMeters});
}

class _MapCoreServicesState extends State<MapCoreServices> {
  final Completer<GoogleMapController> _controller = Completer();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Map<MapLayerType, List<_MapFeature>> _layerData = {};
  final Set<Polygon> _zonePolygons = {};
  final List<_ZoneFeature> _zoneFeatures = [];
  final Set<String> _zonesWithAssets = {};
  bool _zonesLoaded = false;

  LatLng _currentLocation = const LatLng(-1.2940491, 36.8076449);
  bool _isLoadingLocation = true;
  bool _isLoadingLayers = false;
  String _loadingLayersMessage = 'Loading layers…';
  MapType _mapType = MapType.normal;
  double _nearbyRadiusMeters = 100;
  String _nearbyUnit = 'm'; // 'm' or 'km'
  String _nearbyText = '100';
  final TextEditingController _nearbyController =
      TextEditingController(text: '100');

  bool _measuring = false;
  _MeasureInputMode? _measureMode;
  bool _measurePolygon = false;
  final List<LatLng> _measurePoints = [];
  double _measureTotalMeters = 0;
  double _measureAreaSqm = 0;
  final Map<String, BitmapDescriptor> _measureIconCache = {};
  final Set<String> _measureIconBuilding = {};

  String _selectedCategory = 'All';
  String? _selectedSearchColumn;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String? _searchError;
  bool _allLayersRequested = false;
  bool _allLayersZoomed = false;
  Timer? _fitDebounce;
  /// Bumped on each category switch so stale loads don't hide the spinner early.
  int _categoryLoadToken = 0;

  /// Highlights the last tapped asset on the map (GIS-style); cleared on blank map tap.
  String? _highlightedAssetKey;

  // Toggle to enable verbose debugging logs
  static const bool _debugMap = true;

  bool _legendOpen = false;
  bool _toolsExpanded = false;

  /// Full unfiltered customer meters from GeoJSON (used for client-side search).
  List<_MapFeature>? _customerMetersSource;

  /// Dense point layers (15k+) crash native Google Maps if all markers are added.
  /// Keep full data in memory; only render markers in the current viewport (capped).
  static const int _maxVisiblePointMarkers = 700;
  LatLngBounds? _visibleBounds;
  Set<Marker> _renderedMarkers = {};
  Timer? _viewportDebounce;
  int _customerMetersTotalCount = 0;

  /// Toggleable live device GNSS readout (lat/long, altitude, H/V accuracy, speed).
  bool _gnssPanelOpen = false;
  bool _gnssFollow = true;
  bool _gnssProgrammaticMove = false;
  Position? _gnssPosition;
  String? _gnssError;
  StreamSubscription<Position>? _gnssSubscription;

  static const List<String> _categories = [
    'All',
    'Customer Meters',
    'Valves',
    'Master Meters',
    'Tanks',
    'Water Pipes',
    'Washouts',
    'Kiosks',
    'Dormant Meters',
    'Sewer Lines',
    'Manholes',
  ];

  static const Map<String, MapLayerType> _categoryToLayer = {
    'Customer Meters': MapLayerType.customerMeters,
    'Valves': MapLayerType.valves,
    'Master Meters': MapLayerType.masterMeters,
    'Tanks': MapLayerType.waterTanks,
    'Water Pipes': MapLayerType.waterPipes,
    'Washouts': MapLayerType.washouts,
    'Kiosks': MapLayerType.kiosks,
    'Dormant Meters': MapLayerType.dormantMeters,
    'Sewer Lines': MapLayerType.sewerLines,
    'Manholes': MapLayerType.manholes,
  };

  @override
  void initState() {
    super.initState();
    _initLocation();
    _loadZones();
    // Match admin UX: show everything on "All" without requiring search inputs.
    _ensureCategoryLoaded('All');
  }

  @override
  void dispose() {
    _gnssSubscription?.cancel();
    _searchController.dispose();
    _nearbyController.dispose();
    _fitDebounce?.cancel();
    _viewportDebounce?.cancel();
    super.dispose();
  }

  Future<void> _initLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return;
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });
      if (!_zonesLoaded) {
        _animateTo(_currentLocation);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _animateTo(LatLng target, {double zoom = 16}) async {
    try {
      final controller = await _controller.future;
      _gnssProgrammaticMove = true;
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: zoom),
        ),
      );
    } catch (_) {
    } finally {
      // Allow a short settle so onCameraMoveStarted from this move is ignored.
      Future<void>.delayed(const Duration(milliseconds: 400), () {
        _gnssProgrammaticMove = false;
      });
    }
  }

  Future<void> _toggleGnssPanel() async {
    if (_gnssPanelOpen) {
      await _stopGnssStream();
      if (!mounted) return;
      setState(() {
        _gnssPanelOpen = false;
        _gnssError = null;
      });
      return;
    }

    setState(() {
      _gnssPanelOpen = true;
      _gnssError = null;
      _gnssFollow = true;
    });
    await _startGnssStream();
  }

  Future<void> _startGnssStream() async {
    await _gnssSubscription?.cancel();
    _gnssSubscription = null;

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _gnssError = 'Location services are turned off';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _gnssError = 'Location permission denied';
        });
        return;
      }

      _gnssSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 0,
        ),
      ).listen(
        _onGnssUpdate,
        onError: (Object e) {
          if (!mounted) return;
          setState(() {
            _gnssError = 'Unable to read device position';
          });
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _gnssError = 'Unable to start device positioning';
      });
    }
  }

  Future<void> _stopGnssStream() async {
    await _gnssSubscription?.cancel();
    _gnssSubscription = null;
  }

  void _onGnssUpdate(Position position) {
    if (!mounted || !_gnssPanelOpen) return;
    setState(() {
      _gnssPosition = position;
      _gnssError = null;
      _currentLocation = LatLng(position.latitude, position.longitude);
      _isLoadingLocation = false;
    });
    if (_gnssFollow) {
      _animateTo(
        LatLng(position.latitude, position.longitude),
        zoom: 18,
      );
    }
  }

  String _formatDecimalDegrees(double value, {int decimals = 7}) {
    return value.toStringAsFixed(decimals);
  }

  String _formatGnssMeters(double? value, {int decimals = 1}) {
    if (value == null || value.isNaN || value < 0) return '—';
    return '${value.toStringAsFixed(decimals)} m';
  }

  String _formatSpeed(double? metresPerSecond) {
    if (metresPerSecond == null || metresPerSecond.isNaN || metresPerSecond < 0) {
      return '—';
    }
    final kmh = metresPerSecond * 3.6;
    return '${metresPerSecond.toStringAsFixed(1)} m/s  (${kmh.toStringAsFixed(1)} km/h)';
  }

  double? _verticalAccuracy(Position? p) {
    if (p == null) return null;
    final v = p.altitudeAccuracy;
    if (v.isNaN || v < 0) return null;
    return v;
  }

  Future<void> _loadLayer(
    MapLayerType type, {
    bool forceRefresh = false,
    bool clearLoadingWhenDone = true,
  }) async {
    if (clearLoadingWhenDone && mounted) {
      setState(() {
        _isLoadingLayers = true;
        _loadingLayersMessage = _isDensePointLayer(type)
            ? 'Loading ${type == MapLayerType.customerMeters ? 'customer meters' : 'dormant meters'}…\nThis can take a while (~15,000 records).'
            : 'Loading layers…';
      });
    }

    try {
      final layerFilter = _buildLayerFilter(type);
      final useGeoJson =
          _shouldUseGeoJsonForLayer(type) && layerFilter.isEmpty;

      if (useGeoJson) {
        await _loadGeoJsonLayer(
          type,
          forceRefresh: forceRefresh,
          clearLoadingWhenDone: clearLoadingWhenDone,
        );
        return;
      }

      final uri = _buildLayerUri(type);
      if (uri == null) {
        if (clearLoadingWhenDone && mounted) {
          setState(() {
            _isLoadingLayers = false;
          });
        }
        return;
      }

      if (_debugMap &&
          (type == MapLayerType.waterPipes ||
              type == MapLayerType.sewerLines)) {
        debugPrint('[Map] Loading layer ${type.name} url=$uri');
      }

      final token = await _storage.read(key: 'mwstaffjwt');
      final headers = <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(uri, headers: headers);

      if (_debugMap &&
          (type == MapLayerType.waterPipes ||
              type == MapLayerType.sewerLines)) {
        debugPrint('[Map] Layer ${type.name} status=${response.statusCode}');
        if (response.statusCode != 200) {
          debugPrint('[Map] Layer ${type.name} body=${response.body}');
        }
      }

      if (response.statusCode != 200) {
        if (clearLoadingWhenDone && mounted) {
          setState(() {
            _isLoadingLayers = false;
          });
        }
        return;
      }

      final decoded = jsonDecode(response.body);
      final List data =
          decoded is Map<String, dynamic> ? (decoded['data'] ?? []) : decoded;

      if (_debugMap &&
          (type == MapLayerType.waterPipes ||
              type == MapLayerType.sewerLines)) {
        debugPrint('[Map] Layer ${type.name} records=${data.length}');
        if (data.isNotEmpty && data.first is Map) {
          final m = (data.first as Map).cast<String, dynamic>();
          debugPrint('[Map] Layer ${type.name} sample keys=${m.keys.toList()}');
          debugPrint(
              '[Map] Layer ${type.name} sample coordinatesType=${m['coordinates']?.runtimeType} len=${(m['coordinates'] is List) ? (m['coordinates'] as List).length : 'n/a'}');
          debugPrint(
              '[Map] Layer ${type.name} sample geomType=${(m['geom'] is Map) ? (m['geom'] as Map)['type'] : m['geom']?.runtimeType}');
        }
      }

      final features = <_MapFeature>[];
      for (final raw in data) {
        if (raw is! Map) continue;
        final f = _parseFeature(type, raw.cast<String, dynamic>());
        if (f != null) features.add(f);
      }

      if (_debugMap &&
          (type == MapLayerType.waterPipes ||
              type == MapLayerType.sewerLines)) {
        final withLines =
            features.where((f) => f.line != null && f.line!.length >= 2).length;
        debugPrint(
            '[Map] Layer ${type.name} parsedFeatures=${features.length} withLines=$withLines');
        if (features.isNotEmpty) {
          final firstLine = features.firstWhere(
            (f) => f.line != null && f.line!.length >= 2,
            orElse: () => features.first,
          );
          debugPrint(
              '[Map] Layer ${type.name} sample parsed points=${firstLine.line?.length ?? 0} name="${firstLine.name}"');
        }
      }

      await _applyLoadedFeatures(
        type,
        features,
        clearLoadingWhenDone: clearLoadingWhenDone,
      );
    } catch (_) {
      if (!mounted) return;
      if (clearLoadingWhenDone) {
        setState(() {
          _isLoadingLayers = false;
        });
      }
    }
  }

  bool _shouldUseGeoJsonForLayer(MapLayerType type) {
    return type == MapLayerType.customerMeters;
  }

  String? _geoJsonTableForLayer(MapLayerType type) {
    switch (type) {
      case MapLayerType.customerMeters:
        return 'wt_customer_meters';
      default:
        return null;
    }
  }

  Future<void> _loadGeoJsonLayer(
    MapLayerType type, {
    bool forceRefresh = false,
    bool clearLoadingWhenDone = true,
  }) async {
    final table = _geoJsonTableForLayer(type);
    if (table == null) {
      if (!mounted) return;
      if (clearLoadingWhenDone) {
        setState(() {
          _isLoadingLayers = false;
        });
      }
      return;
    }

    try {
      final query = forceRefresh ? '?refresh=1' : '';
      final uri = Uri.parse('${getUrl()}geojson/$table$query');

      if (_debugMap) {
        debugPrint('[Map] Loading geojson layer ${type.name} url=$uri');
      }

      final token = await _storage.read(key: 'mwstaffjwt');
      final headers = <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(uri, headers: headers);
      if (response.statusCode != 200) {
        if (_debugMap) {
          debugPrint(
              '[Map] GeoJSON ${type.name} failed status=${response.statusCode}; falling back to REST');
        }
        if (type == MapLayerType.customerMeters) {
          await _loadCustomerMetersViaRest(
            clearLoadingWhenDone: clearLoadingWhenDone,
          );
          return;
        }
        if (!mounted) return;
        if (clearLoadingWhenDone) {
          setState(() {
            _isLoadingLayers = false;
          });
        }
        return;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        if (type == MapLayerType.customerMeters) {
          await _loadCustomerMetersViaRest(
            clearLoadingWhenDone: clearLoadingWhenDone,
          );
          return;
        }
        if (!mounted) return;
        if (clearLoadingWhenDone) {
          setState(() {
            _isLoadingLayers = false;
          });
        }
        return;
      }

      final featureList = decoded['features'] as List<dynamic>? ?? [];
      final features = <_MapFeature>[];
      for (final raw in featureList) {
        if (raw is! Map) continue;
        final f = _parseGeoJsonFeature(
          type,
          raw.cast<String, dynamic>(),
        );
        if (f != null) features.add(f);
      }

      if (_debugMap) {
        debugPrint(
            '[Map] GeoJSON layer ${type.name} parsedFeatures=${features.length}');
      }

      // Empty GeoJSON (e.g. geom-only filter on older API): fall back to REST.
      if (features.isEmpty && type == MapLayerType.customerMeters) {
        if (_debugMap) {
          debugPrint(
              '[Map] GeoJSON customerMeters empty; falling back to REST pagination');
        }
        await _loadCustomerMetersViaRest(
          clearLoadingWhenDone: clearLoadingWhenDone,
        );
        return;
      }

      await _applyLoadedFeatures(
        type,
        features,
        clearLoadingWhenDone: clearLoadingWhenDone,
      );
    } catch (e) {
      if (_debugMap) {
        debugPrint('[Map] GeoJSON ${type.name} error: $e');
      }
      if (type == MapLayerType.customerMeters) {
        try {
          await _loadCustomerMetersViaRest(
            clearLoadingWhenDone: clearLoadingWhenDone,
          );
          return;
        } catch (_) {}
      }
      if (!mounted) return;
      if (clearLoadingWhenDone) {
        setState(() {
          _isLoadingLayers = false;
        });
      }
    }
  }

  /// Paginated REST load for customer meters (lat/long). Used when GeoJSON is
  /// empty/unavailable so mapped meters still appear on the map.
  Future<void> _loadCustomerMetersViaRest({
    bool clearLoadingWhenDone = true,
  }) async {
    final token = await _storage.read(key: 'mwstaffjwt');
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    const pageSize = 2000;
    var offset = 0;
    final features = <_MapFeature>[];
    var pages = 0;
    const maxPages = 50; // safety cap

    while (pages < maxPages) {
      final uri = Uri.parse(
        '${getUrl()}wt/customer-meters?limit=$pageSize&offset=$offset',
      );
      if (_debugMap) {
        debugPrint('[Map] REST customerMeters GET $uri');
      }

      final response = await http.get(uri, headers: headers);
      if (response.statusCode != 200) {
        if (_debugMap) {
          debugPrint(
              '[Map] REST customerMeters status=${response.statusCode}');
        }
        break;
      }

      final decoded = jsonDecode(response.body);
      final List data =
          decoded is Map<String, dynamic> ? (decoded['data'] ?? []) : decoded;
      if (data.isEmpty) break;

      for (final raw in data) {
        if (raw is! Map) continue;
        final f = _parseFeature(
          MapLayerType.customerMeters,
          raw.cast<String, dynamic>(),
        );
        if (f != null) features.add(f);
      }

      pages += 1;
      if (data.length < pageSize) break;
      offset += pageSize;
    }

    if (_debugMap) {
      debugPrint(
          '[Map] REST customerMeters parsedFeatures=${features.length} pages=$pages');
    }

    await _applyLoadedFeatures(
      MapLayerType.customerMeters,
      features,
      clearLoadingWhenDone: clearLoadingWhenDone,
    );
  }

  Future<void> _applyLoadedFeatures(
    MapLayerType type,
    List<_MapFeature> features, {
    bool clearLoadingWhenDone = true,
  }) async {
    if (!mounted) return;
    if (type == MapLayerType.customerMeters) {
      _customerMetersSource = List<_MapFeature>.from(features);
      _customerMetersTotalCount = features.length;
    }
    setState(() {
      _layerData[type] = features;
    });
    _updateZonesWithAssets();
    _rebuildZonePolygons();
    if (clearLoadingWhenDone) {
      _scheduleFitToActiveAssets();
      // Keep spinner until markers are actually on the map.
      await _rebuildVisibleMarkers();
      if (mounted) {
        setState(() {
          _isLoadingLayers = false;
        });
      }
    }
  }

  bool _isDensePointLayer(MapLayerType type) {
    return type == MapLayerType.customerMeters ||
        type == MapLayerType.dormantMeters;
  }

  void _scheduleRebuildVisibleMarkers() {
    _viewportDebounce?.cancel();
    _viewportDebounce = Timer(const Duration(milliseconds: 250), () {
      _rebuildVisibleMarkers();
    });
  }

  Future<void> _onCameraIdle() async {
    try {
      final controller = await _controller.future;
      final bounds = await controller.getVisibleRegion();
      if (!mounted) return;
      _visibleBounds = bounds;
      await _rebuildVisibleMarkers();
    } catch (_) {}
  }

  bool _pointInBounds(LatLng p, LatLngBounds b) {
    final sw = b.southwest;
    final ne = b.northeast;
    // Handle antimeridian simply: our data is Kenya-local.
    return p.latitude >= sw.latitude &&
        p.latitude <= ne.latitude &&
        p.longitude >= sw.longitude &&
        p.longitude <= ne.longitude;
  }

  Future<void> _rebuildVisibleMarkers() async {
    if (!mounted) return;

    LatLngBounds? bounds = _visibleBounds;
    if (bounds == null && _controller.isCompleted) {
      try {
        final controller = await _controller.future;
        bounds = await controller.getVisibleRegion();
        _visibleBounds = bounds;
      } catch (_) {}
    }

    final markers = <Marker>{};
    final activeLayer = _categoryToLayer[_selectedCategory];
    var denseShown = 0;
    var denseTotal = 0;
    var denseCapped = false;

    _layerData.forEach((type, features) {
      if (activeLayer != null && activeLayer != type) return;

      // On "All", skip dense customer/dormant meter markers — load via category.
      if (activeLayer == null && _isDensePointLayer(type)) {
        return;
      }

      final dense = _isDensePointLayer(type);
      final candidates = <_MapFeature>[];

      for (final f in features) {
        if (f.point == null) continue;
        if (dense && bounds != null && !_pointInBounds(f.point!, bounds)) {
          continue;
        }
        candidates.add(f);
      }

      if (dense) {
        denseTotal += features.where((f) => f.point != null).length;
        if (candidates.length > _maxVisiblePointMarkers) {
          denseCapped = true;
          // Keep highlighted asset if present, then first N in viewport.
          final highlighted = candidates
              .where((f) => _assetMapKey(type, f.id) == _highlightedAssetKey)
              .toList();
          final rest = candidates
              .where((f) => _assetMapKey(type, f.id) != _highlightedAssetKey)
              .take(_maxVisiblePointMarkers - highlighted.length)
              .toList();
          candidates
            ..clear()
            ..addAll(highlighted)
            ..addAll(rest);
        }
        denseShown += candidates.length;
      }

      for (final f in candidates) {
        final key = _assetMapKey(type, f.id);
        final highlighted = key == _highlightedAssetKey;
        markers.add(
          Marker(
            markerId: MarkerId(key),
            position: f.point!,
            infoWindow: InfoWindow(title: f.name),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              _markerHueForMap(type, highlighted),
            ),
            zIndexInt: highlighted ? 1 : 0,
            onTap: () => _openAssetDetailsSheet(f),
          ),
        );
      }
    });

    if (!mounted) return;
    setState(() {
      _renderedMarkers = markers;
    });

    if (_debugMap && denseTotal > 0) {
      debugPrint(
          '[Map] Visible dense markers=$denseShown of ~$denseTotal (cap=$_maxVisiblePointMarkers capped=$denseCapped)');
    }
  }

  List<_MapFeature> _filterFeatures(
    List<_MapFeature> features,
    String column,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return features;

    return features.where((f) {
      final prop = f.props[column]?.toString().toLowerCase() ?? '';
      if (prop.contains(q)) return true;
      if (column == 'accountNo' && f.name.toLowerCase().contains(q)) {
        return true;
      }
      if (column == 'name') {
        final account =
            f.props['accountNo']?.toString().toLowerCase() ?? '';
        if (account.contains(q)) return true;
      }
      return false;
    }).toList();
  }

  Future<void> _ensureCustomerMetersSourceLoaded() async {
    if (_customerMetersSource != null && _customerMetersSource!.isNotEmpty) {
      return;
    }
    await _loadGeoJsonLayer(MapLayerType.customerMeters);
  }

  _MapFeature? _parseGeoJsonFeature(
    MapLayerType type,
    Map<String, dynamic> feature,
  ) {
    try {
      final props = feature['properties'] as Map<String, dynamic>? ?? {};
      final geom = feature['geometry'] as Map<String, dynamic>?;
      if (geom == null) return null;

      final id = (props['id'] ?? props['ObjectID'] ?? '').toString();
      final name = (props['name'] ??
              props['accountNo'] ??
              props['meterNo'] ??
              props['lineName'] ??
              props['location'] ??
              '')
          .toString();
      final zoneId = (props['zone'] ??
              props['dma_zone'] ??
              props['dmaZone'] ??
              props['Zone'] ??
              props['ZONE'])
          ?.toString();

      if (type == MapLayerType.waterPipes || type == MapLayerType.sewerLines) {
        return _parseFeature(type, props);
      }

      final point = _pointFromGeometry(geom) ?? _pointFromRaw(props);
      if (point == null) return null;

      return _MapFeature(
        id: id,
        name: name,
        type: type,
        point: point,
        zoneId: zoneId,
        props: _extractProps(props, keys: _relevantKeysForType(type).toList()),
      );
    } catch (_) {
      return null;
    }
  }

  LatLng? _pointFromRaw(Map<String, dynamic> raw) {
    final lat = double.tryParse(raw['latitude']?.toString() ?? '');
    final lon = double.tryParse(raw['longitude']?.toString() ?? '');
    if (lat != null && lon != null) {
      return LatLng(lat, lon);
    }
    return _pointFromGeometry(raw['geom']);
  }

  LatLng? _pointFromGeometry(dynamic geom) {
    if (geom is! Map) return null;
    final gType = geom['type']?.toString();
    final gCoords = geom['coordinates'];
    if (gType == 'Point' && gCoords is List && gCoords.length >= 2) {
      final lon = double.tryParse(gCoords[0]?.toString() ?? '');
      final lat = double.tryParse(gCoords[1]?.toString() ?? '');
      if (lat != null && lon != null) {
        return LatLng(lat, lon);
      }
    }
    return null;
  }

  Uri? _buildLayerUri(MapLayerType type) {
    final base = getUrl();
    const denseLimit = 1000;
    const filteredLimit = 5000;
    final layerFilter = _buildLayerFilter(type);
    final limit = layerFilter.isNotEmpty ? filteredLimit : denseLimit;
    switch (type) {
      case MapLayerType.customerMeters:
        return Uri.parse(
            '${base}wt/customer-meters?limit=$limit&offset=0$layerFilter');
      case MapLayerType.waterPipes:
        return Uri.parse(
            '${base}wt/water-pipes?limit=$limit&offset=0$layerFilter');
      case MapLayerType.waterTanks:
        return Uri.parse('${base}wt/tanks?limit=$limit&offset=0$layerFilter');
      case MapLayerType.valves:
        return Uri.parse(
            '${base}wt/valves?limit=$limit&offset=0$layerFilter');
      case MapLayerType.masterMeters:
        return Uri.parse(
            '${base}wt/master-meters?limit=$limit&offset=0$layerFilter');
      case MapLayerType.washouts:
        return Uri.parse(
            '${base}wt/washouts?limit=$limit&offset=0$layerFilter');
      case MapLayerType.kiosks:
        return Uri.parse(
            '${base}wt/kiosks?limit=$limit&offset=0$layerFilter');
      case MapLayerType.dormantMeters:
        return Uri.parse(
            '${base}wt/dormant-customer-meters?limit=$limit&offset=0$layerFilter');
      case MapLayerType.sewerLines:
        return Uri.parse(
            '${base}sr/sewer-lines?limit=$limit&offset=0$layerFilter');
      case MapLayerType.manholes:
        return Uri.parse(
            '${base}sr/manholes?limit=$limit&offset=0$layerFilter');
    }
  }

  String _buildLayerFilter(MapLayerType type) {
    final layer = _categoryToLayer[_selectedCategory];
    if (layer == null || layer != type) return '';
    if (_selectedSearchColumn == null) return '';
    final value = _searchController.text.trim();
    if (value.isEmpty) return '';

    final encodedValue = Uri.encodeQueryComponent(value);
    final column = _selectedSearchColumn!;
    return '&$column=$encodedValue';
  }

  _MapFeature? _parseFeature(MapLayerType type, Map<String, dynamic> raw) {
    try {
      final id = (raw['id'] ?? raw['ObjectID'] ?? '').toString();
      final name = (raw['name'] ??
              raw['accountNo'] ??
              raw['meterNo'] ??
              raw['lineName'] ??
              raw['location'] ??
              '')
          .toString();
      final zoneId = (raw['zone'] ??
              raw['dma_zone'] ??
              raw['dmaZone'] ??
              raw['Zone'] ??
              raw['ZONE'])
          ?.toString();

      if (type == MapLayerType.waterPipes || type == MapLayerType.sewerLines) {
        final points = <LatLng>[];

        void addLonLatPair(dynamic lonRaw, dynamic latRaw) {
          final lon = double.tryParse(lonRaw?.toString() ?? '');
          final lat = double.tryParse(latRaw?.toString() ?? '');
          if (lat != null && lon != null) {
            points.add(LatLng(lat, lon));
          }
        }

        // Primary: coordinates column (may be null in API, depending on controller)
        final coords = raw['coordinates'];
        if (coords is List && coords.isNotEmpty) {
          for (final c in coords) {
            if (c is Map) {
              addLonLatPair(c['longitude'], c['latitude']);
            } else if (c is List && c.length >= 2) {
              addLonLatPair(c[0], c[1]); // [lon, lat]
            }
          }
        }

        // Fallback: PostGIS geometry returned by Sequelize in `geom`
        // Expected shapes:
        // - { type: "LineString", coordinates: [[lon,lat], ...] }
        // - { type: "MultiLineString", coordinates: [[[lon,lat], ...], ...] }
        if (points.length < 2) {
          final geom = raw['geom'];
          if (geom is Map) {
            final gType = geom['type']?.toString();
            final gCoords = geom['coordinates'];
            if (gType == 'LineString' && gCoords is List) {
              for (final c in gCoords) {
                if (c is List && c.length >= 2) addLonLatPair(c[0], c[1]);
              }
            } else if (gType == 'MultiLineString' && gCoords is List) {
              for (final line in gCoords) {
                if (line is List) {
                  for (final c in line) {
                    if (c is List && c.length >= 2) addLonLatPair(c[0], c[1]);
                  }
                  // Only take the first part for display (keeps polyline simple)
                  if (points.length >= 2) break;
                }
              }
            }
          }
        }

        if (points.length >= 2) {
          if (_debugMap && type == MapLayerType.sewerLines) {
            debugPrint(
                '[Map] Parsed sewer line id=$id points=${points.length} geomType=${(raw['geom'] is Map) ? (raw['geom'] as Map)['type'] : raw['geom']?.runtimeType}');
          }

          final props =
              _extractProps(raw, keys: _relevantKeysForType(type).toList());

          return _MapFeature(
            id: id,
            name: name,
            type: type,
            line: points,
            zoneId: zoneId,
            props: props,
          );
        }

        if (_debugMap && type == MapLayerType.sewerLines) {
          debugPrint(
              '[Map] Skipping sewer line id=$id: no drawable points. coordinates=${raw['coordinates']?.runtimeType} geom=${raw['geom']?.runtimeType}');
        }
        return null;
      }

      final point = _pointFromRaw(raw);
      if (point == null) return null;

      return _MapFeature(
        id: id,
        name: name,
        type: type,
        point: point,
        zoneId: zoneId,
        props: _extractProps(raw, keys: _relevantKeysForType(type).toList()),
      );
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _extractProps(
    Map<String, dynamic> raw, {
    required List<String> keys,
  }) {
    final out = <String, dynamic>{};
    for (final k in keys) {
      if (!raw.containsKey(k)) continue;
      final v = raw[k];
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isEmpty || s == 'null') continue;
      out[k] = v;
    }
    return out;
  }

  Iterable<String> _relevantKeysForType(MapLayerType type) {
    // Keep this intentionally small: show only the fields staff need most.
    switch (type) {
      case MapLayerType.customerMeters:
        return const [
          'accountNo',
          'meterNo',
          'name',
          'status',
          'zone',
          'dma',
          'route',
          'location',
        ];
      case MapLayerType.dormantMeters:
        return const [
          'accountNo',
          'meterNo',
          'name',
          'status',
          'zone',
          'dma',
          'route',
          'location',
        ];
      case MapLayerType.valves:
        return const [
          'objectId',
          'type',
          'size',
          'status',
          'zone',
          'dma',
          'route',
          'schemeName',
          'location',
        ];
      case MapLayerType.masterMeters:
        return const [
          'name',
          'serial',
          'status',
          'zone',
          'dma',
          'route',
          'location',
        ];
      case MapLayerType.waterTanks:
        return const [
          'name',
          'status',
          'zone',
          'schemeName',
          'location',
        ];
      case MapLayerType.washouts:
        return const [
          'name',
          'status',
          'zone',
          'dma',
          'route',
          'location',
        ];
      case MapLayerType.kiosks:
        return const [
          'name',
          'status',
          'zone',
          'route',
          'location',
        ];
      case MapLayerType.manholes:
        return const [
          'ObjectID',
          'name',
          'status',
          'zone',
          'route',
          'location',
        ];
      case MapLayerType.waterPipes:
        return const [
          'lineName',
          'lineType',
          'material',
          'size',
          'diameter',
          'status',
          'zone',
          'dma',
          'route',
          'schemeName',
        ];
      case MapLayerType.sewerLines:
        return const [
          'type',
          'material',
          'size',
          'diameter',
          'status',
          'zone',
          'route',
          'schemeName',
        ];
    }
  }

  String _labelForKey(String key) {
    switch (key) {
      case 'accountNo':
        return 'Account No';
      case 'meterNo':
        return 'Meter No';
      case 'lineName':
        return 'Line Name';
      case 'lineType':
        return 'Line Type';
      case 'schemeName':
        return 'Scheme';
      case 'ObjectID':
        return 'Object ID';
      case 'objectId':
        return 'Object ID';
      case 'dma':
        return 'DMA';
      default:
        if (key.isEmpty) return key;
        // Basic humanization: status -> Status, createdAt -> Created At
        final spaced = key.replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'),
          (m) => '${m[1]} ${m[2]}',
        );
        return spaced[0].toUpperCase() + spaced.substring(1);
    }
  }

  /// Stable id used by markers/polylines and selection highlight (matches MarkerId/PolylineId suffix).
  String _assetMapKey(MapLayerType type, String id) => '${type.name}_$id';

  void _setHighlightedAsset(_MapFeature f) {
    final key = _assetMapKey(f.type, f.id);
    if (_highlightedAssetKey == key) return;
    setState(() => _highlightedAssetKey = key);
    _scheduleRebuildVisibleMarkers();
  }

  void _clearHighlightedAsset() {
    if (_highlightedAssetKey == null) return;
    setState(() => _highlightedAssetKey = null);
    _scheduleRebuildVisibleMarkers();
  }

  /// Yellow highlight for selected points (red when the asset type already uses yellow, e.g. manholes).
  double _markerHueForMap(MapLayerType type, bool isHighlighted) {
    if (!isHighlighted) return _markerHue(type);
    if (type == MapLayerType.manholes) return BitmapDescriptor.hueRed;
    return BitmapDescriptor.hueYellow;
  }

  Set<Marker> get _markers => _renderedMarkers;

  Set<Marker> get _measureMarkers {
    final markers = <Marker>{};
    for (var i = 0; i < _measurePoints.length; i++) {
      final p = _measurePoints[i];
      final idx = i + 1;
      String? snippet;
      if (i > 0) {
        final prev = _measurePoints[i - 1];
        final seg = Geolocator.distanceBetween(
          prev.latitude,
          prev.longitude,
          p.latitude,
          p.longitude,
        );
        snippet = 'Segment: ${_formatMeters(seg)}';
      }
      markers.add(
        Marker(
          markerId: MarkerId('measure_$idx'),
          position: p,
          // Use a custom generated icon so measurement points are visually
          // distinct from asset markers.
          icon: _measureIconFor(i),
          infoWindow: InfoWindow(title: 'Point $idx', snippet: snippet),
        ),
      );
    }
    return markers;
  }

  BitmapDescriptor _measureIconFor(int index) {
    final isStart = index == 0;
    final isEnd = index == _measurePoints.length - 1;
    final key = isStart ? 'start' : (isEnd ? 'end' : 'mid');
    final cached = _measureIconCache[key];
    if (cached != null) return cached;
    _ensureMeasureIconsBuilt();
    return BitmapDescriptor.defaultMarker;
  }

  void _ensureMeasureIconsBuilt() {
    for (final key in const ['start', 'mid', 'end']) {
      if (_measureIconCache.containsKey(key)) continue;
      if (_measureIconBuilding.contains(key)) continue;
      _measureIconBuilding.add(key);
      final isStart = key == 'start';
      final isEnd = key == 'end';
      _buildMeasureIcon(isStart: isStart, isEnd: isEnd).then((icon) {
        if (!mounted) return;
        setState(() {
          _measureIconCache[key] = icon;
          _measureIconBuilding.remove(key);
        });
      }).catchError((_) {
        _measureIconBuilding.remove(key);
      });
    }
  }

  Future<BitmapDescriptor> _buildMeasureIcon({
    required bool isStart,
    required bool isEnd,
  }) async {
    const size = 56.0; // px (smaller + faster)
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = const Offset(size / 2, size / 2);

    final bgColor = isStart
        ? const Color(0xFF2E7D32) // green
        : isEnd
            ? const Color(0xFFC62828) // red
            : AppTheme.primaryMain;

    // Outer shadow ring
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center.translate(1, 2), 20, shadowPaint);

    // Main circle
    final fillPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 18, fillPaint);

    // White border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, 18, borderPaint);

    // Pin tip (small triangle)
    final tipPath = Path()
      ..moveTo(center.dx, center.dy + 28)
      ..lineTo(center.dx - 7, center.dy + 12)
      ..lineTo(center.dx + 7, center.dy + 12)
      ..close();
    canvas.drawPath(tipPath, fillPaint);
    canvas.drawPath(tipPath, borderPaint);

    // Simple symbol: S (start) / E (end) / • (middle).
    final symbol = isStart ? 'S' : (isEnd ? 'E' : '•');
    final textPainter = TextPainter(
      text: TextSpan(
        text: symbol,
        style: TextStyle(
          color: Colors.white,
          fontSize: isStart || isEnd ? 18 : 28,
          fontWeight: FontWeight.w900,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2 - 1,
      ),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  Set<Polyline> get _polylines {
    final lines = <Polyline>{};
    _layerData.forEach((type, features) {
      final activeLayer = _categoryToLayer[_selectedCategory];
      if (activeLayer != null && activeLayer != type) return;

      for (final f in features) {
        if (f.line == null || f.line!.length < 2) continue;
        final key = _assetMapKey(type, f.id);
        final highlighted = key == _highlightedAssetKey;
        final baseColor = type == MapLayerType.waterPipes
            ? Colors.blueAccent
            : Colors.tealAccent.shade700;
        if (highlighted) {
          lines.add(
            Polyline(
              polylineId: PolylineId('${key}_selection_glow'),
              points: f.line!,
              color: Colors.amberAccent,
              width: 14,
              zIndex: 0,
              consumeTapEvents: false,
            ),
          );
        }
        lines.add(
          Polyline(
            polylineId: PolylineId(key),
            points: f.line!,
            color: baseColor,
            width: highlighted ? 6 : 4,
            zIndex: 1,
            consumeTapEvents: true,
            onTap: () => _openLineDetailsSheet(f),
          ),
        );
      }
    });
    return lines;
  }

  Set<Polyline> get _measurePolylines {
    if (_measurePoints.length < 2) return {};
    return {
      Polyline(
        polylineId: const PolylineId('measure_polyline'),
        points: List<LatLng>.from(_measurePoints),
        color: Colors.deepOrange,
        width: 4,
      ),
    };
  }

  Set<Polygon> get _measurePolygons {
    if (!_measurePolygon) return {};
    if (_measurePoints.length < 3) return {};
    return {
      Polygon(
        polygonId: const PolygonId('measure_polygon'),
        points: List<LatLng>.from(_measurePoints),
        strokeColor: Colors.deepOrange,
        strokeWidth: 3,
        fillColor: Colors.deepOrange.withValues(alpha: 0.18),
      ),
    };
  }

  void _recomputeMeasureTotal() {
    var total = 0.0;
    for (var i = 0; i < _measurePoints.length - 1; i++) {
      final a = _measurePoints[i];
      final b = _measurePoints[i + 1];
      total += Geolocator.distanceBetween(
        a.latitude,
        a.longitude,
        b.latitude,
        b.longitude,
      );
    }
    _measureTotalMeters = total;
    _measureAreaSqm =
        (_measurePolygon && _measurePoints.length >= 3) ? _polygonAreaSqm(_measurePoints) : 0;
  }

  String _formatMeters(double meters) {
    if (meters >= 1000) return '${(meters / 1000).toStringAsFixed(2)} km';
    return '${meters.toStringAsFixed(0)} m';
  }

  String _formatArea(double sqm) {
    if (sqm >= 1000000) return '${(sqm / 1000000).toStringAsFixed(2)} km²';
    if (sqm >= 10000) return '${(sqm / 10000).toStringAsFixed(2)} ha';
    return '${sqm.toStringAsFixed(0)} m²';
  }

  double _polygonAreaSqm(List<LatLng> pts) {
    // Spherical excess area approximation (good for small polygons).
    const r = 6378137.0;
    if (pts.length < 3) return 0;
    double area = 0;
    for (var i = 0; i < pts.length; i++) {
      final p1 = pts[i];
      final p2 = pts[(i + 1) % pts.length];
      final lon1 = p1.longitude * (math.pi / 180);
      final lon2 = p2.longitude * (math.pi / 180);
      final lat1 = p1.latitude * (math.pi / 180);
      final lat2 = p2.latitude * (math.pi / 180);
      area += (lon2 - lon1) * (2 + math.sin(lat1) + math.sin(lat2));
    }
    area = area * (r * r) / 2.0;
    return area.abs();
  }

  void _toggleMeasure() {
    if (_measuring) {
      setState(() {
        _measuring = false;
      });
      return;
    }
    _openMeasureStartSheet();
  }

  void _openMeasureStartSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Start measuring',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryMain,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Choose how you want to capture measurement points.',
                  style: TextStyle(fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _measureChoiceCard(
                        icon: Icons.my_location,
                        title: 'Current location',
                        subtitle:
                            'Pick start/end by pressing “Add point” as you move.',
                        onTap: () {
                          Navigator.pop(ctx);
                          setState(() {
                            _measuring = true;
                            _measureMode = _MeasureInputMode.currentLocation;
                            _measurePolygon = false;
                            _clearMeasureState();
                          });
                          _ensureMeasureIconsBuilt();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _measureChoiceCard(
                        icon: Icons.touch_app,
                        title: 'Place markers',
                        subtitle: 'Tap on the map to drop points.',
                        onTap: () {
                          Navigator.pop(ctx);
                          setState(() {
                            _measuring = true;
                            _measureMode = _MeasureInputMode.mapTap;
                            _measurePolygon = false;
                            _clearMeasureState();
                          });
                          _ensureMeasureIconsBuilt();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Tip: You can switch to Area (polygon) after starting.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withValues(alpha: 0.65),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _measureChoiceCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppTheme.primaryMain),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addMeasurePoint(LatLng p) {
    setState(() {
      _measurePoints.add(p);
      _recomputeMeasureTotal();
    });
  }

  void _addMeasureMyLocation() {
    _addMeasurePoint(_currentLocation);
    _animateTo(_currentLocation, zoom: 18);
  }

  void _undoMeasurePoint() {
    if (_measurePoints.isEmpty) return;
    setState(() {
      _measurePoints.removeLast();
      _recomputeMeasureTotal();
    });
  }

  void _clearMeasureState() {
    _measurePoints.clear();
    _measureTotalMeters = 0;
    _measureAreaSqm = 0;
  }

  void _clearMeasure() {
    setState(() {
      _clearMeasureState();
      _measureIconCache.clear();
      _measureIconBuilding.clear();
    });
  }

  void _openLineDetailsSheet(_MapFeature f) {
    _openAssetDetailsSheet(f);
  }

  void _openAssetDetailsSheet(_MapFeature f) {
    _setHighlightedAsset(f);
    final title = (f.name.trim().isEmpty) ? '${f.type.name} ${f.id}' : f.name;
    final entries = f.props.entries.toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.timeline, color: AppTheme.primaryMain),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _typeLabel(f.type),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 520),
                  child: entries.isEmpty
                      ? const Text(
                          'No attributes available for this feature.',
                          style: TextStyle(color: Colors.black87),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: entries.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final e = entries[index];
                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                _labelForKey(e.key),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                e.value.toString(),
                                style: const TextStyle(fontSize: 13),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        );
      },
    );
  }

  String _typeLabel(MapLayerType type) {
    switch (type) {
      case MapLayerType.customerMeters:
        return 'Customer Meter';
      case MapLayerType.waterPipes:
        return 'Water Pipe';
      case MapLayerType.waterTanks:
        return 'Water Tank';
      case MapLayerType.valves:
        return 'Valve';
      case MapLayerType.masterMeters:
        return 'Master Meter';
      case MapLayerType.washouts:
        return 'Washout';
      case MapLayerType.kiosks:
        return 'Kiosk';
      case MapLayerType.dormantMeters:
        return 'Dormant Meter';
      case MapLayerType.sewerLines:
        return 'Sewer Line';
      case MapLayerType.manholes:
        return 'Manhole';
    }
  }

  Future<void> _findNearby() async {
    final activeLayer = _categoryToLayer[_selectedCategory];

    // If the user is on a specific category and it's not loaded yet, load it
    // so nearby search works without requiring a manual search/filter step.
    if (activeLayer != null && (_layerData[activeLayer]?.isEmpty ?? true)) {
      await _loadLayer(activeLayer);
    }

    final candidates = <_MapFeature>[];
    _layerData.forEach((type, features) {
      if (activeLayer != null && activeLayer != type) return;
      candidates.addAll(features);
    });

    if (candidates.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No assets loaded for nearby search.'),
        ),
      );
      return;
    }

    final results = <_NearbyResult>[];
    for (final f in candidates) {
      double? d;
      if (f.point != null) {
        final p = f.point!;
        d = Geolocator.distanceBetween(
          _currentLocation.latitude,
          _currentLocation.longitude,
          p.latitude,
          p.longitude,
        );
      } else if (f.line != null && f.line!.length >= 2) {
        d = _distancePointToPolylineMeters(_currentLocation, f.line!);
      }
      if (d != null && d <= _nearbyRadiusMeters) {
        results.add(_NearbyResult(feature: f, distanceMeters: d));
      }
    }

    if (!mounted) return;

    if (results.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('No assets found within ${_nearbyRadiusMeters.toInt()} m.'),
        ),
      );
      return;
    }

    results.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.radar, color: AppTheme.primaryMain),
                title: Text(
                  'Assets within ${_nearbyRadiusMeters.toInt()} m',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Divider(height: 1),
              SizedBox(
                height: 300,
                child: ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final r = results[index];
                    final f = r.feature;
                    final isLine = f.line != null && (f.line?.length ?? 0) >= 2;
                    final distanceLabel = r.distanceMeters >= 1000
                        ? '${(r.distanceMeters / 1000).toStringAsFixed(2)} km'
                        : '${r.distanceMeters.toStringAsFixed(0)} m';
                    return ListTile(
                      leading: Icon(
                        isLine ? Icons.timeline : Icons.place,
                        color: AppTheme.primaryMain,
                      ),
                      title: Text(f.name.isEmpty ? f.id : f.name),
                      subtitle: Text('${_typeLabel(f.type)} • $distanceLabel'),
                      onTap: () {
                        Navigator.pop(context);
                        _setHighlightedAsset(f);
                        if (f.point != null) {
                          _animateTo(f.point!, zoom: 18);
                        } else if (f.line != null && f.line!.length >= 2) {
                          final b = _boundsForLine(f.line!);
                          if (b != null) {
                            _fitBoundsWithRetry(_safeBounds(b), padding: 70);
                          }
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  LatLngBounds? _boundsForLine(List<LatLng> pts) {
    if (pts.isEmpty) return null;
    var minLat = pts.first.latitude;
    var maxLat = pts.first.latitude;
    var minLon = pts.first.longitude;
    var maxLon = pts.first.longitude;
    for (final p in pts) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLon) minLon = p.longitude;
      if (p.longitude > maxLon) maxLon = p.longitude;
    }
    return LatLngBounds(
      southwest: LatLng(minLat, minLon),
      northeast: LatLng(maxLat, maxLon),
    );
  }

  double _distancePointToPolylineMeters(LatLng p, List<LatLng> line) {
    // Local tangent-plane approximation (equirectangular projection) around p.
    // Accurate enough for small radii (meters to a few km), and fast.
    if (line.length < 2) return double.infinity;
    var best = double.infinity;
    for (var i = 0; i < line.length - 1; i++) {
      final d = _distancePointToSegmentMeters(p, line[i], line[i + 1]);
      if (d < best) best = d;
    }
    return best;
  }

  double _distancePointToSegmentMeters(LatLng p, LatLng a, LatLng b) {
    // Convert to local meters.
    final pm = _toLocalMeters(p, p);
    final am = _toLocalMeters(a, p);
    final bm = _toLocalMeters(b, p);

    final ax = am.$1;
    final ay = am.$2;
    final bx = bm.$1;
    final by = bm.$2;
    final px = pm.$1;
    final py = pm.$2;

    final abx = bx - ax;
    final aby = by - ay;
    final apx = px - ax;
    final apy = py - ay;

    final abLen2 = abx * abx + aby * aby;
    if (abLen2 == 0) {
      final dx = px - ax;
      final dy = py - ay;
      return math.sqrt(dx * dx + dy * dy);
    }

    var t = (apx * abx + apy * aby) / abLen2;
    if (t < 0) t = 0;
    if (t > 1) t = 1;
    final cx = ax + t * abx;
    final cy = ay + t * aby;
    final dx = px - cx;
    final dy = py - cy;
    return math.sqrt(dx * dx + dy * dy);
  }

  (double, double) _toLocalMeters(LatLng ll, LatLng origin) {
    const earthRadius = 6378137.0; // meters
    final lat0 = origin.latitude * (3.141592653589793 / 180.0);
    final x = (ll.longitude - origin.longitude) *
        (3.141592653589793 / 180.0) *
        earthRadius *
        math.cos(lat0);
    final y = (ll.latitude - origin.latitude) *
        (3.141592653589793 / 180.0) *
        earthRadius;
    return (x, y);
  }

  void _openBufferSheet() {
    // Keep controller in sync with current stored text.
    _nearbyController.text = _nearbyText;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Nearby search radius',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryMain,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Distance',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        controller: _nearbyController,
                        onChanged: (value) {
                          setState(() {
                            _nearbyText = value;
                            final parsed =
                                double.tryParse(value.replaceAll(',', '.'));
                            if (parsed != null && parsed > 0) {
                              _nearbyRadiusMeters =
                                  _nearbyUnit == 'km' ? parsed * 1000 : parsed;
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<String>(
                      value: _nearbyUnit,
                      items: const [
                        DropdownMenuItem(
                          value: 'm',
                          child: Text('Meters'),
                        ),
                        DropdownMenuItem(
                          value: 'km',
                          child: Text('Kilometers'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() {
                          _nearbyUnit = v;
                          final parsed =
                              double.tryParse(_nearbyText.replaceAll(',', '.'));
                          if (parsed != null && parsed > 0) {
                            _nearbyRadiusMeters =
                                _nearbyUnit == 'km' ? parsed * 1000 : parsed;
                          }
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryMain,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _findNearby();
                    },
                    icon: const Icon(Icons.radar),
                    label: const Text('Find assets near me'),
                  ),
                ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _openLegendSheet() {
    if (_legendOpen) return;
    _legendOpen = true;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final items = <MapEntry<String, Widget>>[
          MapEntry('Customer Meters',
              _legendDot(_legendColor(MapLayerType.customerMeters))),
          MapEntry('Valves', _legendDot(_legendColor(MapLayerType.valves))),
          MapEntry('Master Meters',
              _legendDot(_legendColor(MapLayerType.masterMeters))),
          MapEntry(
              'Water Tanks', _legendDot(_legendColor(MapLayerType.waterTanks))),
          MapEntry('Washouts', _legendDot(_legendColor(MapLayerType.washouts))),
          MapEntry('Kiosks', _legendDot(_legendColor(MapLayerType.kiosks))),
          MapEntry('Dormant Meters',
              _legendDot(_legendColor(MapLayerType.dormantMeters))),
          MapEntry('Manholes', _legendDot(_legendColor(MapLayerType.manholes))),
          MapEntry('Water Pipes',
              _legendLine(_legendColor(MapLayerType.waterPipes))),
          MapEntry('Sewer Lines',
              _legendLine(_legendColor(MapLayerType.sewerLines))),
        ];

        return SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Legend',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryMain,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Marker and line colors by asset type.',
                  style: TextStyle(fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 420),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final e = items[index];
                      return ListTile(
                        dense: true,
                        leading: e.value,
                        title: Text(
                          e.key,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      _legendOpen = false;
    });
  }

  Widget _legendDot(Color color) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black.withValues(alpha: 0.15)),
      ),
    );
  }

  Widget _legendLine(Color color) {
    return Container(
      width: 22,
      height: 6,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  void _toggleMapType() {
    setState(() {
      _mapType =
          _mapType == MapType.normal ? MapType.satellite : MapType.normal;
    });
  }

  Future<void> _recenter() async {
    setState(() {
      _isLoadingLocation = true;
      if (_gnssPanelOpen) {
        _gnssFollow = true;
      }
    });
    if (_gnssPanelOpen && _gnssPosition != null) {
      await _animateTo(
        LatLng(_gnssPosition!.latitude, _gnssPosition!.longitude),
        zoom: 18,
      );
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
      return;
    }
    await _initLocation();
  } 

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Network Map',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppTheme.primaryMain,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentLocation,
              zoom: 15,
            ),
            mapType: _mapType,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: {..._markers, ..._measureMarkers},
            polylines: {..._polylines, ..._measurePolylines},
            polygons: {..._zonePolygons, ..._measurePolygons},
            onTap: (p) {
              if (_measuring && _measureMode == _MeasureInputMode.mapTap) {
                _addMeasurePoint(p);
              } else {
                _clearHighlightedAsset();
              }
            },
            onMapCreated: (controller) {
              _controller.complete(controller);
              _onCameraIdle();
            },
            onCameraIdle: _onCameraIdle,
            onCameraMoveStarted: () {
              if (_gnssPanelOpen &&
                  _gnssFollow &&
                  !_gnssProgrammaticMove &&
                  mounted) {
                setState(() => _gnssFollow = false);
              }
            },
          ),
          Positioned(
            top: topPadding + 12,
            left: 12,
            right: 12,
            child: _buildTopFilterPanel(),
          ),
          Positioned(
            left: 12,
            bottom: 12 + bottomPadding,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _openLegendSheet,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.legend_toggle, color: AppTheme.primaryMain),
                      const SizedBox(width: 8),
                      const Text(
                        'Legend',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_gnssPanelOpen)
            Positioned(
              left: 12,
              right: _toolsExpanded ? 280 : 88,
              bottom: (_measuring ? 168 : 64) + bottomPadding,
              child: _buildGnssPanel(),
            ),
          if (_measuring)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12 + bottomPadding,
              child: _buildMeasurePanel(),
            ),
          if (_isLoadingLocation || _isLoadingLayers)
            Positioned(
              left: 12,
              right: 72,
              top: topPadding + 120,
              child: Card(
                elevation: 6,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: LoadingAnimationWidget.horizontalRotatingDots(
                          color: AppTheme.primaryMain,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _isLoadingLocation
                                  ? 'Getting location…'
                                  : (_loadingLayersMessage.contains('\n')
                                      ? _loadingLayersMessage.split('\n').first
                                      : _loadingLayersMessage),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (!_isLoadingLocation &&
                                _loadingLayersMessage.contains('\n')) ...[
                              const SizedBox(height: 4),
                              Text(
                                _loadingLayersMessage
                                    .split('\n')
                                    .skip(1)
                                    .join(' '),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _buildMapToolsFab(),
    );
  }

  Widget _buildMapToolsFab() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_toolsExpanded) ...[
          _mapToolChip(
            icon: Icons.pin_drop_outlined,
            label: 'Device Position',
            subtitle: 'Live lat, long, altitude & accuracy',
            active: _gnssPanelOpen,
            activeColor: AppTheme.primaryMain,
            onTap: () {
              _toggleGnssPanel();
            },
          ),
          const SizedBox(height: 8),
          _mapToolChip(
            icon: Icons.navigation,
            label: 'Go to My Location',
            subtitle: 'Centre / follow the map on you',
            onTap: () {
              setState(() => _toolsExpanded = false);
              _recenter();
            },
          ),
          const SizedBox(height: 8),
          _mapToolChip(
            icon: _mapType == MapType.normal
                ? Icons.satellite_alt
                : Icons.map_outlined,
            label: 'Base Map',
            subtitle: _mapType == MapType.normal
                ? 'Switch to satellite view'
                : 'Switch to street map',
            onTap: () {
              _toggleMapType();
            },
          ),
          const SizedBox(height: 8),
          _mapToolChip(
            icon: Icons.radar,
            label: 'Assets Near Me',
            subtitle: 'List assets within a radius',
            activeColor: AppTheme.primaryMain,
            onTap: () {
              setState(() => _toolsExpanded = false);
              _openBufferSheet();
            },
          ),
          const SizedBox(height: 8),
          _mapToolChip(
            icon: Icons.straighten,
            label: 'Measure',
            subtitle: 'Distance or area on the map',
            active: _measuring,
            activeColor: Colors.deepOrange,
            onTap: () {
              setState(() => _toolsExpanded = false);
              _toggleMeasure();
            },
          ),
          const SizedBox(height: 10),
        ],
        FloatingActionButton.extended(
          heroTag: 'map_tools_fab',
          onPressed: () {
            setState(() => _toolsExpanded = !_toolsExpanded);
          },
          backgroundColor: AppTheme.primaryMain,
          foregroundColor: Colors.white,
          icon: Icon(_toolsExpanded ? Icons.close : Icons.handyman_outlined),
          label: Text(_toolsExpanded ? 'Close tools' : 'Map tools'),
        ),
      ],
    );
  }

  Widget _mapToolChip({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    bool active = false,
    Color activeColor = const Color(0xff0288D1),
  }) {
    final bg = active ? activeColor : Colors.white;
    final fg = active ? Colors.white : AppTheme.primaryMain;
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(14),
      color: bg,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minWidth: 220, maxWidth: 260),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: active
                      ? Colors.white.withValues(alpha: 0.2)
                      : AppTheme.primaryMain.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: fg, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: active ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: active
                            ? Colors.white.withValues(alpha: 0.9)
                            : Colors.grey[700],
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGnssPanel() {
    final p = _gnssPosition;
    final hAcc = p?.accuracy;
    final vAcc = _verticalAccuracy(p);

    return Card(
      elevation: 6,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.gps_fixed, color: AppTheme.primaryMain, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Device Position',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
                IconButton(
                  tooltip: _gnssFollow
                      ? 'Stop following device'
                      : 'Follow device',
                  onPressed: () {
                    setState(() => _gnssFollow = !_gnssFollow);
                    if (_gnssFollow && _gnssPosition != null) {
                      _animateTo(
                        LatLng(
                          _gnssPosition!.latitude,
                          _gnssPosition!.longitude,
                        ),
                        zoom: 18,
                      );
                    }
                  },
                  icon: Icon(
                    _gnssFollow ? Icons.lock : Icons.lock_open,
                    size: 18,
                    color: _gnssFollow
                        ? AppTheme.primaryMain
                        : Colors.grey[600],
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: _toggleGnssPanel,
                  icon: Icon(Icons.close, size: 18, color: Colors.grey[700]),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
            if (_gnssError != null) ...[
              const SizedBox(height: 4),
              Text(
                _gnssError!,
                style: TextStyle(color: Colors.red[700], fontSize: 12),
              ),
            ] else if (p == null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  LoadingAnimationWidget.horizontalRotatingDots(
                    color: AppTheme.primaryMain,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Waiting for GPS fix…',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 6),
              _gnssRow(
                'Latitude',
                '${_formatDecimalDegrees(p.latitude)} °',
              ),
              _gnssRow(
                'Longitude',
                '${_formatDecimalDegrees(p.longitude)} °',
              ),
              _gnssRow('Altitude', _formatGnssMeters(p.altitude)),
              _gnssRow('H. Accuracy', _formatGnssMeters(hAcc)),
              _gnssRow('V. Accuracy', _formatGnssMeters(vAcc)),
              _gnssRow('Speed', _formatSpeed(p.speed)),
              const SizedBox(height: 4),
              Text(
                _gnssFollow
                    ? 'Following device — map updates as you move'
                    : 'Follow unlocked — pan freely; tap lock to track',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _gnssRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurePanel() {
    final mode = _measureMode;
    final modeLabel = mode == _MeasureInputMode.currentLocation
        ? 'Current location'
        : 'Place markers';
    // Responsive sizing: reserve space for the right-side FAB stack and clamp the panel width.
    final screenWidth = MediaQuery.of(context).size.width;
    final rightFabReserve = (screenWidth * 0.22).clamp(72.0, 96.0);
    final maxPanelWidth = (screenWidth - rightFabReserve - 16).clamp(240.0, 520.0);

    return SafeArea(
      minimum: const EdgeInsets.only(left: 12, bottom: 12),
      child: Padding(
        // Keep panel clear of the right FAB stack without hardcoding a single value.
        padding: EdgeInsets.only(right: rightFabReserve),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxPanelWidth),
          child: Card(
            elevation: 6,
            color: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Row(
                children: [
                  Icon(Icons.straighten, color: AppTheme.primaryMain),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Measuring',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '${modeLabel}${_measurePolygon ? ' • Area' : ' • Distance'}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.black.withValues(alpha: 0.65),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatMeters(_measureTotalMeters),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppTheme.primaryMain,
                    ),
                  ),
                ],
              ),
              if (_measurePolygon && _measurePoints.length >= 3)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Area: ${_formatArea(_measureAreaSqm)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryMain,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: SegmentedButton<_MeasureInputMode>(
                      segments: const [
                        ButtonSegment(
                          value: _MeasureInputMode.currentLocation,
                          label: Text('Location'),
                          icon: Icon(Icons.my_location),
                        ),
                        ButtonSegment(
                          value: _MeasureInputMode.mapTap,
                          label: Text('Tap map'),
                          icon: Icon(Icons.touch_app),
                        ),
                      ],
                      selected: {mode ?? _MeasureInputMode.mapTap},
                      onSelectionChanged: (s) {
                        final v = s.first;
                        setState(() {
                          _measureMode = v;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    selected: _measurePolygon,
                    label: const Text(
                      'Area',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    onSelected: (v) {
                      setState(() {
                        _measurePolygon = v;
                        _recomputeMeasureTotal();
                      });
                    },
                    selectedColor: AppTheme.primaryMain,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: _measurePolygon
                          ? Colors.white
                          : AppTheme.primaryMain,
                    ),
                    side: BorderSide(
                      color: AppTheme.primaryMain.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_measureMode == _MeasureInputMode.currentLocation)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryMain,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _addMeasureMyLocation,
                      icon: const Icon(Icons.add_location_alt, size: 18),
                      label: const Text('Add point'),
                    ),
                  OutlinedButton.icon(
                    onPressed: _measurePoints.isEmpty ? null : _undoMeasurePoint,
                    icon: const Icon(Icons.undo, size: 18),
                    label: const Text('Undo'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _measurePoints.isEmpty ? null : _clearMeasure,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Clear'),
                  ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryMain,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _toggleMeasure,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Done'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _measureMode == _MeasureInputMode.currentLocation
                    ? 'Press “Add point” to capture your current location as you move.'
                    : 'Tap the map to add points.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w600,
                ),
              ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadZones() async {
    if (_zonesLoaded) return;
    try {
      final token = await _storage.read(key: 'mwstaffjwt');
      final headers = <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      final uri = Uri.parse('${getUrl()}geojson/zones');
      final response = await http.get(uri, headers: headers);
      if (response.statusCode != 200) return;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return;
      final features = decoded['features'] as List<dynamic>? ?? [];

      final zoneFeatures = <_ZoneFeature>[];

      for (final feature in features) {
        if (feature is! Map<String, dynamic>) continue;
        final props = feature['properties'] as Map<String, dynamic>? ?? {};
        final zoneId = (props['zone'] ??
                props['dma_zone'] ??
                props['name'] ??
                props['Zone'] ??
                props['ZONE'] ??
                props['id'])
            ?.toString();

        final geom = feature['geometry'] as Map<String, dynamic>?;
        if (geom == null) continue;
        final type = geom['type']?.toString();
        final coords = geom['coordinates'];

        if (type == 'Polygon' && coords is List && coords.isNotEmpty) {
          final ring = coords[0];
          if (ring is List && ring.isNotEmpty) {
            final pts = _parseRingToLatLng(ring);
            if (pts.length >= 3) {
              zoneFeatures.add(_ZoneFeature(zoneId: zoneId, points: pts));
            }
          }
        } else if (type == 'MultiPolygon' &&
            coords is List &&
            coords.isNotEmpty) {
          for (final poly in coords) {
            if (poly is List && poly.isNotEmpty) {
              final ring = poly[0];
              if (ring is List && ring.isNotEmpty) {
                final pts = _parseRingToLatLng(ring);
                if (pts.length >= 3) {
                  zoneFeatures.add(_ZoneFeature(zoneId: zoneId, points: pts));
                }
              }
            }
          }
        }
      }

      if (zoneFeatures.isEmpty || !mounted) return;

      // Compute bounds of all zones for initial zoom
      LatLngBounds? bounds;
      for (final z in zoneFeatures) {
        for (final p in z.points) {
          if (bounds == null) {
            bounds = LatLngBounds(southwest: p, northeast: p);
          } else {
            final sw = bounds.southwest;
            final ne = bounds.northeast;
            bounds = LatLngBounds(
              southwest: LatLng(
                p.latitude < sw.latitude ? p.latitude : sw.latitude,
                p.longitude < sw.longitude ? p.longitude : sw.longitude,
              ),
              northeast: LatLng(
                p.latitude > ne.latitude ? p.latitude : ne.latitude,
                p.longitude > ne.longitude ? p.longitude : ne.longitude,
              ),
            );
          }
        }
      }

      setState(() {
        _zoneFeatures
          ..clear()
          ..addAll(zoneFeatures);
        _zonesLoaded = true;
      });
      _rebuildZonePolygons();

      if (bounds != null) {
        try {
          final controller = await _controller.future;
          await controller.animateCamera(
            CameraUpdate.newLatLngBounds(bounds, 50),
          );
        } catch (_) {
          // ignore zoom errors
        }
      }
    } catch (_) {
      // ignore zone load errors; map still works without them
    }
  }

  List<LatLng> _parseRingToLatLng(List<dynamic> ring) {
    final pts = <LatLng>[];
    for (final c in ring) {
      if (c is List && c.length >= 2) {
        final lon = (c[0] as num?)?.toDouble();
        final lat = (c[1] as num?)?.toDouble();
        if (lat != null && lon != null) {
          pts.add(LatLng(lat, lon));
        }
      }
    }
    return pts;
  }

  void _updateZonesWithAssets() {
    final zones = <String>{};
    _layerData.forEach((_, features) {
      for (final f in features) {
        final z = f.zoneId;
        if (z != null && z.trim().isNotEmpty) {
          zones.add(z.trim());
        }
      }
    });
    _zonesWithAssets
      ..clear()
      ..addAll(zones);
  }

  void _rebuildZonePolygons() {
    if (_zoneFeatures.isEmpty) return;

    final polygons = <Polygon>{};
    var idx = 0;

    for (final z in _zoneFeatures) {
      final hasAssets =
          z.zoneId != null && _zonesWithAssets.contains(z.zoneId!.trim());

      final strokeColor = hasAssets
          ? const Color(0xFF00E5FF)
          : Colors.white.withValues(alpha: 0.35);
      final fillColor = hasAssets
          ? const Color.fromARGB(46, 0, 229, 255) // ~rgba(0,229,255,0.18)
          : Colors.white.withValues(alpha: 0.04);

      polygons.add(
        Polygon(
          polygonId: PolygonId('zone_${idx++}'),
          points: z.points,
          strokeColor: strokeColor,
          strokeWidth: hasAssets ? 3 : 1,
          fillColor: fillColor,
        ),
      );
    }

    if (!mounted) return;
    setState(() {
      _zonePolygons
        ..clear()
        ..addAll(polygons);
    });
  }

  Widget _buildTopFilterPanel() {
    return Card(
      elevation: 6,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchControls(),
            if (_selectedCategory == 'Customer Meters' &&
                _customerMetersTotalCount > _maxVisiblePointMarkers) ...[
              const SizedBox(height: 6),
              Text(
                'Showing up to $_maxVisiblePointMarkers meters in view '
                '(of $_customerMetersTotalCount). Zoom in or search by DMA/account.',
                style: TextStyle(fontSize: 11, color: Colors.grey[700]),
              ),
            ],
            const SizedBox(height: 10),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final selected = _selectedCategory == cat;
                  return FilterChip(
                    showCheckmark: false,
                    selected: selected,
                    label: Text(
                      cat.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : AppTheme.primaryMain,
                      ),
                    ),
                    backgroundColor: Colors.white,
                    selectedColor: AppTheme.primaryMain,
                    side: BorderSide(
                      color: selected
                          ? AppTheme.primaryMain
                          : AppTheme.primaryMain.withValues(alpha: 0.35),
                    ),
                    onSelected: (_) {
                      _onCategorySelected(cat);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onCategorySelected(String cat) {
    final layer = _categoryToLayer[cat];
    final token = ++_categoryLoadToken;

    setState(() {
      _selectedCategory = cat;
      _selectedSearchColumn = null;
      _searchError = null;
      _searchController.clear();
      _highlightedAssetKey = null;
      // Drop previous category markers immediately so "All" pins don't linger.
      _renderedMarkers = {};
      _isLoadingLayers = true;
      _loadingLayersMessage = _loadingMessageForCategory(cat, layer);
    });

    _ensureCategoryLoaded(cat, loadToken: token);
  }

  String _loadingMessageForCategory(String cat, MapLayerType? layer) {
    if (cat == 'All') return 'Loading network layers…';
    if (layer == MapLayerType.customerMeters) {
      return 'Loading customer meters…\nThis can take a while (~15,000 records). Please wait.';
    }
    if (layer == MapLayerType.dormantMeters) {
      return 'Loading dormant meters…\nThis can take a while. Please wait.';
    }
    return 'Loading $cat…';
  }

  Future<void> _refreshMapData() async {
    final token = ++_categoryLoadToken;
    setState(() {
      _highlightedAssetKey = null;
      _searchError = null;
      _customerMetersSource = null;
      _renderedMarkers = {};
      _isLoadingLayers = true;
      _loadingLayersMessage = _selectedCategory == 'Customer Meters'
          ? 'Refreshing customer meters…\nThis can take a while. Please wait.'
          : 'Refreshing map layers…';
    });

    try {
      final cat = _selectedCategory;
      if (cat == 'All') {
        // Reload light layers only; keep dense caches out of All view.
        for (final type
            in MapLayerType.values.where((t) => !_isDensePointLayer(t))) {
          _layerData.remove(type);
        }
        _allLayersRequested = true;
        _allLayersZoomed = false;
        final lightLayers =
            MapLayerType.values.where((t) => !_isDensePointLayer(t)).toList();
        await Future.wait(
          lightLayers.map(
            (type) => _loadLayer(type, clearLoadingWhenDone: false),
          ),
        );
        if (!mounted || token != _categoryLoadToken) return;
        await _zoomToAllLoadedAssets();
        await _rebuildVisibleMarkers();
      } else {
        final layer = _categoryToLayer[cat];
        if (layer != null) {
          _layerData.remove(layer);
          if (layer == MapLayerType.customerMeters) {
            _customerMetersSource = null;
            _customerMetersTotalCount = 0;
          }
          await _loadLayer(
            layer,
            forceRefresh: layer == MapLayerType.customerMeters &&
                _buildLayerFilter(layer).isEmpty,
            clearLoadingWhenDone: false,
          );
          if (!mounted || token != _categoryLoadToken) return;
          await _zoomToLayer(layer);
          await _rebuildVisibleMarkers();
        }
      }

      if (!mounted || token != _categoryLoadToken) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Map data refreshed')),
      );
    } finally {
      if (mounted && token == _categoryLoadToken) {
        setState(() {
          _isLoadingLayers = false;
        });
      }
    }
  }

  Future<void> _ensureCategoryLoaded(
    String cat, {
    int? loadToken,
  }) async {
    final token = loadToken ?? _categoryLoadToken;

    try {
      if (cat == 'All') {
        if (!_allLayersRequested) {
          _allLayersRequested = true;
          _allLayersZoomed = false;
          if (mounted) {
            setState(() {
              _isLoadingLayers = true;
              _loadingLayersMessage = 'Loading network layers…';
            });
          }
          // Do NOT load dense customer/dormant meters on All — ~15k markers OOMs
          // Android. Those layers load when their category chip is selected.
          final lightLayers = MapLayerType.values
              .where((t) => !_isDensePointLayer(t))
              .toList();
          await Future.wait(
            lightLayers.map(
              (t) => _loadLayer(t, clearLoadingWhenDone: false),
            ),
          );
          if (!mounted || token != _categoryLoadToken) return;
          await _zoomToAllLoadedAssets();
          await _rebuildVisibleMarkers();
        } else {
          // Re-selecting ALL: reuse cache; hide dense meters, show light layers.
          await _rebuildVisibleMarkers();
          if (!mounted || token != _categoryLoadToken) return;
          _zoomToAllLoadedAssets();
        }
        return;
      }

      final layer = _categoryToLayer[cat];
      if (layer == null) return;

      // If already loaded, zoom + rebuild markers, then hide spinner.
      final alreadyLoaded = (_layerData[layer]?.isNotEmpty ?? false);
      if (alreadyLoaded) {
        await _zoomToLayer(layer);
        if (!mounted || token != _categoryLoadToken) return;
        await _rebuildVisibleMarkers();
        return;
      }

      // Otherwise load unfiltered data then zoom — keep spinner until markers show.
      await _loadLayer(layer, clearLoadingWhenDone: false);
      if (!mounted || token != _categoryLoadToken || _selectedCategory != cat) {
        return;
      }
      await _zoomToLayer(layer);
      if (!mounted || token != _categoryLoadToken) return;
      await _rebuildVisibleMarkers();
    } finally {
      if (mounted && token == _categoryLoadToken) {
        setState(() {
          _isLoadingLayers = false;
        });
      }
    }
  }

  Widget _buildSearchControls() {
    final layer = _categoryToLayer[_selectedCategory];
    final columns = _getColumnsForCategory(layer);

    final searchDisabled =
        layer == null || _selectedSearchColumn == null || _isSearching;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              flex: 5,
              child: DropdownButtonFormField<String>(
                value: _selectedSearchColumn,
                isExpanded: true,
                decoration: const InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                  labelText: 'Select Column',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                ),
                items: columns
                    .map(
                      (c) => DropdownMenuItem<String>(
                        value: c.value,
                        child: Text(c.label),
                      ),
                    )
                    .toList(),
                onChanged: layer == null
                    ? null
                    : (value) {
                        setState(() {
                          _selectedSearchColumn = value;
                          _searchError = null;
                        });
                      },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 6,
              child: TextField(
                controller: _searchController,
                enabled: layer != null && _selectedSearchColumn != null,
                decoration: const InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                  labelText: 'Search',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                ),
                onSubmitted: (_) => _handleSearchWithFilter(),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: searchDisabled ? null : _handleSearchWithFilter,
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  backgroundColor: AppTheme.primaryMain,
                  foregroundColor: Colors.white,
                ),
                child: _isSearching
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.search, size: 18),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 44,
              width: 44,
              child: OutlinedButton(
                onPressed: _isLoadingLayers ? null : _refreshMapData,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  foregroundColor: AppTheme.primaryMain,
                  side: const BorderSide(color: AppTheme.primaryMain),
                ),
                child: const Icon(Icons.refresh, size: 18),
              ),
            ),
          ],
        ),
        if (_searchError != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              _searchError!,
              style: TextStyle(color: AppTheme.errorMain, fontSize: 11),
            ),
          ),
      ],
    );
  }

  List<_SearchColumn> _getColumnsForCategory(MapLayerType? layer) {
    if (layer == null) return const [];
    switch (layer) {
      case MapLayerType.customerMeters:
        return const [
          _SearchColumn(value: 'accountNo', label: 'Account No'),
          _SearchColumn(value: 'meterNo', label: 'Meter No'),
          _SearchColumn(value: 'name', label: 'Name'),
          _SearchColumn(value: 'zone', label: 'Zone'),
          _SearchColumn(value: 'route', label: 'Route'),
          _SearchColumn(value: 'dma', label: 'DMA'),
          _SearchColumn(value: 'location', label: 'Location'),
        ];
      case MapLayerType.valves:
        return const [
          _SearchColumn(value: 'objectId', label: 'Object ID'),
          _SearchColumn(value: 'type', label: 'Type'),
          _SearchColumn(value: 'dma', label: 'DMA'),
          _SearchColumn(value: 'status', label: 'Status'),
          _SearchColumn(value: 'size', label: 'Size'),
          _SearchColumn(value: 'schemeName', label: 'Scheme Name'),
          _SearchColumn(value: 'zone', label: 'Zone'),
          _SearchColumn(value: 'route', label: 'Route'),
          _SearchColumn(value: 'location', label: 'Location'),
        ];
      case MapLayerType.masterMeters:
        return const [
          _SearchColumn(value: 'name', label: 'Name'),
          _SearchColumn(value: 'serial', label: 'Serial'),
          _SearchColumn(value: 'zone', label: 'Zone'),
          _SearchColumn(value: 'route', label: 'Route'),
          _SearchColumn(value: 'dma', label: 'DMA'),
          _SearchColumn(value: 'location', label: 'Location'),
        ];
      case MapLayerType.waterTanks:
        return const [
          _SearchColumn(value: 'name', label: 'Name'),
          _SearchColumn(value: 'zone', label: 'Zone'),
          _SearchColumn(value: 'location', label: 'Location'),
        ];
      case MapLayerType.waterPipes:
        return const [
          _SearchColumn(value: 'lineName', label: 'Line Name'),
          _SearchColumn(value: 'lineType', label: 'Line Type'),
          _SearchColumn(value: 'material', label: 'Material'),
          _SearchColumn(value: 'dma', label: 'DMA'),
          _SearchColumn(value: 'zone', label: 'Zone'),
          _SearchColumn(value: 'route', label: 'Route'),
          _SearchColumn(value: 'schemeName', label: 'Scheme Name'),
        ];
      case MapLayerType.washouts:
        return const [
          _SearchColumn(value: 'name', label: 'Name'),
          _SearchColumn(value: 'zone', label: 'Zone'),
          _SearchColumn(value: 'route', label: 'Route'),
          _SearchColumn(value: 'dma', label: 'DMA'),
          _SearchColumn(value: 'location', label: 'Location'),
        ];
      case MapLayerType.kiosks:
        return const [
          _SearchColumn(value: 'name', label: 'Name'),
          _SearchColumn(value: 'zone', label: 'Zone'),
          _SearchColumn(value: 'route', label: 'Route'),
        ];
      case MapLayerType.dormantMeters:
        return const [
          _SearchColumn(value: 'accountNo', label: 'Account No'),
          _SearchColumn(value: 'meterNo', label: 'Meter No'),
          _SearchColumn(value: 'name', label: 'Name'),
          _SearchColumn(value: 'zone', label: 'Zone'),
          _SearchColumn(value: 'route', label: 'Route'),
        ];
      case MapLayerType.sewerLines:
        return const [
          _SearchColumn(value: 'type', label: 'Type'),
          _SearchColumn(value: 'material', label: 'Material'),
          _SearchColumn(value: 'size', label: 'Size'),
          _SearchColumn(value: 'status', label: 'Status'),
          _SearchColumn(value: 'zone', label: 'Zone'),
          _SearchColumn(value: 'route', label: 'Route'),
          _SearchColumn(value: 'schemeName', label: 'Scheme Name'),
        ];
      case MapLayerType.manholes:
        return const [
          _SearchColumn(value: 'ObjectID', label: 'Object ID'),
          _SearchColumn(value: 'name', label: 'Name'),
          _SearchColumn(value: 'status', label: 'Status'),
          _SearchColumn(value: 'route', label: 'Route'),
        ];
    }
  }

  double _markerHue(MapLayerType type) {
    switch (type) {
      case MapLayerType.customerMeters:
        return BitmapDescriptor.hueAzure;
      case MapLayerType.waterPipes:
        return BitmapDescriptor.hueBlue;
      case MapLayerType.waterTanks:
        return BitmapDescriptor.hueCyan;
      case MapLayerType.valves:
        return BitmapDescriptor.hueGreen;
      case MapLayerType.masterMeters:
        return BitmapDescriptor.hueOrange;
      case MapLayerType.washouts:
        return BitmapDescriptor.hueRed;
      case MapLayerType.kiosks:
        return BitmapDescriptor.hueRose;
      case MapLayerType.dormantMeters:
        return BitmapDescriptor.hueViolet;
      case MapLayerType.sewerLines:
        return BitmapDescriptor.hueMagenta;
      case MapLayerType.manholes:
        return BitmapDescriptor.hueYellow;
    }
  }

  Color _legendColor(MapLayerType type) {
    switch (type) {
      case MapLayerType.customerMeters:
        return const Color(0xFF2196F3);
      case MapLayerType.waterTanks:
        return const Color(0xFF00BCD4);
      case MapLayerType.valves:
        return const Color(0xFF4CAF50);
      case MapLayerType.masterMeters:
        return const Color(0xFFFF9800);
      case MapLayerType.washouts:
        return const Color(0xFFF44336);
      case MapLayerType.kiosks:
        return const Color(0xFFE91E63);
      case MapLayerType.dormantMeters:
        return const Color(0xFF9C27B0);
      case MapLayerType.manholes:
        return const Color(0xFFFFC107);
      case MapLayerType.waterPipes:
        return Colors.blueAccent;
      case MapLayerType.sewerLines:
        return Colors.tealAccent.shade700;
    }
  }

  Future<void> _handleSearchWithFilter() async {
    final layer = _categoryToLayer[_selectedCategory];
    if (layer == null) {
      setState(() {
        _searchError = 'Select an asset category first.';
      });
      return;
    }
    if (_selectedSearchColumn == null) {
      setState(() {
        _searchError = 'Select a column to search.';
      });
      return;
    }
    final value = _searchController.text.trim();
    if (value.isEmpty) {
      setState(() {
        _searchError = 'Enter a value to search.';
      });
      return;
    }

    setState(() {
      _searchError = null;
      _isSearching = true;
    });

    try {
      if (layer == MapLayerType.customerMeters) {
        await _ensureCustomerMetersSourceLoaded();
        final source = _customerMetersSource ?? const <_MapFeature>[];
        final filtered = _filterFeatures(
          source,
          _selectedSearchColumn!,
          value,
        );

        if (!mounted) return;
        setState(() {
          _layerData[layer] = filtered;
        });
        _updateZonesWithAssets();
        _rebuildZonePolygons();
        await _rebuildVisibleMarkers();

        if (!mounted) return;
        if (filtered.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'No customer meters found for ${_labelForKey(_selectedSearchColumn!)}: $value',
              ),
            ),
          );
        } else {
          await _zoomToLayer(layer);
          await _rebuildVisibleMarkers();
        }
        return;
      }

      await _loadLayer(layer);
      await _zoomToLayer(layer);
      await _rebuildVisibleMarkers();
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _zoomToLayer(MapLayerType layer) async {
    final features = _layerData[layer] ?? const [];
    if (features.isEmpty) return;

    final bounds = _computeBoundsForActiveAssets(activeLayer: layer);
    if (bounds == null) return;

    final safeBounds = _safeBounds(bounds);

    await _fitBoundsWithRetry(safeBounds, padding: 60);
  }

  Future<void> _zoomToAllLoadedAssets() async {
    if (_allLayersZoomed) return;

    // Prefer densest cluster so we zoom to where assets are many.
    final bounds = _computeDensestClusterBounds(activeLayer: null) ??
        _computeBoundsForActiveAssets(activeLayer: null);
    if (bounds == null) return;

    final safeBounds = _safeBounds(bounds);
    final ok = await _fitBoundsWithRetry(safeBounds, padding: 70);
    if (ok) _allLayersZoomed = true;
  }

  Future<bool> _fitBoundsWithRetry(LatLngBounds bounds,
      {required double padding}) async {
    try {
      final controller = await _controller.future;
      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, padding),
      );
      return true;
    } catch (_) {
      // Often fails if called before the map has a size; retry shortly.
      try {
        await Future.delayed(const Duration(milliseconds: 350));
        final controller = await _controller.future;
        await controller.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, padding),
        );
        return true;
      } catch (_) {
        return false;
      }
    }
  }

  void _scheduleFitToActiveAssets() {
    // Debounce so fit happens after render settles.
    _fitDebounce?.cancel();
    _fitDebounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      final activeLayer = _categoryToLayer[_selectedCategory];
      if (_selectedCategory == 'All') {
        // Keep ALL view fitted as new layers arrive.
        _allLayersZoomed = false;
        _zoomToAllLoadedAssets();
      } else if (activeLayer != null) {
        _zoomToLayer(activeLayer);
      }
    });
  }

  LatLngBounds? _computeBoundsForActiveAssets(
      {required MapLayerType? activeLayer}) {
    LatLngBounds? bounds;

    void extendBounds(LatLng p) {
      if (bounds == null) {
        bounds = LatLngBounds(southwest: p, northeast: p);
      } else {
        final b = bounds!;
        final sw = b.southwest;
        final ne = b.northeast;
        bounds = LatLngBounds(
          southwest: LatLng(
            p.latitude < sw.latitude ? p.latitude : sw.latitude,
            p.longitude < sw.longitude ? p.longitude : sw.longitude,
          ),
          northeast: LatLng(
            p.latitude > ne.latitude ? p.latitude : ne.latitude,
            p.longitude > ne.longitude ? p.longitude : ne.longitude,
          ),
        );
      }
    }

    _layerData.forEach((type, features) {
      if (activeLayer != null && activeLayer != type) return;
      for (final f in features) {
        if (f.point != null) extendBounds(f.point!);
        final line = f.line;
        if (line != null) {
          for (final p in line) {
            extendBounds(p);
          }
        }
      }
    });

    return bounds;
  }

  LatLngBounds? _computeDensestClusterBounds(
      {required MapLayerType? activeLayer}) {
    // Bin points into a fixed lat/lon grid and choose the busiest cell.
    // This is a lightweight alternative to full clustering and gives an
    // admin-like "zoom to where assets are many" behavior.
    const cellSizeDeg = 0.01; // ~1km grid
    final bins = <String, List<LatLng>>{};

    void addPoint(LatLng p) {
      final gx = (p.longitude / cellSizeDeg).floor();
      final gy = (p.latitude / cellSizeDeg).floor();
      final key = '$gx:$gy';
      (bins[key] ??= <LatLng>[]).add(p);
    }

    _layerData.forEach((type, features) {
      if (activeLayer != null && activeLayer != type) return;
      for (final f in features) {
        if (f.point != null) addPoint(f.point!);
      }
    });

    if (bins.isEmpty) return null;

    String? bestKey;
    var bestCount = 0;
    bins.forEach((k, pts) {
      if (pts.length > bestCount) {
        bestKey = k;
        bestCount = pts.length;
      }
    });

    // If not enough points to be considered a "cluster", fall back to full extent.
    if (bestKey == null || bestCount < 5) return null;

    final pts = bins[bestKey]!;
    LatLngBounds? bounds;
    for (final p in pts) {
      if (bounds == null) {
        bounds = LatLngBounds(southwest: p, northeast: p);
      } else {
        final b = bounds;
        final sw = b.southwest;
        final ne = b.northeast;
        bounds = LatLngBounds(
          southwest: LatLng(
            p.latitude < sw.latitude ? p.latitude : sw.latitude,
            p.longitude < sw.longitude ? p.longitude : sw.longitude,
          ),
          northeast: LatLng(
            p.latitude > ne.latitude ? p.latitude : ne.latitude,
            p.longitude > ne.longitude ? p.longitude : ne.longitude,
          ),
        );
      }
    }
    return bounds;
  }

  LatLngBounds _safeBounds(LatLngBounds b) {
    // GoogleMap can throw if bounds are too small (same SW/NE). Expand slightly.
    const eps = 0.0005; // ~50m-ish; good enough for camera fit stability
    final sw = b.southwest;
    final ne = b.northeast;
    final sameLat = (sw.latitude - ne.latitude).abs() < 1e-12;
    final sameLon = (sw.longitude - ne.longitude).abs() < 1e-12;
    if (!sameLat && !sameLon) return b;
    return LatLngBounds(
      southwest: LatLng(
        sw.latitude - (sameLat ? eps : 0),
        sw.longitude - (sameLon ? eps : 0),
      ),
      northeast: LatLng(
        ne.latitude + (sameLat ? eps : 0),
        ne.longitude + (sameLon ? eps : 0),
      ),
    );
  }
}
