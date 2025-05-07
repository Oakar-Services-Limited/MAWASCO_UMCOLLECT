import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kiambu_umcollect/components/MySelectInput.dart';
import 'package:kiambu_umcollect/components/MyDrawer.dart';
import 'package:kiambu_umcollect/components/SubmitButton.dart';
import 'package:kiambu_umcollect/components/Utils.dart';
import 'package:kiambu_umcollect/models/Map.dart';
import 'package:kiambu_umcollect/pages/NRW.dart';
import 'package:kiambu_umcollect/pages/TextOakar.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart';
import 'package:geolocator/geolocator.dart';

class NRWLeakages extends StatefulWidget {
  const NRWLeakages({super.key});

  @override
  State<NRWLeakages> createState() => _NRWLeakagesState();
}

class _NRWLeakagesState extends State<NRWLeakages> {
  final storage = const FlutterSecureStorage();
  var long = 36.0, lat = -2.0, acc = 100.0;
  String image = '#';
  String dmaname = '';
  String nature = '';
  String name = '';
  String date = '';
  String error = '';
  var isLoading;
  late File? _image;
  final imagePicker = ImagePicker();
  bool servicestatus = false;
  late LocationPermission permission;
  bool haspermission = false;
  late Position position;
  String userid = '';
  bool successful = false;
  String myimage = '';
  StreamSubscription<Position>? positionStreamSubscription;

  getUserLocation() async {
    try {
      var token = await storage.read(key: "mwjwt");
      var decoded = parseJwt(token.toString());
      var id = decoded["id"];
      setState(() {
        userid = id.toString();
      });
    } catch (e) {}

    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.always ||
          perm == LocationPermission.whileInUse) {
        position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        setState(() {
          long = position.longitude;
          lat = position.latitude;
          acc = position.accuracy;
        });

        LocationSettings locationSettings = const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 1,
        );

        positionStreamSubscription =
            Geolocator.getPositionStream(locationSettings: locationSettings)
                .listen((Position position) {
          setState(() {
            long = position.longitude;
            lat = position.latitude;
            acc = position.accuracy;
          });
        });
      } else {
        promptUserForLocation();
      }
    } catch (e) {}
  }

  Future<String> convertFileToBase64(XFile file) async {
    List<int> fileBytes = await file.readAsBytes();
    String base64String = base64Encode(fileBytes);
    return base64String;
  }

  promptUserForLocation() async {
    servicestatus = await Geolocator.isLocationServiceEnabled();
    if (servicestatus) {
      permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        } else if (permission == LocationPermission.deniedForever) {
          permission = await Geolocator.requestPermission();
        } else {
          haspermission = true;
        }
      } else {
        haspermission = true;
      }
    }
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

  Future<void> getStaffUser() async {
    try {
      var token = await storage.read(key: "mwstaffjwt");
      var decoded = parseJwt(token.toString());

      if (decoded["error"] == "Invalid token") {
      } else {
        setState(() {
          name = decoded["name"];
        });
      }
    } catch (e) {}
  }

  @override
  void initState() {
    super.initState();
    _image = null;
    getUserLocation();
    _initializeDateVariables();
    getStaffUser();
  }

  @override
  void dispose() {
    positionStreamSubscription?.cancel();
    super.dispose();
  }

  void _initializeDateVariables() {
    DateTime today = DateTime.now();

    date =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    setState(() {
      date = date;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Report Incident',
      theme: ThemeData(),
      home: Scaffold(
        appBar: AppBar(
          actions: <Widget>[
            IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.white,
              ),
              onPressed: () {
                Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (_) => const NRW()));
              },
            ),
          ],
          title: const Text(
            "Report Leakage",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xff0288D1),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        drawer: const MyDrawer(),
        body: Stack(
          children: [
            SafeArea(
                child: Container(
                    padding: const EdgeInsets.all(12.0),
                    child: SizedBox(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 8,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Take a Photo',
                                  style: TextStyle(
                                    color: Color(0xff0288D1),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(
                                  height: 8,
                                ),
                                Card(
                                  elevation: 2,
                                  clipBehavior: Clip.hardEdge,
                                  child: Stack(
                                    children: [
                                      SizedBox(
                                        height: 150,
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
                                                    fontSize: 8,
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
                                            color: Color.fromARGB(
                                                255, 28, 100, 140),
                                          ),
                                          onPressed: () => takePhoto(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(
                                  height: 8,
                                ),
                                MySelectInput(
                                  onSubmit: (value) {
                                    setState(() {
                                      dmaname = value;
                                    });
                                  },
                                  list: const [
                                    "--Select--",
                                    "Kamiti A",
                                    "Kamiti B",
                                    "Samaki 1",
                                    "Samaki 2",
                                    "Makanja 1",
                                    "Makanja 2",
                                    "Kiu River",
                                    "Kiu Kenda",
                                    "Kanjata",
                                    "Kiambu Golf Club",
                                  ],
                                  label: 'Select DMA Name',
                                  value: dmaname,
                                ),
                                MySelectInput(
                                  onSubmit: (value) {
                                    setState(() {
                                      nature = value;
                                    });
                                  },
                                  list: const [
                                    "--Select--",
                                    "Visible",
                                    "Underground",
                                  ],
                                  label: 'Nature of Leakage',
                                  value: nature,
                                ),
                                const SizedBox(
                                  height: 4,
                                ),
                                TextOakar(
                                    label: error, issuccessful: successful),
                                const SizedBox(
                                  height: 4,
                                ),
                                Align(
                                  alignment: Alignment.bottomCenter,
                                  child: SubmitButton(
                                    label: "Submit",
                                    onButtonPressed: () async {
                                      setState(() {
                                        error = "";
                                        isLoading = LoadingAnimationWidget
                                            .staggeredDotsWave(
                                          color: const Color.fromARGB(
                                              255, 28, 100, 140),
                                          size: 100,
                                        );
                                      });

                                      var res = await submitData(
                                        userid,
                                        myimage,
                                        dmaname,
                                        nature,
                                        lat,
                                        long,
                                        name,
                                        date,
                                      );
                                      setState(() {
                                        isLoading = null;
                                        if (res.error == null) {
                                          successful = true;
                                          error = res.success;
                                        } else {
                                          successful = false;
                                          error = res.error;
                                        }
                                      });
                                      if (res.error == null) {
                                        Timer(const Duration(seconds: 2), () {
                                          Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) => const NRW()));
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ))),
            Center(
              child: isLoading ?? const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }
}

Future<Message> submitData(
  String userid,
  String myimage,
  String dmaname,
  String nature,
  double lat,
  double long,
  String name,
  String date,
) async {
  if (myimage.isEmpty) {
    return Message(token: null, success: null, error: "Take Photo!");
  }

  if (dmaname.isEmpty) {
    return Message(token: null, success: null, error: "Empty Mandatory Field!");
  }

  if (nature.isEmpty) {
    return Message(
      token: null,
      success: null,
      error: "Nature of leakage cannot be empty!",
    );
  }

  try {
    final response = await post(
      Uri.parse("${getUrl()}nrw_leakages/create"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'DMAName': dmaname,
        'Nature': nature,
        'Latitude': lat.toString(),
        'Longitude': long.toString(),
        'DateReported': date,
        'Image': myimage,
        'ReportedBy': name,
      }),
    );

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
