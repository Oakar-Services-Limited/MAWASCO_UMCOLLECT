// ignore_for_file: use_build_context_synchronously, non_constant_identifier_names, file_names

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:um_collect/components/MyDrawer.dart';
import 'package:um_collect/components/MySelectInput.dart';
import 'package:um_collect/components/MyTextInput.dart';
import 'package:um_collect/components/SubmitButton.dart';
import 'package:um_collect/components/TextResponse.dart';
import 'package:um_collect/components/Utils.dart';
import 'package:um_collect/pages/Assets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:http/http.dart' as http;

class ConsumerLines extends StatefulWidget {
  final List<Map<String, double>> coordinates;
  const ConsumerLines({
    super.key,
    required this.coordinates,
  });

  @override
  State<ConsumerLines> createState() => _ConsumerLinesState();
}

class _ConsumerLinesState extends State<ConsumerLines> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final storage = const FlutterSecureStorage();
  late Position position;

  String error = '';
  String? editing = 'false';
  String staffid = '';
  String waterpipeID = '';
  String linename = '';
  String diameter = '';
  String zone = '';
  String subzone = '';
  String pipematerial = '';
  String year = '';
  String wpclass = '';
  String distribution = '';
  String status = '';
  String remarks = '';
  late File? _image;
  final imagePicker = ImagePicker();
  String myimage = '';
  String user = '';
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
      waterpipeID = data[0]["ID"] ?? "";
      linename = data[0]["Name"] ?? "";
      diameter = data[0]["Diameter"] ?? "";
      zone = data[0]["Material"] ?? "";
      pipematerial = data[0]["Length"]?.toString() ?? "";
      year = data[0]["Year"]?.toString() ?? "";

      wpclass = data[0]["Class"] ?? "";

      status = data[0]["Status"] ?? "";
      distribution = data[0]["Distribution"] ?? "";

      remarks = data[0]["Remarks"] ?? "";
    });
  }

  @override
  void initState() {
    _image = null;
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
          'Consumer Line Details',
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
                          diameter = value;
                        });
                      },
                      list: const [
                        "--Select--",
                        "16mm 0.5\"",
                        "25mm 0.75\"",
                        "32mm 1\"",
                        "40mm 1.25\"",
                        "50mm 1.5\"",
                        "63mm 2\"",
                        "90mm 3\"",
                        "110mm 4\"",
                        "160mm 6\"",
                        "200mm 8\"",
                        "225mm 10\"",
                        "250mm 12\"",
                        "275mm 14\"",
                        "315mm 16\""
                      ],
                      label: 'Diameter',
                      value: diameter,
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
                    MySelectInput(
                      onSubmit: (value) {
                        setState(() {
                          pipematerial = value;
                        });
                      },
                      list: const ["--Select--", "HDPE", "UPVC", "HI", "PPR"],
                      label: 'Material',
                      value: pipematerial,
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
                          wpclass = value;
                        });
                      },
                      list: const ["--Select--", "B", "C", "D"],
                      label: 'Class',
                      value: wpclass,
                    ),
                    MySelectInput(
                      onSubmit: (value) {
                        setState(() {
                          distribution = value;
                        });
                      },
                      list: const ["--Select--", "Gravity", "Pumping", "Both"],
                      label: 'Distribution',
                      value: distribution,
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
                              widget.coordinates,
                              waterpipeID,
                              linename,
                              diameter,
                              zone,
                              subzone,
                              pipematerial,
                              year,
                              wpclass,
                              distribution,
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
  List<Map<String, double>> coordinates,
  String waterpipeId,
  String linename,
  String diameter,
  String zone,
  String subzone,
  String pipematerial,
  String year,
  String wpclass,
  String distribution,
  String status,
  String remarks,
  String myimage,
  String user,
  String? editing,
) async {
  try {
    http.Response response;

    if (editing == 'true') {
      response = await http.put(
        Uri.parse("${getUrl()}consumerline/$waterpipeId"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'Name': linename,
          'Diameter': diameter,
          'Zone': zone,
          'Subzone': subzone,
          'PipeMaterial': pipematerial,
          'YearOfInstallation': year,
          'Class': wpclass,
          'Distribution': distribution,
          'Status': status,
          'Remarks': remarks,
          // 'Photo': myimage,
          'User': user
        }),
      );
    } else {
      response = await http.post(
        Uri.parse("${getUrl()}consumerline/create"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'Name': linename,
          'Diameter': diameter,
          'Zone': zone,
          'Subzone': subzone,
          'PipeMaterial': pipematerial,
          'YearOfInstallation': year,
          'Class': wpclass,
          'Distribution': distribution,
          'Status': status,
          'Remarks': remarks,
          'Photo': myimage,
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
