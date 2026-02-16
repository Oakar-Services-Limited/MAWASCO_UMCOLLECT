// ignore_for_file: use_build_context_synchronously, non_constant_identifier_names, file_names

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:um_collect/components/MyTextInput.dart';
import 'package:um_collect/components/StaffDrawer.dart';
import 'package:um_collect/components/SubmitButton.dart';
import 'package:um_collect/components/TextResponse.dart';
import 'package:um_collect/components/Utils.dart';
import 'package:um_collect/pages/Assets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:http/http.dart' as http;

class SewerMainTrunk extends StatefulWidget {
  final List<Map<String, double>> coordinates;

  const SewerMainTrunk({
    super.key,
    required this.coordinates,
  });

  @override
  State<SewerMainTrunk> createState() => _SewerMainTrunkState();
}

class _SewerMainTrunkState extends State<SewerMainTrunk> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final storage = const FlutterSecureStorage();
  late Position position;

  String error = '';
  String? editing = 'false';
  String staffid = '';
  String user = '';
  String maintrunkID = '';
  String name = '';
  String remarks = '';
  String rectime = '';
  String length = '';
  String trunkname = '';
  String pipediameter = '';
  String pipematerial = '';
  String picture = '';
  String pipestatus = '';
  String condition = '';
  String intersec1 = '';
  String outfall = '';
  String current1 = '';
  String year = '';
  String shapelength = '';
  late File? _image;
  final imagePicker = ImagePicker();
  String myimage = '';

  dynamic data;

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
    } catch (e) {
      // Error handling: silently ignore errors during data fetching
    }
  }

  Future<void> prefillForm(data) async {
    var fetchedData = await storage.read(key: "data");
    data = json.decode(fetchedData!);
    setState(() {
      maintrunkID = data[0]["ID"].toString();
      remarks = data[0]["Remarks"].toString();
      name = data[0]["Name"].toString();
      length = data[0]["Length"].toString();
      trunkname = data[0]["TrunkName"].toString();
      pipediameter = data[0]["PipeDiameter"].toString();
      pipematerial = data[0]["PipeMaterial"].toString();
      pipestatus = data[0]["PipeStatus"].toString();
      condition = data[0]["Condition"].toString();
      intersec1 = data[0]["Intersec_1"].toString();
      outfall = data[0]["Outfall"].toString();
      current1 = data[0]["Current_1"].toString();
      year = data[0]["YearLaid"].toString();
      shapelength = data[0]["ShapeLength"].toString();
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
          'SewerMainTrunk Details',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 28, 100, 140),
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
                      height: 10,
                    ),
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
                      value: length,
                      type:
                          const TextInputType.numberWithOptions(decimal: true),
                      onSubmit: (value) {
                        setState(() {
                          length = value;
                        });
                      },
                      title: 'Length',
                    ),
                    MyTextInput(
                      lines: 1,
                      value: trunkname,
                      type: TextInputType.text,
                      onSubmit: (value) {
                        setState(() {
                          trunkname = value;
                        });
                      },
                      title: 'TrunkName',
                    ),
                    MyTextInput(
                      lines: 1,
                      value: pipediameter,
                      type:
                          const TextInputType.numberWithOptions(decimal: true),
                      onSubmit: (value) {
                        setState(() {
                          pipediameter = value;
                        });
                      },
                      title: 'Pipe Diameter',
                    ),
                    MyTextInput(
                      lines: 1,
                      value: pipematerial,
                      type: TextInputType.text,
                      onSubmit: (value) {
                        setState(() {
                          pipematerial = value;
                        });
                      },
                      title: 'PipeMaterial',
                    ),
                    MyTextInput(
                      lines: 1,
                      value: pipestatus,
                      type: TextInputType.text,
                      onSubmit: (value) {
                        setState(() {
                          pipestatus = value;
                        });
                      },
                      title: 'PipeStatus',
                    ),
                    MyTextInput(
                      lines: 1,
                      value: intersec1,
                      type: TextInputType.text,
                      onSubmit: (value) {
                        setState(() {
                          intersec1 = value;
                        });
                      },
                      title: 'Intersec 1',
                    ),
                    MyTextInput(
                      lines: 1,
                      value: outfall,
                      type: TextInputType.text,
                      onSubmit: (value) {
                        setState(() {
                          outfall = value;
                        });
                      },
                      title: 'Outfall',
                    ),
                    MyTextInput(
                      lines: 1,
                      value: current1,
                      type: TextInputType.text,
                      onSubmit: (value) {
                        setState(() {
                          current1 = value;
                        });
                      },
                      title: 'Current 1',
                    ),
                    MyTextInput(
                      lines: 1,
                      value: year,
                      type: TextInputType.numberWithOptions(decimal: true),
                      onSubmit: (value) {
                        setState(() {
                          year = value;
                        });
                      },
                      title: 'Year Laid',
                    ),
                    MyTextInput(
                      lines: 1,
                      value: shapelength,
                      type: TextInputType.text,
                      onSubmit: (value) {
                        setState(() {
                          shapelength = value;
                        });
                      },
                      title: 'Shape Length',
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
                        label: "Submit",
                        onButtonPressed: () async {
                          setState(() {
                            isLoading =
                                LoadingAnimationWidget.staggeredDotsWave(
                                    color:
                                        const Color.fromARGB(255, 28, 100, 140),
                                    size: 100);
                          });
                          var res = await submitData(
                              maintrunkID,
                              remarks,
                              user,
                              name,
                              rectime,
                              length,
                              trunkname,
                              pipediameter,
                              pipematerial,
                              picture,
                              pipestatus,
                              condition,
                              intersec1,
                              outfall,
                              current1,
                              year,
                              shapelength,
                              widget.coordinates,
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
  String maintrunkID,
  String remarks,
  String user,
  String name,
  String rectime,
  String length,
  String trunkname,
  String pipediameter,
  String pipematerial,
  String picture,
  String pipestatus,
  String condition,
  String intersec1,
  String outfall,
  String current1,
  String year,
  String shapelenght,
  List<Map<String, double>> coordinates,
  String? editing,
) async {
  try {
    http.Response response;

    if (editing == 'true') {
      response = await http.put(
        Uri.parse("${getUrl()}sewermaintrunk/$maintrunkID"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          "Remarks": remarks,
          "User": user,
          "Name": name,
          "Coordinates": coordinates,
          "RecordTime": rectime,
          "Length": length,
          "TrunkName": trunkname,
          "PipeDiameter": pipediameter,
          "PipeMaterial": pipematerial,
          "Picture": picture,
          "PipeStatus": pipestatus,
          "Condition": condition,
          "Intersec_1": intersec1,
          "Outfall": outfall,
          "Current_1": current1,
          "YearLaid": year,
          "ShapeLength": shapelenght,
        }),
      );
    } else {
      response = await http.post(
        Uri.parse("${getUrl()}sewermaintrunk/create"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          "Remarks": remarks,
          "User": user,
          "Name": name,
          "Coordinates": coordinates,
          "RecordTime": rectime,
          "Length": length,
          "TrunkName": trunkname,
          "PipeDiameter": pipediameter,
          "PipeMaterial": pipematerial,
          "Picture": picture,
          "PipeStatus": pipestatus,
          "Condition": condition,
          "Intersec_1": intersec1,
          "Outfall": outfall,
          "Current_1": current1,
          "YearLaid": year,
          "ShapeLength": shapelenght,
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
