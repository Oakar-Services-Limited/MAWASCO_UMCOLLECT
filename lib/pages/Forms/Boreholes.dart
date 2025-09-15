// ignore_for_file: use_build_context_synchronously, non_constant_identifier_names, file_names

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

class Boreholes extends StatefulWidget {
  const Boreholes({
    super.key,
  });

  @override
  State<Boreholes> createState() => _BoreholesState();
}

class _BoreholesState extends State<Boreholes> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final storage = const FlutterSecureStorage();
  late Position position;

  var long = 36.0, lat = -2.0, acc = 100.0;
  String error = '';
  String? editing = 'false';
  String staffid = '';
  String boreholeID = '';
  String name = '';
  String zone = '';
  String subzone = '';
  String depth = '';
  String outputyield = '';
  String year = '';
  String casing = '';
  String pipediameter = '';
  String pumptype = '';
  String status = '';
  String remarks = '';
  String user = '';

  late File? _image;
  final imagePicker = ImagePicker();
  String myimage = '';

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
      print('token is $token');
      var decoded = parseJwt(token.toString());
      editing = await storage.read(key: "editing");
      print('token is $decoded');

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
      boreholeID = data[0]["ID"] ?? "";
      name = data[0]["Name"] ?? "";
      zone = data[0]["Zone"] ?? "";
      subzone = data[0]["Subzone"] ?? "";
      depth = data[0]["Depth"] ?? "";
      outputyield = data[0]["Yield"] ?? "";
      year = data[0]["Year"] ?? "";
      casing = data[0]["Casing"] ?? "";
      pipediameter = data[0]["PipeDiameter"]?.toString() ?? "";
      pumptype = data[0]["PumpType"]?.toString() ?? "";
      status = data[0]["Status"] ?? "";
      remarks =
          data[0]["Remarks"] == null ? "" : remarks = data[0]["Remarks"] ?? "";
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
          'Boreholes Details',
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
                    MySelectInput(
                      onSubmit: (value) {
                        setState(() {
                          zone = value;
                        });
                      },
                      list: const [
                        "--Select--",
                        "001_Kirigiti_Thathini",
                        "002_IndianBazaar_Kangoya",
                        "003_Bureria_Ndumberi",
                        "004_Kiambu_Town(MainStagetoRiverside)",
                        "005_Kiambu_Town(NdumberiStagetoDCOffice)",
                        "006_Riabai_Ruthiruini",
                        "007_Karunga_KKTowers",
                        "008_Kihingo",
                        "009_Mugumo_Kamiti_KiuKenda",
                        "010_Kiamumbi",
                        "011-Thindigua"
                      ],
                      label: 'Zone',
                      value: zone,
                    ),
                    MySelectInput(
                      onSubmit: (value) {
                        setState(() {
                          subzone = value;
                        });
                      },
                      list: const [
                        "--Select--",
                        "011-1 Kiamumb",
                        "009-6 makaja",
                        "001-7 Project",
                        "009- Kamiti B",
                        "009-7 Gachiru",
                        "009-3 Samaki",
                        "007-2 640",
                        "006-5 Vee",
                        "006-6 Ndichu",
                        "006-4 Kairo",
                        "001-4 Kimana",
                        "001-3 Watetu",
                        "005-3 K.K",
                        "003-23 Nyautu",
                        "005-2 D.C",
                        "004-2 P E F A",
                        "005-1 Hospital",
                        "003-25 Njunu",
                        "004-1 Posta",
                        "002-8 Ngegu",
                        "003-21 Barua",
                        "009-1 Kamiti C",
                        "010-1 Thindigu",
                        "009-4 Kiu-Rive",
                        "007-1 Rock-line",
                        "009-5 Kiu Kend",
                        "008-2 Lower Ki",
                        "008-1 Upper Ki",
                        "001-1 Kiambu H",
                        "008-4 Gichocho",
                        "006-7 Ruthiru-i",
                        "006-2 Bara-Bar",
                        "006-3 Wamuthe",
                        "006-1 Shopping",
                        "001-5 Thathi-in",
                        "001-2 Kamanda",
                        "002-4 Edden V",
                        "002-1 Route 41",
                        "002- 412-Umon",
                        "002- Karambai",
                        "003-24 Gatiti B",
                        "004-3 River Sid",
                        "003-16 karunga",
                        "003-2 Ndumbe",
                        "002-6 Lower Ka",
                        "003-22 Gachie",
                        "002-2 Kanjata",
                        "003-13 Kabae",
                        "003-7 gatitu",
                        "003-3 Allan",
                        "003-6 kiriguini",
                        "003-14 DEB",
                        "003-9 Ngaita",
                        "002-3 Upper Ka",
                        "003-11 tingang",
                        "003-1 Mburaria",
                        "003-10 Kagong",
                        "003-15 Tumbur",
                        "003-19 Kamuny"
                      ],
                      label: 'Sub Zone',
                      value: subzone,
                    ),
                    MyTextInput(
                      lines: 1,
                      value: depth,
                      type:
                          const TextInputType.numberWithOptions(decimal: true),
                      onSubmit: (value) {
                        setState(() {
                          depth = value;
                        });
                      },
                      title: 'Depth',
                    ),
                    MyTextInput(
                      lines: 1,
                      value: outputyield,
                      type: TextInputType.numberWithOptions(decimal: true),
                      onSubmit: (value) {
                        setState(() {
                          outputyield = value;
                        });
                      },
                      title: 'Yield',
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
                      title: 'Year',
                    ),
                    MySelectInput(
                      onSubmit: (value) {
                        setState(() {
                          casing = value;
                        });
                      },
                      list: const [
                        "--Select--",
                        "160mm 6\"",
                        "225mm 10\"",
                      ],
                      label: 'Casing Diameter',
                      value: casing,
                    ),
                    MySelectInput(
                      onSubmit: (value) {
                        setState(() {
                          pipediameter = value;
                        });
                      },
                      list: const [
                        "--Select--",
                        "63mm 2\"",
                        "90mm 3\"",
                        "50mm 1.5\"",
                        "32mm 1\""
                      ],
                      label: 'Pipe Diameter',
                      value: pipediameter,
                    ),
                    MySelectInput(
                      onSubmit: (value) {
                        setState(() {
                          pumptype = value;
                        });
                      },
                      list: const [
                        "--Select--",
                        "9A42BS",
                        "SP12",
                        "DS-30-26",
                        "7KW 30 HP",
                        "Dayliff",
                        "Electric submersible",
                        "SP2A-33 submersible",
                        "Grundfos SP17-10",
                        "Grundfos SP 17",
                        "Grundfos SP 2A",
                        "CRI",
                        "Grundfos SP 30-26",
                        "Grundfos SP 30-26"
                      ],
                      label: 'Pump Type',
                      value: pumptype,
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
                                    color: const Color(0xff0288D1), size: 100);
                          });
                          var res = await submitData(
                              boreholeID,
                              lat.toString(),
                              long.toString(),
                              name,
                              zone,
                              subzone,
                              depth,
                              outputyield,
                              year,
                              casing,
                              pipediameter,
                              pumptype,
                              status,
                              remarks,
                              myimage,
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
  String boreholeID,
  String lat,
  String long,
  String name,
  String zone,
  String subzone,
  String depth,
  String outputyield,
  String year,
  String casing,
  String pipediameter,
  String pumptype,
  String status,
  String remarks,
  String myimage,
  String user,
  String? editing,
) async {
  try {
    http.Response response;
    const storage = FlutterSecureStorage();
    String? update = await storage.read(key: "updateLocation");

    print("boreholes submited $lat, $long, $update");

    if (editing == 'true') {
      response = await http.put(
        Uri.parse("${getUrl()}boreholes/$boreholeID"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'Latitude': update != null ? lat : null,
          'Longitude': update != null ? long : null,
          'Name': name,
          'Zone': zone,
          'Subzone': subzone,
          "Category": depth,
          "Yield": outputyield,
          'YearOfInstallation': year,
          "CasingDiameter": casing,
          'PipeDiameter': pipediameter,
          "Year": pumptype,
          'Status': status,
          'Remarks': remarks,
          // "Photo": myimage,
          'User': user
        }),
      );
    } else {
      response = await http.post(
        Uri.parse("${getUrl()}boreholes/create"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'Latitude': lat,
          'Longitude': long,
          'Name': name,
          'Zone': zone,
          'Subzone': subzone,
          "Category": depth,
          "Yield": outputyield,
          'YearOfInstallation': year,
          "CasingDiameter": casing,
          'PipeDiameter': pipediameter,
          "Year": pumptype,
          'Status': status,
          'Remarks': remarks,
          "Photo": myimage,
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
