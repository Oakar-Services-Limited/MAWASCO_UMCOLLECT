import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class MyMap extends StatefulWidget {
  final double lat;
  final double lon;
  final double acc;

  const MyMap(
      {super.key, required this.lat, required this.lon, required this.acc});

  @override
  State<MyMap> createState() => _MyMapState();
}

class _MyMapState extends State<MyMap> {
  final Completer<GoogleMapController?> _controller = Completer();
  Marker? sourcePosition;
  late BitmapDescriptor _vehicleIcon;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  var isLoading = true; // Changed to bool for simplicity
  LatLng curLocation = const LatLng(-1.2940491, 36.8076449);
  final storage = const FlutterSecureStorage();
  String editing = 'false';
  bool updating = false;

  /// QGIS-like emphasis: tap the location pin to toggle a strong red halo;
  /// a softer yellow ring is always shown so the active point stays visible.
  bool _gpsPointTappedHighlight = false;

  static const Color _haloYellowStroke = Color(0xFFFFC107);
  static const Color _haloYellowFill = Color(0x4DFFEE58);
  static const Color _haloRedStroke = Color(0xFFE53935);
  static const Color _haloRedFill = Color(0x40E53935);

  @override
  void initState() {
    super.initState();
    setState(() {
      isLoading = true;
      curLocation = LatLng(widget.lat, widget.lon);
    });
    addMarker();
    checkEditing();
  }

  Future<void> checkEditing() async {
    String? d = await storage.read(key: "editing");
    if (d != null) {
      setState(() {
        editing = d;
      });
    }
  }

  Future<void> addMarker() async {
    _vehicleIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(devicePixelRatio: 0.5),
      'assets/images/loc.png',
    );
    setState(() {
      sourcePosition = _buildSourceMarker(curLocation);
    });
  }

  void _onGpsMarkerTap() {
    setState(() {
      _gpsPointTappedHighlight = !_gpsPointTappedHighlight;
    });
  }

  Marker _buildSourceMarker(LatLng position) {
    return Marker(
      markerId: const MarkerId('source'),
      position: position,
      icon: _vehicleIcon,
      anchor: const Offset(0.5, 0.5),
      onTap: _onGpsMarkerTap,
    );
  }

  Set<Circle> _gpsSelectionHalos() {
    return {
      Circle(
        circleId: const CircleId('gps_selection_halo'),
        center: curLocation,
        radius: _gpsPointTappedHighlight ? 22 : 14,
        strokeWidth: _gpsPointTappedHighlight ? 4 : 2,
        strokeColor:
            _gpsPointTappedHighlight ? _haloRedStroke : _haloYellowStroke,
        fillColor: _gpsPointTappedHighlight ? _haloRedFill : _haloYellowFill,
      ),
    };
  }

  @override
  void didUpdateWidget(covariant MyMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lat != widget.lat || oldWidget.lon != widget.lon) {
      _updateCameraPosition(LatLng(widget.lat, widget.lon));
      setState(() {
        _gpsPointTappedHighlight = false;
        curLocation = LatLng(widget.lat, widget.lon);
        if (sourcePosition != null) {
          sourcePosition =
              sourcePosition!.copyWith(positionParam: LatLng(widget.lat, widget.lon));
        }
      });
    }
  }

  void _updateCameraPosition(LatLng newPosition) async {
    try {
      final GoogleMapController? controller = await _controller.future;
      await controller?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: newPosition,
            zoom: 20,
          ),
        ),
      );
    } catch (e) {
      // Error handling: silently ignore errors
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Card(
          clipBehavior: Clip.hardEdge,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: BorderSide(
              color: _gpsPointTappedHighlight ? _haloRedStroke : Colors.transparent,
              width: _gpsPointTappedHighlight ? 3 : 0,
            ),
          ),
          child: GoogleMap(
            zoomControlsEnabled: false,
            mapType: MapType.satellite,
            initialCameraPosition: CameraPosition(
              target: curLocation,
              zoom: 12,
            ),
            markers: sourcePosition != null ? {sourcePosition!} : {},
            circles: _gpsSelectionHalos(),
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
              setState(() {
                isLoading = false;
              });
            },
          ),
        ),
        Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                    child: Text("Accuracy: ${widget.acc.floorToDouble()}"),
                  )),
            )),
        Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                    child: Text("Lat: ${widget.lat}"),
                  )),
            )),
        Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                    child: Text("Lon: ${widget.lon}"),
                  )),
            )),
        if (isLoading)
          Center(
            child: LoadingAnimationWidget.horizontalRotatingDots(
                color: Colors.yellow, size: 100),
          ),
        if (editing == 'true')
          Align(
              alignment: Alignment.center,
              child: ElevatedButton(
                  style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(
                          updating ? Colors.orange : const Color(0xff0288D1))),
                  onPressed: () {
                    if (!updating) {
                      storage.write(key: "updateLocation", value: 'true');
                    } else {
                      storage.delete(key: "updateLocation");
                    }

                    setState(() {
                      updating = !updating;
                    });
                  },
                  child: Text(
                    updating
                        ? "Click to disable location update"
                        : "Click to Allow Location Update",
                    style: const TextStyle(color: Colors.white),
                  )))
      ],
    );
  }
}
