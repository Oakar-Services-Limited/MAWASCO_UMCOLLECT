// ignore_for_file: use_build_context_synchronously, non_constant_identifier_names, file_names

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kiambu_umcollect/components/MySelectInput.dart';
import 'package:kiambu_umcollect/components/MyTextInput.dart';
import 'package:kiambu_umcollect/components/StaffDrawer.dart';
import 'package:kiambu_umcollect/components/SubmitButton.dart';
import 'package:kiambu_umcollect/components/TextResponse.dart';
import 'package:kiambu_umcollect/components/Utils.dart';
import 'package:kiambu_umcollect/models/Map.dart';
import 'package:kiambu_umcollect/pages/Assets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:http/http.dart' as http;

class Valves extends StatefulWidget {
  const Valves({
    super.key,
  });

  @override
  State<Valves> createState() => _ValvesState();
}

class _ValvesState extends State<Valves> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final storage = const FlutterSecureStorage();
  late Position position;

  var long = 36.0, lat = -2.0, acc = 100.0;
  String error = '';
  String? editing = 'false';
  String staffid = '';
  String valveID = '';
  String dma = '';
  String type = '';
  String status = '';
  String size = '';
  String schemename = '';
  String zone = '';
  String route = '';
  String location = '';
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
      var decoded = parseJwt(token.toString());
      editing = await storage.read(key: "editing");

      setState(() {
        user = decoded["name"];
        staffid = decoded["id"];
      });

      if (editing == 'true') {
        //  prefillForm(data);
      } else {}
    } catch (e) {}
  }

  // prefillForm(data) async {
  //   var fetchedData = await storage.read(key: "data");
  //   data = json.decode(fetchedData!);

  //   setState(() {
  //     valveID = data[0]["ID"] ?? "";
  //     type = data[0]["Type"] ?? "";
  //     name = data[0]["Name"] ?? "";
  //     diameter = data[0]["Diameter"]?.toString() ?? "";
  //     zone = data[0]["Zone"]?.toString() ?? "";
  //     subzone = data[0]["Subzone"]?.toString() ?? "";
  //     pipelinename = data[0]["Pipeline"] ?? '' ?? "";
  //     year = data[0]["YearOfInstallation"]?.toString() ?? "";
  //     depth = data[0]["Depth"]?.toString() ?? "";
  //     status = data[0]["Status"] ?? "";
  //     remarks = data[0]["Remarks"] ?? "";
  //     myimage = data[0]["Picture"] ?? '';
  //   });
  // }

  getLocation() async {
    position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      long = position.longitude;
      lat = position.latitude;
      acc = position.accuracy;
    });
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
          'Valves Details',
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
                    MySelectInput(
                      onSubmit: (value) => setState(() => dma = value),
                      list: getDMAs(),
                      label: 'DMA',
                      value: dma,
                    ),
                    MySelectInput(
                      onSubmit: (value) {
                        setState(() {
                          type = value;
                        });
                      },
                      list: const [
                        "--Select--",
                        "Gate Valve",
                        "Air Valve",
                        "Sluice Valve",
                        "PRVs",
                      ],
                      label: 'Type',
                      value: type,
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
                      value: size,
                      type: TextInputType.text,
                      onSubmit: (value) {
                        setState(() {
                          size = value;
                        });
                      },
                      title: 'Size',
                    ),
                    MySelectInput(
                      onSubmit: (value) {
                        setState(() {
                          schemename = value;
                        });
                      },
                      list: const [
                        "--Select--",
                        "Rural",
                        "Urban",
                      ],
                      label: 'Scheme Name',
                      value: schemename,
                    ),
                    MySelectInput(
                      onSubmit: (value) => setState(() => zone = value),
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
                              valveID,
                              lat.toString(),
                              long.toString(),
                              dma,
                              type,
                              status,
                              size,
                              schemename,
                              zone,
                              route,
                              location,
                              remarks,
                              staffid,
                              editing);

                          setState(() {
                            isLoading = null;
                            if (res.error == null) {
                              error = "";
                              _showSnackBar(res.success, true);
                              // PROCEED TO NEXT PAGE
                              Timer(const Duration(seconds: 2), () {
                                Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => Assets(
                                              staffid: staffid,
                                            )));
                              });
                            } else {
                              error = res.error;
                              _showSnackBar(error, false);
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
}

Future<Message> submitData(
    String valveID,
    String lat,
    String long,
    String dma,
    String type,
    String status,
    String size,
    String schemename,
    String zone,
    String route,
    String location,
    String remarks,
    String staffid,
    String? editing) async {
  try {
    http.Response response;
    const storage = FlutterSecureStorage();
    String? update = await storage.read(key: "updateLocation");

    if (editing == 'true') {
      response = await http.put(
        Uri.parse("${getUrl()}wt/valves/$valveID"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'type': type,
          'dma': dma,
          'status': status,
          'size': size,
          'name': schemename,
          'zone': zone,
          'route': route,
          'location': location,
          'remarks': remarks,
          'userId': staffid,
          'latitude': lat,
          'longitude': long,
        }),
      );
    } else {
      response = await http.post(
        Uri.parse("${getUrl()}wt/valves"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'type': type,
          'dma': dma,
          'status': status,
          'size': size,
          'schemeName': schemename,
          'zone': zone,
          'route': route,
          'location': location,
          'remarks': remarks,
          'userId': staffid,
          'latitude': lat,
          'longitude': long,
        }),
      );
    }

    print("Response status code: ${response.statusCode}");
    print("Response body: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      return Message(
        token: responseData['data']?['id'],
        success: responseData['message'] ?? "Valve saved successfully",
        error: null,
      );
    } else {
      // Try to parse error response, but handle non-JSON responses
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
