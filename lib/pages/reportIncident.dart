import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:um_collect/components/MySelectInput.dart';
import 'package:um_collect/components/MyTextInputII.dart';
import 'package:um_collect/components/MyDrawer.dart';
import 'package:um_collect/components/Utils.dart';
import 'package:um_collect/models/Map.dart';
import 'package:um_collect/pages/incidences.dart';
import 'package:um_collect/pages/TextOakar.dart';
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
  String incidenttype = '';
  String schemetype = '';
  String pipesize = '';
  String pipematerial = '';
  String priority = '';
  var isLoading;
  late File? _image;
  final imagePicker = ImagePicker();
  String userid = '';
  String myimage = '';
  String error = '';
  bool successful = false;

  Future<void> fetchStoredUserData() async {
    try {
      // First check for staff token (priority for staff users)
      var staffToken = await storage.read(key: "mwstaffjwt");
      if (staffToken != null) {
        var decoded = parseJwt(staffToken.toString());
        var id = decoded["id"];
        if (mounted) {
          setState(() {
            userid = id.toString();
            reportertype = "Staff";
            // Get staff name and phone from JWT
            phone = decoded["Phone"] ??
                decoded["phone"] ??
                decoded["PhoneNumber"] ??
                decoded["phoneNumber"] ??
                "";
            name = decoded["name"] ?? decoded["Name"] ?? "";
          });
        }
        return; // Exit early if staff token found
      }

      // If no staff token, check for public user token
      var token = await storage.read(key: "mwjwt");
      if (token != null) {
        var decoded = parseJwt(token.toString());
        var id = decoded["id"];
        if (mounted) {
          setState(() {
            userid = id.toString();
            reportertype = "Public";
          });
        }
      } else {
        if (mounted) {
          setState(() {
            userid = '';
            reportertype = "Public";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          userid = '';
          reportertype = "Public";
        });
      }
    }
  }

  StreamSubscription<Position>? _locationSubscription;

  Future<void> getLocation() async {
    LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
    );

    _locationSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) {
      if (mounted) {
        setState(() {
          long = position.longitude;
          lat = position.latitude;
          acc = position.accuracy;
        });
      }
    });
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

  @override
  void initState() {
    super.initState();
    _image = null;
    getLocation();
    fetchStoredUserData();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
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
                        if (widget.incident == "Sewer Burst" &&
                            reportertype == "Staff") ...[
                          _buildSectionTitle('Incident Details'),
                          const SizedBox(height: 12),
                          _buildSewerIncidentSelector(),
                          const SizedBox(height: 24),
                        ],
                        if (widget.incident == "Leakage" &&
                            reportertype == "Staff") ...[
                          _buildSectionTitle('Incident Details'),
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
              incidenttype = value;
            });
          },
          list: const [
            "--Select--",
            "Blockage",
            "Burst",
          ],
          label: 'Select Type of Sewer Burst',
          value: incidenttype,
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
              incidenttype = value;
            });
          },
          list: const [
            "--Select--",
            "Leakage",
            "Burst",
          ],
          label: 'Select Type of Leak',
          value: incidenttype,
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
            if (reportertype != "Staff") ...[
              MyTextInputII(
                hint: 'Incident Type',
                lines: 1,
                value: widget.incident,
                type: TextInputType.text,
                onSubmit: (value) {
                  setState(() {
                    incidenttype = value;
                  });
                },
                customIcon: Icons.warning_rounded,
                mycolor: const Color(0xff0288D1),
                iconcolor: const Color(0xff0288D1),
                readOnly: true,
              ),
              const SizedBox(height: 16),
              MyTextInputII(
                hint: 'Your Name (Optional)',
                lines: 1,
                value: name,
                type: TextInputType.text,
                onSubmit: (value) {
                  setState(() {
                    name = value;
                  });
                },
                customIcon: Icons.person_outline_rounded,
                mycolor: const Color(0xff0288D1),
                iconcolor: const Color(0xff0288D1),
              ),
              const SizedBox(height: 16),
              MyTextInputII(
                hint: 'Your Phone Number (Optional)',
                lines: 1,
                value: phone,
                type: TextInputType.phone,
                onSubmit: (value) {
                  setState(() {
                    phone = value;
                  });
                },
                customIcon: Icons.phone_outlined,
                mycolor: const Color(0xff0288D1),
                iconcolor: const Color(0xff0288D1),
              ),
              const SizedBox(height: 16),
            ],
            if (widget.incident == "Leakage" && reportertype == "Staff") ...[
              MySelectInput(
                onSubmit: (value) {
                  setState(() {
                    schemetype = value;
                  });
                },
                list: const [
                  "--Select--",
                  "Urban",
                  "Rural",
                ],
                label: 'Select Scheme',
                value: schemetype,
                labelFontSize: 18,
              ),
              const SizedBox(height: 16),
              MySelectInput(
                onSubmit: (value) {
                  setState(() {
                    pipematerial = value;
                    // Reset size when material changes
                    pipesize = '';
                  });
                },
                list: const ["--Select--", "HDPE", "PVC", "GI"],
                label: 'Pipe Material',
                value: pipematerial,
                labelFontSize: 18,
              ),
              const SizedBox(height: 16),
              MySelectInput(
                onSubmit: (value) {
                  setState(() {
                    pipesize = value;
                  });
                },
                list: pipematerial == "HDPE" || pipematerial == "PVC"
                    ? const [
                        "--Select--",
                        "20mm",
                        "25mm",
                        "32mm",
                        "40mm",
                        "50mm",
                        "63mm",
                        "75mm",
                        "90mm",
                        "110mm",
                        "160mm",
                        "225mm",
                        "280mm",
                        "315mm",
                        "355mm"
                      ]
                    : pipematerial == "GI"
                        ? const [
                            "--Select--",
                            "15mm",
                            "20mm",
                            "25mm",
                            "40mm",
                            "50mm",
                            "60mm",
                            "80mm",
                            "100mm",
                            "150mm",
                            "200mm",
                            "250mm",
                            "300mm",
                            "350mm"
                          ]
                        : const ["--Select--"],
                label: 'Pipe Size',
                value: pipesize,
                labelFontSize: 18,
              ),
              const SizedBox(height: 16),
            ],
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
            const SizedBox(height: 16),
            MySelectInput(
              onSubmit: (value) {
                setState(() {
                  priority = value;
                });
              },
              list: const ["--Select Priority--", "Low", "Medium", "High"],
              label: 'How urgent is the incident?',
              value: priority,
              labelFontSize: 18,
            ),
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
              incidenttype,
              schemetype,
              pipesize,
              reportertype,
              name,
              phone,
              pipematerial,
              priority);

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
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const Incidences()),
                );
              }
            });
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
  String incidenttype,
  String schemetype,
  String pipesize,
  String reportertype,
  String name,
  String phone,
  String pipematerial,
  String priority,
) async {
  if (myimage.isEmpty && incident != "Supply Fail") {
    return Message(
        token: null, success: null, error: "Take Photo of $incident!");
  }

  if (categoryId.isEmpty) {
    return Message(
        token: null, success: null, error: "Category ID is missing!");
  }

  // Only validate incident type selection for staff reporters
  if (reportertype == "Staff" &&
      (incident == "Leakage" || incident == "Sewer Burst") &&
      (incidenttype.isEmpty || incidenttype == "--Select--")) {
    return Message(
        token: null,
        success: null,
        error: "Please select the type of ${incident.toLowerCase()}!");
  }

  if (incident == "Leakage" && reportertype == "Staff") {
    if (schemetype.isEmpty || schemetype == "--Select--") {
      return Message(
          token: null, success: null, error: "Please select the scheme type!");
    }
    if (pipematerial.isEmpty || pipematerial == "--Select--") {
      return Message(
          token: null,
          success: null,
          error: "Please select the pipe material!");
    }
    if (pipesize.isEmpty || pipesize == "--Select--") {
      return Message(
          token: null, success: null, error: "Please select the pipe size!");
    }
  }
  try {
    final payload = {
      'description': description,
      'image': myimage,
      'location': location,
      'route': route,
      'userId': reportertype == "Staff" ? userId : null,
      'categoryId': categoryId,
      'longitude': longitude,
      'latitude': latitude,
      'incidentType': reportertype == "Staff"
          ? (incident == "Leakage" || incident == "Sewer Burst")
              ? incidenttype
              : null
          : incident,
      'schemeType':
          incident == "Leakage" && reportertype == "Staff" ? schemetype : null,
      'pipeSize':
          incident == "Leakage" && reportertype == "Staff" ? pipesize : null,
      'pipeMaterial': incident == "Leakage" && reportertype == "Staff"
          ? pipematerial
          : null,
      'reporterName': name,
      'reporterPhone': phone,
      'priority': priority,
    };

    final response = await post(
      Uri.parse("${getUrl()}om/reports"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(payload),
    );

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
