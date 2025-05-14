// ignore_for_file: use_build_context_synchronously, non_constant_identifier_names, file_names

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kiambu_umcollect/components/MyDrawer.dart';
import 'package:kiambu_umcollect/components/MySelectInput.dart';
import 'package:kiambu_umcollect/components/MyTextInput.dart';
import 'package:kiambu_umcollect/components/SubmitButton.dart';
import 'package:kiambu_umcollect/components/Utils.dart';
import 'package:kiambu_umcollect/pages/Assets.dart';
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
        // prefillForm(data);
      } else {}
    } catch (e) {}
  }

  // prefillForm(data) async {
  //   var fetchedData = await storage.read(key: "data");
  //   data = json.decode(fetchedData!);

  //   setState(() {
  //     waterpipeID = data[0]["ID"] ?? "";
  //     linetype = data[0]["Length"]?.toString() ?? "";
  //     linename = data[0]["Name"] ?? "";
  //     diameter = data[0]["Diameter"] ?? "";
  //     zone = data[0]["Material"] ?? "";
  //     pipematerial = data[0]["Length"]?.toString() ?? "";
  //     year = data[0]["Year"]?.toString() ?? "";

  //     wpclass = data[0]["Class"] ?? "";

  //     status = data[0]["Status"] ?? "";
  //     distribution = data[0]["Distribution"] ?? "";

  //     remarks = data[0]["Remarks"] ?? "";
  //   });
  // }

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
                      onSubmit: (value) {
                        setState(() {
                          dma = value;
                        });
                      },
                      list: const [
                        "--Select--",
                        "Saigon",
                        "Blue Valley",
                        "Karindundu",
                        "Mathaithi",
                        "Gathugu",
                        "Sofia",
                        "Indian",
                        "Industrial",
                        "Muthua",
                        "Ragati",
                        "Kiamariga Factory Line",
                        "Kiamariga Lower",
                        "Mbari ya Miiria",
                        "Karogogo",
                        "Kaiyaba",
                        "Ikonju",
                        "Gitumbi",
                        "Karembu",
                        "Mukangu",
                        "Kiangai",
                        "Ndiriti",
                        "Ihwagi",
                        "Jambo",
                        "Mugugutu",
                        "Gatheu",
                        "Kiunjugi/Kirima",
                        "Migingo/Giakaburi",
                        "Magutu",
                        "Giakimuru",
                        "Kanjuri",
                        "Gikore",
                      ],
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
    print("Coordinates here are now: " + coordinates.toString());
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

    // Debug: Print response details
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
