import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:um_collect/components/MySelectInput.dart';
import 'package:um_collect/components/MyTextInputII.dart';
import 'package:um_collect/components/MyDrawer.dart';
import 'package:um_collect/components/SubmitButton.dart';
import 'package:um_collect/components/Utils.dart';
import 'package:um_collect/models/Map.dart';
import 'package:um_collect/pages/TextOakar.dart';
import 'package:um_collect/pages/incidences.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart';
import 'package:geolocator/geolocator.dart';

class ReportIncident extends StatefulWidget {
  final String incident;
  final String categoryId;

  const ReportIncident(
    this.incident, {
    super.key,
    required this.categoryId,
  });

  @override
  State<ReportIncident> createState() => _ReportIncidentState();
}

class _ReportIncidentState extends State<ReportIncident> {
  final storage = const FlutterSecureStorage();
  var long = 36.0, lat = -2.0, acc = 100.0;
  String image = '#';
  String description = '';
  String location = '';
  String route = '';
  String phone = '';
  String name = '';
  String reportertype = 'Public';
  String sewerincident = '';
  String leaktype = '';
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
      if (token != null) {
        var decoded = parseJwt(token.toString());
        var id = decoded["id"];
        setState(() {
          userid = id.toString();
        });
        print("User ID set to: $userid");
      } else {
        print("No JWT token found");
        // Try to get staff token as fallback
        var staffToken = await storage.read(key: "mwstaffjwt");
        if (staffToken != null) {
          var decoded = parseJwt(staffToken.toString());
          var id = decoded["id"];
          setState(() {
            userid = id.toString();
          });
          print("Staff ID set to: $userid");
        } else {
          print("No staff token found either");
        }
      }
    } catch (e) {
      print("Error getting user ID: $e");
    }

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
    } catch (e) {
      print("Error getting location: $e");
    }
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
    try {
      final pickedFile = await imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85, // Optimize image quality
        maxWidth: 1920, // Limit max dimensions
        maxHeight: 1080,
      );

      if (pickedFile != null) {
        String base64Image = await convertFileToBase64(pickedFile);
        setState(() {
          _image = File(pickedFile.path);
          myimage = base64Image;
        });
      }
    } catch (e) {
      // Show error dialog
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

  Future<void> getStaffUser() async {
    try {
      var token = await storage.read(key: "mwstaffjwt");
      var decoded = parseJwt(token.toString());

      if (decoded["error"] == "Invalid token") {
      } else {
        setState(() {
          phone = decoded["Phone"];
          name = decoded["name"];
          reportertype = "Staff";
        });
      }
    } catch (e) {}
  }

  @override
  void initState() {
    super.initState();
    print("Category ID: ${widget.categoryId}");
    print("Incident: ${widget.incident}");

    _image = null;
    getUserLocation();
    getStaffUser();
  }

  @override
  void dispose() {
    positionStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Report Incident',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff0288D1),
          brightness: Brightness.light,
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xff0288D1),
                  const Color(0xff0288D1).withOpacity(0.8),
                ],
              ),
            ),
          ),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
            ),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const Incidences()),
            ),
          ),
          title: Text(
            "Report - ${widget.incident}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),
          centerTitle: true,
        ),
        drawer: const MyDrawer(),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xff0288D1).withOpacity(0.05),
                Colors.white,
              ],
            ),
          ),
          child: Stack(
            children: [
              SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _buildSectionTitle('${widget.incident} Location'),
                        const SizedBox(height: 12),
                        _buildMapCard(),
                        const SizedBox(height: 24),
                        if (widget.incident != "Supply Fail") ...[
                          _buildSectionTitle('Take a Photo'),
                          const SizedBox(height: 12),
                          _buildImageCapture(),
                          const SizedBox(height: 24),
                        ],
                        if (widget.incident == "Sewer Incident") ...[
                          _buildSectionTitle('Incident Details'),
                          const SizedBox(height: 12),
                          _buildSewerIncidentSelector(),
                          const SizedBox(height: 24),
                        ],
                        if (widget.incident == "Leakage") ...[
                          _buildSectionTitle('Leak Details'),
                          const SizedBox(height: 12),
                          _buildLeakTypeSelector(),
                          const SizedBox(height: 24),
                        ],
                        _buildSectionTitle('Additional Details'),
                        const SizedBox(height: 12),
                        _buildReporterInfoCard(),
                        if (error.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          TextOakar(
                            label: error,
                            issuccessful: successful,
                          ),
                        ],
                        const SizedBox(height: 24),
                        _buildSubmitButton(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
              if (isLoading != null)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Center(child: isLoading),
                ),
            ],
          ),
        ),
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

  Widget _buildMapCard() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 250,
          child: MyMap(
            lat: lat,
            lon: long,
            acc: acc,
          ),
        ),
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
            color: const Color(0xff0288D1).withOpacity(0.2),
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
                          color: const Color(0xff0288D1).withOpacity(0.7),
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
                      const Color(0xff0288D1).withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
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
                    color: Colors.red.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
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

  Widget _buildSewerIncidentSelector() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: MySelectInput(
          onSubmit: (value) {
            setState(() {
              sewerincident = value;
            });
          },
          list: const [
            "--Select--",
            "Sewer Burst",
            "Shifted Manhole Covers",
            "Broken Manhole Cover",
            "Silted Sewer Line",
            "Silted Manhole",
            "Sewer Overflow",
          ],
          label: 'Select Type',
          value: sewerincident,
          labelFontSize: 18,
        ),
      ),
    );
  }

  Widget _buildLeakTypeSelector() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: MySelectInput(
          onSubmit: (value) {
            setState(() {
              leaktype = value;
            });
          },
          list: const [
            "--Select--",
            "Leakage",
            "Burst",
          ],
          label: 'Select Type of Leak',
          value: leaktype,
          labelFontSize: 18,
        ),
      ),
    );
  }

  Widget _buildReporterInfoCard() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            MyTextInputII(
              hint: 'Describe the incident *',
              lines: 1,
              value: description,
              type: TextInputType.text,
              onSubmit: (value) {
                setState(() {
                  description = value;
                });
              },
              customIcon: Icons.location_on_rounded,
              mycolor: const Color(0xff0288D1),
              iconcolor: const Color(0xff0288D1),
            ),
            const SizedBox(height: 16),
            MyTextInputII(
              hint: 'Describe location of incident *',
              lines: 1,
              value: location,
              type: TextInputType.text,
              onSubmit: (value) {
                setState(() {
                  location = value;
                });
              },
              customIcon: Icons.location_on_rounded,
              mycolor: const Color(0xff0288D1),
              iconcolor: const Color(0xff0288D1),
            ),
            const SizedBox(height: 16),
            MyTextInputII(
              hint: 'Describe route to incident location',
              lines: 1,
              value: route,
              type: TextInputType.text,
              onSubmit: (value) {
                setState(() {
                  route = value;
                });
              },
              customIcon: Icons.person_rounded,
              mycolor: const Color(0xff0288D1),
              iconcolor: const Color(0xff0288D1),
            ),
            // if (reportertype == "Public") ...[
            //   const SizedBox(height: 16),
            //   MyTextInputII(
            //     hint: 'Your Phone Number',
            //     lines: 1,
            //     value: phone,
            //     type: TextInputType.phone,
            //     onSubmit: (value) {
            //       setState(() {
            //         phone = value;
            //       });
            //     },
            //     customIcon: Icons.phone_rounded,
            //     mycolor: const Color(0xff0288D1),
            //     iconcolor: const Color(0xff0288D1),
            //   ),
            // ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: () async {
          setState(() {
            error = "";
            isLoading = LoadingAnimationWidget.staggeredDotsWave(
              color: Colors.white,
              size: 50,
            );
          });

          var res = await submitData(
              widget.incident,
              description,
              myimage,
              location,
              route,
              userid,
              widget.categoryId,
              long.toString(),
              lat.toString(),
              leaktype);

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
            // Show success snackbar
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  res.success ?? 'Report submitted successfully!',
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );

            Timer(const Duration(seconds: 2), () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const Incidences()),
              );
            });
          } else {
            // Show error snackbar
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  res.error ?? 'Failed to submit report',
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff0288D1),
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'Submit Report',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
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
}

