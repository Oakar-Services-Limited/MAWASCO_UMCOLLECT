import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:um_collect/pages/NRWComplete.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:um_collect/components/MyDrawer.dart';
import 'package:um_collect/components/MyTextInputII.dart';
import 'package:um_collect/components/SubmitButton.dart';
import 'package:um_collect/components/Utils.dart';
import 'package:um_collect/pages/TextOakar.dart';

class FileReportNRW extends StatefulWidget {
  final String incidentid;
  const FileReportNRW({super.key, required this.incidentid});

  @override
  State<FileReportNRW> createState() => _FileReportNRWState();
}

class _FileReportNRWState extends State<FileReportNRW> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  var isLoading;
  String userid = '';
  String staffid = '';
  String incidentId = '';
  String incident = '';
  String error = '';
  String serial = '';
  String type = '';
  String description = '';
  String latitude = '0';
  String longitude = '0';
  String taskremark = '';
  String status = '';
  String imageUrl = '';
  String repairedImage = '';
  bool successful = false;

  String capturedImageUrl = '';
  dynamic userData = [];
  late File? _image;
  final imagePicker = ImagePicker();

  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _image = null;
    loadFileReport(widget.incidentid);
  }

  Future<String> convertFileToBase64(XFile file) async {
    List<int> fileBytes = await file.readAsBytes();
    String base64String = base64Encode(fileBytes);
    return base64String;
  }

  Future<void> loadFileReport(String id) async {
    setState(() {
      isLoading = LoadingAnimationWidget.horizontalRotatingDots(
        color: const Color(0xff0288D1),
        size: 100,
      );
    });

    try {
      final response = await get(
        Uri.parse("${getUrl()}nrw_leakages/$id"),
      );

      var data = json.decode(response.body);
      setState(() {
        userData = data;
        type = data["Type"];
        description = data["Description"];
        serial = data["SerialNo"].toString();
        latitude = data["Latitude"];
        longitude = data["Longitude"];
        status = data["Status"];
        imageUrl = data["Image"];
        incidentId = id;
        staffid = data["NRWUserID"];
        isLoading = null;
      });
    } catch (e) {
      setState(() {
        isLoading = null;
      });
    }
  }

  Future<void> takePhoto() async {
    final XFile? pickedFile = await imagePicker.pickImage(
      source: ImageSource.camera, // Open the camera to take a photo
    );

    if (pickedFile != null) {
      String base64Image = await convertFileToBase64(pickedFile);
      // Here you can save `base64Image` to your database

      setState(() {
        _image = File(pickedFile.path);
        repairedImage = base64Image;
      });
    } else {}
  }

  Future getImage() async {
    final pickedFile = await imagePicker.pickImage(
        source: ImageSource
            .gallery); // This will open the image picker for selecting from the gallery

    if (pickedFile != null) {
      String base64Image = await convertFileToBase64(pickedFile);
      setState(() {
        _image = File(pickedFile.path);
        repairedImage = base64Image;
      });
    } else {}
  }

  DateTime parsePostgresTimestamp(String timestamp) {
    return DateTime.parse(timestamp)
        .toLocal(); // Parse timestamp and convert to local time
  }

  @override
  Widget build(BuildContext context) {
    final String fullImageUrl = imageUrl.isNotEmpty
        ? "${getUrl()}uploads/${imageUrl.replaceAll("uploads/", "")}"
        : '';
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Row(
          children: [
            Flexible(
              flex: 1,
              fit: FlexFit.tight,
              child: Row(
                children: [
                  Text(
                    userData.isNotEmpty
                        ? userData["Type"]
                        : "Reported Incident",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: const Icon(Icons.arrow_back),
            )
          ],
        ),
        backgroundColor: const Color(0xff0288D1),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const MyDrawer(),
      body: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Text(
                      'Captured Photo',
                      style: TextStyle(
                        color: Color(0xff0288D1),
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  imageUrl.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          child: Container(
                              width: double.infinity,
                              clipBehavior: Clip.hardEdge,
                              decoration: BoxDecoration(
                                color: Colors.white, // Cream color
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Colors.grey.withOpacity(0.1),
                                    width: 0),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color.fromARGB(82, 158, 158, 158),
                                    offset: Offset(2.0, 2.0),
                                    blurRadius: 5.0,
                                    spreadRadius: 2.0,
                                  ),
                                ],
                              ),
                              child: SizedBox(
                                height: 250,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          if (fullImageUrl.isNotEmpty) {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return Dialog(
                                                  child: InteractiveViewer(
                                                    child: Image.network(
                                                      fullImageUrl,
                                                      fit: BoxFit.contain,
                                                      loadingBuilder: (context,
                                                          child,
                                                          loadingProgress) {
                                                        if (loadingProgress ==
                                                            null) return child;
                                                        return const Center(
                                                          child:
                                                              CircularProgressIndicator(),
                                                        );
                                                      },
                                                      errorBuilder: (context,
                                                          error, stackTrace) {
                                                        return const Center(
                                                          child: Text(
                                                              'Failed to load image'),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                );
                                              },
                                            );
                                          }
                                        },
                                        child: Image.network(
                                          fullImageUrl,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (context, child,
                                              loadingProgress) {
                                            if (loadingProgress == null) {
                                              return child;
                                            }
                                            return const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            );
                                          },
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return const Center(
                                              child:
                                                  Text('Image not available'),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        )
                      : const SizedBox(),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: Text(
                      'Incident Details',
                      style: TextStyle(
                        color: Color(0xff0288D1),
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  userData.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white, // Cream color
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.grey.withOpacity(0.1),
                                  width: 1),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color.fromARGB(82, 158, 158, 158),
                                  offset: Offset(2.0, 2.0),
                                  blurRadius: 5.0,
                                  spreadRadius: 2.0,
                                ),
                              ],
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(24, 24, 24, 24),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.category,
                                        color: Color(0xff0288D1),
                                      ),
                                      const SizedBox(
                                        width: 4,
                                      ),
                                      Expanded(
                                        child: Text(
                                          'Category: $type',
                                          softWrap: true,
                                          style: const TextStyle(
                                              fontSize: 16,
                                              color: Color.fromARGB(
                                                  255, 28, 100, 140),
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const Text(""),
                                    ],
                                  ),
                                  const Divider(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.pin,
                                        color: Color(0xff0288D1),
                                      ),
                                      const SizedBox(
                                        width: 4,
                                      ),
                                      Expanded(
                                        child: Text(
                                          'Serial: $serial',
                                          softWrap: true,
                                          style: const TextStyle(
                                              fontSize: 16,
                                              color: Color.fromARGB(
                                                  255, 28, 100, 140),
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const Text(""),
                                    ],
                                  ),
                                  const Divider(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.comment,
                                        color: Color(0xff0288D1),
                                      ),
                                      const SizedBox(
                                        width: 4,
                                      ),
                                      Expanded(
                                        child: Text(
                                          "Description: $description",
                                          softWrap: true,
                                          style: const TextStyle(
                                              fontSize: 16,
                                              color: Color.fromARGB(
                                                  255, 28, 100, 140),
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const Text(""),
                                    ],
                                  ),
                                  const Divider(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.calendar_month,
                                        color: Color(0xff0288D1),
                                      ),
                                      const SizedBox(
                                        width: 4,
                                      ),
                                      Expanded(
                                          child: Text(
                                        "Date Reported: ${DateFormat('EEEE, MMMM d, y').format(parsePostgresTimestamp(userData["createdAt"]))} ${DateFormat('HH:mm').format(parsePostgresTimestamp(userData["createdAt"]))}",
                                        style: const TextStyle(
                                            fontSize: 16,
                                            color: Color.fromARGB(
                                                255, 28, 100, 140),
                                            fontWeight: FontWeight.bold),
                                      )),
                                      const Text(""),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : isLoading != null
                          ? Center(child: isLoading)
                          : const SizedBox(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        height: 24,
                      ),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
                        child: Text(
                          'Take a Photo',
                          style: TextStyle(
                            color: Color(0xff0288D1),
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                        child: Container(
                          width: MediaQuery.of(context).size.width,
                          clipBehavior: Clip.hardEdge,
                          decoration: BoxDecoration(
                            color: Colors.white, // Cream color
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.grey.withOpacity(0.1), width: 1),
                            boxShadow: const [
                              BoxShadow(
                                color: Color.fromARGB(82, 158, 158, 158),
                                offset: Offset(2.0, 2.0),
                                blurRadius: 5.0,
                                spreadRadius: 2.0,
                              ),
                            ],
                          ),
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
                                    : Image.file(
                                        _image!,
                                        fit: BoxFit.cover,
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
                      ),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 24, 16, 0),
                        child: Text(
                          'Describe Action Taken',
                          style: TextStyle(
                            color: Color.fromARGB(
                                255, 28, 100, 140), // Cream color

                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                        child: MyTextInputII(
                          lines: 1,
                          value: '',
                          type: TextInputType.text,
                          customIcon: Icons.local_activity,
                          onSubmit: (value) {
                            setState(() {
                              taskremark = value;
                            });
                          },
                          hint: 'Action',
                          mycolor: const Color(0xff0288D1),
                          iconcolor: const Color(0xff0288D1),
                        ),
                      ),
                      TextOakar(label: error, issuccessful: successful),
                      Center(
                        child: isLoading ?? const SizedBox(),
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: SubmitButton(
                          label: "Submit",
                          onButtonPressed: () async {
                            setState(() {
                              error = "";
                              isLoading =
                                  LoadingAnimationWidget.staggeredDotsWave(
                                color: const Color(0xff0288D1),
                                size: 100,
                              );
                            });

                            var res = await submitData(
                                incidentId, repairedImage, taskremark);
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
                              Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => NRWComplete(
                                            staffid: staffid,
                                          )));
                            }
                          },
                        ),
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<Message> submitData(
  String incidentId,
  String repairedImage,
  String taskremark,
) async {
  if (repairedImage.isEmpty || taskremark.isEmpty) {
    return Message(
        token: null, success: null, error: "All Fields Must Be Filled!");
  }

  DateTime now = DateTime.now();
  String resolvedDate = DateFormat('YYYY-MM-DD').format(now);
  String resolvedTime = DateFormat('hh:mm a').format(now);

  try {
    var response = await put(
      Uri.parse("${getUrl()}nrw_leakages/update/$incidentId"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'TaskImage': repairedImage,
        'TaskRemark': taskremark,
        'ResolvedDate': resolvedDate,
        'ResolvedTime': resolvedTime,
        'Status': 'Resolved',
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
