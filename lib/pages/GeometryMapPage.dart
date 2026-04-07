// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:um_collect/services/connectivity_helper.dart';
import 'package:um_collect/theme/app_theme.dart';

class GeometryMapPage extends StatefulWidget {
  final String geometryType;
  final dynamic initialGeometry;
  final String fieldLabel;

  const GeometryMapPage({
    super.key,
    required this.geometryType,
    this.initialGeometry,
    required this.fieldLabel,
  });

  @override
  State<GeometryMapPage> createState() => _GeometryMapPageState();
}

class _GeometryMapPageState extends State<GeometryMapPage> {
  final Completer<GoogleMapController> _controller = Completer();
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final Set<Polygon> _polygons = {};
  LatLng _currentLocation = const LatLng(-1.2940491, 36.8076449);
  List<LatLng> _selectedPoints = [];
  bool _isLoading = true;
  bool _isGettingGps = false;
  bool _isTracking = false;
  Timer? _trackingTimer;
  double _totalDistance = 0.0; // Distance in meters
  Map<String, dynamic>? _currentGeometry;
  bool _isOnline = true;
  StreamSubscription<bool>? _connectivitySub;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadInitialGeometry();
    _listenToConnectivity();
  }

  @override
  void dispose() {
    _trackingTimer?.cancel();
    _connectivitySub?.cancel();
    super.dispose();
  }

  void _listenToConnectivity() {
    _connectivitySub =
        ConnectivityHelper().connectivityStream.listen((isOnline) {
      if (!mounted) return;
      setState(() {
        _isOnline = isOnline;
      });
    });
    // Seed initial state
    ConnectivityHelper().checkConnectivity().then((isOnline) {
      if (!mounted) return;
      setState(() {
        _isOnline = isOnline;
      });
    });
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
  }

  void _startTracking() async {
    if (_isTracking || widget.geometryType == 'POINT') return;

    // Request permission first
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      return;
    }

    // Get initial position
    try {
      Position initialPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );
      if (!mounted) return;

      final initialPoint =
          LatLng(initialPosition.latitude, initialPosition.longitude);

      setState(() {
        _isTracking = true;
        _currentLocation = initialPoint;
        if (_selectedPoints.isEmpty) {
          _selectedPoints = [initialPoint];
          _updateMarkers();
        } else {
          // Calculate distance from last point
          final lastPoint = _selectedPoints.last;
          final distance = _calculateDistance(lastPoint, initialPoint);
          _totalDistance += distance;

          _selectedPoints.add(initialPoint);
          _updateMarkers();
          _updatePolylines();
          _updatePolygons();
        }
        _createGeometry();
      });
      _updateCamera();

      // Start timer to update every minute
      _trackingTimer =
          Timer.periodic(const Duration(minutes: 1), (timer) async {
        if (!mounted || !_isTracking) {
          timer.cancel();
          return;
        }

        try {
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.bestForNavigation,
          );
          if (!mounted || !_isTracking) return;

          final point = LatLng(position.latitude, position.longitude);
          final lastPoint =
              _selectedPoints.isNotEmpty ? _selectedPoints.last : point;

          // Calculate distance moved
          final distance = _calculateDistance(lastPoint, point);

          // Only add point if moved at least 5 meters (to avoid duplicate points)
          if (distance >= 5.0) {
            setState(() {
              _totalDistance += distance;
              _currentLocation = point;
              _selectedPoints.add(point);
              _updateMarkers();
              _updatePolylines();
              _updatePolygons();
              _createGeometry();
            });
            _updateCamera();
          }
        } catch (e) {
          // Error getting location, continue tracking
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isTracking = false);
      }
    }
  }

  void _stopTracking() {
    setState(() {
      _isTracking = false;
    });
    _trackingTimer?.cancel();
    _trackingTimer = null;
  }

  Future<void> _getAndApplyGpsLocation() async {
    if (_isGettingGps || !mounted) return;
    setState(() => _isGettingGps = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _isGettingGps = false);
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) setState(() => _isGettingGps = false);
          return;
        }
      }
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        if (mounted) setState(() => _isGettingGps = false);
        return;
      }
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );
      if (!mounted) return;
      final point = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentLocation = point;
        if (widget.geometryType == 'POINT') {
          _selectedPoints = [point];
          _updateMarkers();
        } else {
          _selectedPoints.add(point);
          _updateMarkers();
          _updatePolylines();
          _updatePolygons();
        }
        _createGeometry();
        _isGettingGps = false;
      });
      _updateCamera();
    } catch (e) {
      if (mounted) setState(() => _isGettingGps = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.bestForNavigation,
        );
        if (!mounted) return;
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _isLoading = false;
        });
        _updateCamera();
      } else {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _loadInitialGeometry() {
    if (widget.initialGeometry != null) {
      try {
        Map<String, dynamic> geometry = widget.initialGeometry is String
            ? jsonDecode(widget.initialGeometry)
            : widget.initialGeometry;

        String type = geometry['type']?.toString().toUpperCase() ?? 'POINT';
        List coordinates = geometry['coordinates'] ?? [];

        if (type == 'POINT' && coordinates.length >= 2) {
          LatLng point = LatLng(
            coordinates[1].toDouble(),
            coordinates[0].toDouble(),
          );
          _selectedPoints = [point];
          _updateMarkers();
          _currentLocation = point;
        } else if (type == 'LINESTRING' && coordinates.isNotEmpty) {
          _selectedPoints = coordinates.map((coord) {
            return LatLng(coord[1].toDouble(), coord[0].toDouble());
          }).toList();
          _updateMarkers();
          _updatePolylines();
          if (_selectedPoints.isNotEmpty) {
            _currentLocation = _selectedPoints.first;
          }
        } else if (type == 'POLYGON' && coordinates.isNotEmpty) {
          List ring = coordinates[0];
          _selectedPoints = ring.map((coord) {
            return LatLng(coord[1].toDouble(), coord[0].toDouble());
          }).toList();
          _updateMarkers();
          _updatePolygons();
          if (_selectedPoints.isNotEmpty) {
            _currentLocation = _selectedPoints.first;
          }
        }
        _createGeometry();
      } catch (e) {
        // Error parsing initial geometry
      }
    }
  }

  void _updateCamera() async {
    try {
      final GoogleMapController controller = await _controller.future;
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _currentLocation,
            zoom: _selectedPoints.isEmpty ? 15.0 : 18.0,
          ),
        ),
      );
    } catch (e) {
      // Error updating camera
    }
  }

  void _onMapTap(LatLng position) {
    setState(() {
      if (widget.geometryType == 'POINT') {
        _selectedPoints = [position];
        _updateMarkers();
        _createGeometry();
      } else if (widget.geometryType == 'LINESTRING') {
        _selectedPoints.add(position);
        _updateMarkers();
        _updatePolylines();
        _createGeometry();
      } else if (widget.geometryType == 'POLYGON') {
        _selectedPoints.add(position);
        _updateMarkers();
        _updatePolygons();
        _createGeometry();
      }
    });
  }

  void _updateMarkers() {
    _markers.clear();
    for (int i = 0; i < _selectedPoints.length; i++) {
      _markers.add(
        Marker(
          markerId: MarkerId('point_$i'),
          position: _selectedPoints[i],
          icon: BitmapDescriptor.defaultMarkerWithHue(
            widget.geometryType == 'POINT'
                ? BitmapDescriptor.hueRed
                : BitmapDescriptor.hueBlue,
          ),
        ),
      );
    }
  }

  void _updatePolylines() {
    _polylines.clear();
    if (_selectedPoints.length > 1) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('line'),
          points: _selectedPoints,
          color: AppTheme.primaryMain,
          width: 3,
        ),
      );
    }
  }

  void _updatePolygons() {
    _polygons.clear();
    if (_selectedPoints.length >= 3) {
      _polygons.add(
        Polygon(
          polygonId: const PolygonId('polygon'),
          points: _selectedPoints,
          strokeColor: AppTheme.primaryMain,
          fillColor: AppTheme.primaryMain.withValues(alpha: 0.2),
          strokeWidth: 3,
        ),
      );
    }
  }

  void _createGeometry() {
    if (_selectedPoints.isEmpty) {
      _currentGeometry = null;
      return;
    }

    Map<String, dynamic> geometry;

    if (widget.geometryType == 'POINT') {
      geometry = {
        'type': 'Point',
        'coordinates': [
          _selectedPoints[0].longitude,
          _selectedPoints[0].latitude,
        ],
      };
    } else if (widget.geometryType == 'LINESTRING') {
      geometry = {
        'type': 'LineString',
        'coordinates': _selectedPoints.map((point) {
          return [point.longitude, point.latitude];
        }).toList(),
      };
    } else if (widget.geometryType == 'POLYGON') {
      // Close the polygon
      List<List<double>> coordinates = _selectedPoints.map((point) {
        return [point.longitude, point.latitude];
      }).toList();
      coordinates
          .add([_selectedPoints[0].longitude, _selectedPoints[0].latitude]);

      geometry = {
        'type': 'Polygon',
        'coordinates': [coordinates],
      };
    } else {
      return;
    }

    _currentGeometry = geometry;
  }

  void _saveAndReturn() {
    Navigator.pop(context, _currentGeometry);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.fieldLabel,
          style: TextStyle(
            color: Colors.white,
            fontSize:
                (MediaQuery.of(context).size.width * 0.045).clamp(16.0, 20.0),
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.primaryMain,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          if (_currentGeometry != null)
            TextButton.icon(
              onPressed: _saveAndReturn,
              icon: Icon(
                Icons.check,
                color: Colors.white,
                size: MediaQuery.of(context).size.width * 0.055,
              ),
              label: Text(
                'Save',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: (MediaQuery.of(context).size.width * 0.038)
                      .clamp(14.0, 16.0),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentLocation,
              zoom: 15,
            ),
            mapType: MapType.normal,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
            markers: _markers,
            polylines: _polylines,
            polygons: _polygons,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
              if (_selectedPoints.isNotEmpty) {
                _updateCamera();
              }
            },
            onTap: _onMapTap,
          ),
          if (!_isOnline)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 12,
              right: 12,
              child: Card(
                color: Colors.amber[100],
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.wifi_off,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Offline mode: map tiles and routing may be unavailable, '
                          'but GNSS capture (GPS/GLONASS/GALILEO/BeiDou on supported devices) '
                          'and drawing geometry still work. Geometry will be '
                          'saved locally and synced when back online.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_isLoading)
            Container(
              color: Colors.white.withValues(alpha: 0.8),
              child: Center(
                child: LoadingAnimationWidget.horizontalRotatingDots(
                  color: AppTheme.primaryMain,
                  size: (MediaQuery.of(context).size.width * 0.12)
                      .clamp(40.0, 60.0),
                ),
              ),
            ),
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom +
                (MediaQuery.of(context).size.height * 0.02).clamp(12.0, 20.0),
            left: (MediaQuery.of(context).size.width * 0.03).clamp(12.0, 16.0),
            right: (MediaQuery.of(context).size.width * 0.03).clamp(12.0, 16.0),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  (MediaQuery.of(context).size.width * 0.04).clamp(12.0, 20.0),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.045,
                  vertical: MediaQuery.of(context).size.height * 0.018,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          widget.geometryType == 'POINT'
                              ? Icons.location_on
                              : widget.geometryType == 'LINESTRING'
                                  ? Icons.timeline
                                  : Icons.map,
                          color: AppTheme.primaryMain,
                          size: MediaQuery.of(context).size.width * 0.07,
                        ),
                        SizedBox(
                            width: MediaQuery.of(context).size.width * 0.03),
                        Expanded(
                          child: Text(
                            widget.geometryType == 'POINT'
                                ? 'Tap map or use GPS'
                                : 'Tap map or add GPS (${_selectedPoints.length})',
                            style: TextStyle(
                              fontSize:
                                  (MediaQuery.of(context).size.width * 0.042)
                                      .clamp(14.0, 18.0),
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        if (_selectedPoints.isNotEmpty)
                          IconButton(
                            icon: Icon(
                              Icons.clear,
                              size: MediaQuery.of(context).size.width * 0.065,
                            ),
                            onPressed: () {
                              setState(() {
                                _selectedPoints.clear();
                                _markers.clear();
                                _polylines.clear();
                                _polygons.clear();
                                _currentGeometry = null;
                              });
                            },
                            tooltip: 'Clear all',
                            padding: EdgeInsets.all(
                                MediaQuery.of(context).size.width * 0.02),
                          ),
                      ],
                    ),
                    SizedBox(
                        height: MediaQuery.of(context).size.height * 0.015),
                    if (_isTracking && widget.geometryType != 'POINT')
                      Container(
                        padding: EdgeInsets.symmetric(
                          vertical: MediaQuery.of(context).size.height * 0.012,
                          horizontal: MediaQuery.of(context).size.width * 0.035,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.successMain.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(
                            (MediaQuery.of(context).size.width * 0.03)
                                .clamp(10.0, 14.0),
                          ),
                          border: Border.all(
                            color: AppTheme.successMain.withValues(alpha: 0.3),
                            width: (MediaQuery.of(context).size.width * 0.004)
                                .clamp(1.0, 2.0),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.my_location,
                              size: MediaQuery.of(context).size.width * 0.055,
                              color: AppTheme.successMain,
                            ),
                            SizedBox(
                                width:
                                    MediaQuery.of(context).size.width * 0.03),
                            Expanded(
                              child: Text(
                                'Tracking: ${(_totalDistance / 1000).toStringAsFixed(2)} km',
                                style: TextStyle(
                                  fontSize: (MediaQuery.of(context).size.width *
                                          0.038)
                                      .clamp(13.0, 16.0),
                                  color: AppTheme.successMain,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_isTracking && widget.geometryType != 'POINT')
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.012),
                    Row(
                      children: [
                        if (widget.geometryType != 'POINT')
                          Expanded(
                            child: FilledButton.icon(
                              onPressed:
                                  _isTracking ? _stopTracking : _startTracking,
                              icon: _isTracking
                                  ? Icon(
                                      Icons.stop_circle,
                                      size: MediaQuery.of(context).size.width *
                                          0.055,
                                    )
                                  : Icon(
                                      Icons.gps_fixed,
                                      size: MediaQuery.of(context).size.width *
                                          0.055,
                                    ),
                              label: Text(
                                _isTracking
                                    ? 'Stop tracking'
                                    : 'Start GPS tracking',
                                style: TextStyle(
                                  fontSize: (MediaQuery.of(context).size.width *
                                          0.038)
                                      .clamp(13.0, 16.0),
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: _isTracking
                                    ? AppTheme.errorMain
                                    : AppTheme.successMain,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  vertical: MediaQuery.of(context).size.height *
                                      0.016,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    (MediaQuery.of(context).size.width * 0.03)
                                        .clamp(10.0, 14.0),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (widget.geometryType != 'POINT')
                          SizedBox(
                              width: MediaQuery.of(context).size.width * 0.03),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _isGettingGps || _isTracking
                                ? null
                                : _getAndApplyGpsLocation,
                            icon: _isGettingGps
                                ? SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        0.055,
                                    height: MediaQuery.of(context).size.width *
                                        0.055,
                                    child: CircularProgressIndicator(
                                      strokeWidth:
                                          (MediaQuery.of(context).size.width *
                                                  0.006)
                                              .clamp(2.0, 3.0),
                                    ),
                                  )
                                : Icon(
                                    Icons.gps_fixed,
                                    size: MediaQuery.of(context).size.width *
                                        0.055,
                                  ),
                            label: Text(
                              _isGettingGps
                                  ? 'Getting location…'
                                  : 'Add GPS point',
                              style: TextStyle(
                                fontSize:
                                    (MediaQuery.of(context).size.width * 0.038)
                                        .clamp(13.0, 16.0),
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.primaryMain,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                vertical:
                                    MediaQuery.of(context).size.height * 0.016,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  (MediaQuery.of(context).size.width * 0.03)
                                      .clamp(10.0, 14.0),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
