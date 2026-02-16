// ignore_for_file: use_build_context_synchronously, non_constant_identifier_names, file_names

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
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

class Kiosks extends StatefulWidget {
  const Kiosks({
    super.key,
  });

  @override
  State<Kiosks> createState() => _KiosksState();
}

class _KiosksState extends State<Kiosks> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final storage = const FlutterSecureStorage();
  late Position position;
  StreamSubscription<Position>? _positionStreamSubscription;

  var long = 36.0, lat = -2.0, acc = 100.0;
  String error = '';
  String? editing = 'false';
  String staffid = '';
  String kioskID = '';
  String name = '';
  String image = '#';
  String route = '';
  String zone = '';
  String remarks = '';
  String user = '';
  String role = '';
  File? _image;
  final imagePicker = ImagePicker();
  String myimage = '';

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
      // Error handling: silently ignore errors during data fetching
    }
  }

  Future<String> convertFileToBase64(XFile file) async {
    List<int> fileBytes = await file.readAsBytes();
    String base64String = base64Encode(fileBytes);
    return base64String;
  }

  Future<void> takePhoto() async {
    try {
      final pickedFile = await imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85, // Optimize image quality
        maxWidth: 1920, // Limit max dimensions
        maxHeight: 1080,
      );

      if (pickedFile != null) {
        String base64Image = await convertFileToBase64(pickedFile);
        if (!mounted) return;
        setState(() {
          _image = File(pickedFile.path);
          myimage = base64Image;
        });
      }
    } catch (e) {
      // Show error dialog
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Camera Error'),
            content: const Text('Failed to capture image. Please try again.'),
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );
    }
  }

  prefillForm(data) async {
    var fetchedData = await storage.read(key: "data");
    data = json.decode(fetchedData!);

    if (!mounted) return;
    setState(() {
      kioskID = data[0]["id"] ?? "";
      name = data[0]["name"] ?? "";
      route = data[0]["route"] ?? "";
      zone = data[0]["zone"] ?? "";
      remarks = data[0]["remarks"] ?? "";
      user = data[0]["userId"] ?? "";
    });
  }

  getLocation() async {
    LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation, // Highest possible
      distanceFilter: 0, // Get all movements
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) {
      if (!mounted) return;
      setState(() {
        long = position.longitude;
        lat = position.latitude;
        acc = position.accuracy;
        this.position = position;
      });
    });
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
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
          'Kiosks Details',
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
                    editing == 'false' ? const SizedBox() : const SizedBox(),
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
                    _buildSectionTitle('Take a Photo'),
                    const SizedBox(height: 12),
                    _buildImageCapture(),
                    const SizedBox(height: 24),
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
                          if (editing == 'true' && role != 'Super Admin') {
                            _showSnackBar(
                                'Updating asset restricted to Super Admins only',
                                false);
                            return;
                          }
                          if (!mounted) return;
                          setState(() {
                            isLoading =
                                LoadingAnimationWidget.staggeredDotsWave(
                                    color: const Color(0xff0288D1), size: 100);
                          });
                          var res = await submitData(
                              kioskID,
                              myimage,
                              lat.toString(),
                              long.toString(),
                              name,
                              zone,
                              route,
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xff0288D1),
        fontWeight: FontWeight.w600,
        fontSize: 20,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildImageCapture() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xff0288D1).withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            SizedBox(
              height: 250,
              width: double.infinity,
              child: _image == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt_outlined,
                          size: 48,
                          color: const Color(0xff0288D1).withValues(alpha: 0.7),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Tap camera icon to take a photo",
                          style: TextStyle(
                            color: Color(0xff0288D1),
                            fontWeight: FontWeight.w400,
                            fontSize: 15,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    )
                  : GestureDetector(
                      onTap: () => _showFullImage(context),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          _image!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xff0288D1),
                      const Color(0xff0288D1).withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                  onPressed: takePhoto,
                ),
              ),
            ),
            if (_image != null)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _image = null;
                        myimage = '';
                      });
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showFullImage(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
              ),
              child: InteractiveViewer(
                child: Image.file(_image!),
              ),
            ),
          ),
        );
      },
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
    String kioskID,
    String myimage,
    String lat,
    String long,
    String name,
    String zone,
    String route,
    String remarks,
    String staffid,
    String? editing) async {
  print("====== KIOSK SUBMIT START ======");
  print("Editing flag: $editing");
  print("Kiosk ID: $kioskID");

  if (myimage.isEmpty) {
    print("❌ Image missing");
    return Message(token: null, success: null, error: "Take Photo of Kiosk!");
  }

  try {
    Response response;

    final bool isEditing = editing == 'true' && kioskID.isNotEmpty;

    final String url =
        isEditing ? "${getUrl()}wt/kiosks/$kioskID" : "${getUrl()}wt/kiosks";

    print("➡️ HTTP METHOD: ${isEditing ? 'PUT' : 'POST'}");
    print("➡️ URL: $url");

    final Map<String, dynamic> requestBody = {
      'latitude': lat,
      'longitude': long,
      'name': name,
      'route': route,
      'zone': zone,
      'remarks': remarks,
      'userId': staffid,
      'image': myimage,
    };

    print("📦 REQUEST BODY:");
    requestBody.forEach((k, v) {
      print("   $k: ${v.toString().length > 100 ? '<<large value>>' : v}");
    });

    if (isEditing) {
      response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(requestBody),
      );
    } else {
      response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(requestBody),
      );
    }

    print("⬅️ RESPONSE STATUS: ${response.statusCode}");
    print("⬅️ RESPONSE HEADERS: ${response.headers}");
    print("⬅️ RESPONSE BODY:");
    print(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      print("✅ SUCCESS");
      return Message(
        token: responseData['data']?['id'],
        success: responseData['message'] ?? "Kiosk saved successfully",
        error: null,
      );
    } else {
      print("❌ SERVER ERROR");
      return Message(
        token: null,
        success: null,
        error: "Server error ${response.statusCode}: ${response.reasonPhrase}",
      );
    }
  } catch (e, stackTrace) {
    print("🔥 EXCEPTION THROWN");
    print(e);
    print(stackTrace);

    return Message(
      token: null,
      success: null,
      error: "Exception: $e",
    );
  } finally {
    print("====== KIOSK SUBMIT END ======");
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