Future<Message> submitData(
  String incident,
  String description,
  String myimage,
  String location,
  String route,
  String userId,
  String categoryId,
  String longitude,
  String latitude,
  String leaktype,
) async {
  if (myimage.isEmpty) {
    return Message(
        token: null, success: null, error: "Take Photo of $incident!");
  }

  if (categoryId.isEmpty) {
    return Message(
        token: null, success: null, error: "Category ID is missing!");
  }

  if (incident == "Leakage" && (leaktype.isEmpty || leaktype == "--Select--")) {
    return Message(
        token: null, success: null, error: "Please select the type of leak!");
  }

  print("Category ID here: ${categoryId}");
  print("Incident: ${incident}");
  print("Leak Type: ${leaktype}");

  print("Submitting data to server...");

  try {
    final payload = {
      'description': description,
      'image': myimage,
      'location': location,
      'route': route,
      'userId': userId.isNotEmpty ? userId : null,
      'categoryId': categoryId,
      'longitude': longitude,
      'latitude': latitude,
      'incidentType': incident == "Leakage" ? leaktype : null,
    };

    print("Request payload: $payload");

    final response = await post(
      Uri.parse("${getUrl()}om/reports"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(payload),
    );

    print("Response status code: ${response.statusCode}"); // Debug log
    print("Response body: ${response.body}"); // Debug log

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Message.fromJson(jsonDecode(response.body));
    } else {
      // Try to parse the error message from the response
      String errorMessage = "Server error (${response.statusCode})!";
      try {
        final errorData = jsonDecode(response.body);
        if (errorData['error'] != null) {
          errorMessage += " ${errorData['error']}";
        } else if (errorData['message'] != null) {
          errorMessage += " ${errorData['message']}";
        } else {
          errorMessage += " ${response.body}";
        }
      } catch (e) {
        errorMessage += " ${response.body}";
      }

      return Message(
        token: null,
        success: null,
        error: errorMessage,
      );
    }
  } catch (e) {
    print("Error submitting data: $e"); // Debug log
    return Message(
      token: null,
      success: null,
      error: "Connection failed! Check your internet connection. Error: $e",
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
