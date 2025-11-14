// ignore_for_file: unnecessary_null_comparison, prefer_collection_literals, empty_catches, depend_on_referenced_packages, prefer_typing_uninitialized_variables, library_private_types_in_public_api, file_names, library_prefixes

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:um_collect/components/StaffDrawer.dart';
import 'package:um_collect/components/Utils.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_html/flutter_html.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as GoogleMaps;
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:location/location.dart';

class Routing extends StatefulWidget {
  final String label;
  final String staffid;
  const Routing({super.key, required this.label, required this.staffid});

  @override
  _RoutingState createState() => _RoutingState();
}

class _RoutingState extends State<Routing> {
  late GoogleMaps.GoogleMapController _controller;
  final Location _location = Location();
  Set<GoogleMaps.Polyline> _polylines = {};
  String startAddress = "";
  String manuever = "";
  String distance = "";
  List<dynamic> legs = [];
  GoogleMaps.Marker _vehicleMarker =
      const GoogleMaps.Marker(markerId: GoogleMaps.MarkerId("value"));
  late GoogleMaps.BitmapDescriptor _vehicleIcon;
  final GoogleMaps.LatLng _initialCameraPosition =
      const GoogleMaps.LatLng(-1.3003675, 36.8159307);
  var selected;
  var destination;
  var loading;

  @override
  void initState() {
    super.initState();
    _loadMarkerIcon();
    _getLocation();
  }

