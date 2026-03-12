import 'dart:async';
import 'dart:convert';

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

class _MapFeature {
  final String id;
  final String name;
  final MapLayerType type;
  final LatLng? point;
  final List<LatLng>? line;
  final String? zoneId;

  _MapFeature({
    required this.id,
    required this.name,
    required this.type,
    this.point,
    this.line,
    this.zoneId,
  });
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
  MapType _mapType = MapType.normal;
  double _nearbyRadiusMeters = 100;
  String _nearbyUnit = 'm'; // 'm' or 'km'
  String _nearbyText = '100';
  final TextEditingController _nearbyController =
      TextEditingController(text: '100');

  String _selectedCategory = 'All';
  String? _selectedSearchColumn;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String? _searchError;
  bool _allLayersRequested = false;
  bool _allLayersZoomed = false;
  Timer? _fitDebounce;

  // Toggle to enable verbose debugging logs
  static const bool _debugMap = true;

  bool _legendOpen = false;

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
    _searchController.dispose();
    _nearbyController.dispose();
    _fitDebounce?.cancel();
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
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: zoom),
        ),
      );
    } catch (_) {}
  }

  Future<void> _loadLayer(MapLayerType type) async {
    setState(() {
      _isLoadingLayers = true;
    });

    try {
      final uri = _buildLayerUri(type);
      if (uri == null) {
        setState(() {
          _isLoadingLayers = false;
        });
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
        setState(() {
          _isLoadingLayers = false;
        });
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

      setState(() {
        _layerData[type] = features;
        _isLoadingLayers = false;
      });
      _updateZonesWithAssets();
      _rebuildZonePolygons();
      _scheduleFitToActiveAssets();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingLayers = false;
      });
    }
  }

  Uri? _buildLayerUri(MapLayerType type) {
    final base = getUrl();
    const denseLimit = 1000;
    final layerFilter = _buildLayerFilter(type);
    switch (type) {
      case MapLayerType.customerMeters:
        return Uri.parse(
            '${base}wt/customer-meters?limit=$denseLimit&offset=0$layerFilter');
      case MapLayerType.waterPipes:
        return Uri.parse(
            '${base}wt/water-pipes?limit=$denseLimit&offset=0$layerFilter');
      case MapLayerType.waterTanks:
        return Uri.parse(
            '${base}wt/tanks?limit=$denseLimit&offset=0$layerFilter');
      case MapLayerType.valves:
        return Uri.parse(
            '${base}wt/valves?limit=$denseLimit&offset=0$layerFilter');
      case MapLayerType.masterMeters:
        return Uri.parse(
            '${base}wt/master-meters?limit=$denseLimit&offset=0$layerFilter');
      case MapLayerType.washouts:
        return Uri.parse(
            '${base}wt/washouts?limit=$denseLimit&offset=0$layerFilter');
      case MapLayerType.kiosks:
        return Uri.parse(
            '${base}wt/kiosks?limit=$denseLimit&offset=0$layerFilter');
      case MapLayerType.dormantMeters:
        return Uri.parse(
            '${base}wt/dormant-customer-meters?limit=$denseLimit&offset=0$layerFilter');
      case MapLayerType.sewerLines:
        return Uri.parse(
            '${base}sr/sewer-lines?limit=$denseLimit&offset=0$layerFilter');
      case MapLayerType.manholes:
        return Uri.parse(
            '${base}sr/manholes?limit=$denseLimit&offset=0$layerFilter');
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
          return _MapFeature(
            id: id,
            name: name,
            type: type,
            line: points,
            zoneId: zoneId,
          );
        }

        if (_debugMap && type == MapLayerType.sewerLines) {
          debugPrint(
              '[Map] Skipping sewer line id=$id: no drawable points. coordinates=${raw['coordinates']?.runtimeType} geom=${raw['geom']?.runtimeType}');
        }
        return null;
      }

      final lat = double.tryParse(raw['latitude']?.toString() ?? '');
      final lon = double.tryParse(raw['longitude']?.toString() ?? '');
      if (lat == null || lon == null) return null;

      return _MapFeature(
        id: id,
        name: name,
        type: type,
        point: LatLng(lat, lon),
        zoneId: zoneId,
      );
    } catch (_) {
      return null;
    }
  }

  Set<Marker> get _markers {
    final markers = <Marker>{};
    _layerData.forEach((type, features) {
      // If a specific category is selected, only show that layer
      final activeLayer = _categoryToLayer[_selectedCategory];
      if (activeLayer != null && activeLayer != type) return;

      for (final f in features) {
        if (f.point == null) continue;
        markers.add(
          Marker(
            markerId: MarkerId('${type.name}_${f.id}'),
            position: f.point!,
            infoWindow: InfoWindow(title: f.name),
            icon: BitmapDescriptor.defaultMarkerWithHue(_markerHue(type)),
          ),
        );
      }
    });
    return markers;
  }

  Set<Polyline> get _polylines {
    final lines = <Polyline>{};
    _layerData.forEach((type, features) {
      final activeLayer = _categoryToLayer[_selectedCategory];
      if (activeLayer != null && activeLayer != type) return;

      for (final f in features) {
        if (f.line == null || f.line!.length < 2) continue;
        lines.add(
          Polyline(
            polylineId: PolylineId('${type.name}_${f.id}'),
            points: f.line!,
            color: type == MapLayerType.waterPipes
                ? Colors.blueAccent
                : Colors.tealAccent.shade700,
            width: 4,
          ),
        );
      }
    });
    return lines;
  }

  Future<void> _findNearby() async {
    final allPoints = <_MapFeature>[];
    _layerData.forEach((type, features) {
      final activeLayer = _categoryToLayer[_selectedCategory];
      if (activeLayer != null && activeLayer != type) return;
      allPoints.addAll(features.where((f) => f.point != null));
    });

    if (allPoints.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No assets loaded for nearby search.'),
        ),
      );
      return;
    }

    final nearby = <_MapFeature>[];
    for (final f in allPoints) {
      final p = f.point!;
      final d = Geolocator.distanceBetween(
        _currentLocation.latitude,
        _currentLocation.longitude,
        p.latitude,
        p.longitude,
      );
      if (d <= _nearbyRadiusMeters) {
        nearby.add(f);
      }
    }

    if (!mounted) return;

    if (nearby.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('No assets found within ${_nearbyRadiusMeters.toInt()} m.'),
        ),
      );
      return;
    }

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
                  itemCount: nearby.length,
                  itemBuilder: (context, index) {
                    final f = nearby[index];
                    return ListTile(
                      leading: Icon(Icons.place, color: AppTheme.primaryMain),
                      title: Text(f.name.isEmpty ? f.id : f.name),
                      subtitle: Text(f.type.name),
                      onTap: () {
                        Navigator.pop(context);
                        if (f.point != null) {
                          _animateTo(f.point!, zoom: 18);
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

  void _openBufferSheet() {
    // Keep controller in sync with current stored text.
    _nearbyController.text = _nearbyText;
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
    });
    await _initLocation();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

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
            markers: _markers,
            polylines: _polylines,
            polygons: _zonePolygons,
            onMapCreated: (controller) {
              _controller.complete(controller);
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
            bottom: 12 + MediaQuery.of(context).padding.bottom,
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
          if (_isLoadingLocation || _isLoadingLayers)
            Positioned(
              top: 16,
              right: 16,
              child: Card(
                elevation: 4,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LoadingAnimationWidget.horizontalRotatingDots(
                        color: AppTheme.primaryMain,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isLoadingLocation
                            ? 'Getting location…'
                            : 'Loading layers…',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'recenter_fab',
            mini: true,
            onPressed: _recenter,
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.primaryMain,
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'basemap_fab',
            mini: true,
            onPressed: _toggleMapType,
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.primaryMain,
            child: Icon(
              _mapType == MapType.normal
                  ? Icons.satellite_alt
                  : Icons.map_outlined,
            ),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'buffer_fab',
            mini: true,
            onPressed: _openBufferSheet,
            backgroundColor: AppTheme.primaryMain,
            foregroundColor: Colors.white,
            child: const Icon(Icons.radar),
          ),
        ],
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
    setState(() {
      _selectedCategory = cat;
      _selectedSearchColumn = null;
      _searchError = null;
      _searchController.clear();
    });
    _ensureCategoryLoaded(cat);
  }

  void _ensureCategoryLoaded(String cat) {
    if (cat == 'All') {
      if (!_allLayersRequested) {
        _allLayersRequested = true;
        _allLayersZoomed = false;
        // Load all layers in background, then auto-fit to their combined extent.
        Future.wait(MapLayerType.values.map(_loadLayer)).then((_) {
          if (!mounted) return;
          _zoomToAllLoadedAssets();
        });
      } else {
        // Re-selecting ALL: if assets already loaded, fit immediately.
        _zoomToAllLoadedAssets();
      }
      return;
    }

    final layer = _categoryToLayer[cat];
    if (layer == null) return;

    // If already loaded, just zoom to it for immediate feedback.
    final alreadyLoaded = (_layerData[layer]?.isNotEmpty ?? false);
    if (alreadyLoaded) {
      _zoomToLayer(layer);
      return;
    }

    // Otherwise load unfiltered data then zoom.
    _loadLayer(layer).then((_) {
      _zoomToLayer(layer);
    });
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
      await _loadLayer(layer);
      await _zoomToLayer(layer);
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
