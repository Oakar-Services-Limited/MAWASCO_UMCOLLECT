// ignore_for_file: use_build_context_synchronously, non_constant_identifier_names, file_names, unused_field

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

class NewWaterConn extends StatefulWidget {
  const NewWaterConn({super.key});

  @override
  State<NewWaterConn> createState() => _NewWaterConnState();
}

class _NewWaterConnState extends State<NewWaterConn> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final storage = const FlutterSecureStorage();
  late Position position;

  var long = 36.0, lat = -2.0, acc = 100.0;
  String error = '';
  String? editing = 'false';
  String staffid = '';
  String meterlocation = '';
  String brandname = '';
  String accnum = '';
  String meterserial = '';
  String size = '';
  String metertype = '';
  String installationmode = '';
  String status = '';
  String sewered = '';
  String othermeter = '';
  String material = '';
  String remarks = '';
  late File? _image;
  final imagePicker = ImagePicker();
  String myimage = '';
  String user = '';
  String userid = '';
  dynamic data;

  var isLoading;

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

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
      setState(() {
        _image = File(pickedFile.path);
        myimage = base64Image;
      });
    } else {}
  }

  @override
  void initState() {
    _image = null;
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
      userid = data[0]["ID"]?.toString() ?? "";
      meterlocation = data[0]["MeterLocation"]?.toString() ?? "";
      brandname = data[0]["BrandName"]?.toString() ?? "";
      accnum = data[0]["AccountNo"]?.toString() ?? "";
      meterserial = data[0]["MeterSerial"]?.toString() ?? "";
      size = data[0]["Size"]?.toString() ?? "";
      metertype = data[0]["MeterType"]?.toString() ?? "";
      installationmode = data[0]["InstallationMode"]?.toString() ?? "";
      status = data[0]["Status"]?.toString() ?? "";
      sewered = data[0]["Sewered"]?.toString() ?? "";
      othermeter = data[0]["OtherMeter"]?.toString() ?? "";
      material = data[0]["Material"]?.toString() ?? "";
      remarks = data[0]["Remarks"]?.toString() ?? "";
      // myimage = data[0]["Picture"] ?? "";
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
          'New Water Connection',
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
                    MySelectInput(
                      onSubmit: (value) {
                        setState(() {
                          meterlocation = value;
                        });
                      },
                      list: const ["--Select--", "Gate", "Compound"],
                      label: 'Meter Location',
                      value: meterlocation,
                    ),
                    MySelectInput(
                      onSubmit: (value) {
                        setState(() {
                          brandname = value;
                        });
                      },
                      list: const [
                        "--Select--",
                        "Honey Well",
                        "Diehl",
                        "Lianli",
                        "Eister-Kent",
                        "Wesan-Wottman",
                        "Janz",
                        "Other"
                      ],
                      label: 'Brand Name',
                      value: brandname,
                    ),
                    MyTextInput(
                      lines: 1,
                      value: accnum,
                      type: TextInputType.number,
                      onSubmit: (value) {
                        setState(() {
                          accnum = value;
                        });
                      },
                      title: 'Account Number *',
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
                      title: 'Meter Serial',
                    ),
                    MySelectInput(
                      onSubmit: (value) {
                        setState(() {
                          size = value;
                        });
                      },
                      list: const [
                        "--Select--",
                        "0.5\"16mm",
                        "0.75\"25mm",
                        "1\"32mm",
                        "1.25\"40mm",
                        "1.5\"50mm",
                        "2\"63mm",
                        "3\"90mm"
                      ],
                      label: 'Size',
                      value: size,
                    ),
                    MySelectInput(
                      onSubmit: (value) {
                        setState(() {
                          metertype = value;
                        });
                      },
                      list: const ["--Select--", "Mechanical", "Smart"],
                      label: 'Meter Type',
                      value: metertype,
                    ),
                    MySelectInput(
                      onSubmit: (value) {
                        setState(() {
                          installationmode = value;
                        });
                      },
                      list: const ["--Select--", "Horizontal", "Vertical"],
                      label: 'Installation Type',
                      value: installationmode,
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
                        "Dormant",
                        "Dilapidated",
                        "Abandoned"
                      ],
                      label: 'Status',
                      value: status,
                    ),
                    MySelectInput(
                      onSubmit: (value) {
                        setState(() {
                          sewered = value;
                        });
                      },
                      list: const ["--Select--", "Yes", "No"],
                      label: 'Sewered',
                      value: sewered,
                    ),
                    MySelectInput(
                      onSubmit: (value) {
                        setState(() {
                          othermeter = value;
                        });
                      },
                      list: const ["--Select--", "None", "Check-meter"],
                      label: 'Other Meter',
                      value: othermeter,
                    ),
                    MySelectInput(
                      onSubmit: (value) {
                        setState(() {
                          material = value;
                        });
                      },
                      list: const [
                        "--Select--",
                        "Iron",
                        "Plastic",
                        "Brass",
                        "Copper"
                      ],
                      label: 'Material',
                      value: material,
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
                    MyTextInput(
                      lines: 1,
                      value: user,
                      type: TextInputType.text,
                      onSubmit: (value) {
                        setState(() {
                          user = value;
                        });
                      },
                      title: 'User',
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
                        label: "Next",
                        onButtonPressed: () async {
                          setState(() {
                            isLoading =
                                LoadingAnimationWidget.staggeredDotsWave(
                                    color: const Color(0xff0288D1), size: 100);
                          });
                          var res = await submitData(
                              userid,
                              lat.toString(),
                              long.toString(),
                              accnum,
                              meterserial,
                              metertype,
                              size,
                              brandname,
                              material,
                              meterlocation,
                              status,
                              sewered,
                              othermeter,
                              myimage,
                              installationmode,
                              remarks,
                              user,
                              editing);

                          setState(() {
                            isLoading = null;
                            if (res.error == null) {
                              error = res.success;
                            } else {
                              error = res.error;
                            }
                          });
                          if (res.error == null) {
                            await storage.write(
                                key: 'meterid', value: res.token);

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
    String userid,
    String lat,
    String long,
    String accountnumber,
    String meterserial,
    String metertype,
    String size,
    String brandname,
    String material,
    String meterlocation,
    String status,
    String sewered,
    String othermeter,
    String myimage,
    String installationmode,
    String remarks,
    String user,
    String? editing) async {
  if (accountnumber.isEmpty) {
    return Message(
      token: null,
      success: null,
      error: "Account number must be filled!",
    );
  }

  try {
    http.Response response;
    const storage = FlutterSecureStorage();
    String? update = await storage.read(key: "updateLocation");

    if (editing == 'true') {
      response = await http.put(
        Uri.parse("${getUrl()}water/$userid"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'AccountNo': accountnumber,
          'MeterSerial': meterserial,
          'MeterType': metertype,
          'Size': size,
          'BrandName': brandname,
          'Material': material,
          'MeterLocation': meterlocation,
          'Status': status,
          'Sewered': sewered,
          'OtherMeter': othermeter,
          'InstallationMode': installationmode,
          'Latitude': update != null ? lat : null,
          'Longitude': update != null ? long : null,
          'Remarks': remarks,
          'User': user
        }),
      );
    } else {
      response = await http.post(
        Uri.parse("${getUrl()}water/create"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'AccountNo': accountnumber,
          'MeterSerial': meterserial,
          'MeterType': metertype,
          'Size': size,
          'BrandName': brandname,
          'Material': material,
          'MeterLocation': meterlocation,
          'Status': status,
          'Sewered': sewered,
          'OtherMeter': othermeter,
          'InstallationMode': installationmode,
          'Remarks': remarks,
          'Latitude': lat,
          'Longitude': long,
          'User': user
        }),
      );
    }

    if (response.statusCode == 200 || response.statusCode == 203) {
      return Message.fromJson(jsonDecode(response.body));
    } else {
      return Message(
        token: null,
        success: null,
        error: "Server error! Contact administrator.",
      );
    }
  } catch (e) {
    return Message(
      token: null,
      success: null,
      error: "Connection failed! Check your internet connection.!",
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
