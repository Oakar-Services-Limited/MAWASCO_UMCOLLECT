// ignore_for_file: use_build_context_synchronously, non_constant_identifier_names, file_names, prefer_typing_uninitialized_variables

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:um_collect/components/MyDrawer.dart';
import 'package:um_collect/components/MySelectInput.dart';
import 'package:um_collect/components/MyTextInput.dart';
import 'package:um_collect/components/SubmitButton.dart';
import 'package:um_collect/components/Utils.dart';
import 'package:um_collect/pages/Assets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:http/http.dart' as http;

class LineProjects extends StatefulWidget {
  final List<Map<String, double>> coordinates;
  const LineProjects({
    super.key,
    required this.coordinates,
  });

  @override
  State<LineProjects> createState() => _LineProjectsState();
}

class _LineProjectsState extends State<LineProjects> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final storage = const FlutterSecureStorage();
  late Position position;
  String staffid = '';
  String? editing = 'false';
  String lineprojectID = '';
  String error = '';
  String lineType = '--Select--'; // Water Pipes or Sewerline
  String linename = '';
  String intake = '';
  String zone = '';
  String route = '';
  String size = '';
  String user = '';
  String role = '';

  var isLoading;
  Timer? _navigationTimer;

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchStoredData() async {
    var token = await storage.read(key: "mwstaffjwt");
    var decoded = parseJwt(token.toString());

    if (!mounted) return;

    setState(() {
      user = decoded["name"];
      staffid = decoded["id"];
      role = decoded["role"] ?? '';
    });
  }

  prefillForm(data) async {
    var fetchedData = await storage.read(key: "data");
    data = json.decode(fetchedData!);

    if (!mounted) return;

    setState(() {
      data[0]["LineName"] = linename;
      data[0]["LineType"] = lineType;
      data[0]["Intake"] = intake;
      data[0]["Route"] = route;
      data[0]["Zone"] = zone;
      data[0]["Size"] = size;
    });
  }

  @override
  void initState() {
    fetchStoredData();
    super.initState();
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
          'Line Project',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xff0288D1),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const MyDrawer(),
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
                    MySelectInput(
                      onSubmit: (value) {
                        setState(() {
                          lineType = value;
                          // Clear fields when switching types
                          if (value == '--Select--') {
                            linename = '';
                            intake = '';
                            zone = '--Select--';
                            route = '';
                            size = '';
                          }
                        });
                      },
                      list: const [
                        "--Select--",
                        "Water Pipes",
                        "Sewerline",
                      ],
                      label: 'Line Type *',
                      value: lineType,
                    ),
                    if (lineType != '--Select--') ...[
                      MyTextInput(
                        lines: 1,
                        value: linename,
                        type: TextInputType.text,
                        onSubmit: (value) {
                          setState(() {
                            linename = value;
                          });
                        },
                        title: 'Line Name *',
                      ),
                      if (lineType == 'Water Pipes') ...[
                        MyTextInput(
                          lines: 1,
                          value: intake,
                          type: TextInputType.numberWithOptions(decimal: true),
                          onSubmit: (value) {
                            setState(() {
                              intake = value;
                            });
                          },
                          title: 'Intake *',
                        ),
                      ],
                      MyTextInput(
                        lines: 1,
                        value: size,
                        type: TextInputType.text,
                        onSubmit: (value) {
                          setState(() {
                            size = value;
                          });
                        },
                        title: 'Size *',
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
                        title: 'Route *',
                      ),
                      MySelectInput(
                        onSubmit: (value) => setState(() => zone = value),
                        list: getZones(),
                        label: 'Zone *',
                        value: zone,
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
                          // Validate required fields
                          if (lineType == '--Select--') {
                            _showSnackBar("Please select a line type", false);
                            return;
                          }

                          if (linename.isEmpty ||
                              size.isEmpty ||
                              route.isEmpty ||
                              zone == '--Select--') {
                            _showSnackBar(
                                "Please fill in all required fields", false);
                            return;
                          }

                          // Validate intake for Water Pipes only
                          if (lineType == 'Water Pipes' && intake.isEmpty) {
                            _showSnackBar(
                                "Please fill in all required fields", false);
                            return;
                          }

                          if (!mounted) return;

                          setState(() {
                            isLoading =
                                LoadingAnimationWidget.staggeredDotsWave(
                                    color: const Color(
                                        0xff0288D1), // Consistent blue color
                                    size: 100);
                          });

                          var res = await submitData(
                            widget.coordinates,
                            lineprojectID,
                            lineType,
                            linename,
                            intake,
                            zone,
                            route,
                            size,
                            staffid,
                            editing,
                          );

                          if (!mounted) return;

                          setState(() {
                            isLoading = null;
                          });

                          if (res.error == null) {
                            _showSnackBar(res.success, true);
                            // Proceed to next page after successful submission
                            _navigationTimer?.cancel();
                            _navigationTimer =
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
    List<Map<String, double>> coordinates,
    String lineprojectID,
    String lineType,
    String linename,
    String intake,
    String zone,
    String route,
    String size,
    String staffid,
    String? editing) async {
  try {
    // Debug print
    http.Response response;
    final requestBody = {
      'lineName': linename,
      'lineType': lineType,
      'zone': zone,
      'route': route,
      'size': size,
      'userId': staffid,
      'coordinates': coordinates
    };

    // Add intake only for Water Pipes
    if (lineType == 'Water Pipes') {
      requestBody['intake'] = intake;
    }

    if (editing == 'true') {
      response = await http.put(
        // Changed from post to put for editing
        Uri.parse("${getUrl()}pj/lines/$lineprojectID"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(requestBody),
      );
    } else {
      response = await http.post(
        Uri.parse("${getUrl()}pj/lines"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(requestBody),
      );
    }

    // Debug print
    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      return Message(
        token: responseData['data']?['id'],
        success: responseData['message'] ?? "Line project saved successfully",
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
        return Message(
          token: null,
          success: null,
          error:
              "Server returned invalid response. Status: ${response.statusCode}",
        );
      }
    }
  } catch (e) {
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
