// ignore_for_file: use_build_context_synchronously, non_constant_identifier_names, file_names, prefer_typing_uninitialized_variables

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:um_collect/components/MyDrawer.dart';
import 'package:um_collect/components/MySelectInput.dart';
import 'package:um_collect/components/MyTextInput.dart';
import 'package:um_collect/components/offline_pending_card.dart';
import 'package:um_collect/components/SubmitButton.dart';
import 'package:um_collect/components/Utils.dart';
import 'package:um_collect/services/connectivity_helper.dart';
import 'package:um_collect/services/database_helper.dart';
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
  String role = '';

  dynamic data;

  var isLoading;

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
        role = decoded["role"] ?? '';
      });

      if (editing == 'true') {
        prefillForm(data);
      } else {}
    } catch (e) {
      // 
    }
  }

  Future<void> prefillForm(data) async {
    var fetchedData = await storage.read(key: "data");
    data = json.decode(fetchedData!);

    setState(() {
      waterpipeID = data[0]["id"] ?? "";
      linename = data[0]["lineName"] ?? "";
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
                    const OfflinePendingCard(
                      types: ['asset_water_pipes'],
                      label: 'Water Pipes',
                    ),
                    MyTextInput(
                      lines: 1,
                      value: linename,
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
                          material = value;
                          // Reset size when material changes
                          size = '';
                        });
                      },
                      list: const ["--Select--", "HDPE", "PVC", "GI"],
                      label: 'Material',
                      value: material,
                    ),
                    MySelectInput(
                      onSubmit: (value) {
                        setState(() {
                          size = value;
                        });
                      },
                      list: material == "HDPE" || material == "PVC"
                          ? const [
                              "--Select--",
                              "20mm",
                              "25mm",
                              "32mm",
                              "40mm",
                              "50mm",
                              "63mm",
                              "75mm",
                              "90mm",
                              "110mm",
                              "160mm",
                              "225mm",
                              "280mm",
                              "315mm",
                              "355mm"
                            ]
                          : material == "GI"
                              ? const [
                                  "--Select--",
                                  "15mm",
                                  "20mm",
                                  "25mm",
                                  "40mm",
                                  "50mm",
                                  "60mm",
                                  "80mm",
                                  "100mm",
                                  "150mm",
                                  "200mm",
                                  "250mm",
                                  "300mm",
                                  "350mm"
                                ]
                              : const ["--Select--"],
                      label: 'Size',
                      value: size,
                    ),
                    MyTextInput(
                      lines: 1,
                      value: intake,
                      type: TextInputType.numberWithOptions(decimal: true),
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
                          // Restrict editing to Super Admins only
                          if (editing == 'true' && role != 'Super Admin') {
                            _showSnackBar(
                                'Updating asset restricted to Super Admins only',
                                false);
                            return;
                          }
                          setState(() {
                            isLoading =
                                LoadingAnimationWidget.staggeredDotsWave(
                                    color: const Color(0xff0288D1), size: 100);
                          });
                          var res = await submitData(
                              widget.coordinates,
                              linename,
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
  final db = DatabaseHelper();
  final isOnline = await ConnectivityHelper().checkConnectivity();

  Future<Message> queueOffline(String reason) async {
    final payload = <String, dynamic>{
      'LineName': linename,
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
      'coordinates': coordinates,
    };

    await db.saveSubmission(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      formId: 'asset_water_pipes',
      formName: 'Water Pipe',
      responses: {
        '_type': 'asset_water_pipes',
        '_endpoint': 'wt/water-pipes',
        '_method': 'POST',
        '_body': payload,
      },
    );

    return Message(
      token: null,
      success:
          "Saved offline. Will sync when you have internet. ($reason)",
      error: null,
    );
  }

  try {
    // Validate required fields
    if (linename.isEmpty) {
      return Message(
          token: null, success: null, error: "Line Name is required");
    }

    if (material.isEmpty) {
      return Message(token: null, success: null, error: "Material is required");
    }
    if (function == "--Select--" || function.isEmpty) {
      return Message(token: null, success: null, error: "Function is required");
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

    if (!isOnline) {
      return await queueOffline('Offline');
    }

    var response = await http.post(
      Uri.parse("${getUrl()}wt/water-pipes"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'LineName': linename,
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
    return await queueOffline('Network error');
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
