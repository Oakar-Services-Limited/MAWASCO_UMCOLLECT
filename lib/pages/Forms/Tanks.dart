// ignore_for_file: use_build_context_synchronously, non_constant_identifier_names, file_names

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

class Tanks extends StatefulWidget {
  const Tanks({
    super.key,
  });

  @override
  State<Tanks> createState() => _TanksState();
}

class _TanksState extends State<Tanks> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final storage = const FlutterSecureStorage();
  late Position position;

  var long = 36.0, lat = -2.0, acc = 100.0;
  String error = '';
  String? editing = 'false';
  String staffid = '';
  String tankID = '';
  String name = '';
  String zone = '';
  String elevation = '';
  String area = '';
  String location = '';
  String inletpipe = '';
  String outletpipe = '';
  String material = '';
  String capacity = '';
  String status = '';
  String remarks = '';
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
      print('token is $token');
      var decoded = parseJwt(token.toString());
      editing = await storage.read(key: "editing");
      print('token is $decoded');

      setState(() {
        user = decoded["name"];
        staffid = decoded["id"];
      });

      print('editing is $editing');

      if (editing == 'true') {
        prefillForm(data);
      } else {}
    } catch (e) {}
  }

  prefillForm(data) async {
    var fetchedData = await storage.read(key: "data");
    data = json.decode(fetchedData!);

    setState(() {
      tankID = data[0]["id"] ?? "";
      name = data[0]["name"] ?? "";
      zone = data[0]["zone"] ?? "";
      elevation = data[0]["elevation"]?.toString() ?? "";
      area = data[0]["area"] ?? "";
      location = data[0]["location"] ?? "";
      inletpipe = data[0]["inletPipe"] ?? "";
      outletpipe = data[0]["outletPipe"] ?? "";
      material = data[0]["material"] ?? "";
      capacity = data[0]["capacity"] ?? "";
      status = data[0]["status"] ?? "";
      remarks = data[0]["remarks"] ?? "";
      user = data[0]["userId"] ?? "";
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
          'Tanks Details',
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
                    const SizedBox(
                      height: 10,
                    ),
                    editing == 'false' ? const SizedBox() : const SizedBox(),
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
                    MySelectInput(
                      onSubmit: (value) => setState(() => zone = value),
                      list: getZones(),
                      label: 'Zone',
                      value: zone,
                    ),
                    MyTextInput(
                      lines: 1,
                      value: elevation,
                      type: TextInputType.number,
                      onSubmit: (value) {
                        setState(() {
                          elevation = value;
                        });
                      },
                      title: 'Elevation',
                    ),
                    MyTextInput(
                      lines: 1,
                      value: area,
                      type: TextInputType.text,
                      onSubmit: (value) {
                        setState(() {
                          area = value;
                        });
                      },
                      title: 'Area',
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
                    MyTextInput(
                      lines: 1,
                      value: inletpipe,
                      type: TextInputType.text,
                      onSubmit: (value) {
                        setState(() {
                          inletpipe = value;
                        });
                      },
                      title: 'Inlet Pipe',
                    ),
                    MyTextInput(
                      lines: 1,
                      value: outletpipe,
                      type: TextInputType.text,
                      onSubmit: (value) {
                        setState(() {
                          outletpipe = value;
                        });
                      },
                      title: 'Outlet Pipe',
                    ),
                    MyTextInput(
                      lines: 1,
                      value: material,
                      type: TextInputType.text,
                      onSubmit: (value) {
                        setState(() {
                          material = value;
                        });
                      },
                      title: 'Material',
                    ),
                    MyTextInput(
                      lines: 1,
                      value: capacity,
                      type: TextInputType.text,
                      onSubmit: (value) {
                        setState(() {
                          capacity = value;
                        });
                      },
                      title: 'Capacity',
                    ),
                    MySelectInput(
                      onSubmit: (value) {
                        setState(() {
                          status = value;
                        });
                      },
                      list: const [
                        "--Select--",
                        "Active",
                        "Inactive",
                      ],
                      label: 'Status',
                      value: status,
                    ),
                    MyTextInput(
                      lines: 1,
                      value: remarks,
                      type: TextInputType.text,
                      onSubmit: (value) {
                        setState(() {
                          remarks = value;
                        });
                      },
                      title: 'Remarks',
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: SubmitButton(
                        label: "Submit",
                        onButtonPressed: () async {
                          setState(() {
                            isLoading =
                                LoadingAnimationWidget.staggeredDotsWave(
                                    color: const Color(0xff0288D1), size: 100);
                          });
                          var res = await submitData(
                              tankID,
                              lat.toString(),
                              long.toString(),
                              name,
                              zone,
                              elevation,
                              area,
                              location,
                              inletpipe,
                              outletpipe,
                              material,
                              capacity,
                              status,
                              remarks,
                              staffid,
                              editing);

                          setState(() {
                            isLoading = null;
                            if (res.error == null) {
                              error = "";
                              _showSnackBar(res.success, true);
                            } else {
                              error = res.error;
                              _showSnackBar(error, false);
                            }
                          });
                          if (res.error == null) {
                            // PROCEED TO NEXT PAGE
                            Timer(const Duration(seconds: 2), () {
                              Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => Assets(
                                            staffid: staffid,
                                          )));
                            });
                          }
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
    String tankID,
    String lat,
    String long,
    String name,
    String zone,
    String elevation,
    String area,
    String location,
    String inletpipe,
    String outletpipe,
    String material,
    String capacity,
    String status,
    String remarks,
    String staffid,
    String? editing) async {
  try {
    http.Response response;
    const storage = FlutterSecureStorage();
    String? update = await storage.read(key: "updateLocation");

    // Debug: Print the full URL and request body
    String url = editing == 'true' && tankID.isNotEmpty
        ? "${getUrl()}wt/tanks/$tankID"
        : "${getUrl()}wt/tanks";
    print("Submitting to URL: $url");

    Map<String, dynamic> requestBody = {
      'latitude': lat,
      'longitude': long,
      'name': name,
      'zone': zone,
      'elevation': elevation,
      'area': area,
      'location': location,
      'inletPipe': inletpipe,
      'outletPipe': outletpipe,
      'material': material,
      'capacity': capacity,
      'status': status,
      'remarks': remarks,
      'userId': staffid
    };

    print("Request body: ${jsonEncode(requestBody)}");

    if (editing == 'true' && tankID.isNotEmpty) {
      response = await http.put(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(requestBody),
      );
    } else {
      response = await http.post(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(requestBody),
      );
    }

    print("Response status code: ${response.statusCode}");
    print("Response body: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      return Message(
        token: responseData['data']?['id'],
        success: responseData['message'] ?? "Tank saved successfully",
        error: null,
      );
    } else {
      String errorMessage;
      try {
        var responseBody = jsonDecode(response.body);
        errorMessage =
            responseBody['error'] ?? "Server error! Contact administrator.";
      } catch (e) {
        errorMessage =
            "Server returned invalid response. Status: ${response.statusCode}";
      }
      return Message(
        token: null,
        success: null,
        error: errorMessage,
      );
    }
  } catch (e) {
    print("Error submitting tank data: $e");
    return Message(
      token: null,
      success: null,
      error: "Connection failed! Check your internet connection. Error: $e",
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
