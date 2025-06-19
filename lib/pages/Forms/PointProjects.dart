// ignore_for_file: use_build_context_synchronously, non_constant_identifier_zones, file_zones, prefer_typing_uninitialized_variables

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:um_collect/components/MySelectInput.dart';
import 'package:um_collect/components/MyTextInput.dart';
import 'package:um_collect/components/StaffDrawer.dart';
import 'package:um_collect/components/SubmitButton.dart';
import 'package:um_collect/components/TextResponse.dart';
import 'package:um_collect/components/Utils.dart';
import 'package:um_collect/models/Map.dart';
import 'package:um_collect/pages/Assets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:http/http.dart' as http;

class PointProjects extends StatefulWidget {
  const PointProjects({
    super.key,
  });

  @override
  State<PointProjects> createState() => _PointProjectsState();
}

class _PointProjectsState extends State<PointProjects> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final storage = const FlutterSecureStorage();
  late Position position;

  var long = 36.0, lat = -2.0, acc = 100.0;
  String error = '';
  String? editing = 'false';
  String staffid = '';

  String pointID = '';
  String name = '';
  String zone = '';
  String route = '';
  String phone = '';
  String user = '';
  dynamic data;

  var isLoading;

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  @override
  void initState() {
    fetchStoredData();
    getLocation();
    super.initState();
  }

  Future<void> fetchStoredData() async {
    try {
      var token = await storage.read(key: "mwstaffjwt");
      if (token == null) {
        print("No token found");
        return;
      }

      var decoded = parseJwt(token.toString());
      editing = await storage.read(key: "editing");

      print("Decoded token: $decoded");
      print("Staff ID from token: ${decoded["id"]}");

      setState(() {
        user = decoded["name"];
        staffid = decoded["id"];
      });

      print("Set staffid to: $staffid");

      if (editing == 'true') {
        prefillForm(data);
      }
    } catch (e) {
      print("Error in fetchStoredData: $e");
    }
  }

  prefillForm(data) async {
    var fetchedData = await storage.read(key: "data");
    data = json.decode(fetchedData!);

    setState(() {
      pointID = data[0]["ID"];
      name = data[0]["Name"];
      zone = data[0]["Zone"];
      route = data[0]["Route"];
      phone = data[0]["Phone"];
      user = data[0]["User"];
    });
  }

  getLocation() async {
    LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation, // Highest possible
      distanceFilter: 0, // Get all movements
    );

    Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      print(position.latitude);
      print(position.longitude);
      setState(() {
        long = position.longitude;
        lat = position.latitude;
        acc = position.accuracy;
        position = position;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        actions: <Widget>[
          IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (_) => Assets(
                            staffid: staffid,
                          )));
            },
          ),
        ],
        title: const Text(
          'Point Project Details',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xff0288D1),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: StaffDrawer(
        staffid: staffid,
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(color: Colors.white),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: SizedBox(
              // MediaQuery.of(context).material.height,
              height: MediaQuery.of(context).size.height,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      height: 8,
                    ),
                    const Text(
                      "All fields marked with * are required",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Padding(
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                        child: SizedBox(
                            height: 250,
                            child: MyMap(
                              lat: lat,
                              lon: long,
                              acc: acc,
                            ))),
                    MyTextInput(
                      lines: 1,
                      value: '',
                      type: TextInputType.text,
                      onSubmit: (value) {
                        setState(() {
                          name = value;
                        });
                      },
                      title: 'name',
                    ),
                    MySelectInput(
                      onSubmit: (value) {
                        setState(() {
                          zone = value;
                        });
                      },
                      list: const [
                        "--Select--",
                        "001 Gathugu",
                        "002 Urban Institution",
                        "003 Indian",
                        "004 Industrial",
                        "005 Karindundu",
                        "006 Mathaithi",
                        "007 Ragati",
                        "008 Saigon 1",
                        "009 Sofia",
                        "010 Muthua",
                        "011 Blue Valley",
                        "012 83",
                        "013 84",
                        "014 85",
                        "015 86",
                        "016 87",
                        "017 88",
                        "018 Jambo-88",
                        "019 Tumutumu-87",
                        "019 89",
                        "020 90",
                        "021 91",
                        "022 92",
                        "023 82(Inst.Rural)",
                        "024 93",
                      ],
                      label: 'Zone',
                      value: zone,
                    ),
                    MyTextInput(
                      lines: 1,
                      value: '',
                      type: TextInputType.text,
                      onSubmit: (value) {
                        setState(() {
                          route = value;
                        });
                      },
                      title: 'Route',
                    ),
                    MyTextInput(
                      lines: 1,
                      value: '',
                      type: TextInputType.number,
                      onSubmit: (value) {
                        setState(() {
                          phone = value;
                        });
                      },
                      title: 'Phone',
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: SubmitButton(
                        label: "Submit",
                        onButtonPressed: () async {
                          // Validate required fields
                          if (name.isEmpty ||
                              zone == '--Select--' ||
                              zone.isEmpty ||
                              route.isEmpty ||
                              phone.isEmpty) {
                            _showSnackBar(
                                "Please fill in all required fields", false);
                            return;
                          }

                          setState(() {
                            isLoading =
                                LoadingAnimationWidget.staggeredDotsWave(
                                    color: const Color(0xff0288D1), size: 100);
                          });

                          var res = await submitData(
                              pointID,
                              lat.toString(),
                              long.toString(),
                              name,
                              zone,
                              route,
                              phone,
                              staffid,
                              editing);

                          setState(() {
                            isLoading = null;
                            if (res.error == null) {
                              error = "";
                              _showSnackBar(res.success, true);
                              // Proceed to next page after successful submission
                              Timer(const Duration(seconds: 2), () {
                                Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => Assets(
                                              staffid: staffid,
                                            )));
                              });
                            } else {
                              _showSnackBar(res.error, false);
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: isLoading ?? const SizedBox(),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, bool isSuccess) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

Future<Message> submitData(
    String pointID,
    String lat,
    String long,
    String name,
    String zone,
    String route,
    String phone,
    String staffid,
    String? editing) async {
  try {
    // Debug print
    print("Submitting point data with staffid: $staffid");

    var response;
    final requestBody = editing == 'true'
        ? {
            'name': name,
            'zone': zone,
            'route': route,
            'phone': phone,
            'userId': staffid,
            'latitude': lat,
            'longitude': long,
          }
        : {
            'name': name,
            'zone': zone,
            'route': route,
            'phone': phone,
            'userId': staffid,
            'latitude': lat,
            'longitude': long,
          };

    // Debug print
    print("Request body: ${jsonEncode(requestBody)}");

    if (editing == 'true') {
      response = await http.put(
        Uri.parse("${getUrl()}pj/points/$pointID"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(requestBody),
      );
    } else {
      response = await http.post(
        Uri.parse("${getUrl()}pj/points"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(requestBody),
      );
    }

    // Debug print
    print("Response status: ${response.statusCode}");
    print("Response body: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      return Message(
        token: responseData['data']?['id'],
        success: responseData['message'] ?? "Point saved successfully",
        error: null,
      );
    } else {
      try {
        var responseBody = jsonDecode(response.body);
        return Message(
          token: null,
          success: null,
          error: responseBody['message'] ??
              responseBody['error'] ??
              "Server error! Contact administrator.",
        );
      } catch (e) {
        print("Error parsing response: $e");
        return Message(
          token: null,
          success: null,
          error:
              "Server returned invalid response. Status: ${response.statusCode}",
        );
      }
    }
  } catch (e) {
    print("Network error: $e");
    return Message(
      token: null,
      success: null,
      error: "Connection failed! Check your internet connection.",
    );
  }
}

class Message {
  var token;
  var success;
  var error;

  Message({
    required this.token,
    required this.success,
    required this.error,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      token: json['token'],
      success: json['success'],
      error: json['error'],
    );
  }
}
