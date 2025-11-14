// ignore_for_file: use_build_context_synchronously, non_constant_identifier_depths, file_depths

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

class PumpingStations extends StatefulWidget {
  const PumpingStations({
    super.key,
  });

  @override
  State<PumpingStations> createState() => _PumpingStationsState();
}

class _PumpingStationsState extends State<PumpingStations> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final storage = const FlutterSecureStorage();
  late Position position;

  var long = 36.0, lat = -2.0, acc = 100.0;
  String error = '';
  String? editing = 'false';
  String staffid = '';
  String pumpingStationID = '';
  String name = '';
  String depth = '';
  String material = '';
  String status = '';
  String route = '';
  String remarks = '';
  String user = '';
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
      pumpingStationID = data[0]["ID"];
      name = data[0]["name"];
      depth = data[0]["Depth"];
      material = data[0]["Material"];
      status = data[0]["Status"];
      route = data[0]["Route"];
      remarks = data[0]["Remarks"];
      user = data[0]["User"];
    });
  }

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
          'Pumping Stations Details',
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
                      value: name,
                      type: TextInputType.text,
                      onSubmit: (value) {
                        setState(() {
                          name = value;
                        });
                      },
                      title: 'Name',
                    ),
                    MyTextInput(
                      lines: 1,
                      value: depth,
                      type: TextInputType.numberWithOptions(decimal: true),
                      onSubmit: (value) {
                        setState(() {
                          depth = value;
                        });
                      },
                      title: 'Depth',
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
                              pumpingStationID,
                              lat.toString(),
                              long.toString(),
                              name,
                              depth,
                              material,
                              status,
                              route,
                              remarks,
                              staffid,
                              editing);

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
}

Future<Message> submitData(
  String pumpingStationID,
  String lat,
  String long,
  String name,
  String depth,
  String material,
  String status,
  String route,
  String remarks,
  String staffid,
  String? editing,
) async {
  try {
    // Debug print
    var response;
    final requestBody = editing == 'true'
        ? {
            'name': name,
            'depth': depth,
            'material': material,
            'status': status,
            'route': route,
            'remarks': remarks,
            'userId': staffid,
          }
        : {
            'name': name,
            'depth': depth,
            'material': material,
            'status': status,
            'route': route,
            'remarks': remarks,
            'userId': staffid,
            'latitude': lat,
            'longitude': long,
          };

    if (editing == 'true') {
      response = await http.put(
        Uri.parse("${getUrl()}sr/pumpingstations/$pumpingStationID"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(requestBody),
      );
    } else {
      response = await http.post(
        Uri.parse("${getUrl()}sr/pumpingstations"),
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
        success:
            responseData['message'] ?? "PumpingStations saved successfully",
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
          error: "Server error! Contact administrator.",
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
