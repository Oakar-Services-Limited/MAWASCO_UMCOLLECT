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

class WaterPipes extends StatefulWidget {
  final List<Map<String, double>> coordinates;
  const WaterPipes({
    super.key,
    required this.coordinates,
  });

  @override
  State<WaterPipes> createState() => _WaterPipesState();
}

class _WaterPipesState extends State<WaterPipes> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final storage = const FlutterSecureStorage();
  late Position position;
  String? editing = 'false';
  String error = '';
  String waterpipeID = '';
  String linename = '';
  String material = '';
  String intake = '';
  String lineType = '';
  String function = '';
  String dma = '';
  String route = '';
  String schemename = '';
  String zone = '';
  String size = '';
  String status = '';
  String remarks = '';
  String user = '';
  String staffid = '';

  dynamic data;

  var isLoading;

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
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
        prefillForm(data);
      } else {}
    } catch (e) {}
  }

  prefillForm(data) async {
    var fetchedData = await storage.read(key: "data");
    data = json.decode(fetchedData!);

    setState(() {
      waterpipeID = data[0]["id"] ?? "";
      linename = data[0]["lineName"] ?? "";
      lineType = data[0]["lineType"] ?? "";
      material = data[0]["material"] ?? "";
      intake = data[0]["intake"]?.toString() ?? "";
      function = data[0]["function"] ?? "";
      dma = data[0]["dma"] ?? "";
      route = data[0]["route"] ?? "";
      schemename = data[0]["schemeName"] ?? "";
      zone = data[0]["zone"] ?? "";
      size = data[0]["size"] ?? "";
      status = data[0]["status"] ?? "";
      remarks = data[0]["remarks"] ?? "";
      user = data[0]["userId"] ?? "";
    });
  }

  @override
  void initState() {
    fetchStoredData();
    print("Coordinates are now: " + widget.coordinates.toString());
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
          'Water Pipe Details',
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
                      height: 10,
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
                    MySelectInput(
                      onSubmit: (value) {
                        setState(() {
                          lineType = value;
                        });
                      },
                      list: const [
                        "--Select--",
                        "Feeders",
                        "Sewer Lines",
                        "Main Lines",
                      ],
                      label: 'Line Type',
                      value: lineType,
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
                          function = value;
                        });
                      },
                      list: const [
                        "--Select--",
                        "Laterals",
                        "Service Lines",
                        "Main Lines",
                      ],
                      label: 'Function',
                      value: function,
                    ),
                    MySelectInput(
                      onSubmit: (value) => setState(() => dma = value),
                      list: getDMAs(),
                      label: 'DMA',
                      value: dma,
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
                      onSubmit: (value) {
                        setState(() {
                          size = value;
                        });
                      },
                      list: const [
                        "--Select--",
                        "0.5",
                        "1",
                        "0.75",
                        "2",
                        "3",
                        "4",
                        "5",
                        "6",
                        "8",
                        "10",
                        "12",
                        "14",
                      ],
                      label: 'Size',
                      value: size,
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
                      value: '',
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
                              widget.coordinates,
                              linename,
                              lineType,
                              material,
                              intake,
                              function,
                              dma,
                              route,
                              schemename,
                              zone,
                              size,
                              status,
                              remarks,
                              staffid);

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
}

Future<Message> submitData(
    List<Map<String, double>> coordinates,
    String linename,
    String lineType,
    String material,
    String intake,
    String function,
    String dma,
    String route,
    String schemename,
    String zone,
    String size,
    String status,
    String remarks,
    String staffid) async {
  try {
    // Validate required fields
    if (linename.isEmpty) {
      return Message(
          token: null, success: null, error: "Line Name is required");
    }
    if (lineType == "--Select--" || lineType.isEmpty) {
      return Message(
          token: null, success: null, error: "Line Type is required");
    }
    if (material.isEmpty) {
      return Message(token: null, success: null, error: "Material is required");
    }
    if (function == "--Select--" || function.isEmpty) {
      return Message(token: null, success: null, error: "Function is required");
    }
    if (dma == "--Select--" || dma.isEmpty) {
      return Message(token: null, success: null, error: "DMA is required");
    }
    if (schemename == "--Select--" || schemename.isEmpty) {
      return Message(
          token: null, success: null, error: "Scheme Name is required");
    }
    if (zone == "--Select--" || zone.isEmpty) {
      return Message(token: null, success: null, error: "Zone is required");
    }
    if (size == "--Select--" || size.isEmpty) {
      return Message(token: null, success: null, error: "Size is required");
    }
    if (status == "--Select--" || status.isEmpty) {
      return Message(token: null, success: null, error: "Status is required");
    }

    print("Submitting water pipe data...");
    print("Coordinates: $coordinates");
    print("Line Name: $linename");
    print("Line Type: $lineType");
    print("Material: $material");
    print("Function: $function");
    print("DMA: $dma");
    print("Scheme Name: $schemename");
    print("Zone: $zone");
    print("Size: $size");
    print("Status: $status");
    print("Staff ID: $staffid");

    var response = await http.post(
      Uri.parse("${getUrl()}wt/water-pipes"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'LineName': linename,
        'LineType': lineType,
        'Material': material,
        'Intake': intake,
        'Function': function,
        'DMA': dma,
        'Route': route,
        'SchemeName': schemename,
        'Zone': zone,
        'Size': size,
        'Status': status,
        'Remarks': remarks,
        'userId': staffid,
        'coordinates': coordinates
      }),
    );

    print("Response status code: ${response.statusCode}");
    print("Response body: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      return Message(
        token: responseData['data']?['id'],
        success: responseData['message'] ?? "Water pipe saved successfully",
        error: null,
      );
    } else {
      String errorMessage;
      try {
        var responseBody = jsonDecode(response.body);
        errorMessage = responseBody['error'] ??
            responseBody['message'] ??
            "Server error (${response.statusCode})! Please check all required fields.";
        print("Error details: $errorMessage");
      } catch (e) {
        errorMessage =
            "Server returned invalid response. Status: ${response.statusCode}";
        print("Error parsing response: $e");
      }
      return Message(
        token: null,
        success: null,
        error: errorMessage,
      );
    }
  } catch (e) {
    print("Error submitting water pipe data: $e");
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
