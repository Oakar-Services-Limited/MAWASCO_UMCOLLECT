import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:um_collect/components/StaffDrawer.dart';
import 'package:um_collect/pages/Assets.dart';
import 'package:um_collect/pages/Forms/ConsumerLine.dart';
import 'package:um_collect/pages/Forms/CustomerLines.dart';
import 'package:um_collect/pages/Forms/LineProjects.dart';
import 'package:um_collect/pages/Forms/SewerLines.dart';
import 'package:um_collect/pages/Forms/SewerMainTrunk.dart';
import 'package:um_collect/pages/Forms/WaterPipes.dart';

class MappingLines extends StatefulWidget {
  final String assetName;
  final String staffid;
  const MappingLines(
      {super.key, required this.assetName, required this.staffid});

  @override
  _MappingLinesState createState() => _MappingLinesState();
}

class _MappingLinesState extends State<MappingLines> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Completer<GoogleMapController> _mapController = Completer();
  LatLng _currentLocation = const LatLng(0, 0);
  Marker _locMarker = const Marker(markerId: MarkerId("value"));
  final Set<Marker> _markers = {};
  late BitmapDescriptor _locIcon;
  late BitmapDescriptor _closeIcon;
  List<Map<String, double>> _coordinates = [];
  final storage = const FlutterSecureStorage();
  bool isDragged = false;
  final Set<Polyline> _polylines = {};
  late BuildContext _context;
  StreamSubscription<Position>? positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    storage.delete(key: "coordinates");
    _loadMarkerIcon();
    _loadCoordinates();
    _listenToLocationUpdates();
  }

  void _listenToLocationUpdates() {
    try {
      positionStreamSubscription = Geolocator.getPositionStream(
              locationSettings: const LocationSettings(
                  accuracy: LocationAccuracy.high, distanceFilter: 0))
          .listen((Position position) async {
        if (!isDragged) {
          setState(() {
            _currentLocation = LatLng(position.latitude, position.longitude);
            _updateCoordinate(_currentLocation);
          });
          GoogleMapController controller = await _mapController.future;
          controller.animateCamera(CameraUpdate.newCameraPosition(
              CameraPosition(target: _currentLocation, bearing: 0, zoom: 20)));
        }
      });
    } catch (e) {
      // Error handling: silently ignore errors
    }
  }

  void _loadCoordinates() async {
    String? storedData = await storage.read(key: 'coordinates');
    if (storedData != null) {
      final Iterable decoded = json.decode(storedData);
      setState(() {
        _coordinates = decoded
            .map<Map<String, double>>((coordinate) {
              if (coordinate is Map<String, dynamic> &&
                  coordinate.containsKey('latitude') &&
                  coordinate.containsKey('longitude')) {
                return {
                  'latitude': coordinate['latitude'] is double
                      ? coordinate['latitude']
                      : double.parse(coordinate['latitude'].toString()),
                  'longitude': coordinate['longitude'] is double
                      ? coordinate['longitude']
                      : double.parse(coordinate['longitude'].toString()),
                };
              } else {
                return {
                  'latitude': coordinate['latitude'] is double
                      ? coordinate['latitude']
                      : double.parse(coordinate['latitude'].toString()),
                  'longitude': coordinate['longitude'] is double
                      ? coordinate['longitude']
                      : double.parse(coordinate['longitude'].toString()),
                };
              }
            })
            .where((element) => element != null)
            .toList();

        if (_coordinates.isNotEmpty) {
          _markers.addAll(_coordinates.map((coordinate) {
            return Marker(
                markerId: MarkerId(coordinate.toString()),
                position:
                    LatLng(coordinate['latitude']!, coordinate['longitude']!),
                icon: _closeIcon,
                onTap: () {
                  _removeCoordinate(coordinate);
                },
                anchor: const Offset(0.5, 0.5));
          }));
        }

        // Create a polyline from the coordinates
        if (_coordinates.length > 1) {
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('route'),
              points: _coordinates.map((coordinate) {
                return LatLng(
                    coordinate['latitude']!, coordinate['longitude']!);
              }).toList(),
              color: Colors.blue,
              width: 5,
            ),
          );
        }
      });
    }
  }

  void _saveCoordinates(LatLng position) async {
    Map<String, double> c = {
      "latitude": position.latitude,
      "longitude": position.longitude
    };
    setState(() {
      isDragged = false;
      _coordinates.add(c);
    });
    await storage.write(
      key: 'coordinates',
      value: json.encode(_coordinates),
    );
    _showSnackbar(context, "Point mapped successfully!", Colors.green);
    _loadCoordinates();
  }

  void _loadMarkerIcon() async {
    _locIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(devicePixelRatio: 0.5, size: Size(24, 24)),
      'assets/images/loc.png',
    );
    _closeIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(devicePixelRatio: 0.5, size: Size(24, 24)),
      'assets/images/close.png',
    );
    _locMarker = Marker(
        markerId: const MarkerId('loc'),
        icon: _locIcon,
        draggable: true,
        zIndex: 1000000,
        anchor: const Offset(0.5, 0.5),
        rotation: 0,
        onDragStart: (LatLng position) {
          _updateCoordinate(position);
        },
        onDragEnd: (LatLng position) {
          setState(() {
            isDragged = true;
          });
          _updateCoordinate(position);
        });
  }

  void _updateCoordinate(LatLng position) {
    setState(() {
      _locMarker = _locMarker.copyWith(
        positionParam: position,
      );
    });
  }

  void _removeCoordinate(Map<String, double> coordinateToRemove) async {
    setState(() {
      _coordinates.remove(coordinateToRemove);
      _markers.removeWhere((marker) =>
          marker.position.latitude == coordinateToRemove['latitude'] &&
          marker.position.longitude == coordinateToRemove['longitude']);

      // Update the polyline
      _polylines.clear();
    });

    // Save updated coordinates
    await storage.write(
      key: 'coordinates',
      value: json.encode(_coordinates),
    );

    _showSnackbar(context, "Last point removed successfully!", Colors.orange);
    _loadCoordinates();
  }

  void _showSnackbar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: color,
      showCloseIcon: true,
    ));
  }

  @override
  void dispose() {
    // Cancel the position stream subscription when the widget is disposed
    positionStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: Text(
                "Map ${widget.assetName}",
                style: const TextStyle(color: Colors.white),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) => Assets(staffid: widget.staffid)));
              },
              child: const Icon(Icons.arrow_back),
            )
          ],
        ),
        backgroundColor: const Color(0xff0288D1),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: StaffDrawer(
        staffid: widget.staffid,
      ),
      body: Stack(
        children: [
          _currentLocation == null
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                        _currentLocation.latitude, _currentLocation.longitude),
                    zoom: 20,
                  ),
                  onMapCreated: (GoogleMapController controller) {
                    setState(() {
                      _mapController.complete(controller);
                    });
                  },
                  markers: {
                    _markers.isNotEmpty
                        ? _markers.last
                        : const Marker(
                            markerId: MarkerId("null"),
                          ),
                    _locMarker
                  },
                  polylines: _polylines,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  scrollGesturesEnabled: false,
                  rotateGesturesEnabled: true,
                  zoomControlsEnabled: false,
                ),
          Positioned(
              bottom: 10,
              left: 10,
              child: Material(
                elevation: 10,
                color: Colors.blue,
                borderRadius: const BorderRadius.all(Radius.circular(5)),
                child: InkWell(
                  onTap: () {
                    _saveCoordinates(_locMarker.position);
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_pin,
                          color: Colors.white,
                        ),
                        SizedBox(
                          width: 2,
                        ),
                        Text(
                          "Add",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                        SizedBox(
                          width: 5,
                        ),
                      ],
                    ),
                  ),
                ),
              )),
          if (_coordinates.length > 2)
            Positioned(
                bottom: 10,
                right: 10,
                child: Material(
                  elevation: 10,
                  color: Colors.blue,
                  borderRadius: const BorderRadius.all(Radius.circular(5)),
                  child: InkWell(
                    onTap: () {
                      if (widget.assetName == "Water Pipes") {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => WaterPipes(
                                      coordinates: _coordinates,
                                    )));
                      } else if (widget.assetName == "Sewer Lines") {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => SewerLines(
                                      coordinates: _coordinates,
                                    )));
                      } else if (widget.assetName == "Sewer MainTrunk") {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => SewerMainTrunk(
                                      coordinates: _coordinates,
                                    )));
                      } else if (widget.assetName == "Consumer Lines") {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => ConsumerLines(
                                      coordinates: _coordinates,
                                    )));
                      } else if (widget.assetName == "Customer Lines") {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => CustomerLines(
                                      coordinates: _coordinates,
                                    )));
                      } else {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => LineProjects(
                                      coordinates: _coordinates,
                                    )));
                      }
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_document,
                            color: Colors.white,
                          ),
                          SizedBox(
                            width: 2,
                          ),
                          Text(
                            "Submit & Proceed",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                          SizedBox(
                            width: 5,
                          ),
                        ],
                      ),
                    ),
                  ),
                )),
          if (_coordinates.length > 2)
            Positioned(
                top: 10,
                left: 10,
                child: Material(
                  elevation: 10,
                  color: Colors.orange,
                  borderRadius: const BorderRadius.all(Radius.circular(5)),
                  child: InkWell(
                    onTap: () async {
                      await storage.delete(key: "coordinates");

                      setState(() {
                        _coordinates = [];
                        _polylines.clear();
                        _markers.clear();
                      });
                      _showSnackbar(context, "All points have been cleared",
                          Colors.orange);
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.refresh,
                            color: Colors.white,
                          ),
                          SizedBox(
                            width: 2,
                          ),
                          Text(
                            "Clear",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                          SizedBox(
                            width: 5,
                          ),
                        ],
                      ),
                    ),
                  ),
                ))
        ],
      ),
    );
  }
}
