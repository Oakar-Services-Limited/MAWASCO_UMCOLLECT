// ignore_for_file: use_build_context_synchronously, non_constant_identifier_zones, file_zones, prefer_typing_uninitialized_variables, file_names

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:um_collect/components/MySelectInput.dart';
import 'package:um_collect/components/MyTextInput.dart';
import 'package:um_collect/components/StaffDrawer.dart';
import 'package:um_collect/components/SubmitButton.dart';
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
  String selectedAssetType = '--Select--';
  String name = '';
  String zone = '';
  String route = '';
  String phone = '';
  String size = '';
  String location = '';
  String remarks = '';
  String user = '';
  String role = '';
  dynamic data;

  var isLoading;

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
        return;
      }

      var decoded = parseJwt(token.toString());
      editing = await storage.read(key: "editing");
      if (!mounted) return;
      setState(() {
        user = decoded["name"];
        staffid = decoded["id"];
        role = decoded["role"] ?? '';
      });
      if (editing == 'true') {
        prefillForm(data);
      }
    } catch (e) {
      //
    }
  }

  prefillForm(data) async {
    var fetchedData = await storage.read(key: "data");
    data = json.decode(fetchedData!);

    if (!mounted) return;
    setState(() {
      pointID = data[0]["ID"];
      selectedAssetType = data[0]["AssetType"] ?? '--Select--';
      name = data[0]["Name"] ?? '';
      zone = data[0]["Zone"] ?? '';
      route = data[0]["Route"] ?? '';
      phone = data[0]["Phone"] ?? '';
      size = data[0]["Size"] ?? '';
      location = data[0]["Location"] ?? '';
      remarks = data[0]["Remarks"] ?? '';
      user = data[0]["User"] ?? '';
    });
  }

  getLocation() async {
    LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation, // Highest possible
      distanceFilter: 0, // Get all movements
    );

    Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      if (!mounted) return;
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
                    MySelectInput(
                      onSubmit: (value) {
                        setState(() {
                          selectedAssetType = value;
                          // Clear fields when asset type changes
                          name = '';
                          zone = '';
                          route = '';
                          phone = '';
                          size = '';
                          location = '';
                          remarks = '';
                        });
                      },
                      list: const [
                        "--Select--",
                        "Customer Meter",
                        "Tank",
                        "Master Meter",
                        "Washout",
                        "Manhole",
                      ],
                      label: 'Asset Type',
                      value: selectedAssetType,
                    ),
                    if (selectedAssetType != '--Select--')
                      MyTextInput(
                        lines: 1,
                        value: name,
                        type: TextInputType.text,
                        onSubmit: (value) {
                          setState(() {
                            name = value;
                          });
                        },
                        title: 'Name',
                      ),
                    // Customer Meter fields
                    if (selectedAssetType == 'Customer Meter') ...[
                      MyTextInput(
                        lines: 1,
                        value: phone,
                        type: TextInputType.phone,
                        onSubmit: (value) {
                          setState(() {
                            phone = value;
                          });
                        },
                        title: 'Phone',
                      ),
                      MySelectInput(
                        onSubmit: (value) {
                          setState(() {
                            zone = value;
                          });
                        },
                        list: getZones(),
                        label: 'Zone',
                        value: zone,
                      ),
                      MyTextInput(
                        lines: 1,
                        value: route,
                        type: TextInputType.text,
                        onSubmit: (value) {
                          setState(() {
                            route = value;
                          });
                        },
                        title: 'Route',
                      ),
                    ],
                    // Tank fields
                    if (selectedAssetType == 'Tank') ...[
                      MySelectInput(
                        onSubmit: (value) {
                          setState(() {
                            zone = value;
                          });
                        },
                        list: getZones(),
                        label: 'Zone',
                        value: zone,
                      ),
                      MyTextInput(
                        lines: 1,
                        value: location,
                        type: TextInputType.text,
                        onSubmit: (value) {
                          setState(() {
                            location = value;
                          });
                        },
                        title: 'Location',
                      ),
                    ],
                    // Master Meter fields
                    if (selectedAssetType == 'Master Meter') ...[
                      MyTextInput(
                        lines: 1,
                        value: size,
                        type: TextInputType.text,
                        onSubmit: (value) {
                          setState(() {
                            size = value;
                          });
                        },
                        title: 'Size',
                      ),
                      MyTextInput(
                        lines: 1,
                        value: route,
                        type: TextInputType.text,
                        onSubmit: (value) {
                          setState(() {
                            route = value;
                          });
                        },
                        title: 'Route',
                      ),
                      MySelectInput(
                        onSubmit: (value) {
                          setState(() {
                            zone = value;
                          });
                        },
                        list: getZones(),
                        label: 'Zone',
                        value: zone,
                      ),
                      MyTextInput(
                        lines: 1,
                        value: location,
                        type: TextInputType.text,
                        onSubmit: (value) {
                          setState(() {
                            location = value;
                          });
                        },
                        title: 'Location',
                      ),
                    ],
                    // Washout fields
                    if (selectedAssetType == 'Washout') ...[
                      MyTextInput(
                        lines: 1,
                        value: size,
                        type: TextInputType.text,
                        onSubmit: (value) {
                          setState(() {
                            size = value;
                          });
                        },
                        title: 'Size',
                      ),
                      MyTextInput(
                        lines: 1,
                        value: route,
                        type: TextInputType.text,
                        onSubmit: (value) {
                          setState(() {
                            route = value;
                          });
                        },
                        title: 'Route',
                      ),
                      MySelectInput(
                        onSubmit: (value) {
                          setState(() {
                            zone = value;
                          });
                        },
                        list: getZones(),
                        label: 'Zone',
                        value: zone,
                      ),
                      MyTextInput(
                        lines: 1,
                        value: location,
                        type: TextInputType.text,
                        onSubmit: (value) {
                          setState(() {
                            location = value;
                          });
                        },
                        title: 'Location',
                      ),
                    ],
                    // Manhole fields
                    if (selectedAssetType == 'Manhole') ...[
                      MyTextInput(
                        lines: 1,
                        value: route,
                        type: TextInputType.text,
                        onSubmit: (value) {
                          setState(() {
                            route = value;
                          });
                        },
                        title: 'Route',
                      ),
                      MySelectInput(
                        onSubmit: (value) {
                          setState(() {
                            zone = value;
                          });
                        },
                        list: getZones(),
                        label: 'Zone',
                        value: zone,
                      ),
                      MyTextInput(
                        lines: 3,
                        value: remarks,
                        type: TextInputType.multiline,
                        onSubmit: (value) {
                          setState(() {
                            remarks = value;
                          });
                        },
                        title: 'Remarks',
                      ),
                    ],
                    const SizedBox(
                      height: 12,
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: SubmitButton(
                        label: "Submit",
                        onButtonPressed: () async {
                          // Restrict editing to Super Admins only
                          if (editing == 'true' && role != 'Super Admin') {
                            _showSnackBar(
                                'Updating asset restricted to Super Admins only',
                                false);
                            return;
                          }
                          // Validate asset type selection
                          if (selectedAssetType == '--Select--') {
                            _showSnackBar("Please select an asset type", false);
                            return;
                          }

                          // Validate required fields based on asset type
                          bool isValid = true;
                          String errorMessage =
                              "Please fill in all required fields";

                          if (name.isEmpty) {
                            isValid = false;
                          }

                          if (selectedAssetType == 'Customer Meter') {
                            if (phone.isEmpty ||
                                zone == '--Select--' ||
                                zone.isEmpty ||
                                route.isEmpty) {
                              isValid = false;
                            }
                          } else if (selectedAssetType == 'Tank') {
                            if (zone == '--Select--' ||
                                zone.isEmpty ||
                                location.isEmpty) {
                              isValid = false;
                            }
                          } else if (selectedAssetType == 'Master Meter') {
                            if (size.isEmpty ||
                                route.isEmpty ||
                                zone == '--Select--' ||
                                zone.isEmpty ||
                                location.isEmpty) {
                              isValid = false;
                            }
                          } else if (selectedAssetType == 'Washout') {
                            if (size.isEmpty ||
                                route.isEmpty ||
                                zone == '--Select--' ||
                                zone.isEmpty ||
                                location.isEmpty) {
                              isValid = false;
                            }
                          } else if (selectedAssetType == 'Manhole') {
                            if (route.isEmpty ||
                                zone == '--Select--' ||
                                zone.isEmpty ||
                                remarks.isEmpty) {
                              isValid = false;
                            }
                          }

                          if (!isValid) {
                            _showSnackBar(errorMessage, false);
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
                              selectedAssetType,
                              name,
                              zone,
                              route,
                              phone,
                              size,
                              location,
                              remarks,
                              staffid,
                              editing);

                          if (!mounted) return;
                          setState(() {
                            isLoading = null;
                            if (res.error == null) {
                              error = "";
                              _showSnackBar(res.success, true);
                              // Proceed to next page after successful submission
                              Timer(const Duration(seconds: 2), () {
                                if (mounted) {
                                  Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => Assets(
                                                staffid: staffid,
                                              )));
                                }
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
    String assetType,
    String name,
    String zone,
    String route,
    String phone,
    String size,
    String location,
    String remarks,
    String staffid,
    String? editing) async {
  try {
    final storage = const FlutterSecureStorage();
    final token = await storage.read(key: "mwstaffjwt");

    if (token == null) {
      print("Error: Authentication token not found");
      return Message(
        token: null,
        success: null,
        error: "Authentication token not found. Please login again.",
      );
    }

    // Build request body
    Map<String, dynamic> requestBody = {
      'assetType': assetType,
      'name': name,
      'userId': staffid,
      'latitude': lat,
      'longitude': long,
    };

    // Add fields based on asset type
    if (assetType == 'Customer Meter') {
      requestBody['phone'] = phone;
      requestBody['zone'] = zone;
      requestBody['route'] = route;
    } else if (assetType == 'Tank') {
      requestBody['zone'] = zone;
      requestBody['location'] = location;
    } else if (assetType == 'Master Meter') {
      requestBody['size'] = size;
      requestBody['route'] = route;
      requestBody['zone'] = zone;
      requestBody['location'] = location;
    } else if (assetType == 'Washout') {
      requestBody['size'] = size;
      requestBody['route'] = route;
      requestBody['zone'] = zone;
      requestBody['location'] = location;
    } else if (assetType == 'Manhole') {
      requestBody['route'] = route;
      requestBody['zone'] = zone;
      requestBody['remarks'] = remarks;
    }

    // Make API request
    http.Response response;
    if (editing == 'true') {
      response = await http.put(
        Uri.parse("${getUrl()}pj/points/$pointID"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );
    } else {
      response = await http.post(
        Uri.parse("${getUrl()}pj/points"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );
    }

    print("Submit point response: ${response.statusCode}");

    // Handle response
    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        final responseData = jsonDecode(response.body);
        return Message(
          token: responseData['data']?['id'],
          success: responseData['message'] ?? "Point saved successfully",
          error: null,
        );
      } catch (e) {
        print("Error parsing response: $e");
        return Message(
          token: null,
          success: null,
          error:
              "Failed to parse server response. Status: ${response.statusCode}",
        );
      }
    } else {
      try {
        var responseBody = jsonDecode(response.body);
        final errorMessage = responseBody['message'] ??
            responseBody['error'] ??
            "Server error! Contact administrator.";
        print("API error: $errorMessage");
        return Message(
          token: null,
          success: null,
          error: errorMessage,
        );
      } catch (e) {
        print("Error parsing error response: $e");
        return Message(
          token: null,
          success: null,
          error:
              "Server returned invalid response. Status: ${response.statusCode}",
        );
      }
    }
  } catch (e) {
    print("Submit point exception: $e");
    return Message(
      token: null,
      success: null,
      error: "Connection failed! Check your internet connection.",
    );
  }
}

class Message {
  dynamic token;
  dynamic success;
  dynamic error;

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
