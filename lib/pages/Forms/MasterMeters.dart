// ignore_for_file: use_build_context_synchronously, non_constant_identifier_names, file_names, prefer_typing_uninitialized_variables

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
import 'package:um_collect/pages/home.dart';
import 'package:geolocator/geolocator.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:http/http.dart' as http;

class MasterMeters extends StatefulWidget {
  const MasterMeters({
    super.key,
  });

  @override
  State<MasterMeters> createState() => _MasterMetersState();
}

class _MasterMetersState extends State<MasterMeters> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final storage = const FlutterSecureStorage();
  late Position position;

  var long = 36.0, lat = -2.0, acc = 100.0;
  String error = '';
  String? editing = 'false';
  String staffid = '';
  String masterMeterID = '';
  String dma = '';
  String cover = '';
  String status = '';
  String category = '';
  String size = '';
  String name = '';
  String serial = '';
  String zone = '';
  String route = '';
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
      } else {}
    } catch (e) {
      //
    }
  }

  Future<void> prefillForm(data) async {
    var fetchedData = await storage.read(key: "data");
    data = json.decode(fetchedData!);

    if (!mounted) return;
    setState(() {
      masterMeterID = data[0]["id"]?.toString() ?? "";
      category = data[0]["category"]?.toString() ?? "";
      name = data[0]["name"]?.toString() ?? "";
      serial = data[0]["serial"]?.toString() ?? "";
      size = data[0]["size"]?.toString() ?? "";
      route = data[0]["route"]?.toString() ?? "";
      zone = data[0]["zone"]?.toString() ?? "";
      dma = data[0]["dma"]?.toString() ?? "";
      cover = data[0]["cover"]?.toString() ?? "";
      location = data[0]["location"]?.toString() ?? "";
      remarks = data[0]["remarks"]?.toString() ?? "";
      user = data[0]["userId"]?.toString() ?? "";
    });
  }

  Future<void> getLocation() async {
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
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => Assets(staffid: staffid)));
            },
          ),
        ],
        title: const Text(
          'MasterMeters Details',
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
                      value: serial,
                      type: TextInputType.number,
                      onSubmit: (value) {
                        setState(() {
                          serial = value;
                        });
                      },
                      title: 'Serial Number',
                    ),
                    MySelectInput(
                      onSubmit: (value) => setState(() => category = value),
                      list: const [
                        "--Select--",
                        "Production Meter",
                        "Zonal Meter",
                        "DMA Meter"
                      ],
                      label: 'Category',
                      value: category,
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
                      onSubmit: (value) => setState(() => zone = value),
                      list: getZones(),
                      label: 'Zone',
                      value: zone,
                    ),
                    MySelectInput(
                      onSubmit: (value) => setState(() => dma = value),
                      list: getDMAs(),
                      label: 'DMA',
                      value: dma,
                    ),
                    MyTextInput(
                      lines: 1,
                      value: cover,
                      type: TextInputType.text,
                      onSubmit: (value) {
                        setState(() {
                          cover = value;
                        });
                      },
                      title: 'Cover',
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
                              masterMeterID,
                              lat.toString(),
                              long.toString(),
                              name,
                              serial,
                              category,
                              size,
                              route,
                              zone,
                              dma,
                              cover,
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
                            } else {
                              error = res.error;
                              _showSnackBar(error, false);
                            }
                          });
                          if (res.error == null) {
                            // PROCEED TO NEXT PAGE
                            Timer(const Duration(seconds: 2), () {
                              if (!mounted) return;
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
    String masterMeterID,
    String lat,
    String long,
    String name,
    String serial,
    String category,
    String size,
    String route,
    String zone,
    String dma,
    String cover,
    String location,
    String remarks,
    String staffid,
    String? editing) async {
  try {
    var response;

    if (editing == 'true') {
      response = await http.put(
        Uri.parse("${getUrl()}wt/master-meters/$masterMeterID"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'name': name,
          'serial': serial,
          'category': category,
          'size': size,
          'route': route,
          'zone': zone,
          'dma': dma,
          'cover': cover,
          'location': location,
          'remarks': remarks,
          'userId': staffid,
        }),
      );
    } else {
      response = await http.post(
        Uri.parse("${getUrl()}wt/master-meters"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'name': name,
          'serial': serial,
          'category': category,
          'size': size,
          'route': route,
          'zone': zone,
          'dma': dma,
          'cover': cover,
          'location': location,
          'remarks': remarks,
          'userId': staffid,
          'longitude': double.parse(long),
          'latitude': double.parse(lat),
        }),
      );
    }

    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 203) {
      final responseData = jsonDecode(response.body);
      return Message(
        token: responseData['id'],
        success: "Master meter saved successfully",
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