  void searchIncidenID(String v) async {
    try {
      final response = await http.get(
        Uri.parse("${getUrl()}reports/serial/search/$v"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );
      if (response.statusCode == 200 || response.statusCode == 203) {
        List<dynamic> body = jsonDecode(response.body);

        if (body.isNotEmpty) {
          setState(() {
            selected = body.first;
          });
        } else {
          setState(() {
            selected = null;
          });
        }
      } else {}
    } catch (e) {
      setState(() {
        selected = null;
      });
    }
  }

  void searchObjectID(String v) async {
    try {
      final response = await http.get(
        Uri.parse(
            "${getUrl()}customers/searchothers/${widget.label.replaceAll(RegExp(" "), "")}/$v"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );
      if (response.statusCode == 200 || response.statusCode == 203) {
        List<dynamic> body = jsonDecode(response.body);
        if (body.isNotEmpty) {
          setState(() {
            selected = body.first;
          });
        } else {
          setState(() {
            selected = null;
          });
        }
      }
    } catch (e) {
      setState(() {
        selected = null;
      });
    }
  }

  void searchAccounts(String v) async {
    try {
      final response = await http.get(
        Uri.parse("${getUrl()}customers/searchone/$v"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );
      if (response.statusCode == 200 || response.statusCode == 203) {
        List<dynamic> body = jsonDecode(response.body);
        if (body.isNotEmpty) {
          setState(() {
            selected = body.first;
          });
        } else {
          setState(() {
            selected = null;
          });
        }
      }
    } catch (e) {
      setState(() {
        selected = null;
      });
    }
  }

  void _loadMarkerIcon() async {
    _vehicleIcon = await GoogleMaps.BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(devicePixelRatio: 0.5),
      'assets/images/car.png',
    );
    _createVehicleMarker(
        _initialCameraPosition.latitude, _initialCameraPosition.longitude);
  }

  void _getLocation() async {
    _location.changeSettings(
        accuracy: LocationAccuracy.high, distanceFilter: 10, interval: 1000);
    LocationData? currentLocation;
    try {
      currentLocation = await _location.getLocation();
      if (currentLocation != null) {
        _location.onLocationChanged.listen((LocationData locationData) {
          if (destination != null && manuever != "arrive") {
            _drawRoute(
                GoogleMaps.LatLng(
                    locationData.latitude!, locationData.longitude!),
                destination,
                locationData.heading!);
          }
        });
      }
    } catch (e) {
      currentLocation = null;
    }

    try {
      final Location location2 = Location();
      var currentLocation2 = await _location.getLocation();

      if (currentLocation2 != null) {
        _controller.animateCamera(GoogleMaps.CameraUpdate.newCameraPosition(
          GoogleMaps.CameraPosition(
              target: GoogleMaps.LatLng(
                  currentLocation2.latitude!, currentLocation2.longitude!),
              zoom: 18,
              bearing: currentLocation2.heading!),
        ));
        location2.onLocationChanged.listen((LocationData locationData) {
          GoogleMaps.CameraPosition(
              target: GoogleMaps.LatLng(
                  locationData.latitude!, locationData.longitude!),
              zoom: 18,
              bearing: locationData.heading!);
          _updateVehicleMarker(locationData);
        });
      }
    } catch (e) {}
  }

  Future<void> _drawRoute(
      GoogleMaps.LatLng start, GoogleMaps.LatLng end, double heading) async {
    try {
      String apiKey =
          'AIzaSyBqx0f1yaQY_3bgy4-pGwkHF8QmRy94dTE'; // Replace with your Google Maps API key
      String origin = '${start.latitude},${start.longitude}';
      String destination = '${end.latitude},${end.longitude}';
      String apiUrl =
          'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&key=$apiKey';

      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        List<dynamic> routes = data['routes'];
        Set<GoogleMaps.Polyline> polylines =
            {}; // Create polylines set outside of loop
        if (routes.isNotEmpty) {
          final route = routes[0];

          dynamic points = route['legs'];

          List<GoogleMaps.LatLng> polylineCoordinates = PolylinePoints()
              .decodePolyline(route["overview_polyline"]["points"])
              .map((PointLatLng point) =>
                  GoogleMaps.LatLng(point.latitude, point.longitude))
              .toList();

          polylines.add(GoogleMaps.Polyline(
            polylineId: const GoogleMaps.PolylineId('route'),
            points: polylineCoordinates,
            color: Colors.blue,
            width: 10,
          ));

          setState(() {
            _polylines = polylines;
            startAddress =
                points[0]["steps"][0]['html_instructions'].toString();
            distance = points[0]["steps"][0]['distance']["text"];
            manuever = points[0]["steps"][0]['maneuver'] ?? "";
            loading = null;
          });
        }
      } else {
        throw Exception('Failed to load directions');
      }
    } catch (e) {}
  }

  void _createVehicleMarker(double latitude, double longitude) {
    GoogleMaps.LatLng latLng = GoogleMaps.LatLng(latitude, longitude);
    _vehicleMarker = GoogleMaps.Marker(
      markerId: const GoogleMaps.MarkerId('vehicle'),
      position: latLng,
      icon: _vehicleIcon,
      rotation: 0,
    );
  }

  void _updateVehicleMarker(LocationData locationData) {
    GoogleMaps.LatLng latLng =
        GoogleMaps.LatLng(locationData.latitude!, locationData.longitude!);
    setState(() {
      _vehicleMarker = _vehicleMarker.copyWith(
        positionParam: latLng,
      );
    });
  }

  IconData _getMeneuverIcon(String maneuver) {
    switch (maneuver) {
      case 'turn-left':
        return Icons.arrow_back;
      case 'turn-right':
        return Icons.arrow_forward;
      case 'turn-slight-left':
        return Icons.subdirectory_arrow_left;
      case 'turn-slight-right':
        return Icons.subdirectory_arrow_right;
      case 'turn-sharp-left':
        return Icons.arrow_back_ios;
      case 'turn-sharp-right':
        return Icons.arrow_forward_ios;
      case 'merge':
        return Icons.merge_type;
      case 'fork-left':
        return Icons.call_split;
      case 'fork-right':
        return Icons.call_split;
      case 'ramp-left':
        return Icons.trending_down;
      case 'ramp-right':
        return Icons.trending_up;
      case 'keep-left':
        return Icons.directions;
      case 'keep-right':
        return Icons.directions;
      case 'roundabout-left':
        return Icons.rotate_left;
      case 'roundabout-right':
        return Icons.rotate_right;
      case 'uturn-left':
        return Icons.undo;
      case 'uturn-right':
        return Icons.redo;
      case 'straight':
        return Icons.arrow_upward;
      case 'depart':
        return Icons.trip_origin;
      case 'arrive':
        return Icons.flag;
      default:
        return Icons.directions;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${widget.label} Routing",
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xff0288D1),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      drawer: StaffDrawer(
        staffid: widget.staffid,
      ),
      body: Stack(
        children: [
          GoogleMaps.GoogleMap(
            initialCameraPosition: GoogleMaps.CameraPosition(
              target: _initialCameraPosition,
              zoom: 14.0,
            ),
            polylines: _polylines,
            markers: _vehicleMarker != null
                ? Set<GoogleMaps.Marker>.from([_vehicleMarker])
                : <GoogleMaps.Marker>{},
            onMapCreated: (GoogleMaps.GoogleMapController controller) {
              _controller = controller;
            },
          ),
          _polylines.isNotEmpty && manuever != "arrive"
              ? Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: const Color(0xFFF5E8DD),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey
                                  .withValues(alpha: 0.2), // shadow color
                              spreadRadius: 1, // spread radius
                              blurRadius: 1, // blur radius
                              offset: const Offset(
                                  0, 1), // changes position of shadow
                            ),
                          ],
                          border: Border.all(
                              color: const Color.fromARGB(10, 0, 0, 0),
                              width: 1,
                              style: BorderStyle.solid),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(8))),
                      child: Row(
                        children: [
                          Icon(
                            _getMeneuverIcon(manuever),
                            size: 64,
                            color: Colors.green,
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Flexible(
                            flex: 1,
                            fit: FlexFit.tight,
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Html(
                                    data: startAddress,
                                    style: {
                                      "*": Style(
                                          color: const Color.fromARGB(
                                              255, 28, 100, 140),
                                          fontSize: FontSize.medium)
                                    },
                                  ),
                                  Align(
                                    alignment: Alignment.center,
                                    child: Text(
                                      distance,
                                      style: const TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 24),
                                    ),
                                  ),
                                ]),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : loading == null
                  ? Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: const Color(0xFFF5E8DD),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey
                                      .withValues(alpha: 0.2), // shadow color
                                  spreadRadius: 1, // spread radius
                                  blurRadius: 1, // blur radius
                                  offset: const Offset(
                                      0, 1), // changes position of shadow
                                ),
                              ],
                              border: Border.all(
                                  color: const Color.fromARGB(10, 0, 0, 0),
                                  width: 1,
                                  style: BorderStyle.solid),
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(8))),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              selected != null
                                  ? Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          0, 0, 0, 16),
                                      child: TextButton(
                                          onPressed: () {
                                            FocusScope.of(context).unfocus();
                                            setState(() {
                                              destination = GoogleMaps.LatLng(
                                                  double.tryParse(
                                                      selected["Latitude"])!,
                                                  double.tryParse(
                                                      selected["Longitude"])!);
                                              selected = null;
                                              loading = LoadingAnimationWidget
                                                  .horizontalRotatingDots(
                                                      color: Colors.orange,
                                                      size: 100);
                                            });
                                            _drawRoute(_initialCameraPosition,
                                                destination, 0);
                                          },
                                          child: Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                                color: Colors.white,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.grey.withValues(
                                                        alpha:
                                                            0.2), // shadow color
                                                    spreadRadius:
                                                        2, // spread radius
                                                    blurRadius:
                                                        2, // blur radius
                                                    offset: const Offset(0,
                                                        2), // changes position of shadow
                                                  )
                                                ],
                                                borderRadius:
                                                    const BorderRadius.all(
                                                        Radius.circular(5))),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                widget.label == "Incidences"
                                                    ? Text(
                                                        'Serial: ${selected["SerialNo"]}',
                                                        style: const TextStyle(
                                                            color: Colors.grey,
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600),
                                                      )
                                                    : Text(
                                                        selected["Name"],
                                                        style: const TextStyle(
                                                            color:
                                                                Color.fromARGB(
                                                                    255,
                                                                    28,
                                                                    100,
                                                                    140),
                                                            fontSize: 18,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                const SizedBox(
                                                  height: 4,
                                                ),
                                                widget.label ==
                                                        "Customer Meters"
                                                    ? Text(
                                                        'Account No: ${selected["AccountNo"]}',
                                                        style: const TextStyle(
                                                            color: Colors.grey,
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600),
                                                      )
                                                    : widget.label ==
                                                            "Incidences"
                                                        ? Text(
                                                            'Type: ${selected["Type"]}',
                                                            style: const TextStyle(
                                                                color:
                                                                    Colors.grey,
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600),
                                                          )
                                                        : Text(
                                                            'Object ID: ${selected["ObjectID"]}',
                                                            style: const TextStyle(
                                                                color:
                                                                    Colors.grey,
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600),
                                                          ),
                                              ],
                                            ),
                                          )),
                                    )
                                  : const SizedBox(),
                              Stack(
                                children: [
                                  TextField(
                                    onChanged: (value) {
                                      if (value != "") {
                                        if (widget.label == "Customer Meters") {
                                          searchAccounts(value);
                                        } else if (widget.label ==
                                            "Incidences") {
                                          searchIncidenID(value);
                                        } else {
                                          searchObjectID(value);
                                        }
                                      } else {
                                        setState(() {
                                          selected = null;
                                        });
                                      }
                                    },
                                    decoration: InputDecoration(
                                        contentPadding:
                                            const EdgeInsets.all(12),
                                        border: const OutlineInputBorder(
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(44)),
                                            borderSide: BorderSide(
                                                color: Color.fromARGB(
                                                    255, 28, 100, 140))),
                                        filled: false,
                                        label: Text(
                                          widget.label == "Customer Meters"
                                              ? "Name/Account No"
                                              : widget.label == "Incidences"
                                                  ? "Name/Serial No"
                                                  : "Name/ObjectID",
                                          style: const TextStyle(
                                              color: Color.fromARGB(
                                                  255, 28, 100, 140)),
                                        ),
                                        floatingLabelBehavior:
                                            FloatingLabelBehavior.auto),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.fromLTRB(0, 12, 12, 0),
                                    child: Align(
                                      alignment: Alignment.bottomRight,
                                      child: Icon(
                                        Icons.search,
                                        color: Color(0xff0288D1),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : const SizedBox(),
          Center(
            child: loading,
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
