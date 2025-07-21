// ignore_for_file: use_build_context_synchronously, non_constant_identifier_names, file_names

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
  String linename = '';
  String material = '';
  String intake = '';
  String type = '';
  String dma = '';
  String schemename = '';
  String zone = '';
  String subzone = '';
  String route = '';
  String size = '';
  String user = '';
  String role = '';

  var isLoading;

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  Future<void> fetchStoredData() async {
    var token = await storage.read(key: "mwstaffjwt");
    var decoded = parseJwt(token.toString());

    setState(() {
      user = decoded["name"];
      staffid = decoded["id"];
      role = decoded["role"] ?? '';
    });
  }

  prefillForm(data) async {
    var fetchedData = await storage.read(key: "data");
    data = json.decode(fetchedData!);

    setState(() {
      data[0]["LineName"] = linename;
      data[0]["Material"] = material;
      data[0]["Intake"] = intake;
      data[0]["Type"] = linename;
      data[0]["DMA"] = linename;
      data[0]["Route"] = linename;
      data[0]["SchemeName"] = linename;
      data[0]["Zone"] = linename;
      data[0]["Size"] = linename;
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
                    MyTextInput(
                      lines: 1,
                      value: '',
                      type: TextInputType.text,
                      onSubmit: (value) {
                        setState(() {
                          linename = value;
                        });
                      },
                      title: 'Line Name',
                    ),
                    MyTextInput(
                      lines: 1,
                      value: '',
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
                      value: '',
                      type: TextInputType.number,
                      onSubmit: (value) {
                        setState(() {
                          intake = value;
                        });
                      },
                      title: 'Intake',
                    ),
                    MySelectInput(
                      onSubmit: (value) {
                        setState(() {
                          type = value;
                        });
                      },
                      list: const [
                        "--Select--",
                        "Laterals",
                        "Service Lines",
                        "Main Lines",
                      ],
                      label: 'Type',
                      value: type,
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

                      MySelectInput(
                      onSubmit: (value) => setState(() => subzone = value),
                      list: getSubZones(),
                      label: 'Subzone',
                      value: subzone,
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
                      type: TextInputType.text,
                      onSubmit: (value) {
                        setState(() {
                          size = value;
                        });
                      },
                      title: 'Size',
                    ),
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
                          if (linename.isEmpty ||
                              material.isEmpty ||
                              type == '--Select--' ||
                              zone == '--Select--' ||
                              schemename == '--Select--') {
                            _showSnackBar(
                                "Please fill in all required fields", false);
                            return;
                          }

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
                            linename,
                            material,
                            intake,
                            type,
                            dma,
                            schemename,
                            zone,
                            route,
                            size,
                            staffid,
                            editing,
                          );

                          setState(() {
                            isLoading = null;
                            if (res.error == null) {
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
    List<Map<String, double>> coordinates,
    String lineprojectID,
    String linename,
    String material,
    String intake,
    String type,
    String dma,
    String schemename,
    String zone,
    String route,
    String size,
    String staffid,
    String? editing) async {
  try {
    // Debug print
    print("Submitting line project with staffid: $staffid");
    print("Coordinates count: ${coordinates.length}");

    http.Response response;
    final requestBody = {
      'lineName': linename, // Changed from LineName to match server
      'material': material,
      'intake': intake,
      'type': type,
      'dma': dma,
      'route': route,
      'schemeName': schemename, // Changed from SchemeName to match server
      'zone': zone,
      'size': size,
      'userId': staffid, // This is now correct
      'coordinates': coordinates
    };

    // Debug print
    print("Request body: ${jsonEncode(requestBody)}");

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
    print("Response status: ${response.statusCode}");
    print("Response body: ${response.body}");

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
