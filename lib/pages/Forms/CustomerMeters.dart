// ignore_for_file: use_build_context_synchronously, non_constant_identifier_names, file_names, unused_field, prefer_typing_uninitialized_variables

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
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

class CustomerMeters extends StatefulWidget {
  final Map<String, dynamic> customerMeter;
  const CustomerMeters({super.key, required this.customerMeter});

  @override
  State<CustomerMeters> createState() => _CustomerMetersState();
}

class _CustomerMetersState extends State<CustomerMeters> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final storage = const FlutterSecureStorage();
  late Position position;
  StreamSubscription<Position>? _positionSubscription;

  var long = 36.0, lat = -2.0, acc = 100.0;
  String error = '';
  String accountNumberError = '';
  String? editing = 'false';
  String staffid = '';
  String accnum = '';
  String meterserial = '';
  String metertype = '';
  String meterclass = '';
  String size = '';
  String brandname = '';
  String material = '';
  String meterlocation = '';
  String status = '';
  String sewered = '';
  String othermeter = '';
  String installationmode = '';
  String remarks = '';
  late File? _image;
  final imagePicker = ImagePicker();
  String myimage = '';
  String user = '';
  String userid = '';
  String id = '';
  String role = '';
  dynamic data;

  // Add missing variables from CustomerMeters1
  String name = '';
  String phone = '';

  // Add missing variables from CustomerMeters2
  String accstatus = '';
  String acctype = '';
  String instituteMeterType = '';

  // Add missing variables from CustomerMeters3
  String schemename = '';
  String zone = '';
  String route = '';
  String dma = '';
  String location = '';
  String parcelno = '';

  var isLoading;

  Future<String> convertFileToBase64(XFile file) async {
    List<int> fileBytes = await file.readAsBytes();
    String base64String = base64Encode(fileBytes);
    return base64String;
  }

  Future<void> takePhoto() async {
    final pickedFile = await imagePicker.pickImage(
      source: ImageSource.camera, // Open the camera to take a photo
    );

    if (pickedFile != null) {
      String base64Image = await convertFileToBase64(pickedFile);
      if (!mounted) return;
      setState(() {
        _image = File(pickedFile.path);
        myimage = base64Image;
      });
    }
  }

  @override
  void initState() {
    _image = null;
    getLocation();
    fetchStoredData();

    super.initState();
  }

  Future<void> getLocation() async {
    LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation, // Highest possible
      distanceFilter: 0, // Get all movements
    );

    _positionSubscription = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position pos) {
      if (!mounted) return;
      setState(() {
        long = pos.longitude;
        lat = pos.latitude;
        acc = pos.accuracy;
        position = pos;
      });
    });
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  Future<void> fetchStoredData() async {
    try {
      var token = await storage.read(key: "mwstaffjwt");
      var decoded = parseJwt(token.toString());
      if (!mounted) return;
      setState(() {
        userid = decoded["id"];
        role = decoded["role"] ?? '';
      });
      if (mounted && widget.customerMeter.isNotEmpty) {
        prefillForm(widget.customerMeter);
      }
    } catch (e) {
      // Error handling: silently ignore errors during data fetching
    }
  }

  Future<void> prefillForm(data) async {
    if (!mounted) return;
    setState(() {
      id = data["id"] ?? "";
      accnum = data["accountNo"]?.toString() ?? "";
      meterserial = data["meterNo"] ?? "";
      metertype = data["meterStatus"] ?? "";
      size = data["meterSize"]?.toString() ?? "";
      brandname = data["brand"] ?? "";
      material = data["material"] ?? "";
      meterlocation = data["location"] ?? "";
      status = data["meterStatus"] ?? "";
      remarks = data["remarks"] ?? "";

      name = data["name"] ?? "";
      phone = data["phone"]?.toString() ?? "";

      accstatus = data["accountStatus"] ?? "";
      acctype = data["accountType"] ?? "";
      instituteMeterType = data["institution"] ?? "";

      schemename = data["schemeName"] ?? "";
      zone = data["zone"] ?? "";
      route = data["route"] ?? "";
      dma = data["dma"] ?? "";
      location = data["location"] ?? "";
      parcelno = data["parcelNo"] ?? "";

      // New fields
      meterclass = data["meterClass"] ?? "";
      lat = double.tryParse(data["latitude"]?.toString() ?? "") ?? lat;
      long = double.tryParse(data["longitude"]?.toString() ?? "") ?? long;
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
          'Customer Details',
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
                            width: double.infinity,
                            child: MyMap(
                              lat: lat,
                              lon: long,
                              acc: acc,
                            ))),
                    const SizedBox(
                      height: 10,
                    ),
                    editing == 'false'
                        ? Column(
                            children: [
                              const Text(
                                'Take a Photo',
                                style: TextStyle(
                                  color: Color(0xff0288D1),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                ),
                              ),
                              const SizedBox(
                                height: 12,
                              ),
                              Card(
                                elevation: 2,
                                clipBehavior: Clip.hardEdge,
                                child: Stack(
                                  children: [
                                    SizedBox(
                                      height: 250,
                                      width: double.infinity,
                                      child: _image == null
                                          ? const Align(
                                              alignment: Alignment.center,
                                              child: Text(
                                                "No image selected",
                                                style: TextStyle(
                                                  color: Color.fromARGB(
                                                      255, 28, 100, 140),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            )
                                          : GestureDetector(
                                              onTap: () {
                                                showDialog(
                                                  context: context,
                                                  builder:
                                                      (BuildContext context) {
                                                    return Dialog(
                                                      child: Container(
                                                        color: Colors.black,
                                                        child:
                                                            InteractiveViewer(
                                                          child: Image.file(
                                                              _image!),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                              child: Image.file(
                                                _image!,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                    ),
                                    Align(
                                      alignment: Alignment.bottomCenter,
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.photo_camera,
                                          size: 50,
                                          color: Color(0xff0288D1),
                                        ),
                                        onPressed: () => takePhoto(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : const SizedBox(),
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
                      value: phone,
                      type: TextInputType.phone,
                      onSubmit: (value) {
                        setState(() {
                          phone = value;
                        });
                      },
                      title: 'Phone',
                    ),
                    MyTextInput(
                      lines: 1,
                      value: accnum,
                      type: TextInputType.number,
                      maxLength: 5,
                      onSubmit: (value) {
                        setState(() {
                          accnum = value;
                          // Validate account number
                          if (value.isEmpty) {
                            accountNumberError = '';
                          } else if (value.length < 5) {
                            accountNumberError =
                                'Enter ${5 - value.length} more digit(s)';
                          } else {
                            accountNumberError = '';
                          }
                        });
                      },
                      title: 'Account Number',
                    ),
                    if (accountNumberError.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 8, top: 4),
                        child: Text(
                          accountNumberError,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    MyTextInput(
                      lines: 1,
                      value: meterserial,
                      type: TextInputType.text,
                      onSubmit: (value) {
                        setState(() {
                          meterserial = value;
                        });
                      },
                      title: 'Meter Number',
                    ),
                    MySelectInput(
                      onSubmit: (value) => setState(() => size = value),
                      list: const [
                        "--Select--",
                        "0.5",
                        "0.75",
                        "1",
                        "1.25",
                        "1.5",
                        "2",
                        "3"
                      ],
                      label: 'Meter Size',
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
                        "Metered",
                        "Unmetered",
                      ],
                      label: 'Meter Status',
                      value: status,
                    ),
                    MySelectInput(
                      onSubmit: (value) {
                        setState(() {
                          accstatus = value;
                        });
                      },
                      list: const [
                        "--Select--",
                        "ACTIVE",
                        "INACTIVE",
                        "DISCONNECTED",
                        "SEALED",
                        "DORMANT",
                        "CLOSED"
                      ],
                      label: 'Account Status',
                      value: accstatus,
                    ),
                    MySelectInput(
                      onSubmit: (value) => setState(() => acctype = value),
                      list: const ["--Select--", "Domestic", "Commercial"],
                      label: 'Account Type',
                      value: acctype,
                    ),
                    MySelectInput(
                      onSubmit: (value) =>
                          setState(() => instituteMeterType = value),
                      list: const ["--Select--", "Large", "Medium", "Small"],
                      label:
                          'Is it an Institution Meter? If yes, select type...',
                      value: instituteMeterType,
                    ),
                    MySelectInput(
                      onSubmit: (value) => setState(() => brandname = value),
                      list: const [
                        "--Select--",
                        "YUONSO",
                        "Honey Well",
                        "Diehl",
                        "Lianli",
                        "Elstar Kent",
                        "Wesan-Wottman",
                        "Janz",
                        "Other"
                      ],
                      label: 'Meter Brand',
                      value: brandname,
                    ),
                    MySelectInput(
                      onSubmit: (value) => setState(() => material = value),
                      list: const [
                        "--Select--",
                        "Polymer",
                        "Brass",
                        "Plastic",
                      ],
                      label: 'Meter Material',
                      value: material,
                    ),
                    MySelectInput(
                      onSubmit: (value) {
                        setState(() {
                          meterclass = value;
                        });
                      },
                      list: const [
                        "--Select--",
                        "A",
                        "B",
                        "C",
                        "R160",
                        "R200",
                        "R250",
                      ],
                      label: 'Meter Class',
                      value: meterclass,
                    ),
                    MySelectInput(
                      onSubmit: (value) => setState(() => schemename = value),
                      list: const ["--Select--", "Rural", "Urban"],
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
                      onSubmit: (value) => setState(() => route = value),
                      title: 'Route',
                    ),
                    MySelectInput(
                      onSubmit: (value) => setState(() => dma = value),
                      list: getDMAs(),
                      label: 'DMA',
                      value: dma,
                    ),
                    MyTextInput(
                      lines: 1,
                      value: location,
                      type: TextInputType.text,
                      onSubmit: (value) => setState(() => location = value),
                      title: 'Location',
                    ),
                    MyTextInput(
                      lines: 1,
                      value: parcelno,
                      type: TextInputType.text,
                      onSubmit: (value) => setState(() => parcelno = value),
                      title: 'Parcel Number',
                    ),
                    MyTextInput(
                      lines: 1,
                      value: remarks,
                      type: TextInputType.text,
                      onSubmit: (value) => setState(() => remarks = value),
                      title: 'Remarks',
                    ),
                    Center(
                      child: TextResponse(
                        label: error,
                      ),
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
                          if (id != '' && role != 'Super Admin') {
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
                            name,
                            phone,
                            accnum,
                            meterserial,
                            size,
                            status,
                            accstatus,
                            acctype,
                            instituteMeterType,
                            brandname,
                            material,
                            meterclass,
                            schemename,
                            zone,
                            route,
                            dma,
                            location,
                            parcelno,
                            remarks,
                            userid,
                            lat.toString(),
                            long.toString(),
                            myimage,
                            editing,
                            id,
                          );

                          if (!mounted) return;
                          setState(() {
                            isLoading = null;
                            if (res.success != null) {
                              error = "";
                              accountNumberError = "";
                              _showSnackBar(res.success, true);
                            } else {
                              error = res.error ?? "Unknown error occurred";
                              _showSnackBar(error, false);
                            }
                          });
                          if (res.success != null && mounted) {
                            await storage.write(
                                key: 'meterid', value: res.token);

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
  String name,
  String phone,
  String accountnumber,
  String meterserial,
  String size,
  String status,
  String accstatus,
  String acctype,
  String instituteMeterType,
  String brandname,
  String material,
  String meterclass,
  String schemename,
  String zone,
  String route,
  String dma,
  String location,
  String parcelno,
  String remarks,
  String userid,
  String lat,
  String long,
  String myimage,
  String? editing,
  String? id,
) async {
  if (accountnumber.isEmpty) {
    return Message(
      token: null,
      success: null,
      error: "Account number must be filled!",
    );
  }

  // Validate 5-digit constraint
  if (accountnumber.length != 5 ||
      !RegExp(r'^[0-9]{5}$').hasMatch(accountnumber)) {
    return Message(
      token: null,
      success: null,
      error: "Account number must be exactly 5 digits",
    );
  }

  if (zone == "--Select--") {
    return Message(
      token: null,
      success: null,
      error: "Select Zone!!",
    );
  }

  if (dma == "--Select--") {
    return Message(
      token: null,
      success: null,
      error: "Select DMA!!",
    );
  }

  if (name.isEmpty) {
    return Message(
      token: null,
      success: null,
      error: "Name must be filled!",
    );
  }

  try {
    http.Response response;

    final payload = {
      'name': name,
      'phone': phone,
      'accountNo': accountnumber,
      'meterNo': meterserial,
      'accountStatus': accstatus,
      'accountType': acctype,
      'institution': instituteMeterType,
      'meterStatus': status,
      'brand': brandname,
      'material': material,
      'meterClass': meterclass,
      'schemeName': schemename,
      'zone': zone,
      'route': route,
      'dma': dma,
      'location': location,
      'parcelNo': parcelno,
      'meterSize': size,
      'remarks': remarks,
      'userId': userid,
      'latitude': id == '' ? lat : null,
      'longitude': id == '' ? long : null,
    };
    if (id != '') {
      response = await http.put(
        Uri.parse("${getUrl()}wt/customer-meters/$id"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(payload),
      );
    } else {
      response = await http.post(
        Uri.parse("${getUrl()}wt/customer-meters"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(payload),
      );
    }

    if (response.statusCode == 201 || response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      if (responseData['success'] != null) {
        return Message(
          token: null,
          success: id == '' ? "Created successfully" : "Updated successfully",
          error: null,
        );
      } else {
        return Message(
          token: null,
          success: null,
          error: responseData['error'] ?? "Invalid response format",
        );
      }
    } else {
      var responseBody = jsonDecode(response.body);
      return Message(
        token: null,
        success: null,
        error: responseBody['error'] ?? "Server error! Contact administrator.",
      );
    }
  } catch (e) {
    return Message(
      token: null,
      success: null,
      error: "Connection failed! Check your internet connection. Error: $e",
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
      token: json['data']?['id'],
      success: json['success'],
      error: json['error'],
    );
  }
}
