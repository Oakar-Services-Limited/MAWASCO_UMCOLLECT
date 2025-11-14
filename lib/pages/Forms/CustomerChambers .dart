// ignore_for_file: use_build_context_synchronously, non_constant_identifier_names, file_names

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:um_collect/components/MyCheckBox.dart';
import 'package:um_collect/components/MySelectInput.dart';
import 'package:um_collect/components/MyTextInput.dart';
import 'package:um_collect/components/StaffDrawer.dart';
import 'package:um_collect/components/SubmitButton.dart';
import 'package:um_collect/components/TextResponse.dart';
import 'package:um_collect/components/TextSmall.dart';
import 'package:um_collect/components/Utils.dart';
import 'package:um_collect/models/Map.dart';
import 'package:um_collect/pages/Assets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:http/http.dart' as http;

class CustomerChambers extends StatefulWidget {
  const CustomerChambers({
    super.key,
  });

  @override
  State<CustomerChambers> createState() => _CustomerChambersState();
}

class _CustomerChambersState extends State<CustomerChambers> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final storage = const FlutterSecureStorage();
  late Position position;

  var long = 36.0, lat = -2.0, acc = 100.0;
  String error = '';
  String? editing = 'false';
  String staffid = '';
  String user = '';
  String customerChamberID = '';
  String accountno = '';
  String zone = '';
  String subzone = '';
  String year = '';
  String pipematerial = '';
  String pipediameter = '';
  String condition = '';
  List<String> waterSource = [];
  String shape = '';
  String status = '';
  String size = '';
  String remarks = '';
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
      customerChamberID = data[0]["ID"] ?? '';
      accountno = data[0]["AccountNo"]?.toString() ?? "";
      zone = data[0]["Zone"]?.toString() ?? "";
      shape = data[0]["Shape"]?.toString() ?? "";
      subzone = data[0]["Subzone"]?.toString() ?? "";
      year = data[0]["YearOfInstallation"]?.toString() ?? "";
      pipematerial = data[0]["PipeMaterial"]?.toString() ?? "";
      pipediameter = data[0]["PipeDiameter"]?.toString() ?? "";
      condition = data[0]["Condition"]?.toString() ?? "";
      waterSource = (data[0]["WaterSource"] as List<dynamic>)
          .map((e) => e.toString())
          .toList();
      status = data[0]["Status"]?.toString() ?? "";
      size = data[0]["Size"]?.toString() ?? "";
      remarks = data[0]["Remarks"]?.toString() ?? "";
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
          'CustomerChambers Details',
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
                      value: accountno,
                      type: TextInputType.text,
                      onSubmit: (value) {
                        setState(() {
                          accountno = value;
                        });
                      },
                      title: 'AccountNo',
                    ),
                    MySelectInput(
                      onSubmit: (value) {
                        setState(() {
                          shape = value;
                        });
                      },
                      list: const [
                        "--Select--",
                        "Circular",
                        "Rectangular",
                        "Square"
                      ],
                      label: 'Shape',
                      value: shape,
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
                      value: year,
                      type: TextInputType.numberWithOptions(decimal: true),
                      onSubmit: (value) {
                        setState(() {
                          year = value;
                        });
                      },
                      title: 'Year of Installation',
                    ),
                    MySelectInput(
                      onSubmit: (value) {
                        setState(() {
                          pipematerial = value;
                        });
                      },
                      list: const ["--Select--", "HDPE", "PCC", "DWC"],
                      label: 'Pipe Material',
                      value: pipematerial,
                    ),
                    MySelectInput(
                      onSubmit: (value) {
                        setState(() {
                          pipediameter = value;
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
                      label: 'Pipe Diameter',
                      value: pipediameter,
                    ),
                    MySelectInput(
                      onSubmit: (value) {
                        setState(() {
                          condition = value;
                        });
                      },
                      list: const [
                        "--Select--",
                        "Good Condition",
                        "Broken Cover/Opening"
                      ],
                      label: 'Condition',
                      value: condition,
                    ),
                    const TextSmall(label: "Water Source"),
                    const SizedBox(
                      height: 8,
                    ),
                    MyCheckBox(
                      onSubmit: (value) {
                        setState(() {
                          waterSource = value;
                        });
                      },
                      options: const ["Borehole", "Project", "Rain Water"],
                      selectedOptions: waterSource,
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
                    MySelectInput(
                      onSubmit: (value) {
                        setState(() {
                          size = value;
                        });
                      },
                      list: const [
                        "--Select--",
                        "1000mm by 1000mm",
                        "600mm by 600mm",
                        "600mm by 500mm",
                        "450mm by 600mm",
                      ],
                      label: 'Size',
                      value: size,
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
                              customerChamberID,
                              lat,
                              long,
                              accountno,
                              shape,
                              zone,
                              subzone,
                              year,
                              pipematerial,
                              pipediameter,
                              condition,
                              waterSource,
                              status,
                              size,
                              remarks,
                              user,
                              myimage,
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
    String customerChamberID,
    double lat,
    double long,
    String accountno,
    String shape,
    String zone,
    String subzone,
    String year,
    String pipematerial,
    String pipediameter,
    String condition,
    List<String> watersource,
    String status,
    String size,
    String remarks,
    String user,
    String myimage,
    String? editing) async {
  try {
    http.Response response;
    const storage = FlutterSecureStorage();
    String? update = await storage.read(key: "updateLocation");

    if (editing == 'true') {
      response = await http.put(
        Uri.parse("${getUrl()}customerchamber/$customerChamberID"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'Latitude': update != null ? lat : null,
          'Longitude': update != null ? long : null,
          "AccountNo": accountno,
          "Shape": shape,
          "Zone": zone,
          "Subzone": subzone,
          "YearOfInstallation": year,
          "PipeMaterial": pipematerial,
          "PipeDiameter": pipediameter,
          "Condition": condition,
          "WaterSource": watersource.join(', '),
          "Status": status,
          "Size": size,
          "Remarks": remarks,
          "User": user,
          "Photo": myimage,
        }),
      );
    } else {
      response = await http.post(
        Uri.parse("${getUrl()}customerchamber/create"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'Latitude': lat,
          'Longitude': long,
          "AccountNo": accountno,
          "Shape": shape,
          "Zone": zone,
          "Subzone": subzone,
          "YearOfInstallation": year,
          "PipeMaterial": pipematerial,
          "PipeDiameter": pipediameter,
          "Condition": condition,
          "WaterSource": watersource.join(', '),
          "Status": status,
          "Size": size,
          "Remarks": remarks,
          "User": user,
          "Photo": myimage,
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
